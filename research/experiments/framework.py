"""
Research Framework for Multilingual Multi-Modal Item Matching

This module implements the research infrastructure for evaluating and optimizing
the Lost & Found System's matching algorithms.
"""

import json
import logging
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, asdict
from pathlib import Path
import numpy as np
from sqlalchemy.orm import Session
from sqlalchemy import create_engine, text

# Research configuration
@dataclass
class ResearchConfig:
    """Configuration for research experiments"""
    experiment_name: str
    description: str
    languages: List[str] = None
    evaluation_metrics: List[str] = None
    weight_ranges: Dict[str, Tuple[float, float]] = None
    
    def __post_init__(self):
        if self.languages is None:
            self.languages = ["en", "si", "ta"]
        if self.evaluation_metrics is None:
            self.evaluation_metrics = ["recall_at_k", "mrr", "precision_at_k", "f1_score"]
        if self.weight_ranges is None:
            self.weight_ranges = {
                "text": (0.0, 0.5),
                "image": (0.0, 0.4),
                "geo": (0.1, 0.4),
                "time": (0.1, 0.3),
                "meta": (0.1, 0.3)
            }

@dataclass
class ExperimentResult:
    """Results from a single experiment run"""
    experiment_id: str
    timestamp: datetime
    config: Dict[str, Any]
    metrics: Dict[str, float]
    sample_size: int
    execution_time: float
    language_breakdown: Dict[str, Dict[str, float]] = None

class ResearchDataCollector:
    """Collects and manages research data"""
    
    def __init__(self, db_url: str, output_dir: str = "research_output"):
        self.db_url = db_url
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.logger = logging.getLogger(__name__)
    
    def collect_resolved_pairs(self, limit: int = 1000) -> List[Tuple[int, int, str, str]]:
        """Collect resolved lost-found item pairs with language information"""
        engine = create_engine(self.db_url)
        with engine.connect() as conn:
            query = text("""
                SELECT 
                    resolved_lost.id AS lost_id,
                    resolved_found.id AS found_id,
                    resolved_lost.language AS lost_lang,
                    resolved_found.language AS found_lang
                FROM items AS resolved_lost
                JOIN matches ON matches.lost_item_id = resolved_lost.id
                JOIN items AS resolved_found ON resolved_found.id = matches.found_item_id
                WHERE resolved_lost.status = 'resolved' 
                AND resolved_found.status = 'resolved'
                AND matches.status = 'accepted'
                ORDER BY matches.created_at DESC
                LIMIT :limit
            """)
            result = conn.execute(query, {"limit": limit})
            return [(row.lost_id, row.found_id, row.lost_lang, row.found_lang) 
                   for row in result.fetchall()]
    
    def collect_user_interactions(self, days: int = 30) -> Dict[str, Any]:
        """Collect user interaction patterns"""
        engine = create_engine(self.db_url)
        with engine.connect() as conn:
            # Match acceptance rates by language
            lang_query = text("""
                SELECT 
                    items.language,
                    COUNT(CASE WHEN matches.status = 'accepted' THEN 1 END) as accepted,
                    COUNT(CASE WHEN matches.status = 'rejected' THEN 1 END) as rejected,
                    COUNT(*) as total
                FROM matches
                JOIN items ON items.id = matches.lost_item_id
                WHERE matches.created_at >= NOW() - INTERVAL :days DAY
                GROUP BY items.language
            """)
            
            results = conn.execute(lang_query, {"days": days}).fetchall()
            
            interactions = {
                "by_language": {},
                "collection_date": datetime.now().isoformat(),
                "period_days": days
            }
            
            for row in results:
                interactions["by_language"][row.language] = {
                    "accepted": row.accepted,
                    "rejected": row.rejected,
                    "total": row.total,
                    "acceptance_rate": row.accepted / row.total if row.total > 0 else 0
                }
            
            return interactions
    
    def save_experiment_data(self, data: Dict[str, Any], filename: str):
        """Save experiment data to file"""
        filepath = self.output_dir / filename
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False, default=str)
        self.logger.info(f"Saved experiment data to {filepath}")

