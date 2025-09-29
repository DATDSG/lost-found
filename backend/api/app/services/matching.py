"""
Core matching service for Lost & Found system.

Implements baseline geo-time matching with optional NLP/CV enhancements.
Architecture: Baseline first, ML second - the system always works without heavy ML.
"""

from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func
from geoalchemy2.functions import ST_DWithin, ST_Distance
import geohash2
import math
from loguru import logger

from app.core.config import settings
from app.db.models import Item, Match, MediaAsset
from app.services.geospatial import calculate_distance_km, get_geohash_neighbors
from app.services.scoring import ScoreCalculator


class MatchingService:
    """
    Core matching service implementing the tri-lingual Lost & Found matching pipeline.
    
    Pipeline:
    1. Spatial blocking (geohash neighbors within radius)
    2. Temporal filtering (time window)
    3. Category/attribute filtering
    4. Baseline scoring (geo + time + attributes)
    5. Optional NLP scoring (if NLP_ON)
    6. Optional CV scoring (if CV_ON)
    7. Final ranking and Top-K selection
    """
    
    def __init__(self, db: Session):
        self.db = db
        self.score_calculator = ScoreCalculator()
    
    def find_matches(
        self, 
        item: Item, 
        limit: int = None
    ) -> List[Dict[str, Any]]:
        """
        Find potential matches for a lost or found item.
        
        Args:
            item: The item to find matches for
            limit: Maximum number of matches to return (default: TOP_K_MATCHES)
            
        Returns:
            List of match dictionaries with scores and explanations
        """
        limit = limit or settings.TOP_K_MATCHES
        
        logger.info(f"Finding matches for item {item.id} ({item.status})")
        
        # Step 1: Spatial blocking using geohash
        candidate_items = self._get_spatial_candidates(item)
        logger.info(f"Found {len(candidate_items)} spatial candidates")
        
        # Step 2: Temporal filtering
        candidate_items = self._apply_temporal_filter(candidate_items, item)
        logger.info(f"Found {len(candidate_items)} after temporal filtering")
        
        # Step 3: Category and attribute filtering
        candidate_items = self._apply_category_filter(candidate_items, item)
        logger.info(f"Found {len(candidate_items)} after category filtering")
        
        if not candidate_items:
            return []
        
        # Step 4: Score all candidates
        scored_matches = []
        for candidate in candidate_items:
            score_data = self._calculate_match_score(item, candidate)
            if score_data['final_score'] >= settings.MIN_MATCH_SCORE:
                scored_matches.append({
                    'candidate_item': candidate,
                    'score_data': score_data
                })
        
        # Step 5: Sort by score and return top-k
        scored_matches.sort(key=lambda x: x['score_data']['final_score'], reverse=True)
        return scored_matches[:limit]
    
    def _get_spatial_candidates(self, item: Item) -> List[Item]:
        """Get candidate items within geospatial proximity using geohash blocking."""
        if not item.geohash6:
            # If no geohash, fall back to broader search
            return self._get_fallback_candidates(item)
        
        # Get neighboring geohash cells
        neighbor_hashes = get_geohash_neighbors(item.geohash6)
        neighbor_hashes.append(item.geohash6)  # Include the item's own cell
        
        # Query items in neighboring cells with opposite status
        opposite_status = "found" if item.status == "lost" else "lost"
        
        candidates = (
            self.db.query(Item)
            .filter(
                and_(
                    Item.status == opposite_status,
                    Item.geohash6.in_(neighbor_hashes),
                    Item.id != item.id,
                    Item.owner_id != item.owner_id  # Don't match own items
                )
            )
            .all()
        )
        
        # Additional distance filtering for precision
        if item.location_point:
            filtered_candidates = []
            for candidate in candidates:
                if candidate.location_point:
                    distance_km = self._calculate_distance_postgis(item, candidate)
                    if distance_km <= settings.MAX_SEARCH_RADIUS_KM:
                        filtered_candidates.append(candidate)
                else:
                    filtered_candidates.append(candidate)  # Include items without precise location
            return filtered_candidates
        
        return candidates
    
    def _get_fallback_candidates(self, item: Item) -> List[Item]:
        """Fallback spatial search when geohash is not available."""
        opposite_status = "found" if item.status == "lost" else "lost"
        
        query = (
            self.db.query(Item)
            .filter(
                and_(
                    Item.status == opposite_status,
                    Item.id != item.id,
                    Item.owner_id != item.owner_id
                )
            )
        )
        
        # If we have location, use PostGIS distance query
        if item.location_point:
            query = query.filter(
                ST_DWithin(
                    Item.location_point,
                    item.location_point,
                    settings.MAX_SEARCH_RADIUS_KM * 1000  # Convert to meters
                )
            )
        
        return query.limit(100).all()  # Reasonable limit for fallback
    
    def _apply_temporal_filter(self, candidates: List[Item], item: Item) -> List[Item]:
        """Filter candidates based on temporal proximity."""
        if not item.lost_found_at:
            return candidates  # No temporal filtering if no timestamp
        
        # Calculate time window
        time_window_start = item.time_window_start or (
            item.lost_found_at - timedelta(days=settings.DEFAULT_TIME_WINDOW_DAYS)
        )
        time_window_end = item.time_window_end or (
            item.lost_found_at + timedelta(days=settings.DEFAULT_TIME_WINDOW_DAYS)
        )
        
        filtered_candidates = []
        for candidate in candidates:
            if not candidate.lost_found_at:
                filtered_candidates.append(candidate)  # Include items without timestamp
                continue
            
            # Check if candidate's time overlaps with item's time window
            candidate_start = candidate.time_window_start or candidate.lost_found_at
            candidate_end = candidate.time_window_end or candidate.lost_found_at
            
            # Check for temporal overlap
            if (candidate_start <= time_window_end and candidate_end >= time_window_start):
                filtered_candidates.append(candidate)
        
        return filtered_candidates
    
    def _apply_category_filter(self, candidates: List[Item], item: Item) -> List[Item]:
        """Filter candidates based on category and subcategory matching."""
        if not item.category:
            return candidates  # No category filtering if not specified
        
        filtered_candidates = []
        for candidate in candidates:
            # Must match category
            if candidate.category != item.category:
                continue
            
            # If subcategory is specified, it should match
            if item.subcategory and candidate.subcategory:
                if candidate.subcategory != item.subcategory:
                    continue
            
            filtered_candidates.append(candidate)
        
        return filtered_candidates
    
    def _calculate_match_score(self, item: Item, candidate: Item) -> Dict[str, Any]:
        """Calculate comprehensive match score with breakdown."""
        return self.score_calculator.calculate_score(item, candidate)
    
    def _calculate_distance_postgis(self, item1: Item, item2: Item) -> float:
        """Calculate distance between two items using PostGIS."""
        if not (item1.location_point and item2.location_point):
            return float('inf')
        
        # Use PostGIS ST_Distance for accurate geodesic distance
        distance_meters = self.db.query(
            ST_Distance(item1.location_point, item2.location_point)
        ).scalar()
        
        return distance_meters / 1000.0  # Convert to kilometers
    
    def save_matches(self, item: Item, matches: List[Dict[str, Any]]) -> List[Match]:
        """Save calculated matches to database."""
        saved_matches = []
        
        for match_data in matches:
            candidate = match_data['candidate_item']
            score_data = match_data['score_data']
            
            # Determine lost/found item IDs
            if item.status == "lost":
                lost_item_id = item.id
                found_item_id = candidate.id
            else:
                lost_item_id = candidate.id
                found_item_id = item.id
            
            # Check if match already exists
            existing_match = (
                self.db.query(Match)
                .filter(
                    and_(
                        Match.lost_item_id == lost_item_id,
                        Match.found_item_id == found_item_id
                    )
                )
                .first()
            )
            
            if existing_match:
                # Update existing match with new score
                existing_match.score_final = score_data['final_score']
                existing_match.score_breakdown = score_data['breakdown']
                existing_match.distance_km = score_data.get('distance_km')
                existing_match.time_diff_hours = score_data.get('time_diff_hours')
                existing_match.updated_at = datetime.utcnow()
                saved_matches.append(existing_match)
            else:
                # Create new match
                new_match = Match(
                    lost_item_id=lost_item_id,
                    found_item_id=found_item_id,
                    score_final=score_data['final_score'],
                    score_breakdown=score_data['breakdown'],
                    distance_km=score_data.get('distance_km'),
                    time_diff_hours=score_data.get('time_diff_hours')
                )
                self.db.add(new_match)
                saved_matches.append(new_match)
        
        self.db.commit()
        return saved_matches
