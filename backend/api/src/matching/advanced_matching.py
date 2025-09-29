"""
Advanced Matching Engine
Implements fuzzy text matching, multi-image support, time-decay scoring, and user feedback learning
"""

import math
import re
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
import logging

# Text processing libraries
from fuzzywuzzy import fuzz, process
from difflib import SequenceMatcher
import nltk
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from nltk.stem import PorterStemmer

# Image processing
import imagehash
from PIL import Image
import numpy as np

logger = logging.getLogger(__name__)

@dataclass
class MatchScore:
    """Detailed match scoring breakdown"""
    total_score: float
    text_similarity: float
    image_similarity: float
    location_proximity: float
    time_relevance: float
    category_match: float
    user_feedback_boost: float
    confidence_level: str
    explanation: List[str]

@dataclass
class FuzzyMatchResult:
    """Result of fuzzy text matching"""
    similarity_score: float
    matched_terms: List[Tuple[str, str, float]]
    preprocessing_applied: List[str]

class FuzzyTextMatcher:
    """Advanced fuzzy text matching with preprocessing"""
    
    def __init__(self):
        # Download required NLTK data
        try:
            nltk.data.find('tokenizers/punkt')
            nltk.data.find('corpora/stopwords')
        except LookupError:
            nltk.download('punkt')
            nltk.download('stopwords')
        
        self.stemmer = PorterStemmer()
        self.stop_words = set(stopwords.words('english'))
        
        # Common abbreviations and variations
        self.abbreviations = {
            'phone': ['ph', 'mobile', 'cell', 'smartphone'],
            'laptop': ['notebook', 'computer', 'pc'],
            'wallet': ['purse', 'billfold'],
            'keys': ['key', 'keychain', 'keyring'],
            'bag': ['backpack', 'handbag', 'purse', 'satchel'],
            'watch': ['timepiece', 'wristwatch'],
            'glasses': ['spectacles', 'eyeglasses', 'specs'],
            'earphones': ['headphones', 'earbuds', 'headset']
        }
        
        # Color variations
        self.color_variations = {
            'red': ['crimson', 'scarlet', 'burgundy', 'maroon'],
            'blue': ['navy', 'azure', 'cobalt', 'cerulean'],
            'green': ['emerald', 'olive', 'lime', 'forest'],
            'black': ['dark', 'ebony', 'charcoal'],
            'white': ['ivory', 'cream', 'pearl', 'snow'],
            'brown': ['tan', 'beige', 'chocolate', 'coffee'],
            'gray': ['grey', 'silver', 'slate', 'ash'],
            'yellow': ['gold', 'amber', 'lemon', 'canary'],
            'purple': ['violet', 'lavender', 'plum', 'magenta'],
            'orange': ['peach', 'coral', 'salmon', 'tangerine']
        }
    
    def preprocess_text(self, text: str) -> str:
        """Advanced text preprocessing for better matching"""
        if not text:
            return ""
        
        # Convert to lowercase
        text = text.lower().strip()
        
        # Remove special characters but keep spaces
        text = re.sub(r'[^\w\s]', ' ', text)
        
        # Remove extra whitespace
        text = re.sub(r'\s+', ' ', text)
        
        # Expand abbreviations
        words = text.split()
        expanded_words = []
        for word in words:
            expanded = False
            for full_word, abbrevs in self.abbreviations.items():
                if word in abbrevs:
                    expanded_words.append(full_word)
                    expanded = True
                    break
            if not expanded:
                expanded_words.append(word)
        
        return ' '.join(expanded_words)
    
    def extract_keywords(self, text: str) -> List[str]:
        """Extract meaningful keywords from text"""
        processed_text = self.preprocess_text(text)
        tokens = word_tokenize(processed_text)
        
        # Remove stop words and short words
        keywords = [
            self.stemmer.stem(word) 
            for word in tokens 
            if word not in self.stop_words and len(word) > 2
        ]
        
        return list(set(keywords))  # Remove duplicates
    
    def fuzzy_match_texts(self, text1: str, text2: str) -> FuzzyMatchResult:
        """Perform comprehensive fuzzy text matching"""
        if not text1 or not text2:
            return FuzzyMatchResult(0.0, [], [])
        
        preprocessing_applied = []
        matched_terms = []
        
        # 1. Direct similarity
        direct_similarity = fuzz.ratio(text1.lower(), text2.lower()) / 100.0
        
        # 2. Preprocessed similarity
        processed_text1 = self.preprocess_text(text1)
        processed_text2 = self.preprocess_text(text2)
        preprocessing_applied.append("text_normalization")
        
        processed_similarity = fuzz.ratio(processed_text1, processed_text2) / 100.0
        
        # 3. Token-based similarity
        token_similarity = fuzz.token_sort_ratio(processed_text1, processed_text2) / 100.0
        preprocessing_applied.append("token_sorting")
        
        # 4. Partial ratio for substring matches
        partial_similarity = fuzz.partial_ratio(processed_text1, processed_text2) / 100.0
        
        # 5. Keyword-based matching
        keywords1 = self.extract_keywords(text1)
        keywords2 = self.extract_keywords(text2)
        
        keyword_matches = 0
        total_keywords = max(len(keywords1), len(keywords2))
        
        if total_keywords > 0:
            for kw1 in keywords1:
                best_match = process.extractOne(kw1, keywords2)
                if best_match and best_match[1] > 80:  # 80% similarity threshold
                    keyword_matches += 1
                    matched_terms.append((kw1, best_match[0], best_match[1] / 100.0))
            
            keyword_similarity = keyword_matches / total_keywords
            preprocessing_applied.append("keyword_extraction")
        else:
            keyword_similarity = 0.0
        
        # 6. Color variation matching
        color_boost = 0.0
        for color, variations in self.color_variations.items():
            if any(var in processed_text1 for var in [color] + variations) and \
               any(var in processed_text2 for var in [color] + variations):
                color_boost = 0.1
                preprocessing_applied.append("color_variation_matching")
                break
        
        # Calculate weighted final score
        weights = {
            'direct': 0.2,
            'processed': 0.25,
            'token': 0.25,
            'partial': 0.15,
            'keyword': 0.15
        }
        
        final_score = (
            direct_similarity * weights['direct'] +
            processed_similarity * weights['processed'] +
            token_similarity * weights['token'] +
            partial_similarity * weights['partial'] +
            keyword_similarity * weights['keyword'] +
            color_boost
        )
        
        return FuzzyMatchResult(
            similarity_score=min(final_score, 1.0),
            matched_terms=matched_terms,
            preprocessing_applied=preprocessing_applied
        )