class CrossLingualEvaluator:
    """Evaluates cross-lingual matching performance"""
    
    def __init__(self, matching_service, data_collector: ResearchDataCollector):
        self.matching_service = matching_service
        self.data_collector = data_collector
        self.logger = logging.getLogger(__name__)
    
    def evaluate_language_pairs(self, db: Session, sample_size: int = 100) -> Dict[str, Dict[str, float]]:
        """Evaluate matching performance across different language pairs"""
        resolved_pairs = self.data_collector.collect_resolved_pairs(sample_size)
        
        results = {}
        language_combinations = [
            ("en", "en"), ("si", "si"), ("ta", "ta"),  # Same language
            ("en", "si"), ("en", "ta"), ("si", "ta"),  # Cross-language
            ("si", "en"), ("ta", "en"), ("ta", "si")   # Reverse cross-language
        ]
        
        for lost_lang, found_lang in language_combinations:
            # Filter pairs by language combination
            lang_pairs = [
                (lost_id, found_id) for lost_id, found_id, l_lang, f_lang in resolved_pairs
                if l_lang == lost_lang and f_lang == found_lang
            ]
            
            if len(lang_pairs) < 10:  # Skip if insufficient data
                continue
            
            metrics = self._evaluate_pairs(db, lang_pairs[:50])  # Limit for performance
            results[f"{lost_lang}-{found_lang}"] = metrics
        
        return results
    
    def _evaluate_pairs(self, db: Session, pairs: List[Tuple[int, int]]) -> Dict[str, float]:
        """Evaluate a set of item pairs"""
        total_pairs = len(pairs)
        if total_pairs == 0:
            return {}
        
        recall_at_5 = 0
        recall_at_10 = 0
        mrr_scores = []
        execution_times = []
        
        for lost_id, expected_found_id in pairs:
            start_time = time.time()
            
            try:
                matches = self.matching_service.rank_for_item(db, lost_id, limit=10)
                execution_time = time.time() - start_time
                execution_times.append(execution_time)
                
                # Find rank of expected match
                expected_rank = None
                for idx, match in enumerate(matches, 1):
                    if match.found_item_id == expected_found_id:
                        expected_rank = idx
                        break
                
                if expected_rank:
                    if expected_rank <= 5:
                        recall_at_5 += 1
                    if expected_rank <= 10:  
                        recall_at_10 += 1
                    mrr_scores.append(1.0 / expected_rank)
                else:
                    mrr_scores.append(0.0)
                    
            except Exception as e:
                self.logger.error(f"Error evaluating pair ({lost_id}, {expected_found_id}): {e}")
                execution_times.append(0.0)
                mrr_scores.append(0.0)
        
        return {
            "recall_at_5": recall_at_5 / total_pairs,
            "recall_at_10": recall_at_10 / total_pairs,
            "mrr": np.mean(mrr_scores) if mrr_scores else 0.0,
            "avg_latency": np.mean(execution_times) if execution_times else 0.0,
            "sample_size": total_pairs
        }

class WeightOptimizer:
    """Optimizes matching algorithm weights using experimental data"""
    
    def __init__(self, matching_service, evaluator: CrossLingualEvaluator):
        self.matching_service = matching_service
        self.evaluator = evaluator
        self.logger = logging.getLogger(__name__)
    
    def grid_search_optimization(self, db: Session, config: ResearchConfig) -> Dict[str, Any]:
        """Perform grid search over weight combinations"""
        from itertools import product
        
        # Generate weight combinations
        weight_values = {
            component: np.linspace(min_val, max_val, 5)
            for component, (min_val, max_val) in config.weight_ranges.items()
        }
        
        best_score = 0.0
        best_weights = None
        all_results = []
        
        # Generate all combinations
        combinations = list(product(*weight_values.values()))
        self.logger.info(f"Testing {len(combinations)} weight combinations")
        
        for i, weights in enumerate(combinations[:50]):  # Limit for performance
            weight_dict = dict(zip(weight_values.keys(), weights))
            
            # Normalize weights to sum to 1
            total = sum(weight_dict.values())
            if total > 0:
                weight_dict = {k: v/total for k, v in weight_dict.items()}
            
            # Update matching service weights temporarily
            original_weights = self.matching_service._weights.copy()
            self.matching_service._weights.update(weight_dict)
            
            try:
                # Evaluate with these weights
                metrics = self.evaluator.evaluate_language_pairs(db, sample_size=50)
                
                # Calculate average MRR across languages
                avg_mrr = np.mean([lang_metrics.get("mrr", 0.0) 
                                  for lang_metrics in metrics.values()])
                
                result = {
                    "weights": weight_dict,
                    "avg_mrr": avg_mrr,
                    "detailed_metrics": metrics
                }
                all_results.append(result)
                
                if avg_mrr > best_score:
                    best_score = avg_mrr
                    best_weights = weight_dict.copy()
                
                if i % 10 == 0:
                    self.logger.info(f"Completed {i+1}/{len(combinations)} combinations")
                    
            except Exception as e:
                self.logger.error(f"Error in weight combination {weight_dict}: {e}")
            finally:
                # Restore original weights
                self.matching_service._weights = original_weights
        
        return {
            "best_weights": best_weights,
            "best_score": best_score,
            "all_results": all_results,
            "experiment_config": asdict(config)
        }

