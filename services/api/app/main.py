"""
Optimized Lost & Found API main application
==========================================
Performance-optimized version with caching, compression, and connection pooling.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
from prometheus_client import make_asgi_app, Counter, Histogram, Gauge
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import os
import time
import json
import logging
import asyncio
from typing import Dict, Any

# Domain-driven imports
from .domain_router import domain_router, get_domain_tags
from .config import optimized_config
from .clients import get_nlp_client, get_vision_client
from .error_handlers import register_exception_handlers
from .infrastructure.database.session import (
    check_database_health, 
    get_async_db,
    init_database,
    db_metrics
)
from .cache import get_redis_client
from .storage import get_minio_client
from .infrastructure.monitoring.metrics import get_metrics_collector

# Setup logging
logging.basicConfig(level=getattr(logging, optimized_config.LOG_LEVEL))
logger = logging.getLogger(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

MATCH_LATENCY = Histogram(
    'matching_duration_seconds',
    'Matching pipeline duration'
)

CACHE_HITS = Counter(
    'cache_hits_total',
    'Total cache hits',
    ['cache_type']
)

CACHE_MISSES = Counter(
    'cache_misses_total',
    'Total cache misses',
    ['cache_type']
)

SERVICE_CALLS = Counter(
    'service_calls_total',
    'Total service calls',
    ['service', 'endpoint', 'status']
)

# Performance metrics
ACTIVE_CONNECTIONS = Gauge(
    'database_active_connections',
    'Number of active database connections'
)

RESPONSE_CACHE_HITS = Counter(
    'response_cache_hits_total',
    'Total response cache hits'
)

RESPONSE_CACHE_MISSES = Counter(
    'response_cache_misses_total',
    'Total response cache misses'
)

# Response cache
response_cache: Dict[str, Dict[str, Any]] = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Optimized application lifespan manager."""
    # Startup
    logger.info("🚀 Starting Optimized Lost & Found API Service...")
    
    # Validate configuration
    try:
        optimized_config.validate()
        logger.info("✅ Optimized configuration validated successfully")
    except Exception as e:
        logger.error(f"❌ Configuration validation failed: {e}")
        raise
    
    # Log configuration summary
    logger.info("Optimized API Service Configuration:")
    logger.info(json.dumps(optimized_config.summary(), indent=2))
    
    # Initialize database with optimizations
    try:
        await init_database()
        logger.info("✅ Database initialized with performance optimizations")
    except Exception as e:
        logger.error(f"❌ Database initialization failed: {e}")
        raise
    
    # Test database connection with optimized health check
    try:
        db_health = await check_database_health()
        if db_health["status"] == "healthy":
            logger.info(f"✅ Database connected: {db_health['version']}")
            logger.info(f"📊 Found {db_health['table_count']} tables in database")
            logger.info(f"📊 Database size: {db_health.get('database_size', 'unknown')}")
            logger.info(f"⚡ Health check response time: {db_health.get('response_time_ms', 0):.2f}ms")
        else:
            logger.error(f"❌ Database unhealthy: {db_health.get('error', 'Unknown error')}")
    except Exception as e:
        logger.error(f"❌ Database connection failed: {e}")
    
    # Test Redis connection
    try:
        redis_client = get_redis_client()
        redis_health = await redis_client.health_check()
        if redis_health["status"] == "healthy":
            logger.info(f"✅ Redis connected: {redis_health['version']}")
            logger.info(f"📊 Memory used: {redis_health['memory_used']}")
        else:
            logger.warning(f"⚠️ Redis unhealthy: {redis_health.get('error', 'Unknown error')}")
    except Exception as e:
        logger.warning(f"⚠️ Redis connection failed: {e}")
    
    # Test MinIO connection
    try:
        minio_client = get_minio_client()
        if minio_client:
            minio_health = minio_client.health_check()
            if minio_health["status"] == "healthy":
                logger.info(f"✅ MinIO connected: {minio_health['endpoint']}")
                logger.info(f"📊 Buckets: {minio_health['bucket_count']}")
            else:
                logger.warning(f"⚠️ MinIO unhealthy: {minio_health.get('error', 'Unknown error')}")
        else:
            logger.warning("⚠️ MinIO client not available")
    except Exception as e:
        logger.warning(f"⚠️ MinIO connection failed: {e}")
    
    # Test external services with optimized timeouts
    services = {}
    try:
        import httpx
        async with httpx.AsyncClient(timeout=optimized_config.HTTP_TIMEOUT) as client:
            response = await client.get(f"{optimized_config.NLP_SERVICE_URL}/health")
            services["nlp"] = "healthy" if response.status_code == 200 else "unhealthy"
            logger.info(f"✅ NLP service: {services['nlp']}")
    except Exception as e:
        services["nlp"] = "unavailable"
        logger.warning(f"⚠️ NLP service connection failed: {e}")
    
    try:
        import httpx
        async with httpx.AsyncClient(timeout=optimized_config.HTTP_TIMEOUT) as client:
            response = await client.get(f"{optimized_config.VISION_SERVICE_URL}/health")
            services["vision"] = "healthy" if response.status_code == 200 else "unhealthy"
            logger.info(f"✅ Vision service: {services['vision']}")
    except Exception as e:
        services["vision"] = "unavailable"
        logger.warning(f"⚠️ Vision service connection failed: {e}")
    
    logger.info("✅ Optimized API Service startup complete")
    
    yield
    
    # Shutdown
    logger.info("🛑 Shutting down Optimized Lost & Found API Service...")
    
    # Log final metrics
    db_stats = db_metrics.get_stats()
    logger.info(f"📊 Final database metrics: {db_stats}")


