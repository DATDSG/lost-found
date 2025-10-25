"""
Enhanced Health Check for NLP Service
Provides comprehensive health monitoring and service status reporting
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, Optional
import time
import psutil
import os
from datetime import datetime, timezone
import redis
import nltk

from config import config

router = APIRouter(prefix="/health", tags=["health"])

class HealthStatus(BaseModel):
    """Health status response model"""
    status: str
    service: str
    version: str
    timestamp: datetime
    uptime_seconds: float
    environment: str
    features: Dict[str, bool]
    dependencies: Dict[str, Any]
    metrics: Dict[str, Any]

class SystemMetrics(BaseModel):
    """System metrics model"""
    cpu_percent: float
    memory_percent: float
    memory_used_mb: float
    memory_total_mb: float
    disk_percent: float
    load_average: Optional[tuple] = None

# Global startup time
STARTUP_TIME = time.time()

@router.get("/", response_model=HealthStatus)
async def health_check():
    """Comprehensive health check endpoint"""
    current_time = datetime.now(timezone.utc)
    uptime = time.time() - STARTUP_TIME
    
    # Check all dependencies
    dependencies = await check_all_dependencies()
    
    # Get system metrics
    metrics = get_system_metrics()
    
    # Determine overall status
    overall_status = "healthy"
    for dep_name, dep_health in dependencies.items():
        if dep_health.get("status") == "unhealthy":
            overall_status = "degraded"
        elif dep_health.get("status") == "unavailable":
            overall_status = "degraded"
    
    return HealthStatus(
        status=overall_status,
        service="nlp",
        version="1.0.0",
        timestamp=current_time,
        uptime_seconds=uptime,
        environment=config.ENVIRONMENT,
        features={
            "redis_cache": config.ENABLE_REDIS_CACHE,
            "text_preprocessing": True,
            "fuzzy_matching": True,
            "semantic_similarity": True,
            "nltk_available": True,
        },
        dependencies=dependencies,
        metrics=metrics,
    )

@router.get("/ready")
async def readiness_check():
    """Kubernetes readiness probe"""
    dependencies = await check_all_dependencies()
    
    # Check critical dependencies
    if dependencies.get("redis", {}).get("status") != "healthy":
        raise HTTPException(status_code=503, detail="Service not ready: redis")
    
    return {"status": "ready"}

@router.get("/live")
async def liveness_check():
    """Kubernetes liveness probe"""
    return {"status": "alive", "timestamp": datetime.now(timezone.utc)}

@router.get("/dependencies")
async def dependencies_check():
    """Detailed dependencies health check"""
    return await check_all_dependencies()

@router.get("/metrics")
async def metrics_endpoint():
    """System and application metrics"""
    return {
        "system": get_system_metrics(),
        "application": get_application_metrics(),
        "timestamp": datetime.now(timezone.utc),
    }

async def check_all_dependencies() -> Dict[str, Any]:
    """Check health of all service dependencies"""
    dependencies = {}
    
    # Redis health
    try:
        redis_client = redis.Redis.from_url(config.REDIS_URL)
        start_time = time.time()
        redis_client.ping()
        response_time = (time.time() - start_time) * 1000
        
        # Get Redis info
        redis_info = redis_client.info()
        
        dependencies["redis"] = {
            "status": "healthy",
            "response_time_ms": response_time,
            "version": redis_info.get("redis_version", "unknown"),
            "memory_used": redis_info.get("used_memory_human", "unknown"),
            "connected_clients": redis_info.get("connected_clients", 0),
        }
    except Exception as e:
        dependencies["redis"] = {
            "status": "unhealthy",
            "error": str(e),
            "response_time_ms": None
        }
    
    # NLTK data availability
    try:
        nltk_data_status = {}
        required_data = ['punkt', 'stopwords', 'wordnet', 'omw-1.4']
        
        for data_name in required_data:
            try:
                nltk.data.find(f'tokenizers/{data_name}')
                nltk_data_status[data_name] = "available"
            except LookupError:
                nltk_data_status[data_name] = "missing"
        
        dependencies["nltk_data"] = {
            "status": "healthy" if all(status == "available" for status in nltk_data_status.values()) else "degraded",
            "data_status": nltk_data_status,
        }
    except Exception as e:
        dependencies["nltk_data"] = {
            "status": "unavailable",
            "error": str(e),
        }
    
    # Model availability (if using sentence transformers)
    try:
        # Check if models directory exists and has content
        model_dir = "/app/cache/models"
        if os.path.exists(model_dir):
            model_files = os.listdir(model_dir)
            dependencies["models"] = {
                "status": "healthy" if model_files else "degraded",
                "model_count": len(model_files),
                "model_dir": model_dir,
            }
        else:
            dependencies["models"] = {
                "status": "degraded",
                "error": "Model directory not found",
                "model_dir": model_dir,
            }
    except Exception as e:
        dependencies["models"] = {
            "status": "unavailable",
            "error": str(e),
        }
    
    return dependencies

def get_system_metrics() -> Dict[str, Any]:
    """Get system resource metrics"""
    try:
        # CPU usage
        cpu_percent = psutil.cpu_percent(interval=1)
        
        # Memory usage
        memory = psutil.virtual_memory()
        memory_percent = memory.percent
        memory_used_mb = memory.used / (1024 * 1024)
        memory_total_mb = memory.total / (1024 * 1024)
        
        # Disk usage
        disk = psutil.disk_usage('/')
        disk_percent = (disk.used / disk.total) * 100
        
        # Load average (Unix only)
        load_average = None
        if hasattr(os, 'getloadavg'):
            try:
                load_average = os.getloadavg()
            except OSError:
                pass
        
        return {
            "cpu_percent": cpu_percent,
            "memory_percent": memory_percent,
            "memory_used_mb": round(memory_used_mb, 2),
            "memory_total_mb": round(memory_total_mb, 2),
            "disk_percent": round(disk_percent, 2),
            "load_average": load_average,
        }
    except Exception as e:
        return {
            "error": str(e),
            "cpu_percent": 0,
            "memory_percent": 0,
            "memory_used_mb": 0,
            "memory_total_mb": 0,
            "disk_percent": 0,
        }

def get_application_metrics() -> Dict[str, Any]:
    """Get application-specific metrics"""
    try:
        # Process info
        process = psutil.Process()
        
        return {
            "process_id": process.pid,
            "process_cpu_percent": process.cpu_percent(),
            "process_memory_mb": process.memory_info().rss / (1024 * 1024),
            "process_threads": process.num_threads(),
            "uptime_seconds": time.time() - STARTUP_TIME,
            "config": {
                "max_text_length": config.MAX_TEXT_LENGTH,
                "similarity_threshold": config.SIMILARITY_THRESHOLD,
                "fuzzy_threshold": config.FUZZY_MATCH_THRESHOLD,
                "cache_enabled": config.ENABLE_REDIS_CACHE,
            }
        }
    except Exception as e:
        return {
            "error": str(e),
            "uptime_seconds": time.time() - STARTUP_TIME,
        }

# Test NLP functionality
@router.get("/test")
async def test_nlp_functionality():
    """Test NLP service functionality"""
    try:
        # Test text preprocessing
        test_text = "This is a test text for NLP processing."
        
        # Basic preprocessing test
        processed_text = test_text.lower().strip()
        
        # Tokenization test (if NLTK is available)
        try:
            from nltk.tokenize import word_tokenize
            tokens = word_tokenize(processed_text)
            tokenization_working = True
        except:
            tokenization_working = False
            tokens = processed_text.split()
        
        return {
            "status": "healthy",
            "tests": {
                "text_preprocessing": True,
                "tokenization": tokenization_working,
                "token_count": len(tokens),
                "sample_tokens": tokens[:5],  # First 5 tokens
            },
            "test_text": test_text,
            "processed_text": processed_text,
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e),
            "tests": {
                "text_preprocessing": False,
                "tokenization": False,
            }
        }
