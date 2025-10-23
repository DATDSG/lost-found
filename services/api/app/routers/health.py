"""Comprehensive health check endpoints."""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, select
from typing import Dict, Any
import asyncio
import time
import logging

from ..infrastructure.database.session import get_async_db, async_engine
from ..config import config
from ..clients import get_nlp_client, get_vision_client

router = APIRouter()
logger = logging.getLogger(__name__)


async def check_database_health(db: AsyncSession) -> Dict[str, Any]:
    """Check database connectivity and basic query."""
    try:
        start_time = time.time()
        
        # Execute a simple query
        result = await db.execute(text("SELECT 1"))
        result.scalar()
        
        duration = time.time() - start_time
        
        # Check if pgvector extension is available
        vector_result = await db.execute(
            text("SELECT COUNT(*) FROM pg_extension WHERE extname = 'vector'")
        )
        has_pgvector = vector_result.scalar() > 0
        
        return {
            "status": "healthy",
            "response_time_ms": round(duration * 1000, 2),
            "pgvector_available": has_pgvector,
            "driver": "asyncpg"
        }
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return {
            "status": "unhealthy",
            "error": str(e)
        }


async def check_redis_health() -> Dict[str, Any]:
    """Check Redis connectivity."""
    try:
        import redis.asyncio as redis
        
        start_time = time.time()
        client = await redis.from_url(config.REDIS_URL, decode_responses=True)
        
        # Ping Redis
        await client.ping()
        duration = time.time() - start_time
        
        # Get info
        info = await client.info()
        
        await client.close()
        
        return {
            "status": "healthy",
            "response_time_ms": round(duration * 1000, 2),
            "version": info.get("redis_version", "unknown"),
            "connected_clients": info.get("connected_clients", 0)
        }
    except Exception as e:
        logger.error(f"Redis health check failed: {e}")
        return {
            "status": "unhealthy",
            "error": str(e)
        }


async def check_nlp_service_health() -> Dict[str, Any]:
    """Check NLP service connectivity."""
    try:
        start_time = time.time()
        
        async with get_nlp_client() as nlp_client:
            healthy = await nlp_client.health_check()
        
        duration = time.time() - start_time
        
        return {
            "status": "healthy" if healthy else "unhealthy",
            "response_time_ms": round(duration * 1000, 2),
            "url": config.NLP_SERVICE_URL
        }
    except Exception as e:
        logger.error(f"NLP service health check failed: {e}")
        return {
            "status": "unhealthy",
            "error": str(e),
            "url": config.NLP_SERVICE_URL
        }


async def check_vision_service_health() -> Dict[str, Any]:
    """Check Vision service connectivity."""
    try:
        start_time = time.time()
        
        async with get_vision_client() as vision_client:
            healthy = await vision_client.health_check()
        
        duration = time.time() - start_time
        
        return {
            "status": "healthy" if healthy else "unhealthy",
            "response_time_ms": round(duration * 1000, 2),
            "url": config.VISION_SERVICE_URL
        }
    except Exception as e:
        logger.error(f"Vision service health check failed: {e}")
        return {
            "status": "unhealthy",
            "error": str(e),
            "url": config.VISION_SERVICE_URL
        }


@router.get("/health/detailed")
async def detailed_health_check(db: AsyncSession = Depends(get_async_db)):
    """
    Comprehensive health check for all system components.
    
    Returns detailed status of:
    - API service
    - Database (PostgreSQL + pgvector)
    - Redis cache
    - NLP service
    - Vision service
    """
    start_time = time.time()
    
    # Run all checks in parallel
    results = await asyncio.gather(
        check_database_health(db),
        check_redis_health(),
        check_nlp_service_health(),
        check_vision_service_health(),
        return_exceptions=True
    )
    
    database_health, redis_health, nlp_health, vision_health = results
    
    # Handle exceptions
    for i, result in enumerate(results):
        if isinstance(result, Exception):
            component_name = ["database", "redis", "nlp", "vision"][i]
            logger.error(f"{component_name} health check exception: {result}")
            results[i] = {"status": "error", "error": str(result)}
    
    # Determine overall health
    all_healthy = all(
        isinstance(r, dict) and r.get("status") == "healthy"
        for r in results
    )
    
    overall_duration = time.time() - start_time
    
    return {
        "status": "healthy" if all_healthy else "degraded",
        "timestamp": time.time(),
        "total_check_time_ms": round(overall_duration * 1000, 2),
        "components": {
            "api": {
                "status": "healthy",
                "version": "2.0.0",
                "environment": config.ENVIRONMENT
            },
            "database": database_health,
            "redis": redis_health,
            "nlp_service": nlp_health,
            "vision_service": vision_health
        },
        "configuration": {
            "async_database": True,
            "cache_enabled": config.ENABLE_REDIS_CACHE,
            "metrics_enabled": config.ENABLE_METRICS,
            "rate_limiting_enabled": config.ENABLE_RATE_LIMIT
        }
    }


@router.get("/health/ready")
async def readiness_check(db: AsyncSession = Depends(get_async_db)):
    """
    Kubernetes-style readiness probe.
    Returns 200 if service is ready to accept requests.
    """
    try:
        # Check database connectivity
        await db.execute(text("SELECT 1"))
        
        return {
            "ready": True,
            "timestamp": time.time()
        }
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        return {
            "ready": False,
            "error": str(e),
            "timestamp": time.time()
        }


@router.get("/health/live")
async def liveness_check():
    """
    Kubernetes-style liveness probe.
    Returns 200 if service is alive (not deadlocked).
    """
    return {
        "alive": True,
        "timestamp": time.time(),
        "service": "api",
        "version": "2.0.0"
    }


@router.get("/health/startup")
async def startup_check(db: AsyncSession = Depends(get_async_db)):
    """
    Kubernetes-style startup probe.
    Returns 200 when service has fully started.
    """
    try:
        # Check critical dependencies
        await db.execute(text("SELECT 1"))
        
        # Verify configuration
        config.validate()
        
        return {
            "started": True,
            "timestamp": time.time(),
            "environment": config.ENVIRONMENT
        }
    except Exception as e:
        logger.error(f"Startup check failed: {e}")
        return {
            "started": False,
            "error": str(e),
            "timestamp": time.time()
        }