app = FastAPI(
    title="Lost & Found API (Optimized)",
    version="2.1.0",
    description="Optimized API for Lost & Found matching system with performance enhancements",
    lifespan=lifespan,
    tags_metadata=[
        {
            "name": "reports",
            "description": "Lost and found item reports management",
        },
        {
            "name": "matches", 
            "description": "Potential matches between lost and found items",
        },
        {
            "name": "users",
            "description": "User management and authentication",
        },
        {
            "name": "media",
            "description": "File uploads and media processing",
        },
        {
            "name": "taxonomy",
            "description": "Categories and classification system",
        },
        {
            "name": "auth",
            "description": "Authentication and authorization",
        },
        {
            "name": "health",
            "description": "System health and monitoring",
        },
        {
            "name": "mobile",
            "description": "Mobile-optimized endpoints",
        },
        {
            "name": "admin",
            "description": "Administrative operations",
        },
        {
            "name": "performance",
            "description": "Performance monitoring and metrics",
        },
    ]
)

# Register exception handlers
register_exception_handlers(app)

# Rate limiter with optimized configuration
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[],
    storage_uri=optimized_config.REDIS_URL if optimized_config.ENABLE_RATE_LIMIT and optimized_config.RATE_LIMIT_STORAGE == "redis" else "memory://"
)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=optimized_config.CORS_ORIGINS,
    allow_credentials=optimized_config.CORS_ALLOW_CREDENTIALS,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Compression middleware for better performance
if optimized_config.ENABLE_COMPRESSION:
    app.add_middleware(GZipMiddleware, minimum_size=1000)

# Optimized metrics middleware
@app.middleware("http")
async def optimized_metrics_middleware(request: Request, call_next):
    """Optimized request metrics tracking."""
    start_time = time.time()
    
    # Check response cache
    cache_key = f"{request.method}:{request.url.path}:{request.query_params}"
    cached_response = None
    
    if optimized_config.ENABLE_RESPONSE_CACHE and request.method == "GET":
        cached_response = response_cache.get(cache_key)
        if cached_response and (time.time() - cached_response['timestamp']) < optimized_config.RESPONSE_CACHE_TTL:
            RESPONSE_CACHE_HITS.inc()
            return JSONResponse(
                content=cached_response['data'],
                headers=cached_response['headers']
            )
        else:
            RESPONSE_CACHE_MISSES.inc()
    
    # Process request
    response = await call_next(request)
    duration = time.time() - start_time
    
    # Record metrics
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    REQUEST_LATENCY.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)
    
    # Cache successful GET responses
    if (optimized_config.ENABLE_RESPONSE_CACHE and 
        request.method == "GET" and 
        response.status_code == 200 and
        cached_response is None):
        
        try:
            response_body = b""
            async for chunk in response.body_iterator:
                response_body += chunk
            
            response_cache[cache_key] = {
                'data': json.loads(response_body.decode()),
                'headers': dict(response.headers),
                'timestamp': time.time()
            }
            
            # Clean old cache entries
            if len(response_cache) > 1000:
                oldest_key = min(response_cache.keys(), key=lambda k: response_cache[k]['timestamp'])
                del response_cache[oldest_key]
                
        except Exception as e:
            logger.warning(f"Failed to cache response: {e}")
    
    return response

