"""
Advanced Fraud Detection Service
===============================
Implements machine learning-based fraud detection for reports using multiple algorithms
and heuristics to identify potentially fraudulent or suspicious reports.
"""

import asyncio
import logging
import re
import json
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.ensemble import IsolationForest, RandomForestClassifier
from sklearn.cluster import DBSCAN
from sklearn.preprocessing import StandardScaler
import joblib
import hashlib

logger = logging.getLogger(__name__)


class FraudRiskLevel(str, Enum):
    """Fraud risk levels."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


@dataclass
class FraudDetectionResult:
    """Result of fraud detection analysis."""
    report_id: str
    risk_level: FraudRiskLevel
    fraud_score: float  # 0-100
    confidence: float   # 0-1
    flags: List[str]
    details: Dict[str, Any]
    detected_at: datetime
    model_version: str


@dataclass
class FraudPattern:
    """Known fraud patterns and indicators."""
    pattern_type: str
    description: str
    weight: float
    regex_pattern: Optional[str] = None
    keywords: Optional[List[str]] = None


class FraudDetectionService:
    """
    Advanced fraud detection service using multiple ML algorithms and heuristics.
    """
    
    def __init__(self):
        self.models = {}
        self.patterns = self._initialize_fraud_patterns()
        self.vectorizer = TfidfVectorizer(max_features=1000, stop_words='english')
        self.scaler = StandardScaler()
        self.model_version = "1.0.0"
        
    def _initialize_fraud_patterns(self) -> List[FraudPattern]:
        """Initialize known fraud patterns and indicators."""
        return [
            # Suspicious text patterns
            FraudPattern(
                pattern_type="suspicious_text",
                description="Contains suspicious keywords",
                weight=0.3,
                keywords=["click here", "free money", "get rich", "guaranteed", "act now", "limited time", "no risk", "instant", "miracle", "secret", "exclusive", "winner", "congratulations", "claim now", "verify account", "suspended account", "urgent action required", "immediate attention", "account compromised"]
            ),
            FraudPattern(
                pattern_type="duplicate_content",
                description="Similar content detected",
                weight=0.4,
                keywords=None
            ),
            FraudPattern(
                pattern_type="spam_patterns",
                description="Spam-like content patterns",
                weight=0.5,
                regex_pattern=r"(.)\1{4,}"  # Repeated characters
            ),
            FraudPattern(
                pattern_type="fake_contact",
                description="Suspicious contact information",
                weight=0.6,
                regex_pattern=r"(123-456-7890|000-000-0000|test@test\.com|admin@admin\.com|support@support\.com)"
            ),
            FraudPattern(
                pattern_type="scam_phrases",
                description="Common scam phrases",
                weight=0.4,
                keywords=["send money first", "wire transfer", "western union", "moneygram", "bitcoin payment", "crypto payment", "gift card", "prepaid card", "send gift", "shipping fee", "handling fee", "processing fee", "verification fee", "insurance fee", "deposit required", "advance payment"]
            ),
            FraudPattern(
                pattern_type="fake_item_descriptions",
                description="Suspicious item descriptions",
                weight=0.3,
                keywords=["brand new sealed", "never used", "still in box", "original packaging", "authentic", "genuine", "certified", "warranty included", "receipt included", "purchase proof", "store bought", "retail value", "msrp", "original price"]
            ),
            FraudPattern(
                pattern_type="excessive_reward",
                description="Unusually high reward amount",
                weight=0.7,
                keywords=None
            ),
            FraudPattern(
                pattern_type="suspicious_reward_patterns",
                description="Suspicious reward patterns",
                weight=0.5,
                keywords=["reward more than item value", "reward exceeds value", "generous reward", "big reward", "huge reward", "massive reward", "reward no questions asked", "reward immediately", "instant reward", "guaranteed reward"]
            ),
            FraudPattern(
                pattern_type="location_inconsistency",
                description="Location data inconsistencies",
                weight=0.4,
                keywords=None
            ),
            FraudPattern(
                pattern_type="rapid_posting",
                description="Rapid successive postings",
                weight=0.5,
                keywords=None
            ),
            FraudPattern(
                pattern_type="image_manipulation",
                description="Potential image manipulation",
                weight=0.6,
                keywords=None
            )
        ]
    
    async def analyze_report(self, report_data: Dict[str, Any]) -> FraudDetectionResult:
        """
        Perform comprehensive fraud analysis on a report.
        
        Args:
            report_data: Report data including all fields
            
        Returns:
            FraudDetectionResult with analysis details
        """
        try:
            report_id = report_data.get('id', 'unknown')
            flags = []
            details = {}
            total_score = 0.0
            
            # Text analysis
            text_score, text_flags, text_details = await self._analyze_text_content(report_data)
            total_score += text_score
            flags.extend(text_flags)
            details.update(text_details)
            
            # Behavioral analysis
            behavior_score, behavior_flags, behavior_details = await self._analyze_behavior_patterns(report_data)
            total_score += behavior_score
            flags.extend(behavior_flags)
            details.update(behavior_details)
            
            # Location analysis
            location_score, location_flags, location_details = await self._analyze_location_data(report_data)
            total_score += location_score
            flags.extend(location_flags)
            details.update(location_details)
            
            # Image analysis
            image_score, image_flags, image_details = await self._analyze_images(report_data)
            total_score += image_score
            flags.extend(image_flags)
            details.update(image_details)
            
            # ML-based analysis
            ml_score, ml_flags, ml_details = await self._ml_analysis(report_data)
            total_score += ml_score
            flags.extend(ml_flags)
            details.update(ml_details)
            
            # Normalize score to 0-100
            fraud_score = min(100, max(0, total_score * 100))
            
            # Determine risk level
            risk_level = self._determine_risk_level(fraud_score)
            
            # Calculate confidence based on number of flags and score consistency
            confidence = self._calculate_confidence(fraud_score, len(flags), details)
            
            return FraudDetectionResult(
                report_id=report_id,
                risk_level=risk_level,
                fraud_score=fraud_score,
                confidence=confidence,
                flags=list(set(flags)),  # Remove duplicates
                details=details,
                detected_at=datetime.utcnow(),
                model_version=self.model_version
            )
            
        except Exception as e:
            logger.error(f"Error in fraud analysis for report {report_data.get('id', 'unknown')}: {e}")
            return FraudDetectionResult(
                report_id=report_data.get('id', 'unknown'),
                risk_level=FraudRiskLevel.LOW,
                fraud_score=0.0,
                confidence=0.0,
                flags=["analysis_error"],
                details={"error": str(e)},
                detected_at=datetime.utcnow(),
                model_version=self.model_version
            )
    
    async def _analyze_text_content(self, report_data: Dict[str, Any]) -> Tuple[float, List[str], Dict[str, Any]]:
        """Analyze text content for fraud indicators."""
        score = 0.0
        flags = []
        details = {}
        
        title = report_data.get('title', '')
        description = report_data.get('description', '')
        text_content = f"{title} {description}".lower()
        
        # Check for suspicious keywords
        for pattern in self.patterns:
            if pattern.keywords:
                matches = [kw for kw in pattern.keywords if kw.lower() in text_content]
                if matches:
                    score += pattern.weight * len(matches)
                    flags.append(f"suspicious_keywords: {', '.join(matches)}")
                    details[f"keyword_matches_{pattern.pattern_type}"] = matches
            
            # Check regex patterns
            if pattern.regex_pattern:
                if re.search(pattern.regex_pattern, text_content):
                    score += pattern.weight
                    flags.append(pattern.description)
                    details[f"regex_match_{pattern.pattern_type}"] = True
        
        # Check for excessive capitalization
        caps_ratio = sum(1 for c in text_content if c.isupper()) / max(len(text_content), 1)
        if caps_ratio > 0.3:
            score += 0.2
            flags.append("excessive_capitalization")
            details["caps_ratio"] = caps_ratio
        
        # Check for repeated words
        words = text_content.split()
        word_counts = {}
        for word in words:
            word_counts[word] = word_counts.get(word, 0) + 1
        
        repeated_words = [word for word, count in word_counts.items() if count > 3]
        if repeated_words:
            score += 0.3
            flags.append("repeated_words")
            details["repeated_words"] = repeated_words
        
        return score, flags, details
    
    async def _analyze_behavior_patterns(self, report_data: Dict[str, Any]) -> Tuple[float, List[str], Dict[str, Any]]:
        """Analyze user behavior patterns for fraud indicators."""
        score = 0.0
        flags = []
        details = {}
        
        # Check reward amount - only flag extremely suspicious amounts
        reward_amount = report_data.get('reward_amount')
        if reward_amount:
            try:
                amount = float(reward_amount.replace('$', '').replace(',', ''))
                # Only flag rewards over $10,000 as suspicious (very high threshold)
                if amount > 10000:  
                    score += 0.4
                    flags.append("extremely_high_reward_amount")
                    details["reward_amount"] = amount
                # Flag rewards over $5,000 but with lower weight
                elif amount > 5000:
                    score += 0.2
                    flags.append("high_reward_amount")
                    details["reward_amount"] = amount
            except (ValueError, AttributeError):
                pass
        
        # Remove urgent flag penalty - urgent posts are legitimate
        # is_urgent = report_data.get('is_urgent', False)
        # if is_urgent:
        #     score += 0.2
        #     flags.append("marked_as_urgent")
        #     details["is_urgent"] = True
        
        # Check contact information quality
        contact_info = report_data.get('contact_info', '')
        if contact_info:
            # Check for fake contact patterns
            if re.search(r'(123-456-7890|000-000-0000|test@test\.com)', contact_info.lower()):
                score += 0.5
                flags.append("suspicious_contact_info")
                details["contact_info"] = contact_info
        
        return score, flags, details
    
    async def _analyze_location_data(self, report_data: Dict[str, Any]) -> Tuple[float, List[str], Dict[str, Any]]:
        """Analyze location data for inconsistencies."""
        score = 0.0
        flags = []
        details = {}
        
        latitude = report_data.get('latitude')
        longitude = report_data.get('longitude')
        location_city = report_data.get('location_city', '')
        location_address = report_data.get('location_address', '')
        
        # Check for missing location data
        if not latitude or not longitude:
            score += 0.3
            flags.append("missing_coordinates")
            details["has_coordinates"] = False
        
        # Check for invalid coordinates
        if latitude and longitude:
            if not (-90 <= latitude <= 90) or not (-180 <= longitude <= 180):
                score += 0.5
                flags.append("invalid_coordinates")
                details["coordinates"] = {"lat": latitude, "lng": longitude}
        
        # Check for generic location names
        generic_locations = ['city', 'town', 'area', 'location', 'place']
        if any(gen in location_city.lower() for gen in generic_locations):
            score += 0.2
            flags.append("generic_location")
            details["location_city"] = location_city
        
        return score, flags, details
    
    async def _analyze_images(self, report_data: Dict[str, Any]) -> Tuple[float, List[str], Dict[str, Any]]:
        """Analyze images for fraud indicators."""
        score = 0.0
        flags = []
        details = {}
        
        images = report_data.get('images', [])
        image_hashes = report_data.get('image_hashes', [])
        
        # Check for duplicate images
        if len(set(image_hashes)) < len(image_hashes):
            score += 0.4
            flags.append("duplicate_images")
            details["duplicate_image_count"] = len(image_hashes) - len(set(image_hashes))
        
        # Check for excessive number of images
        if len(images) > 10:
            score += 0.2
            flags.append("excessive_images")
            details["image_count"] = len(images)
        
        # Check for missing images when reward is offered
        if report_data.get('reward_offered', False) and not images:
            score += 0.3
            flags.append("reward_without_images")
            details["reward_offered"] = True
        
        return score, flags, details
    
    async def _ml_analysis(self, report_data: Dict[str, Any]) -> Tuple[float, List[str], Dict[str, Any]]:
        """Perform machine learning-based analysis."""
        score = 0.0
        flags = []
        details = {}
        
        try:
            # Prepare features for ML analysis
            features = self._extract_ml_features(report_data)
            
            # Use isolation forest for anomaly detection
            if hasattr(self, 'isolation_model') and self.isolation_model:
                anomaly_score = self.isolation_model.decision_function([features])[0]
                if anomaly_score < -0.5:  # Threshold for anomaly
                    score += 0.6
                    flags.append("ml_anomaly_detected")
                    details["anomaly_score"] = float(anomaly_score)
            
            # Use random forest for classification
            if hasattr(self, 'classification_model') and self.classification_model:
                fraud_probability = self.classification_model.predict_proba([features])[0][1]
                if fraud_probability > 0.7:
                    score += fraud_probability * 0.8
                    flags.append("ml_fraud_classification")
                    details["fraud_probability"] = float(fraud_probability)
            
        except Exception as e:
            logger.warning(f"ML analysis failed: {e}")
            details["ml_error"] = str(e)
        
        return score, flags, details
    
    def _extract_ml_features(self, report_data: Dict[str, Any]) -> List[float]:
        """Extract numerical features for ML analysis."""
        features = []
        
        # Text length features
        title_len = len(report_data.get('title', ''))
        desc_len = len(report_data.get('description', ''))
        features.extend([title_len, desc_len])
        
        # Reward features
        reward_amount = 0
        if report_data.get('reward_amount'):
            try:
                reward_amount = float(str(report_data['reward_amount']).replace('$', '').replace(',', ''))
            except (ValueError, AttributeError):
                pass
        features.append(reward_amount)
        
        # Boolean features
        features.extend([
            1.0 if report_data.get('is_urgent', False) else 0.0,
            1.0 if report_data.get('reward_offered', False) else 0.0,
            1.0 if report_data.get('latitude') else 0.0,
            1.0 if report_data.get('longitude') else 0.0,
        ])
        
        # Image features
        image_count = len(report_data.get('images', []))
        features.append(image_count)
        
        # Location features
        features.extend([
            len(report_data.get('location_city', '')),
            len(report_data.get('location_address', '')),
        ])
        
        return features
    
    def _determine_risk_level(self, fraud_score: float) -> FraudRiskLevel:
        """Determine risk level based on fraud score."""
        if fraud_score >= 80:
            return FraudRiskLevel.CRITICAL
        elif fraud_score >= 60:
            return FraudRiskLevel.HIGH
        elif fraud_score >= 30:
            return FraudRiskLevel.MEDIUM
        else:
            return FraudRiskLevel.LOW
    
    def _calculate_confidence(self, fraud_score: float, flag_count: int, details: Dict[str, Any]) -> float:
        """Calculate confidence score for the fraud detection result."""
        # Base confidence on score consistency and flag count
        base_confidence = min(1.0, fraud_score / 100)
        
        # Adjust based on number of flags
        flag_factor = min(1.0, flag_count / 5)  # More flags = higher confidence
        
        # Adjust based on details richness
        detail_factor = min(1.0, len(details) / 10)
        
        return (base_confidence + flag_factor + detail_factor) / 3
    
    async def train_models(self, training_data: List[Dict[str, Any]]) -> None:
        """Train ML models with historical data."""
        try:
            if not training_data:
                logger.warning("No training data provided")
                return
            
            # Extract features and labels
            features = []
            labels = []
            
            for data in training_data:
                features.append(self._extract_ml_features(data))
                labels.append(1.0 if data.get('is_fraud', False) else 0.0)
            
            features = np.array(features)
            labels = np.array(labels)
            
            # Scale features
            features_scaled = self.scaler.fit_transform(features)
            
            # Train isolation forest for anomaly detection
            self.isolation_model = IsolationForest(contamination=0.1, random_state=42)
            self.isolation_model.fit(features_scaled)
            
            # Train random forest for classification
            self.classification_model = RandomForestClassifier(
                n_estimators=100,
                random_state=42,
                class_weight='balanced'
            )
            self.classification_model.fit(features_scaled, labels)
            
            logger.info(f"Successfully trained models with {len(training_data)} samples")
            
        except Exception as e:
            logger.error(f"Failed to train models: {e}")
            raise
    
    async def batch_analyze_reports(self, reports: List[Dict[str, Any]]) -> List[FraudDetectionResult]:
        """Analyze multiple reports in batch."""
        tasks = [self.analyze_report(report) for report in reports]
        return await asyncio.gather(*tasks)
    
    def save_models(self, filepath: str) -> None:
        """Save trained models to disk."""
        try:
            model_data = {
                'isolation_model': self.isolation_model,
                'classification_model': self.classification_model,
                'scaler': self.scaler,
                'model_version': self.model_version
            }
            joblib.dump(model_data, filepath)
            logger.info(f"Models saved to {filepath}")
        except Exception as e:
            logger.error(f"Failed to save models: {e}")
            raise
    
    def load_models(self, filepath: str) -> None:
        """Load trained models from disk."""
        try:
            model_data = joblib.load(filepath)
            self.isolation_model = model_data['isolation_model']
            self.classification_model = model_data['classification_model']
            self.scaler = model_data['scaler']
            self.model_version = model_data.get('model_version', '1.0.0')
            logger.info(f"Models loaded from {filepath}")
        except Exception as e:
            logger.error(f"Failed to load models: {e}")
            raise


# Global instance
fraud_detection_service = FraudDetectionService()
