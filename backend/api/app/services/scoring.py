"""
Scoring service for Lost & Found matching.

Implements explainable scoring with baseline + optional ML components.
"""

from typing import Dict, Any, Optional
from datetime import datetime, timedelta
import math
from loguru import logger

from app.core.config import settings
from app.db.models import Item
from app.services.geospatial import calculate_distance_km


class ScoreCalculator:
    """
    Calculates match scores with explainable breakdown.
    
    Scoring Components:
    1. Category/Subcategory match (baseline)
    2. Distance decay (baseline)
    3. Time decay (baseline)
    4. Attribute matching (baseline)
    5. Text similarity (optional, NLP_ON)
    6. Image similarity (optional, CV_ON)
    """
    
    def calculate_score(self, item1: Item, item2: Item) -> Dict[str, Any]:
        """
        Calculate comprehensive match score between two items.
        
        Args:
            item1: First item (usually the query item)
            item2: Second item (candidate match)
            
        Returns:
            Dictionary with final score and detailed breakdown
        """
        breakdown = {}
        
        # 1. Category/Subcategory scoring (baseline)
        category_score = self._calculate_category_score(item1, item2)
        breakdown['category'] = category_score
        
        # 2. Distance scoring (baseline)
        distance_score, distance_km = self._calculate_distance_score(item1, item2)
        breakdown['distance'] = distance_score
        
        # 3. Time scoring (baseline)
        time_score, time_diff_hours = self._calculate_time_score(item1, item2)
        breakdown['time'] = time_score
        
        # 4. Attribute scoring (baseline)
        attribute_score = self._calculate_attribute_score(item1, item2)
        breakdown['attributes'] = attribute_score
        
        # 5. Text similarity (optional, NLP_ON)
        text_score = 0.0
        if settings.NLP_ON:
            text_score = self._calculate_text_similarity(item1, item2)
            breakdown['text'] = text_score
        
        # 6. Image similarity (optional, CV_ON)
        image_score = 0.0
        if settings.CV_ON:
            image_score = self._calculate_image_similarity(item1, item2)
            breakdown['image'] = image_score
        
        # Calculate weighted final score
        final_score = self._calculate_weighted_score(breakdown)
        
        return {
            'final_score': final_score,
            'breakdown': breakdown,
            'distance_km': distance_km,
            'time_diff_hours': time_diff_hours,
            'explanation': self._generate_explanation(breakdown, final_score)
        }
    
    def _calculate_category_score(self, item1: Item, item2: Item) -> float:
        """Calculate category/subcategory match score."""
        if not (item1.category and item2.category):
            return 0.5  # Neutral score if category missing
        
        if item1.category != item2.category:
            return 0.0  # No match if different categories
        
        # Category matches
        base_score = 0.8
        
        # Bonus for subcategory match
        if item1.subcategory and item2.subcategory:
            if item1.subcategory == item2.subcategory:
                base_score = 1.0
            else:
                base_score = 0.6  # Category match but subcategory mismatch
        
        return base_score
    
    def _calculate_distance_score(self, item1: Item, item2: Item) -> tuple[float, Optional[float]]:
        """Calculate distance-based score with decay."""
        # Extract coordinates from PostGIS points or fallback to lat/lng
        coords1 = self._extract_coordinates(item1)
        coords2 = self._extract_coordinates(item2)
        
        if not (coords1 and coords2):
            return 0.5, None  # Neutral score if location missing
        
        lat1, lng1 = coords1
        lat2, lng2 = coords2
        
        distance_km = calculate_distance_km(lat1, lng1, lat2, lng2)
        
        # Distance decay function: score = exp(-distance / decay_factor)
        decay_factor = settings.MAX_SEARCH_RADIUS_KM / 3  # ~16.7km for 50km max
        distance_score = math.exp(-distance_km / decay_factor)
        
        return distance_score, distance_km
    
    def _calculate_time_score(self, item1: Item, item2: Item) -> tuple[float, Optional[float]]:
        """Calculate time-based score with decay."""
        time1 = item1.lost_found_at
        time2 = item2.lost_found_at
        
        if not (time1 and time2):
            return 0.5, None  # Neutral score if time missing
        
        time_diff = abs((time1 - time2).total_seconds())
        time_diff_hours = time_diff / 3600
        
        # Time decay function: score = exp(-hours / decay_factor)
        decay_factor_hours = settings.DEFAULT_TIME_WINDOW_DAYS * 24 / 3  # ~112 hours for 14 days
        time_score = math.exp(-time_diff_hours / decay_factor_hours)
        
        return time_score, time_diff_hours
    
    def _calculate_attribute_score(self, item1: Item, item2: Item) -> float:
        """Calculate attribute matching score (brand, color, model)."""
        matches = 0
        total_attributes = 0
        
        # Brand matching
        if item1.brand or item2.brand:
            total_attributes += 1
            if item1.brand and item2.brand and item1.brand.lower() == item2.brand.lower():
                matches += 1
        
        # Color matching
        if item1.color or item2.color:
            total_attributes += 1
            if item1.color and item2.color and item1.color.lower() == item2.color.lower():
                matches += 1
        
        # Model matching
        if item1.model or item2.model:
            total_attributes += 1
            if item1.model and item2.model and item1.model.lower() == item2.model.lower():
                matches += 1
        
        if total_attributes == 0:
            return 0.5  # Neutral score if no attributes specified
        
        return matches / total_attributes
    
    def _calculate_text_similarity(self, item1: Item, item2: Item) -> float:
        """Calculate text similarity using embeddings (when NLP_ON)."""
        if not (item1.text_embedding and item2.text_embedding):
            return 0.5  # Neutral score if embeddings missing
        
        try:
            # Calculate cosine similarity between embeddings
            embedding1 = item1.text_embedding
            embedding2 = item2.text_embedding
            
            # Cosine similarity calculation
            dot_product = sum(a * b for a, b in zip(embedding1, embedding2))
            magnitude1 = math.sqrt(sum(a * a for a in embedding1))
            magnitude2 = math.sqrt(sum(a * a for a in embedding2))
            
            if magnitude1 == 0 or magnitude2 == 0:
                return 0.0
            
            similarity = dot_product / (magnitude1 * magnitude2)
            
            # Convert from [-1, 1] to [0, 1]
            return (similarity + 1) / 2
            
        except Exception as e:
            logger.warning(f"Error calculating text similarity: {e}")
            return 0.5
    
    def _calculate_image_similarity(self, item1: Item, item2: Item) -> float:
        """Calculate image similarity using perceptual hashing (when CV_ON)."""
        # Get media assets for both items
        media1 = [m for m in item1.media if m.phash]
        media2 = [m for m in item2.media if m.phash]
        
        if not (media1 and media2):
            return 0.5  # Neutral score if no images with hashes
        
        max_similarity = 0.0
        
        # Compare all image pairs and take the maximum similarity
        for m1 in media1:
            for m2 in media2:
                similarity = self._calculate_phash_similarity(m1.phash, m2.phash)
                max_similarity = max(max_similarity, similarity)
        
        return max_similarity
    
    def _calculate_phash_similarity(self, phash1: str, phash2: str) -> float:
        """Calculate similarity between two perceptual hashes."""
        try:
            # Convert hex strings to integers
            hash1 = int(phash1, 16)
            hash2 = int(phash2, 16)
            
            # Calculate Hamming distance
            hamming_distance = bin(hash1 ^ hash2).count('1')
            
            # Convert to similarity score (0-1, where 1 is identical)
            max_distance = 64  # For 64-bit hashes
            similarity = 1 - (hamming_distance / max_distance)
            
            return similarity
            
        except Exception as e:
            logger.warning(f"Error calculating phash similarity: {e}")
            return 0.0
    
    def _calculate_weighted_score(self, breakdown: Dict[str, float]) -> float:
        """Calculate final weighted score from component scores."""
        total_weight = 0.0
        weighted_sum = 0.0
        
        # Baseline components (always active)
        weighted_sum += breakdown['category'] * settings.WEIGHT_CATEGORY
        total_weight += settings.WEIGHT_CATEGORY
        
        weighted_sum += breakdown['distance'] * settings.WEIGHT_DISTANCE
        total_weight += settings.WEIGHT_DISTANCE
        
        weighted_sum += breakdown['time'] * settings.WEIGHT_TIME
        total_weight += settings.WEIGHT_TIME
        
        weighted_sum += breakdown['attributes'] * settings.WEIGHT_ATTRIBUTES
        total_weight += settings.WEIGHT_ATTRIBUTES
        
        # Optional ML components
        if settings.NLP_ON and 'text' in breakdown:
            weighted_sum += breakdown['text'] * settings.WEIGHT_TEXT_SIMILARITY
            total_weight += settings.WEIGHT_TEXT_SIMILARITY
        
        if settings.CV_ON and 'image' in breakdown:
            weighted_sum += breakdown['image'] * settings.WEIGHT_IMAGE_SIMILARITY
            total_weight += settings.WEIGHT_IMAGE_SIMILARITY
        
        # Normalize by total weight
        if total_weight > 0:
            return weighted_sum / total_weight
        else:
            return 0.0
    
    def _extract_coordinates(self, item: Item) -> Optional[tuple[float, float]]:
        """Extract coordinates from item (PostGIS point)."""
        if item.location_point:
            try:
                # Extract coordinates from PostGIS point using geoalchemy2
                from geoalchemy2.shape import to_shape
                point = to_shape(item.location_point)
                return point.y, point.x  # lat, lng
            except Exception as e:
                logger.warning(f"Error extracting coordinates from PostGIS point: {e}")
                return None
        
        return None
    
    def _generate_explanation(self, breakdown: Dict[str, float], final_score: float) -> str:
        """Generate human-readable explanation of the match score."""
        explanations = []
        
        if breakdown.get('category', 0) > 0.8:
            explanations.append("Strong category match")
        elif breakdown.get('category', 0) > 0.5:
            explanations.append("Partial category match")
        
        if breakdown.get('distance', 0) > 0.8:
            explanations.append("Very close location")
        elif breakdown.get('distance', 0) > 0.5:
            explanations.append("Nearby location")
        
        if breakdown.get('time', 0) > 0.8:
            explanations.append("Similar timeframe")
        
        if breakdown.get('attributes', 0) > 0.7:
            explanations.append("Matching attributes")
        
        if settings.NLP_ON and breakdown.get('text', 0) > 0.7:
            explanations.append("Similar description")
        
        if settings.CV_ON and breakdown.get('image', 0) > 0.7:
            explanations.append("Similar appearance")
        
        if not explanations:
            explanations.append("Basic match criteria met")
        
        confidence = "High" if final_score > 0.8 else "Medium" if final_score > 0.5 else "Low"
        
        return f"{confidence} confidence: {', '.join(explanations)}"