# Mount Prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

# Include domain routers
app.include_router(domain_router)

# Performance monitoring endpoints
@app.get("/performance/metrics")
async def get_performance_metrics():
    """Get detailed performance metrics."""
    db_stats = db_metrics.get_stats()
    
    return {
        "database": db_stats,
        "cache": {
            "response_cache_size": len(response_cache),
            "cache_hit_rate": "calculated_from_prometheus_metrics"
        },
        "configuration": {
            "workers": optimized_config.WORKERS,
            "db_pool_size": optimized_config.DB_POOL_SIZE,
            "redis_max_connections": optimized_config.REDIS_MAX_CONNECTIONS,
            "compression_enabled": optimized_config.ENABLE_COMPRESSION,
            "response_cache_enabled": optimized_config.ENABLE_RESPONSE_CACHE,
        }
    }

@app.get("/performance/cache/clear")
async def clear_response_cache():
    """Clear response cache."""
    global response_cache
    cache_size = len(response_cache)
    response_cache.clear()
    
    return {
        "message": "Response cache cleared",
        "cleared_entries": cache_size
    }

# Optimized health check endpoint
@app.get("/health")
async def health_root():
    """Optimized health check endpoint with caching."""
    health_status = {
        "status": "ok",
        "service": "api-optimized",
        "version": "2.1.0",
        "environment": optimized_config.ENVIRONMENT,
        "features": {
            "metrics": optimized_config.ENABLE_METRICS,
            "rate_limit": optimized_config.ENABLE_RATE_LIMIT,
            "redis_cache": optimized_config.ENABLE_REDIS_CACHE,
            "minio_storage": True,
            "compression": optimized_config.ENABLE_COMPRESSION,
            "response_cache": optimized_config.ENABLE_RESPONSE_CACHE,
        }
    }
    
    # Use cached database health check
    db_health = await check_database_health()
    health_status["database"] = db_health
    if db_health["status"] != "healthy":
        health_status["status"] = "degraded"
    
    # Check Redis health
    try:
        redis_client = get_redis_client()
        redis_health = await redis_client.health_check()
        health_status["redis"] = redis_health
        if redis_health["status"] != "healthy":
            health_status["status"] = "degraded"
    except Exception as e:
        health_status["redis"] = {"status": "unhealthy", "error": str(e)}
        health_status["status"] = "degraded"
    
    # Check MinIO health
    try:
        minio_client = get_minio_client()
        if minio_client:
            minio_health = minio_client.health_check()
            health_status["minio"] = minio_health
            if minio_health["status"] != "healthy":
                health_status["status"] = "degraded"
        else:
            health_status["minio"] = {"status": "unhealthy", "error": "MinIO client not available"}
            health_status["status"] = "degraded"
    except Exception as e:
        health_status["minio"] = {"status": "unhealthy", "error": str(e)}
        health_status["status"] = "degraded"
    
    # Check external services with optimized timeouts
    services = {}
    try:
        import httpx
        async with httpx.AsyncClient(timeout=optimized_config.HTTP_TIMEOUT) as client:
            response = await client.get(f"{optimized_config.NLP_SERVICE_URL}/health")
            services["nlp"] = "healthy" if response.status_code == 200 else "unhealthy"
    except Exception:
        services["nlp"] = "unavailable"
    
    try:
        import httpx
        async with httpx.AsyncClient(timeout=optimized_config.HTTP_TIMEOUT) as client:
            response = await client.get(f"{optimized_config.VISION_SERVICE_URL}/health")
            services["vision"] = "healthy" if response.status_code == 200 else "unhealthy"
    except Exception:
        services["vision"] = "unavailable"
    
    health_status["external_services"] = services
    
    return health_status

@app.get("/v1/health")
async def health_v1():
    """Health check endpoint (v1 API version)."""
    return await health_root()

@app.get("/")
def root():
    """Root endpoint."""
    return {
        "message": "Lost & Found API (Optimized)",
        "version": "2.1.0",
        "docs": "/docs",
        "health": "/health",
        "metrics": "/metrics",
        "performance": "/performance/metrics"
    }

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler for unhandled errors."""
    return JSONResponse(
        status_code=500,
        content={
            "code": "internal_error",
            "message": "An internal error occurred",
            "details": str(exc) if optimized_config.DEBUG else None
        }
    )
