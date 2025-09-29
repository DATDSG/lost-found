"""
Enhanced Research Integration Module

This module integrates research capabilities directly into the matching service
for continuous evaluation and optimization.
"""

from typing import Dict, List, Optional, Any
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path

from app.core.config import settings
from app.db.models import Item, Match
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

class ResearchEnhancedMatchingService:
    """Enhanced matching service with integrated research capabilities"""
    
    def __init__(self, base_matching_service):
        self.base_service = base_matching_service
        self.research_enabled = settings.ENV == "research"
        self.metrics_buffer = []
        self.experiment_weights = None
        
    def rank_for_item(self, db: Session, item_id: int, limit: int = 20, 
                     experiment_id: Optional[str] = None) -> List[Any]:
        """Enhanced ranking with research tracking"""
        
        start_time = datetime.now()
        
        # Use experimental weights if specified
        if experiment_id and self.experiment_weights:
            original_weights = self.base_service._weights.copy()
            self.base_service._weights.update(self.experiment_weights)
        
        try:
            # Get base results
            results = self.base_service.rank_for_item(db, item_id, limit)
            
            # Track research metrics if enabled
            if self.research_enabled:
                self._track_query_metrics(
                    item_id=item_id,
                    result_count=len(results),
                    latency=(datetime.now() - start_time).total_seconds(),
                    experiment_id=experiment_id
                )
            
            return results
            
        finally:
            # Restore original weights
            if experiment_id and self.experiment_weights:
                self.base_service._weights = original_weights
    
    def set_experimental_weights(self, weights: Dict[str, float]):
        """Set experimental weights for A/B testing"""
        self.experiment_weights = weights
        logger.info(f"Set experimental weights: {weights}")
    
    def _track_query_metrics(self, item_id: int, result_count: int, 
                           latency: float, experiment_id: Optional[str] = None):
        """Track query metrics for research analysis"""
        metric = {
            "timestamp": datetime.now().isoformat(),
            "item_id": item_id,
            "result_count": result_count,
            "latency": latency,
            "experiment_id": experiment_id
        }
        
        self.metrics_buffer.append(metric)
        
        # Flush metrics periodically
        if len(self.metrics_buffer) >= 100:
            self._flush_metrics()
    
    def _flush_metrics(self):
        """Flush accumulated metrics to storage"""
        if not self.metrics_buffer:
            return
            
        output_dir = Path("research_output/metrics")
        output_dir.mkdir(parents=True, exist_ok=True)
        
        filename = f"query_metrics_{datetime.now().strftime('%Y%m%d_%H')}.json"
        filepath = output_dir / filename
        
        # Load existing data if file exists
        existing_data = []
        if filepath.exists():
            try:
                with open(filepath, 'r') as f:
                    existing_data = json.load(f)
            except Exception as e:
                logger.warning(f"Could not load existing metrics: {e}")
        
        # Append new metrics
        existing_data.extend(self.metrics_buffer)
        
        # Save updated data
        try:
            with open(filepath, 'w') as f:
                json.dump(existing_data, f, indent=2, default=str)
            logger.info(f"Flushed {len(self.metrics_buffer)} metrics to {filepath}")
        except Exception as e:
            logger.error(f"Could not save metrics: {e}")
        
        # Clear buffer
        self.metrics_buffer = []