class ResearchExperimentRunner:
    """Main class for running research experiments"""
    
    def __init__(self, db_url: str, matching_service, output_dir: str = "research_output"):
        self.db_url = db_url
        self.matching_service = matching_service
        self.data_collector = ResearchDataCollector(db_url, output_dir)
        self.evaluator = CrossLingualEvaluator(matching_service, self.data_collector)
        self.optimizer = WeightOptimizer(matching_service, self.evaluator)
        self.logger = logging.getLogger(__name__)
    
    def run_baseline_evaluation(self, db: Session) -> ExperimentResult:
        """Run baseline evaluation with current settings"""
        start_time = time.time()
        
        config = ResearchConfig(
            experiment_name="baseline_evaluation",
            description="Baseline performance evaluation"
        )
        
        # Collect current performance metrics
        language_metrics = self.evaluator.evaluate_language_pairs(db, sample_size=200)
        user_interactions = self.data_collector.collect_user_interactions(days=30)
        
        # Calculate overall metrics
        overall_metrics = {
            "avg_recall_at_5": np.mean([m.get("recall_at_5", 0) for m in language_metrics.values()]),
            "avg_recall_at_10": np.mean([m.get("recall_at_10", 0) for m in language_metrics.values()]),
            "avg_mrr": np.mean([m.get("mrr", 0) for m in language_metrics.values()]),
            "avg_latency": np.mean([m.get("avg_latency", 0) for m in language_metrics.values()])
        }
        
        execution_time = time.time() - start_time
        
        result = ExperimentResult(
            experiment_id=f"baseline_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            timestamp=datetime.now(),
            config=asdict(config),
            metrics=overall_metrics,
            sample_size=sum(m.get("sample_size", 0) for m in language_metrics.values()),
            execution_time=execution_time,
            language_breakdown=language_metrics
        )
        
        # Save results
        self.data_collector.save_experiment_data(
            {
                "experiment_result": asdict(result),
                "user_interactions": user_interactions,
                "detailed_language_metrics": language_metrics
            },
            f"baseline_evaluation_{result.experiment_id}.json"
        )
        
        return result
    
    def run_weight_optimization_experiment(self, db: Session) -> ExperimentResult:
        """Run weight optimization experiment"""
        start_time = time.time()
        
        config = ResearchConfig(
            experiment_name="weight_optimization",
            description="Optimize matching algorithm weights using grid search"
        )
        
        # Run optimization
        optimization_results = self.optimizer.grid_search_optimization(db, config)
        
        execution_time = time.time() - start_time
        
        # Create experiment result
        result = ExperimentResult(
            experiment_id=f"optimization_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            timestamp=datetime.now(),
            config=asdict(config),
            metrics={"best_mrr": optimization_results["best_score"]},
            sample_size=len(optimization_results["all_results"]),
            execution_time=execution_time
        )
        
        # Save results
        self.data_collector.save_experiment_data(
            {
                "experiment_result": asdict(result),
                "optimization_results": optimization_results
            },
            f"weight_optimization_{result.experiment_id}.json"
        )
        
        return result
    
    def generate_research_report(self, experiments: List[ExperimentResult]) -> str:
        """Generate comprehensive research report"""
        report = []
        report.append("# Research Experiment Report")
        report.append(f"\nGenerated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"\nTotal Experiments: {len(experiments)}")
        
        for exp in experiments:
            report.append(f"\n## Experiment: {exp.config['experiment_name']}")
            report.append(f"- **ID**: {exp.experiment_id}")
            report.append(f"- **Timestamp**: {exp.timestamp}")
            report.append(f"- **Sample Size**: {exp.sample_size}")
            report.append(f"- **Execution Time**: {exp.execution_time:.2f}s")
            report.append(f"- **Description**: {exp.config['description']}")
            
            report.append("\n### Metrics:")
            for metric, value in exp.metrics.items():
                report.append(f"- **{metric}**: {value:.4f}")
            
            if exp.language_breakdown:
                report.append("\n### Language Breakdown:")
                for lang_pair, metrics in exp.language_breakdown.items():
                    report.append(f"- **{lang_pair}**:")
                    for metric, value in metrics.items():
                        report.append(f"  - {metric}: {value:.4f}")
        
        return "\n".join(report)

# Example usage
if __name__ == "__main__":
    # This would be integrated with the main application
    logging.basicConfig(level=logging.INFO)
    
    # Initialize research framework
    db_url = "postgresql://lostfound:lostfound@localhost:5432/lostfound"
    # matching_service would be imported from the main app
    # runner = ResearchExperimentRunner(db_url, matching_service)
    
    print("Research framework initialized. Ready for experiments!")