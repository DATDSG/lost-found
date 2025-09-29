#!/usr/bin/env python3
"""
Research Experiment Runner Script

This script runs various research experiments on the Lost & Found System
to evaluate and optimize the multilingual matching algorithms.
"""

import asyncio
import argparse
import logging
import sys
from datetime import datetime
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(project_root))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
from app.services.matching_service import matching_service
from app.research.framework import ResearchExperimentRunner, ResearchConfig

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def setup_database_session():
    """Setup database session for experiments"""
    engine = create_engine(settings.DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    return SessionLocal()

def run_baseline_experiment():
    """Run baseline performance evaluation"""
    logger.info("Starting baseline evaluation experiment")
    
    # Setup
    db = setup_database_session()
    runner = ResearchExperimentRunner(
        settings.DATABASE_URL, 
        matching_service,
        output_dir="research_output/experiments"
    )
    
    try:
        # Run baseline evaluation
        result = runner.run_baseline_evaluation(db)
        
        logger.info(f"Baseline experiment completed: {result.experiment_id}")
        logger.info(f"Average MRR: {result.metrics.get('avg_mrr', 0):.4f}")
        logger.info(f"Average Recall@10: {result.metrics.get('avg_recall_at_10', 0):.4f}")
        logger.info(f"Sample size: {result.sample_size}")
        
        return result
        
    except Exception as e:
        logger.error(f"Baseline experiment failed: {e}")
        raise
    finally:
        db.close()

def run_weight_optimization_experiment():
    """Run weight optimization experiment"""
    logger.info("Starting weight optimization experiment")
    
    # Setup
    db = setup_database_session()
    runner = ResearchExperimentRunner(
        settings.DATABASE_URL,
        matching_service,
        output_dir="research_output/experiments"
    )
    
    try:
        # Run optimization
        result = runner.run_weight_optimization_experiment(db)
        
        logger.info(f"Optimization experiment completed: {result.experiment_id}")
        logger.info(f"Best MRR: {result.metrics.get('best_mrr', 0):.4f}")
        logger.info(f"Combinations tested: {result.sample_size}")
        
        return result
        
    except Exception as e:
        logger.error(f"Optimization experiment failed: {e}")
        raise
    finally:
        db.close()

def run_cross_lingual_analysis():
    """Run detailed cross-lingual performance analysis"""
    logger.info("Starting cross-lingual analysis experiment")
    
    # Setup
    db = setup_database_session()
    runner = ResearchExperimentRunner(
        settings.DATABASE_URL,
        matching_service,
        output_dir="research_output/experiments"  
    )
    
    try:
        # Get cross-lingual metrics
        language_metrics = runner.evaluator.evaluate_language_pairs(db, sample_size=300)
        
        # Analyze results
        same_language_performance = []
        cross_language_performance = []
        
        for lang_pair, metrics in language_metrics.items():
            languages = lang_pair.split('-')
            if languages[0] == languages[1]:
                same_language_performance.append(metrics.get('mrr', 0))
            else:
                cross_language_performance.append(metrics.get('mrr', 0))
        
        # Calculate averages
        avg_same_lang = sum(same_language_performance) / len(same_language_performance) if same_language_performance else 0
        avg_cross_lang = sum(cross_language_performance) / len(cross_language_performance) if cross_language_performance else 0
        
        logger.info(f"Same language MRR: {avg_same_lang:.4f}")
        logger.info(f"Cross language MRR: {avg_cross_lang:.4f}")
        logger.info(f"Cross-lingual performance ratio: {avg_cross_lang/avg_same_lang:.4f}")
        
        # Save detailed analysis
        analysis_data = {
            "timestamp": datetime.now().isoformat(),
            "language_pair_metrics": language_metrics,
            "summary": {
                "same_language_avg_mrr": avg_same_lang,
                "cross_language_avg_mrr": avg_cross_lang,
                "performance_ratio": avg_cross_lang/avg_same_lang if avg_same_lang > 0 else 0
            }
        }
        
        runner.data_collector.save_experiment_data(
            analysis_data,
            f"cross_lingual_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        )
        
        return analysis_data
        
    except Exception as e:
        logger.error(f"Cross-lingual analysis failed: {e}")
        raise
    finally:
        db.close()

def run_performance_benchmark():
    """Run system performance benchmarking"""
    logger.info("Starting performance benchmark")
    
    import time
    import statistics
    
    # Setup
    db = setup_database_session()
    
    try:
        # Test latency with different query sizes
        latencies = {
            "small_queries": [],  # 1-50 characters
            "medium_queries": [],  # 51-200 characters
            "large_queries": []   # 201+ characters
        }
        
        # Get sample items for testing
        from sqlalchemy import text
        sample_items = db.execute(
            text("SELECT id, title, description FROM items WHERE status='lost' LIMIT 50")
        ).fetchall()
        
        for item in sample_items:
            query_text = (item.title or "") + " " + (item.description or "")
            query_length = len(query_text.strip())
            
            # Categorize by length
            if query_length <= 50:
                category = "small_queries"
            elif query_length <= 200:
                category = "medium_queries" 
            else:
                category = "large_queries"
            
            # Measure latency
            start_time = time.time()
            try:
                matches = matching_service.rank_for_item(db, item.id, limit=10)
                latency = time.time() - start_time
                latencies[category].append(latency)
            except Exception as e:
                logger.warning(f"Error processing item {item.id}: {e}")
        
        # Calculate statistics
        benchmark_results = {}
        for category, times in latencies.items():
            if times:
                benchmark_results[category] = {
                    "count": len(times),
                    "mean_latency": statistics.mean(times),
                    "median_latency": statistics.median(times),
                    "min_latency": min(times),
                    "max_latency": max(times),
                    "std_latency": statistics.stdev(times) if len(times) > 1 else 0
                }
        
        # Log results
        for category, stats in benchmark_results.items():
            logger.info(f"{category}: {stats['mean_latency']:.3f}s avg, {stats['count']} samples")
        
        # Save benchmark data
        benchmark_data = {
            "timestamp": datetime.now().isoformat(),
            "benchmark_results": benchmark_results,
            "system_info": {
                "total_items_tested": len(sample_items),
                "database_url": settings.DATABASE_URL.split('@')[-1],  # Remove credentials
                "nlp_enabled": settings.NLP_ON,
                "cv_enabled": settings.CV_ON
            }
        }
        
        # Save to file
        output_dir = Path("research_output/experiments")
        output_dir.mkdir(parents=True, exist_ok=True)
        
        import json
        with open(output_dir / f"performance_benchmark_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json", 'w') as f:
            json.dump(benchmark_data, f, indent=2, default=str)
        
        return benchmark_data
        
    except Exception as e:
        logger.error(f"Performance benchmark failed: {e}")
        raise
    finally:
        db.close()

def generate_comprehensive_report(results: list):
    """Generate comprehensive research report"""
    logger.info("Generating comprehensive research report")
    
    report_lines = [
        "# Lost & Found System Research Report",
        f"\n**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"**Total Experiments:** {len(results)}",
        "\n## Executive Summary\n",
        "This report presents the results of comprehensive research experiments conducted on the",
        "Lost & Found System's multilingual, multi-modal matching algorithms.\n",
        "## Experiments Conducted\n"
    ]
    
    for i, result in enumerate(results, 1):
        if hasattr(result, 'experiment_id'):
            # Experiment result object
            report_lines.extend([
                f"### {i}. {result.config['experiment_name']}",
                f"- **Experiment ID:** {result.experiment_id}",
                f"- **Description:** {result.config['description']}",
                f"- **Sample Size:** {result.sample_size}",
                f"- **Execution Time:** {result.execution_time:.2f}s",
                "\n**Key Metrics:**"
            ])
            
            for metric, value in result.metrics.items():
                if isinstance(value, float):
                    report_lines.append(f"- {metric}: {value:.4f}")
                else:
                    report_lines.append(f"- {metric}: {value}")
                    
        else:
            # Other result types (performance, analysis, etc.)
            report_lines.extend([
                f"### {i}. Analysis Result",
                f"- **Type:** {type(result).__name__}",
                "- **Summary:** See detailed data files for complete results"
            ])
        
        report_lines.append("")
    
    report_lines.extend([
        "## Recommendations\n",
        "Based on the experimental results, the following recommendations are proposed:\n",
        "1. **Algorithm Optimization:** Use the optimized weights from weight optimization experiments",
        "2. **Cross-Lingual Performance:** Focus on improving cross-language matching accuracy", 
        "3. **Performance Tuning:** Address any latency issues identified in benchmarks",
        "4. **Continuous Monitoring:** Implement continuous evaluation using the research framework\n",
        "## Next Steps\n",
        "1. Implement recommended optimizations in production",
        "2. Set up continuous A/B testing framework",
        "3. Expand evaluation to include user satisfaction metrics",
        "4. Prepare research findings for academic publication\n",
        f"---\n*Report generated by Lost & Found Research Framework*"
    ])
    
    # Save report
    output_dir = Path("research_output/reports")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    report_path = output_dir / f"research_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
    
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(report_lines))
    
    logger.info(f"Research report saved to: {report_path}")
    return str(report_path)

def main():
    """Main function to run research experiments"""
    parser = argparse.ArgumentParser(description="Run Lost & Found System Research Experiments")
    parser.add_argument("--experiment", "-e", 
                       choices=["baseline", "optimization", "cross-lingual", "performance", "all"],
                       default="all",
                       help="Type of experiment to run")
    parser.add_argument("--output-dir", "-o",
                       default="research_output",
                       help="Output directory for results")
    
    args = parser.parse_args()
    
    # Create output directory
    Path(args.output_dir).mkdir(parents=True, exist_ok=True)
    
    results = []
    
    try:
        if args.experiment in ["baseline", "all"]:
            logger.info("Running baseline evaluation...")
            results.append(run_baseline_experiment())
        
        if args.experiment in ["optimization", "all"]:
            logger.info("Running weight optimization...")
            results.append(run_weight_optimization_experiment())
        
        if args.experiment in ["cross-lingual", "all"]:
            logger.info("Running cross-lingual analysis...")
            results.append(run_cross_lingual_analysis())
        
        if args.experiment in ["performance", "all"]:
            logger.info("Running performance benchmark...")
            results.append(run_performance_benchmark())
        
        # Generate comprehensive report
        if results:
            report_path = generate_comprehensive_report(results)
            logger.info(f"\n{'='*60}")
            logger.info("RESEARCH EXPERIMENTS COMPLETED SUCCESSFULLY")
            logger.info(f"{'='*60}")
            logger.info(f"Results saved to: {args.output_dir}")
            logger.info(f"Comprehensive report: {report_path}")
            logger.info(f"Total experiments: {len(results)}")
        
    except Exception as e:
        logger.error(f"Experiment failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()