class ABTestingFramework:
    """A/B testing framework for matching algorithms"""
    
    def __init__(self):
        self.active_experiments = {}
        self.results_buffer = []
    
    def create_experiment(self, name: str, description: str, 
                         control_weights: Dict[str, float],
                         variant_weights: Dict[str, float],
                         traffic_split: float = 0.5) -> str:
        """Create a new A/B test experiment"""
        
        experiment_id = f"{name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        experiment = {
            "id": experiment_id,
            "name": name,
            "description": description,
            "control_weights": control_weights,
            "variant_weights": variant_weights,
            "traffic_split": traffic_split,
            "start_time": datetime.now().isoformat(),
            "status": "active"
        }
        
        self.active_experiments[experiment_id] = experiment
        
        logger.info(f"Created A/B test: {experiment_id}")
        return experiment_id
    
    def assign_variant(self, user_id: int, experiment_id: str) -> str:
        """Assign user to control or variant group"""
        if experiment_id not in self.active_experiments:
            return "control"
        
        experiment = self.active_experiments[experiment_id]
        
        # Simple hash-based assignment for consistency
        import hashlib
        hash_input = f"{user_id}_{experiment_id}".encode()
        hash_value = int(hashlib.md5(hash_input).hexdigest(), 16)
        
        # Use traffic split to determine assignment
        if (hash_value % 100) / 100 < experiment["traffic_split"]:
            return "variant"
        else:
            return "control"
    
    def get_experiment_weights(self, experiment_id: str, variant: str) -> Dict[str, float]:
        """Get weights for specified experiment variant"""
        if experiment_id not in self.active_experiments:
            return {}
        
        experiment = self.active_experiments[experiment_id]
        
        if variant == "variant":
            return experiment["variant_weights"]
        else:
            return experiment["control_weights"]
    
    def track_interaction(self, experiment_id: str, variant: str, 
                         user_id: int, item_id: int, 
                         match_accepted: bool, match_rank: Optional[int] = None):
        """Track user interaction for experiment analysis"""
        
        interaction = {
            "timestamp": datetime.now().isoformat(),
            "experiment_id": experiment_id,
            "variant": variant,
            "user_id": user_id,
            "item_id": item_id,  
            "match_accepted": match_accepted,
            "match_rank": match_rank
        }
        
        self.results_buffer.append(interaction)
        
        # Flush periodically
        if len(self.results_buffer) >= 50:
            self._flush_results()
    
    def _flush_results(self):
        """Flush experiment results to storage"""
        if not self.results_buffer:
            return
            
        output_dir = Path("research_output/experiments")
        output_dir.mkdir(parents=True, exist_ok=True)
        
        filename = f"ab_test_results_{datetime.now().strftime('%Y%m%d_%H')}.json"
        filepath = output_dir / filename
        
        # Load existing data
        existing_data = []
        if filepath.exists():
            try:
                with open(filepath, 'r') as f:
                    existing_data = json.load(f)
            except Exception as e:
                logger.warning(f"Could not load existing results: {e}")
        
        # Append new results
        existing_data.extend(self.results_buffer)
        
        # Save updated data
        try:
            with open(filepath, 'w') as f:
                json.dump(existing_data, f, indent=2, default=str)
            logger.info(f"Flushed {len(self.results_buffer)} A/B test results")
        except Exception as e:
            logger.error(f"Could not save A/B results: {e}")
        
        # Clear buffer
        self.results_buffer = []
    
    def analyze_experiment(self, experiment_id: str) -> Dict[str, Any]:
        """Analyze A/B test results"""
        
        # Load all result files
        results = []
        output_dir = Path("research_output/experiments")
        
        for file in output_dir.glob("ab_test_results_*.json"):
            try:
                with open(file, 'r') as f:
                    data = json.load(f)
                    results.extend([r for r in data if r.get("experiment_id") == experiment_id])
            except Exception as e:
                logger.warning(f"Could not load results from {file}: {e}")
        
        if not results:
            return {"error": "No results found for experiment"}
        
        # Separate control and variant results
        control_results = [r for r in results if r.get("variant") == "control"]
        variant_results = [r for r in results if r.get("variant") == "variant"]
        
        # Calculate metrics
        control_acceptance = sum(1 for r in control_results if r.get("match_accepted")) / len(control_results) if control_results else 0
        variant_acceptance = sum(1 for r in variant_results if r.get("match_accepted")) / len(variant_results) if variant_results else 0
        
        # Statistical significance test (simplified)
        improvement = (variant_acceptance - control_acceptance) / control_acceptance if control_acceptance > 0 else 0
        
        analysis = {
            "experiment_id": experiment_id,
            "analysis_date": datetime.now().isoformat(),
            "control": {
                "sample_size": len(control_results),
                "acceptance_rate": control_acceptance
            },
            "variant": {
                "sample_size": len(variant_results),
                "acceptance_rate": variant_acceptance
            },
            "improvement": improvement,
            "significant": abs(improvement) > 0.05 and min(len(control_results), len(variant_results)) > 30
        }
        
        return analysis

class ContinuousLearningSystem:
    """System for continuous learning from user feedback"""
    
    def __init__(self, matching_service):
        self.matching_service = matching_service
        self.feedback_buffer = []
        self.learning_rate = 0.01
    
    def record_feedback(self, item_id: int, match_id: int, 
                       accepted: bool, user_id: int):
        """Record user feedback on match quality"""
        
        feedback = {
            "timestamp": datetime.now().isoformat(),
            "item_id": item_id,
            "match_id": match_id,
            "accepted": accepted,
            "user_id": user_id
        }
        
        self.feedback_buffer.append(feedback)
        
        # Update weights periodically
        if len(self.feedback_buffer) >= 20:
            self._update_weights()
    
    def _update_weights(self):
        """Update matching weights based on user feedback"""
        
        if not self.feedback_buffer:
            return
        
        # Simple weight adjustment based on acceptance rate
        accepted_count = sum(1 for f in self.feedback_buffer if f["accepted"])
        acceptance_rate = accepted_count / len(self.feedback_buffer)
        
        # If acceptance rate is low, adjust weights
        if acceptance_rate < 0.6:
            # Increase text weight, decrease others slightly
            current_weights = self.matching_service._weights
            adjustments = {
                "text": 0.02,
                "image": -0.005,
                "geo": -0.005,
                "time": -0.005,
                "meta": -0.005
            }
            
            for component, adjustment in adjustments.items():
                if component in current_weights:
                    new_weight = current_weights[component] + adjustment
                    current_weights[component] = max(0.1, min(0.5, new_weight))
            
            logger.info(f"Updated weights based on feedback: {current_weights}")
        
        # Clear buffer
        self.feedback_buffer = []

# Factory function to create research-enhanced service
def create_research_enhanced_service(base_matching_service):
    """Create research-enhanced matching service"""
    
    if settings.ENV in ["research", "development"]:
        return ResearchEnhancedMatchingService(base_matching_service)
    else:
        return base_matching_service

# Global instances
ab_testing = ABTestingFramework()
continuous_learning = None  # Will be initialized with matching service