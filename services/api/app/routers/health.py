"""
Enhanced Health Check System for Lost & Found Services
Provides comprehensive health monitoring and service status reporting
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Dict, Any, Optional
import asyncio
import time
import psutil
import os
from datetime import datetime, timezone

from ..config import config
from ..clients import get_nlp_client, get_vision_client
from ..cache import get_redis_client
from ..storage import get_minio_client
from ..infrastructure.database.session import check_database_health

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

class ServiceHealth(BaseModel):
    """Individual service health model"""
    status: str
    response_time_ms: Optional[float] = None
    error: Optional[str] = None
    details: Optional[Dict[str, Any]] = None

class SystemMetrics(BaseModel):
    """System metrics model"""
    cpu_percent: float
    memory_percent: float
    memory_used_mb: float
    memory_total_mb: float
    disk_percent: float
    disk_used_gb: float
    disk_total_gb: float
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
        service="api",
        version="2.0.0",
        timestamp=current_time,
        uptime_seconds=uptime,
        environment=config.ENVIRONMENT,
        features={
            "metrics": config.ENABLE_METRICS,
            "rate_limit": config.ENABLE_RATE_LIMIT,
            "redis_cache": config.ENABLE_REDIS_CACHE,
            "minio_storage": True,
            "nlp_service": True,
            "vision_service": True,
        },
        dependencies=dependencies,
        metrics=metrics,
    )

@router.get("/ready")
async def readiness_check():
    """Kubernetes readiness probe"""
    dependencies = await check_all_dependencies()
    
    # Check critical dependencies
    critical_deps = ["database", "redis"]
    for dep in critical_deps:
        if dependencies.get(dep, {}).get("status") != "healthy":
            raise HTTPException(status_code=503, detail=f"Service not ready: {dep}")
    
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
    
    # Database health
    try:
        db_health = await check_database_health()
        dependencies["database"] = db_health
    except Exception as e:
        dependencies["database"] = {
            "status": "unhealthy",
            "error": str(e),
            "response_time_ms": None
        }
    
    # Redis health
    try:
        redis_client = get_redis_client()
        start_time = time.time()
        redis_health = await redis_client.health_check()
        response_time = (time.time() - start_time) * 1000
        
        dependencies["redis"] = {
            **redis_health,
            "response_time_ms": response_time
        }
    except Exception as e:
        dependencies["redis"] = {
            "status": "unhealthy",
            "error": str(e),
            "response_time_ms": None
        }
    
    # MinIO health
    try:
        minio_client = get_minio_client()
        if minio_client:
            start_time = time.time()
            minio_health = minio_client.health_check()
            response_time = (time.time() - start_time) * 1000
            
            dependencies["minio"] = {
                **minio_health,
                "response_time_ms": response_time
            }
        else:
            dependencies["minio"] = {
                "status": "unavailable",
                "error": "MinIO client not available",
                "response_time_ms": None
            }
    except Exception as e:
        dependencies["minio"] = {
            "status": "unhealthy",
            "error": str(e),
            "response_time_ms": None
        }
    
    # NLP Service health
    try:
        start_time = time.time()
        nlp_client = get_nlp_client()
        # Test direct HTTP call
        import httpx
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{config.NLP_SERVICE_URL}/health", timeout=5.0)
            response_time = (time.time() - start_time) * 1000
            
            dependencies["nlp"] = {
                "status": "healthy" if response.status_code == 200 else "unhealthy",
                "response_time_ms": response_time,
                "version": response.json().get("version", "unknown") if response.status_code == 200 else None,
                "error": None if response.status_code == 200 else f"HTTP {response.status_code}"
            }
    except Exception as e:
        dependencies["nlp"] = {
            "status": "unavailable",
            "error": str(e),
            "response_time_ms": None
        }
    
    # Vision Service health
    try:
        start_time = time.time()
        vision_client = get_vision_client()
        # Test direct HTTP call
        import httpx
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{config.VISION_SERVICE_URL}/health", timeout=5.0)
            response_time = (time.time() - start_time) * 1000
            
            dependencies["vision"] = {
                "status": "healthy" if response.status_code == 200 else "unhealthy",
                "response_time_ms": response_time,
                "version": response.json().get("version", "unknown") if response.status_code == 200 else None,
                "error": None if response.status_code == 200 else f"HTTP {response.status_code}"
            }
    except Exception as e:
        dependencies["vision"] = {
            "status": "unavailable",
            "error": str(e),
            "response_time_ms": None
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
        disk_used_gb = disk.used / (1024 * 1024 * 1024)
        disk_total_gb = disk.total / (1024 * 1024 * 1024)
        
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
            "disk_used_gb": round(disk_used_gb, 2),
            "disk_total_gb": round(disk_total_gb, 2),
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
            "disk_used_gb": 0,
            "disk_total_gb": 0,
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
            "process_open_files": len(process.open_files()),
            "process_connections": len(process.connections()),
            "uptime_seconds": time.time() - STARTUP_TIME,
        }
    except Exception as e:
        return {
            "error": str(e),
            "uptime_seconds": time.time() - STARTUP_TIME,
        }

# Health check for external services
@router.get("/external/{service_name}")
async def external_service_health(service_name: str):
    """Check health of external services"""
    service_urls = {
        "nlp": config.NLP_SERVICE_URL,
        "vision": config.VISION_SERVICE_URL,
    }
    
    if service_name not in service_urls:
        raise HTTPException(status_code=404, detail=f"Service {service_name} not found")
    
    try:
        import httpx
        async with httpx.AsyncClient() as client:
            start_time = time.time()
            response = await client.get(f"{service_urls[service_name]}/health", timeout=10.0)
            response_time = (time.time() - start_time) * 1000
            
            return {
                "service": service_name,
                "status": "healthy" if response.status_code == 200 else "unhealthy",
                "response_time_ms": response_time,
                "status_code": response.status_code,
                "data": response.json() if response.status_code == 200 else None,
            }
    except Exception as e:
        return {
            "service": service_name,
            "status": "unavailable",
            "error": str(e),
            "response_time_ms": None,
        }