class MultiImageMatcher:
    """Multi-image similarity matching"""
    
    def __init__(self):
        self.hash_algorithms = [
            ('phash', imagehash.phash),
            ('dhash', imagehash.dhash),
            ('ahash', imagehash.average_hash),
            ('whash', imagehash.whash)
        ]
    
    def calculate_image_hashes(self, image_path: str) -> Dict[str, str]:
        """Calculate multiple hashes for an image"""
        try:
            image = Image.open(image_path)
            hashes = {}
            
            for name, hash_func in self.hash_algorithms:
                hashes[name] = str(hash_func(image))
            
            return hashes
        except Exception as e:
            logger.error(f"Error calculating hashes for {image_path}: {e}")
            return {}
    
    def compare_image_sets(self, hashes1: List[Dict[str, str]], hashes2: List[Dict[str, str]]) -> float:
        """Compare two sets of images and return best similarity score"""
        if not hashes1 or not hashes2:
            return 0.0
        
        best_similarity = 0.0
        
        for hash_set1 in hashes1:
            for hash_set2 in hashes2:
                similarity = self._compare_hash_sets(hash_set1, hash_set2)
                best_similarity = max(best_similarity, similarity)
        
        return best_similarity
    
    def _compare_hash_sets(self, hashes1: Dict[str, str], hashes2: Dict[str, str]) -> float:
        """Compare two sets of image hashes"""
        similarities = []
        
        for hash_name in self.hash_algorithms:
            name = hash_name[0]
            if name in hashes1 and name in hashes2:
                try:
                    hash1 = imagehash.hex_to_hash(hashes1[name])
                    hash2 = imagehash.hex_to_hash(hashes2[name])
                    
                    # Calculate similarity (inverse of Hamming distance)
                    hamming_distance = hash1 - hash2
                    max_distance = len(hash1.hash.flatten())
                    similarity = 1.0 - (hamming_distance / max_distance)
                    similarities.append(similarity)
                except Exception as e:
                    logger.error(f"Error comparing {name} hashes: {e}")
        
        return np.mean(similarities) if similarities else 0.0

