"""
Enhanced Matching Service
------------------------
Intelligent matching service that combines NLP and Vision services
for better Lost & Found item matching with multi-signal scoring.
"""
import asyncio
import logging
from typing import List, Optional, Dict, Any, Tuple
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func

from .infrastructure.database.session import get_async_db
from .models import User
from .domains.reports.models.report import Report
from .domains.matches.models.match import Match
from .clients import get_nlp_client, get_vision_client
from .config import config

logger = logging.getLogger(__name__)


class EnhancedMatchingService:
    """Enhanced matching service with multi-signal scoring."""
    
    def __init__(self):
        self.nlp_client = None
        self.vision_client = None
    
    async def __aenter__(self):
        """Async context manager entry."""
        self.nlp_client = get_nlp_client()
        self.vision_client = get_vision_client()
        await self.nlp_client.__aenter__()
        await self.vision_client.__aenter__()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        if self.nlp_client:
            await self.nlp_client.__aexit__(exc_type, exc_val, exc_tb)
        if self.vision_client:
            await self.vision_client.__aexit__(exc_type, exc_val, exc_tb)
    
    async def find_matches_for_report(
        self,
        report_id: int,
        db: Session,
        text_threshold: float = 0.7,
        image_threshold: float = 0.8,
        location_threshold: float = 0.5,
        max_matches: int = 20
    ) -> List[Dict[str, Any]]:
        """
        Find matches for a report using enhanced multi-signal matching.
        
        Args:
            report_id: ID of the report to find matches for
            db: Database session
            text_threshold: Minimum text similarity threshold
            image_threshold: Minimum image similarity threshold
            location_threshold: Minimum location similarity threshold
            max_matches: Maximum number of matches to return
        
        Returns:
            List of matches with combined scores
        """
        # Get the source report
        source_report = db.query(Report).filter(Report.id == report_id).first()
        if not source_report:
            logger.error(f"Report {report_id} not found")
            return []
        
        logger.info(f"Finding matches for report {report_id}: {source_report.title}")
        
        # Get candidate reports (opposite type, active status)
        candidate_type = "found" if source_report.type == "lost" else "lost"
        candidate_reports = db.query(Report).filter(
            and_(
                Report.type == candidate_type,
                Report.status == "active",
                Report.id != report_id
            )
        ).all()
        
        if not candidate_reports:
            logger.info(f"No candidate reports found for type {candidate_type}")
            return []
        
        logger.info(f"Found {len(candidate_reports)} candidate reports")
        
        # Process matches in parallel
        match_tasks = []
        for candidate in candidate_reports:
            task = self._calculate_match_score(
                source_report, candidate, text_threshold, image_threshold, location_threshold
            )
            match_tasks.append(task)
        
        # Wait for all match calculations to complete
        match_results = await asyncio.gather(*match_tasks, return_exceptions=True)
        
        # Filter and sort matches
        valid_matches = []
        for i, result in enumerate(match_results):
            if isinstance(result, Exception):
                logger.error(f"Match calculation failed for candidate {candidate_reports[i].id}: {result}")
                continue
            
            if result and result.get("combined_score", 0) > 0:
                valid_matches.append(result)
        
        # Sort by combined score (descending)
        valid_matches.sort(key=lambda x: x["combined_score"], reverse=True)
        
        # Limit results
        top_matches = valid_matches[:max_matches]
        
        logger.info(f"Found {len(top_matches)} high-quality matches")
        
        # Save matches to database
        await self._save_matches_to_db(report_id, top_matches, db)
        
        return top_matches
    
    async def _calculate_match_score(
        self,
        source_report: Report,
        candidate_report: Report,
        text_threshold: float,
        image_threshold: float,
        location_threshold: float
    ) -> Optional[Dict[str, Any]]:
        """
        Calculate comprehensive match score between two reports.
        
        Args:
            source_report: Source report
            candidate_report: Candidate report
            text_threshold: Text similarity threshold
            image_threshold: Image similarity threshold
            location_threshold: Location similarity threshold
        
        Returns:
            Match result with scores or None if below thresholds
        """
        try:
            # Initialize scores
            text_score = 0.0
            image_score = 0.0
            location_score = 0.0
            metadata_score = 0.0
            
            # Calculate text similarity
            if source_report.description and candidate_report.description:
                text_score = await self._calculate_text_similarity(
                    source_report.description, candidate_report.description
                )
            
            # Calculate image similarity
            if source_report.image_path and candidate_report.image_path:
                image_score = await self._calculate_image_similarity(
                    source_report.image_path, candidate_report.image_path
                )
            
            # Calculate location similarity
            if (source_report.latitude and source_report.longitude and 
                candidate_report.latitude and candidate_report.longitude):
                location_score = self._calculate_location_similarity(
                    source_report.latitude, source_report.longitude,
                    candidate_report.latitude, candidate_report.longitude
                )
            
            # Calculate metadata similarity
            metadata_score = self._calculate_metadata_similarity(source_report, candidate_report)
            
            # Check if any score meets minimum thresholds
            if (text_score < text_threshold and 
                image_score < image_threshold and 
                location_score < location_threshold):
                return None
            
            # Calculate combined score with weights
            combined_score = (
                text_score * 0.4 +           # Text similarity weight
                image_score * 0.3 +          # Image similarity weight
                location_score * 0.2 +       # Location similarity weight
                metadata_score * 0.1         # Metadata similarity weight
            )
            
            return {
                "candidate_report_id": candidate_report.id,
                "candidate_title": candidate_report.title,
                "candidate_description": candidate_report.description,
                "candidate_image_url": candidate_report.image_path,
                "candidate_location": {
                    "latitude": candidate_report.latitude,
                    "longitude": candidate_report.longitude,
                    "address": candidate_report.location
                },
                "candidate_contact_info": candidate_report.contact_info,
                "candidate_created_at": candidate_report.created_at.isoformat(),
                "scores": {
                    "text_similarity": text_score,
                    "image_similarity": image_score,
                    "location_similarity": location_score,
                    "metadata_similarity": metadata_score,
                    "combined_score": combined_score
                },
                "match_confidence": self._calculate_confidence_level(combined_score),
                "match_reasons": self._generate_match_reasons(
                    text_score, image_score, location_score, metadata_score
                )
            }
            
        except Exception as e:
            logger.error(f"Error calculating match score: {e}")
            return None
    
    async def _calculate_text_similarity(self, text1: str, text2: str) -> float:
        """Calculate text similarity using NLP service."""
        try:
            if not self.nlp_client:
                return 0.0
            
            similarity = await self.nlp_client.calculate_similarity(
                text1, text2, algorithm="combined"
            )
            return similarity or 0.0
            
        except Exception as e:
            logger.error(f"Text similarity calculation failed: {e}")
            return 0.0
    
    async def _calculate_image_similarity(self, image1_path: str, image2_path: str) -> float:
        """Calculate image similarity using Vision service."""
        try:
            if not self.vision_client:
                return 0.0
            
            # Generate hashes for both images
            hashes1 = await self.vision_client.generate_image_hashes(image1_path)
            hashes2 = await self.vision_client.generate_image_hashes(image2_path)
            
            if not hashes1 or not hashes2:
                return 0.0
            
            # Calculate similarity using pHash (most reliable)
            similarity_result = await self.vision_client.calculate_image_similarity(
                hashes1["phash"], hashes2["phash"], algorithm="combined"
            )
            
            if similarity_result:
                return similarity_result[0]  # Return similarity score
            
            return 0.0
            
        except Exception as e:
            logger.error(f"Image similarity calculation failed: {e}")
            return 0.0
    
    def _calculate_location_similarity(
        self, 
        lat1: float, lon1: float, 
        lat2: float, lon2: float
    ) -> float:
        """Calculate location similarity based on distance."""
        try:
            from geopy.distance import geodesic
            
            # Calculate distance in kilometers
            distance = geodesic((lat1, lon1), (lat2, lon2)).kilometers
            
            # Convert distance to similarity score (0-1)
            # Within 1km = 1.0, within 5km = 0.8, within 10km = 0.6, etc.
            if distance <= 1:
                return 1.0
            elif distance <= 5:
                return 0.8
            elif distance <= 10:
                return 0.6
            elif distance <= 25:
                return 0.4
            elif distance <= 50:
                return 0.2
            else:
                return 0.0
                
        except Exception as e:
            logger.error(f"Location similarity calculation failed: {e}")
            return 0.0
    
    def _calculate_metadata_similarity(self, report1: Report, report2: Report) -> float:
        """Calculate metadata similarity (category, color, etc.)."""
        try:
            score = 0.0
            factors = 0
            
            # Category similarity
            if report1.category and report2.category:
                if report1.category == report2.category:
                    score += 1.0
                factors += 1
            
            # Color similarity (basic)
            if report1.color and report2.color:
                if report1.color.lower() == report2.color.lower():
                    score += 1.0
                factors += 1
            
            # Brand similarity
            if report1.brand and report2.brand:
                if report1.brand.lower() == report2.brand.lower():
                    score += 1.0
                factors += 1
            
            # Size similarity (basic)
            if report1.size and report2.size:
                if report1.size.lower() == report2.size.lower():
                    score += 1.0
                factors += 1
            
            return score / factors if factors > 0 else 0.0
            
        except Exception as e:
            logger.error(f"Metadata similarity calculation failed: {e}")
            return 0.0
    
    def _calculate_confidence_level(self, combined_score: float) -> str:
        """Calculate confidence level based on combined score."""
        if combined_score >= 0.9:
            return "very_high"
        elif combined_score >= 0.8:
            return "high"
        elif combined_score >= 0.7:
            return "medium"
        elif combined_score >= 0.6:
            return "low"
        else:
            return "very_low"
    
    def _generate_match_reasons(
        self, 
        text_score: float, 
        image_score: float, 
        location_score: float, 
        metadata_score: float
    ) -> List[str]:
        """Generate human-readable match reasons."""
        reasons = []
        
        if text_score >= 0.7:
            reasons.append("Similar description")
        if image_score >= 0.8:
            reasons.append("Similar image")
        if location_score >= 0.6:
            reasons.append("Nearby location")
        if metadata_score >= 0.8:
            reasons.append("Matching details")
        
        return reasons
    
    async def _save_matches_to_db(
        self, 
        report_id: int, 
        matches: List[Dict[str, Any]], 
        db: Session
    ):
        """Save matches to database."""
        try:
            # Clear existing matches for this report
            db.query(Match).filter(Match.source_report_id == report_id).delete()
            
            # Save new matches
            for i, match in enumerate(matches):
                db_match = Match(
                    source_report_id=report_id,
                    candidate_report_id=match["candidate_report_id"],
                    similarity_score=match["scores"]["combined_score"],
                    text_similarity=match["scores"]["text_similarity"],
                    image_similarity=match["scores"]["image_similarity"],
                    location_similarity=match["scores"]["location_similarity"],
                    metadata_similarity=match["scores"]["metadata_similarity"],
                    confidence_level=match["match_confidence"],
                    rank=i + 1,
                    created_at=datetime.utcnow()
                )
                db.add(db_match)
            
            db.commit()
            logger.info(f"Saved {len(matches)} matches to database")
            
        except Exception as e:
            logger.error(f"Failed to save matches to database: {e}")
            db.rollback()
    
    async def search_reports(
        self,
        query: str,
        report_type: Optional[str] = None,
        category: Optional[str] = None,
        location: Optional[Dict[str, float]] = None,
        radius_km: float = 10.0,
        limit: int = 20,
        db: Session = None
    ) -> List[Dict[str, Any]]:
        """
        Enhanced search for reports using NLP and location.
        
        Args:
            query: Search query text
            report_type: Type of report (lost/found)
            category: Item category
            location: Location dict with lat/lon
            radius_km: Search radius in kilometers
            limit: Maximum results
            db: Database session
        
        Returns:
            List of matching reports with relevance scores
        """
        try:
            # Build base query
            base_query = db.query(Report).filter(Report.status == "active")
            
            if report_type:
                base_query = base_query.filter(Report.type == report_type)
            
            if category:
                base_query = base_query.filter(Report.category == category)
            
            # Location filtering
            if location and location.get("latitude") and location.get("longitude"):
                # This is a simplified location filter - in production, use PostGIS
                lat, lon = location["latitude"], location["longitude"]
                # For now, we'll filter in Python after getting results
                reports = base_query.all()
            else:
                reports = base_query.limit(limit * 2).all()  # Get more for filtering
            
            if not reports:
                return []
            
            # Process text similarity for all reports
            if query and self.nlp_client:
                candidate_texts = []
                for report in reports:
                    text_parts = []
                    if report.title:
                        text_parts.append(report.title)
                    if report.description:
                        text_parts.append(report.description)
                    candidate_texts.append(" ".join(text_parts))
                
                # Find text matches
                text_matches = await self.nlp_client.find_matches(
                    query, candidate_texts, threshold=0.5
                )
                
                if text_matches:
                    # Create a mapping of text matches to reports
                    text_scores = {}
                    for match in text_matches:
                        idx = match["index"]
                        text_scores[reports[idx].id] = match["similarity_score"]
                else:
                    text_scores = {}
            else:
                text_scores = {}
            
            # Calculate relevance scores
            results = []
            for report in reports:
                relevance_score = 0.0
                
                # Text similarity score
                if report.id in text_scores:
                    relevance_score += text_scores[report.id] * 0.7
                
                # Location score
                if location and report.latitude and report.longitude:
                    location_score = self._calculate_location_similarity(
                        location["latitude"], location["longitude"],
                        report.latitude, report.longitude
                    )
                    if location_score > 0:
                        relevance_score += location_score * 0.3
                
                # Only include reports with some relevance
                if relevance_score > 0.1:
                    results.append({
                        "report_id": report.id,
                        "title": report.title,
                        "description": report.description,
                        "report_type": report.type,
                        "category": report.category,
                        "location": {
                            "latitude": report.latitude,
                            "longitude": report.longitude,
                            "address": report.location
                        },
                        "image_url": report.image_path,
                        "created_at": report.created_at.isoformat(),
                        "relevance_score": relevance_score
                    })
            
            # Sort by relevance score
            results.sort(key=lambda x: x["relevance_score"], reverse=True)
            
            return results[:limit]
            
        except Exception as e:
            logger.error(f"Search failed: {e}")
            return []


# Global matching service instance
async def get_matching_service() -> EnhancedMatchingService:
    """Get enhanced matching service instance."""
    return EnhancedMatchingService()