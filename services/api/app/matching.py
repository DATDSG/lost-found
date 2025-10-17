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

from .config import config
from .models import Report, ReportType
from .clients import get_nlp_client, get_vision_client

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
        Get candidate reports using enhanced text embedding similarity (ANN search).
        
        Returns:
            List of (report_id, similarity_score) tuples
        """
        if report.embedding is None or len(report.embedding) == 0:
            logger.warning(f"Report {report.id} has no embedding")
            return []
        
        # Extended time window for better coverage
        time_window_start = datetime.utcnow() - timedelta(days=config.MATCH_TIME_WINDOW_DAYS * 2)
        
        # Enhanced similarity calculation with multiple distance metrics
        query = select(
            Report.id,
            Report.title,
            Report.description,
            Report.category,
            Report.colors,
            # Primary: Cosine similarity (best for semantic similarity)
            (1 - Report.embedding.cosine_distance(report.embedding)).label("cosine_sim"),
            # Secondary: Euclidean distance (for complementary matching)
            (1 / (1 + Report.embedding.l2_distance(report.embedding))).label("euclidean_sim"),
            # Tertiary: Inner product (for exact phrase matching)
            (Report.embedding.max_inner_product(report.embedding)).label("inner_product")
        ).where(
            and_(
                Report.type == opposite_type,
                Report.status == "approved",
                Report.id != report.id,
                Report.created_at >= time_window_start,
                Report.embedding.isnot(None)
            )
        ).order_by(
            Report.embedding.cosine_distance(report.embedding)
        ).limit(top_k * 2)  # Get more candidates for enhanced filtering
        
        result = await self.db.execute(query)
        candidates = result.all()
        
        # Enhanced scoring with multiple similarity metrics
        enhanced_candidates = []
        for row in candidates:
            cand_id = row.id
            cosine_sim = row.cosine_sim
            euclidean_sim = row.euclidean_sim
            inner_product = row.inner_product
            
            # Weighted combination of similarity metrics
            # Cosine similarity (70%) + Euclidean (20%) + Inner product (10%)
            combined_score = (
                cosine_sim * 0.7 + 
                euclidean_sim * 0.2 + 
                inner_product * 0.1
            )
            
            # Boost score for category matches
            if row.category == report.category:
                combined_score *= 1.15
            
            # Boost score for color matches
            if row.colors and report.colors:
                color_overlap = len(set(row.colors) & set(report.colors)) / max(len(row.colors), len(report.colors))
                combined_score *= (1 + color_overlap * 0.1)
            
            # Boost score for title keyword matches
            title_words = set(row.title.lower().split())
            desc_words = set(report.description.lower().split()) if report.description else set()
            keyword_overlap = len(title_words & desc_words) / max(len(title_words), len(desc_words), 1)
            combined_score *= (1 + keyword_overlap * 0.05)
            
            # Apply enhanced threshold (slightly lower for better recall)
            if combined_score >= config.MATCH_TEXT_THRESHOLD * 0.85:
                enhanced_candidates.append((cand_id, min(combined_score, 1.0)))
        
        # Sort by enhanced score and return top candidates
        enhanced_candidates.sort(key=lambda x: x[1], reverse=True)
        
        logger.info(f"Found {len(enhanced_candidates)} enhanced text candidates for report {report.id}")
        return enhanced_candidates[:top_k]
    
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
        Calculate enhanced image similarity using multiple perceptual hashes.
        Returns score between 0-1 (1 = identical).
        """
        # Both reports must have images
        if not report.image_hash or not candidate.image_hash:
            return None
        
        try:
            # Parse multi-hash format: {"phash": "...", "dhash": "...", "avg_hash": "..."}
            import json
            
            def parse_hash(hash_str: str) -> Dict[str, str]:
                try:
                    return json.loads(hash_str)
                except:
                    # Fallback: assume it's a single phash
                    return {"phash": hash_str}
            
            report_hashes = parse_hash(report.image_hash)
            candidate_hashes = parse_hash(candidate.image_hash)
            
            # Calculate similarity for each hash type
            similarities = []
            
            # pHash (perceptual hash) - best for overall similarity
            if "phash" in report_hashes and "phash" in candidate_hashes:
                phash_sim = self._calculate_hash_similarity(
                    report_hashes["phash"], 
                    candidate_hashes["phash"]
                )
                similarities.append(("phash", phash_sim, 0.5))  # 50% weight
            
            # dHash (difference hash) - good for structural changes
            if "dhash" in report_hashes and "dhash" in candidate_hashes:
                dhash_sim = self._calculate_hash_similarity(
                    report_hashes["dhash"], 
                    candidate_hashes["dhash"]
                )
                similarities.append(("dhash", dhash_sim, 0.3))  # 30% weight
            
            # avgHash (average hash) - good for color/lighting changes
            if "avg_hash" in report_hashes and "avg_hash" in candidate_hashes:
                avg_hash_sim = self._calculate_hash_similarity(
                    report_hashes["avg_hash"], 
                    candidate_hashes["avg_hash"]
                )
                similarities.append(("avg_hash", avg_hash_sim, 0.2))  # 20% weight
            
            if not similarities:
                return None
            
            # Weighted combination of hash similarities
            total_weight = sum(weight for _, _, weight in similarities)
            weighted_score = sum(sim * weight for _, sim, weight in similarities) / total_weight
            
            # Apply enhanced threshold (slightly lower for better recall)
            if weighted_score < config.MATCH_IMAGE_THRESHOLD * 0.9:
                return None
            
            # Boost score if multiple hash types agree
            if len(similarities) > 1:
                hash_agreement = len([sim for _, sim, _ in similarities if sim > 0.8]) / len(similarities)
                weighted_score *= (1 + hash_agreement * 0.1)
            
            return min(weighted_score, 1.0)
            
        except Exception as e:
            logger.warning(f"Error calculating enhanced image score: {e}")
            # Fallback to simple hash comparison
            return self._calculate_hash_similarity(report.image_hash, candidate.image_hash)
    
    def _calculate_hash_similarity(self, hash1: str, hash2: str) -> float:
        """Calculate similarity between two hashes."""
        if len(hash1) != len(hash2):
            return 0.0
        
        hamming_distance = self._hamming_distance(hash1, hash2)
        hash_length = len(hash1) * 4  # 4 bits per hex char
        similarity = 1 - (hamming_distance / hash_length)
        
        return max(similarity, 0.0)
    
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
        Calculate enhanced geographic proximity score using Haversine formula.
        Returns score between 0-1 (1 = same location).
        """
        # Both reports must have geographic data
        if not report.geo or not candidate.geo:
            return None
        
        try:
            # Parse coordinates from POINT format
            def parse_point(geo_str: str) -> Tuple[float, float]:
                if geo_str.startswith('POINT('):
                    coords = geo_str.replace('POINT(', '').replace(')', '').split()
                    return float(coords[0]), float(coords[1])
                return None, None
            
            report_lng, report_lat = parse_point(report.geo)
            cand_lng, cand_lat = parse_point(candidate.geo)
            
            if None in [report_lng, report_lat, cand_lng, cand_lat]:
                # Fallback to city-based matching
                if report.location_city == candidate.location_city:
                    return 0.6
                return None
            
            # Calculate distance using Haversine formula (more accurate than PostGIS for small distances)
            def haversine_distance(lat1, lon1, lat2, lon2):
                """Calculate the great circle distance between two points on Earth."""
                from math import radians, cos, sin, asin, sqrt
                
                # Convert decimal degrees to radians
                lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
                
                # Haversine formula
                dlat = lat2 - lat1
                dlon = lon2 - lon1
                a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
                c = 2 * asin(sqrt(a))
                
                # Radius of earth in kilometers
                r = 6371
                return c * r
            
            distance_km = haversine_distance(report_lat, report_lng, cand_lat, cand_lng)
            
            # Enhanced scoring with multiple distance zones
            if distance_km <= 0.1:  # Same building/very close
                return 1.0
            elif distance_km <= 0.5:  # Same block
                return 0.95
            elif distance_km <= 1.0:  # Same neighborhood
                return 0.90
            elif distance_km <= 2.0:  # Walking distance
                return 0.80
            elif distance_km <= 5.0:  # Short drive
                return 0.70
            elif distance_km <= 10.0:  # Medium distance
                return 0.50
            elif distance_km <= config.MATCH_GEO_RADIUS_KM:  # Within search radius
                # Exponential decay for distances beyond 10km
                return 0.30 * math.exp(-distance_km / 20.0)
            else:
                return None  # Outside search radius
            
        except Exception as e:
            logger.warning(f"Error calculating geo score: {e}")
            # Fallback to city-based matching
            if report.location_city == candidate.location_city:
                return 0.6
            return None
    
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
        time_diff = abs((report.occurred_at - candidate.occurred_at).days)
        
        # Exponential decay based on time window
        # score = exp(-days / window)
        similarity = math.exp(-time_diff / config.MATCH_TIME_WINDOW_DAYS)
        
        return similarity
    
    def _calculate_composite_score(self, scores: Dict[str, Optional[float]]) -> float:
        """
        Calculate enhanced weighted composite score from all signals.
        Uses adaptive weighting based on signal availability and quality.
        """
        available_signals = [k for k, v in scores.items() if v is not None]
        
        # Base weights from config
        weights = {
            "text": config.MATCH_WEIGHT_TEXT,
            "image": config.MATCH_WEIGHT_IMAGE,
            "geo": config.MATCH_WEIGHT_GEO,
            "time": config.MATCH_WEIGHT_TIME
        }
        
        # Adaptive weighting: boost weights for available signals
        if len(available_signals) < 4:
            # Redistribute weights when signals are missing
            total_available_weight = sum(weights[signal] for signal in available_signals)
            if total_available_weight > 0:
                for signal in available_signals:
                    weights[signal] = weights[signal] / total_available_weight
        
        # Calculate weighted score
        total_score = 0.0
        total_weight = 0.0
        
        for signal, score in scores.items():
            if score is not None:
                # Apply signal quality boost
                quality_boost = 1.0
                if signal == "text" and score > 0.8:
                    quality_boost = 1.1  # Boost high-quality text matches
                elif signal == "image" and score > 0.9:
                    quality_boost = 1.15  # Boost high-quality image matches
                elif signal == "geo" and score > 0.9:
                    quality_boost = 1.05  # Boost very close geographic matches
                
                total_score += score * weights[signal] * quality_boost
                total_weight += weights[signal] * quality_boost
        
        # Normalize by total weight
        if total_weight == 0:
            return 0.0
        
        composite_score = total_score / total_weight
        
        # Apply signal diversity bonus
        if len(available_signals) >= 3:
            composite_score *= 1.05  # 5% bonus for multi-signal matches
        
        # Apply high-confidence bonus
        high_confidence_signals = sum(1 for signal, score in scores.items() 
                                    if score is not None and score > 0.85)
        if high_confidence_signals >= 2:
            composite_score *= 1.1  # 10% bonus for multiple high-confidence signals
        
        return min(composite_score, 1.0)
    
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
        async with get_nlp_client() as nlp_client:
            embedding = await nlp_client.get_embedding(report.description)
        
        if embedding is None or len(embedding) == 0:
            logger.error(f"Failed to get embedding for report {report.id}")
            return False
        
        # Update report
        report.embedding = embedding
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
        async with get_vision_client() as vision_client:
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