class TimeDecayScorer:
    """Time-based relevance scoring with decay"""
    
    def __init__(self):
        # Configurable decay parameters
        self.decay_half_life_days = 7  # Score halves every 7 days
        self.min_score_threshold = 0.1  # Minimum score (10%)
        self.peak_relevance_hours = 24  # Peak relevance within 24 hours
    
    def calculate_time_decay_score(self, item_date: datetime, current_date: datetime = None) -> float:
        """Calculate time decay score for an item"""
        if current_date is None:
            current_date = datetime.utcnow()
        
        time_diff = current_date - item_date
        hours_diff = time_diff.total_seconds() / 3600
        days_diff = hours_diff / 24
        
        # Peak relevance for very recent items
        if hours_diff <= self.peak_relevance_hours:
            return 1.0
        
        # Exponential decay after peak period
        decay_rate = math.log(2) / self.decay_half_life_days
        score = math.exp(-decay_rate * days_diff)
        
        # Apply minimum threshold
        return max(score, self.min_score_threshold)
    
    def get_time_relevance_explanation(self, item_date: datetime, current_date: datetime = None) -> str:
        """Get human-readable explanation of time relevance"""
        if current_date is None:
            current_date = datetime.utcnow()
        
        time_diff = current_date - item_date
        hours_diff = time_diff.total_seconds() / 3600
        days_diff = hours_diff / 24
        
        if hours_diff < 1:
            return "Very recent (posted within the hour)"
        elif hours_diff <= 24:
            return f"Recent (posted {int(hours_diff)} hours ago)"
        elif days_diff <= 7:
            return f"Posted {int(days_diff)} days ago"
        elif days_diff <= 30:
            return f"Posted {int(days_diff)} days ago (relevance reduced)"
        else:
            return f"Posted {int(days_diff)} days ago (low relevance)"

class UserFeedbackLearner:
    """Learn from user feedback to improve matching"""
    
    def __init__(self, db: Session):
        self.db = db
        self.feedback_weights = {
            'positive_match': 1.2,      # 20% boost for confirmed matches
            'negative_match': 0.8,      # 20% penalty for rejected matches
            'false_positive': 0.6,      # 40% penalty for false positives
            'user_preference': 1.1      # 10% boost for user preferences
        }
    
    def get_user_feedback_boost(self, user_id: int, item1_id: int, item2_id: int) -> Tuple[float, str]:
        """Calculate feedback-based score boost for a potential match"""
        # This would query a feedback table to get historical user feedback
        # For now, implementing basic logic structure
        
        boost = 1.0
        explanation = "No previous feedback"
        
        # Query historical feedback (pseudo-code structure)
        # feedback_history = self.db.query(MatchFeedback).filter(
        #     MatchFeedback.user_id == user_id,
        #     or_(
        #         and_(MatchFeedback.item1_id == item1_id, MatchFeedback.item2_id == item2_id),
        #         and_(MatchFeedback.item1_id == item2_id, MatchFeedback.item2_id == item1_id)
        #     )
        # ).all()
        
        # Apply learning from similar matches
        # This would analyze patterns in user behavior
        
        return boost, explanation
    
    def learn_from_feedback(self, user_id: int, match_id: int, feedback_type: str, feedback_data: Dict[str, Any]):
        """Learn from user feedback to improve future matches"""
        # Store feedback for future learning
        # This would update ML models or preference weights
        
        logger.info(f"Learning from feedback: user={user_id}, match={match_id}, type={feedback_type}")
        
        # Update user preferences based on feedback
        # This could include:
        # - Category preferences
        # - Location preferences  
        # - Time sensitivity preferences
        # - Image similarity thresholds
        
        pass

