"""
Multi-signal matching pipeline for Lost & Found items.
Implements weighted scoring based on:
- Text embeddings (NLP) - 45%
- Image hashing (Vision) - 35%
- Geo proximity (PostGIS) - 15%
- Time recency - 5%
"""
import math
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from geoalchemy2.functions import ST_Distance, ST_MakePoint
from pgvector.sqlalchemy import Vector
import logging

from ..config import config
from ..models import Report, ReportType
from ..clients import get_nlp_client, get_vision_client

logger = logging.getLogger(__name__)


class MatchingPipeline:
    """Multi-signal matching pipeline."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def find_matches(
        self,
        report: Report,
        max_results: int = None
    ) -> List[Dict[str, Any]]:
        """
        Find potential matches for a report using multi-signal scoring.
        
        Args:
            report: The report to find matches for
            max_results: Maximum number of matches to return
        
        Returns:
            List of matches with scores and explanations
        """
        max_results = max_results or config.MATCH_MAX_RESULTS
        
        # Determine opposite report type
        opposite_type = (
            ReportType.FOUND if report.type == ReportType.LOST 
            else ReportType.LOST
        )
        
        # Stage 1: Text similarity search (ANN with pgvector)
        text_candidates = await self._get_text_candidates(
            report,
            opposite_type,
            top_k=config.ANN_TOP_K
        )
        
        if not text_candidates:
            logger.info(f"No text candidates found for report {report.id}")
            return []
        
        # Stage 2: Calculate composite scores
        matches = []
        
        for candidate_id, text_score in text_candidates:
            # Get candidate report
            result = await self.db.execute(
                select(Report).where(Report.id == candidate_id)
            )
            candidate = result.scalar_one_or_none()
            
            if not candidate:
                continue
            
            # Calculate all signal scores
            scores = await self._calculate_all_scores(report, candidate, text_score)
            
            # Calculate weighted composite score
            composite_score = self._calculate_composite_score(scores)
            
            # Only include if above threshold
            if composite_score >= config.MATCH_MIN_SCORE:
                matches.append({
                    "candidate_id": candidate.id,
                    "candidate": candidate,
                    "score": composite_score,
                    "scores": scores,
                    "explanation": self._generate_explanation(scores)
                })
        
        # Sort by composite score descending
        matches.sort(key=lambda x: x["score"], reverse=True)
        
        # Return top N matches
        return matches[:max_results]
    
    async def _get_text_candidates(
        self,
        report: Report,
        opposite_type: ReportType,
        top_k: int
    ) -> List[Tuple[int, float]]:
        """
        Get candidate reports using text embedding similarity (ANN search).
        
        Returns:
            List of (report_id, similarity_score) tuples
        """
        if not report.description_embedding:
            logger.warning(f"Report {report.id} has no description embedding")
            return []
        
        # Time window filter
        time_window_start = datetime.utcnow() - timedelta(days=config.MATCH_TIME_WINDOW_DAYS)
        
        # Use pgvector cosine similarity for ANN search
        # <=> is the cosine distance operator in pgvector
        query = select(
            Report.id,
            (1 - Report.description_embedding.cosine_distance(report.description_embedding)).label("similarity")
        ).where(
            and_(
                Report.type == opposite_type,
                Report.status == "active",
                Report.id != report.id,
                Report.created_at >= time_window_start,
                Report.description_embedding.isnot(None)
            )
        ).order_by(
            Report.description_embedding.cosine_distance(report.description_embedding)
        ).limit(top_k)
        
        result = await self.db.execute(query)
        candidates = result.all()
        
        # Filter by text threshold
        candidates = [
            (cand_id, sim) 
            for cand_id, sim in candidates 
            if sim >= config.MATCH_TEXT_THRESHOLD
        ]
        
        logger.info(f"Found {len(candidates)} text candidates for report {report.id}")
        return candidates
    
    async def _calculate_all_scores(
        self,
        report: Report,
        candidate: Report,
        text_score: float
    ) -> Dict[str, Optional[float]]:
        """Calculate all signal scores."""
        return {
            "text": text_score,
            "image": await self._calculate_image_score(report, candidate),
            "geo": await self._calculate_geo_score(report, candidate),
            "time": self._calculate_time_score(report, candidate),
        }
    
    async def _calculate_image_score(
        self,
        report: Report,
        candidate: Report
    ) -> Optional[float]:
        """
        Calculate image similarity using perceptual hashes.
        Returns score between 0-1 (1 = identical).
        """
        # Both reports must have images
        if not report.image_hash or not candidate.image_hash:
            return None
        
        # Calculate Hamming distance between hashes
        hamming_distance = self._hamming_distance(report.image_hash, candidate.image_hash)
        
        # Convert to similarity (normalize by hash length)
        # phash is typically 64 bits
        hash_length = len(report.image_hash) * 4  # 4 bits per hex char
        similarity = 1 - (hamming_distance / hash_length)
        
        # Apply threshold
        if similarity < config.MATCH_IMAGE_THRESHOLD:
            return None
        
        return similarity
    
    def _hamming_distance(self, hash1: str, hash2: str) -> int:
        """Calculate Hamming distance between two hex hashes."""
        if len(hash1) != len(hash2):
            return max(len(hash1), len(hash2)) * 4  # Max distance
        
        distance = 0
        for c1, c2 in zip(hash1, hash2):
            # Convert hex to binary and count differing bits
            xor = int(c1, 16) ^ int(c2, 16)
            distance += bin(xor).count('1')
        
        return distance
    
    async def _calculate_geo_score(
        self,
        report: Report,
        candidate: Report
    ) -> Optional[float]:
        """
        Calculate geographic proximity score using PostGIS.
        Returns score between 0-1 (1 = same location).
        """
        # Both reports must have locations
        if not report.location or not candidate.location:
            return None
        
        # Calculate distance in kilometers using PostGIS
        query = select(
            func.ST_Distance(
                func.ST_Transform(report.location, 4326),  # WGS84
                func.ST_Transform(candidate.location, 4326)
            ).label("distance_degrees")
        )
        
        result = await self.db.execute(query)
        distance_degrees = result.scalar()
        
        # Convert degrees to kilometers (approximate)
        distance_km = distance_degrees * 111.32  # 1 degree ≈ 111.32 km at equator
        
        # Apply radius filter
        if distance_km > config.MATCH_GEO_RADIUS_KM:
            return None
        
        # Convert to similarity score (exponential decay)
        # score = exp(-distance / radius)
        similarity = math.exp(-distance_km / config.MATCH_GEO_RADIUS_KM)
        
        return similarity
    
    def _calculate_time_score(
        self,
        report: Report,
        candidate: Report
    ) -> float:
        """
        Calculate time recency score based on report dates.
        Returns score between 0-1 (1 = same day).
        """
        # Calculate time difference in days
        time_diff = abs((report.incident_date - candidate.incident_date).days)
        
        # Exponential decay based on time window
        # score = exp(-days / window)
        similarity = math.exp(-time_diff / config.MATCH_TIME_WINDOW_DAYS)
        
        return similarity
    
    def _calculate_composite_score(self, scores: Dict[str, Optional[float]]) -> float:
        """
        Calculate weighted composite score from all signals.
        Missing signals are excluded from calculation.
        """
        total_score = 0.0
        total_weight = 0.0
        
        # Text signal
        if scores["text"] is not None:
            total_score += scores["text"] * config.MATCH_WEIGHT_TEXT
            total_weight += config.MATCH_WEIGHT_TEXT
        
        # Image signal
        if scores["image"] is not None:
            total_score += scores["image"] * config.MATCH_WEIGHT_IMAGE
            total_weight += config.MATCH_WEIGHT_IMAGE
        
        # Geo signal
        if scores["geo"] is not None:
            total_score += scores["geo"] * config.MATCH_WEIGHT_GEO
            total_weight += config.MATCH_WEIGHT_GEO
        
        # Time signal (always present)
        total_score += scores["time"] * config.MATCH_WEIGHT_TIME
        total_weight += config.MATCH_WEIGHT_TIME
        
        # Normalize by total weight
        if total_weight == 0:
            return 0.0
        
        return total_score / total_weight
    
    def _generate_explanation(self, scores: Dict[str, Optional[float]]) -> str:
        """Generate human-readable explanation of match."""
        parts = []
        
        if scores["text"] is not None:
            parts.append(f"Text similarity: {scores['text']:.2%}")
        
        if scores["image"] is not None:
            parts.append(f"Image similarity: {scores['image']:.2%}")
        
        if scores["geo"] is not None:
            parts.append(f"Location proximity: {scores['geo']:.2%}")
        
        parts.append(f"Time recency: {scores['time']:.2%}")
        
        return " | ".join(parts)
    
    async def update_report_embeddings(self, report: Report) -> bool:
        """
        Update text embeddings for a report using NLP service.
        
        Args:
            report: Report to update
        
        Returns:
            True if successful
        """
        if not report.description:
            logger.warning(f"Report {report.id} has no description")
            return False
        
        # Get embedding from NLP service
        async with await get_nlp_client() as nlp_client:
            embedding = await nlp_client.get_embedding(report.description)
        
        if not embedding:
            logger.error(f"Failed to get embedding for report {report.id}")
            return False
        
        # Update report
        report.description_embedding = embedding
        await self.db.commit()
        
        logger.info(f"Updated embedding for report {report.id}")
        return True
    
    async def update_image_hash(self, report: Report, image_url: str) -> bool:
        """
        Update image hash for a report using Vision service.
        
        Args:
            report: Report to update
            image_url: URL of the image
        
        Returns:
            True if successful
        """
        # Get perceptual hash from Vision service
        async with await get_vision_client() as vision_client:
            image_hash = await vision_client.get_image_hash(image_url)
        
        if not image_hash:
            logger.error(f"Failed to get image hash for report {report.id}")
            return False
        
        # Update report
        report.image_hash = image_hash
        await self.db.commit()
        
        logger.info(f"Updated image hash for report {report.id}")
        return True


async def get_matching_pipeline(db: AsyncSession) -> MatchingPipeline:
    """Get matching pipeline instance."""
    return MatchingPipeline(db)