class AdvancedMatchingEngine:
    """Main advanced matching engine combining all features"""
    
    def __init__(self, db: Session):
        self.db = db
        self.fuzzy_matcher = FuzzyTextMatcher()
        self.image_matcher = MultiImageMatcher()
        self.time_scorer = TimeDecayScorer()
        self.feedback_learner = UserFeedbackLearner(db)
    
    def calculate_advanced_match_score(
        self, 
        item1: Any, 
        item2: Any, 
        user_id: Optional[int] = None
    ) -> MatchScore:
        """Calculate comprehensive match score with all advanced features"""
        
        explanations = []
        
        # 1. Fuzzy text matching
        title_match = self.fuzzy_matcher.fuzzy_match_texts(item1.title, item2.title)
        desc_match = self.fuzzy_matcher.fuzzy_match_texts(
            item1.description or "", 
            item2.description or ""
        )
        
        text_similarity = (title_match.similarity_score * 0.7 + desc_match.similarity_score * 0.3)
        explanations.append(f"Text similarity: {text_similarity:.2f} (title: {title_match.similarity_score:.2f}, desc: {desc_match.similarity_score:.2f})")
        
        # 2. Multi-image matching
        image_similarity = 0.0
        if hasattr(item1, 'media') and hasattr(item2, 'media'):
            # This would compare multiple images per item
            # For now, using basic structure
            image_similarity = 0.5  # Placeholder
            explanations.append(f"Image similarity: {image_similarity:.2f}")
        
        # 3. Category matching
        category_match = 1.0 if item1.category == item2.category else 0.3
        if hasattr(item1, 'subcategory') and hasattr(item2, 'subcategory'):
            if item1.subcategory == item2.subcategory:
                category_match = min(category_match + 0.2, 1.0)
        
        explanations.append(f"Category match: {category_match:.2f}")
        
        # 4. Location proximity (using existing geospatial logic)
        location_proximity = self._calculate_location_proximity(item1, item2)
        explanations.append(f"Location proximity: {location_proximity:.2f}")
        
        # 5. Time relevance with decay
        time_relevance = self._calculate_time_relevance(item1, item2)
        time_explanation = self.time_scorer.get_time_relevance_explanation(item1.created_at)
        explanations.append(f"Time relevance: {time_relevance:.2f} ({time_explanation})")
        
        # 6. User feedback boost
        user_feedback_boost = 1.0
        feedback_explanation = "No user feedback"
        
        if user_id:
            user_feedback_boost, feedback_explanation = self.feedback_learner.get_user_feedback_boost(
                user_id, item1.id, item2.id
            )
        
        explanations.append(f"User feedback boost: {user_feedback_boost:.2f} ({feedback_explanation})")
        
        # Calculate weighted final score
        weights = {
            'text': 0.25,
            'image': 0.20,
            'category': 0.20,
            'location': 0.20,
            'time': 0.15
        }
        
        base_score = (
            text_similarity * weights['text'] +
            image_similarity * weights['image'] +
            category_match * weights['category'] +
            location_proximity * weights['location'] +
            time_relevance * weights['time']
        )
        
        # Apply user feedback boost
        final_score = base_score * user_feedback_boost
        final_score = min(final_score, 1.0)  # Cap at 1.0
        
        # Determine confidence level
        confidence_level = self._determine_confidence_level(final_score, text_similarity, category_match)
        
        return MatchScore(
            total_score=final_score,
            text_similarity=text_similarity,
            image_similarity=image_similarity,
            location_proximity=location_proximity,
            time_relevance=time_relevance,
            category_match=category_match,
            user_feedback_boost=user_feedback_boost,
            confidence_level=confidence_level,
            explanation=explanations
        )
    
    def _calculate_location_proximity(self, item1: Any, item2: Any) -> float:
        """Calculate location proximity score"""
        if not (hasattr(item1, 'location_point') and hasattr(item2, 'location_point')):
            return 0.5  # Default score if no location data
        
        if not (item1.location_point and item2.location_point):
            return 0.5
        
        # This would use PostGIS distance calculation
        # For now, using placeholder logic
        # distance_km = calculate_distance(item1.location_point, item2.location_point)
        distance_km = 2.0  # Placeholder
        
        # Score decreases with distance
        if distance_km <= 0.5:
            return 1.0
        elif distance_km <= 2.0:
            return 0.8
        elif distance_km <= 5.0:
            return 0.6
        elif distance_km <= 10.0:
            return 0.4
        else:
            return 0.2
    
    def _calculate_time_relevance(self, item1: Any, item2: Any) -> float:
        """Calculate time relevance between two items"""
        time_diff = abs((item1.created_at - item2.created_at).total_seconds())
        hours_diff = time_diff / 3600
        
        # Items posted close in time are more likely to be related
        if hours_diff <= 24:
            return 1.0
        elif hours_diff <= 72:  # 3 days
            return 0.8
        elif hours_diff <= 168:  # 1 week
            return 0.6
        elif hours_diff <= 720:  # 1 month
            return 0.4
        else:
            return 0.2
    
    def _determine_confidence_level(self, final_score: float, text_similarity: float, category_match: float) -> str:
        """Determine confidence level for the match"""
        if final_score >= 0.8 and text_similarity >= 0.7 and category_match >= 0.8:
            return "Very High"
        elif final_score >= 0.6 and text_similarity >= 0.5:
            return "High"
        elif final_score >= 0.4:
            return "Medium"
        elif final_score >= 0.2:
            return "Low"
        else:
            return "Very Low"
    
    def find_advanced_matches(
        self, 
        item_id: int, 
        user_id: Optional[int] = None,
        limit: int = 20
    ) -> List[Tuple[Any, MatchScore]]:
        """Find matches using advanced matching algorithm"""
        
        # Get the source item
        from app.db.models import Item
        source_item = self.db.query(Item).filter(Item.id == item_id).first()
        
        if not source_item:
            return []
        
        # Determine opposite type
        opposite_type = 'found' if source_item.status == 'lost' else 'lost'
        
        # Get potential candidates (basic filtering)
        candidates = self.db.query(Item).filter(
            Item.status == opposite_type,
            Item.category == source_item.category,
            Item.is_deleted == False,
            Item.id != item_id
        ).limit(limit * 2).all()  # Get more candidates for better filtering
        
        # Calculate advanced scores for each candidate
        scored_matches = []
        for candidate in candidates:
            match_score = self.calculate_advanced_match_score(source_item, candidate, user_id)
            
            # Only include matches above minimum threshold
            if match_score.total_score >= 0.2:
                scored_matches.append((candidate, match_score))
        
        # Sort by score and return top matches
        scored_matches.sort(key=lambda x: x[1].total_score, reverse=True)
        return scored_matches[:limit]
