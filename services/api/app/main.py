"""Lost & Found API main application with Domain-Driven Design architecture."""
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from prometheus_client import make_asgi_app, Counter, Histogram
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import os
import time
import json
import logging

# Domain-driven imports
from .domain_router import domain_router, get_domain_tags
from .config import config
from .clients import get_nlp_client, get_vision_client
from .error_handlers import register_exception_handlers
from .infrastructure.database.session import check_database_health, get_async_db
from .cache import get_redis_client
from .storage import get_minio_client
from .infrastructure.monitoring.metrics import get_metrics_collector

# Setup logging
logging.basicConfig(level=logging.INFO)
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

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    # Startup
    logger.info("🚀 Starting Lost & Found API Service...")
    
    # Validate configuration
    try:
        config.validate()
        logger.info("✅ Configuration validated successfully")
    except Exception as e:
        logger.error(f"❌ Configuration validation failed: {e}")
        raise
    
    # Log configuration summary
    logger.info("API Service Configuration:")
    logger.info(json.dumps(config.summary(), indent=2))
    
    # Test database connection
    try:
        db_health = await check_database_health()
        if db_health["status"] == "healthy":
            logger.info(f"✅ Database connected: {db_health['version']}")
            logger.info(f"📊 Found {db_health['table_count']} tables in database")
        else:
            logger.error(f"❌ Database unhealthy: {db_health.get('error', 'Unknown error')}")
    except Exception as e:
        logger.error(f"❌ Database connection failed: {e}")
        logger.error("   Make sure PostgreSQL is running and DATABASE_URL is correct")
        logger.error(f"   DATABASE_URL: {config.DATABASE_URL.split('@')[1] if '@' in config.DATABASE_URL else 'not set'}")
    
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
    
    # Test NLP service connection
    try:
        logger.info("Testing NLP service connection...")
        nlp_client = get_nlp_client()
        logger.info(f"NLP client created: {type(nlp_client)}")
        
        # Test direct health check without context manager
        logger.info("Testing NLP health check directly...")
        # Create a simple HTTP client for testing
        import httpx
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{config.NLP_SERVICE_URL}/health")
            if response.status_code == 200:
                logger.info("✅ NLP service is healthy (direct test)")
            else:
                logger.warning("⚠️ NLP service is unavailable (direct test)")
    except Exception as e:
        logger.warning(f"⚠️ NLP service connection failed: {e}")
        logger.warning(f"Error type: {type(e)}")
        import traceback
        logger.warning(f"Traceback: {traceback.format_exc()}")
    
    # Test Vision service connection
    try:
        logger.info("Testing Vision service connection...")
        vision_client = get_vision_client()
        logger.info(f"Vision client created: {type(vision_client)}")
        
        # Test direct health check without context manager
        logger.info("Testing Vision health check directly...")
        # Create a simple HTTP client for testing
        import httpx
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{config.VISION_SERVICE_URL}/health")
            if response.status_code == 200:
                logger.info("✅ Vision service is healthy (direct test)")
            else:
                logger.warning("⚠️ Vision service is unavailable (direct test)")
    except Exception as e:
        logger.warning(f"⚠️ Vision service connection failed: {e}")
        logger.warning(f"Error type: {type(e)}")
        import traceback
        logger.warning(f"Traceback: {traceback.format_exc()}")
    
    logger.info("✅ API Service startup complete")
    
    yield
    
    # Shutdown
    logger.info("🛑 Shutting down Lost & Found API Service...")

app = FastAPI(
    title="Lost & Found API",
    version="2.0.0",
    description="API for Lost & Found matching system with Domain-Driven Design architecture",
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
    ]
)

# Register exception handlers
register_exception_handlers(app)

# Rate limiter
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[],
    storage_uri=config.REDIS_URL if config.ENABLE_RATE_LIMIT and config.RATE_LIMIT_STORAGE == "redis" else "memory://"
)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS,
    allow_credentials=config.CORS_ALLOW_CREDENTIALS,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus metrics middleware
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    """Track request metrics."""
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    REQUEST_LATENCY.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)
    
    return response


# Mount Prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


# Include domain routers (Domain-Driven Design architecture)
app.include_router(domain_router)


@app.get("/health")
async def health_root():
    """Health check endpoint with comprehensive service status."""
    health_status = {
        "status": "ok",
        "service": "api",
        "version": "2.0.0",
        "environment": config.ENVIRONMENT,
            "features": {
                "metrics": config.ENABLE_METRICS,
                "rate_limit": config.ENABLE_RATE_LIMIT,
                "redis_cache": config.ENABLE_REDIS_CACHE,
                "minio_storage": True,
            }
    }
    
    # Check database health
    try:
        db_health = await check_database_health()
        health_status["database"] = db_health
        if db_health["status"] != "healthy":
            health_status["status"] = "degraded"
    except Exception as e:
        health_status["database"] = {"status": "unhealthy", "error": str(e)}
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
    
    # Check external services health
    services = {}
    try:
        # Test NLP service directly
        import httpx
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{config.NLP_SERVICE_URL}/health")
            services["nlp"] = "healthy" if response.status_code == 200 else "unhealthy"
    except Exception:
        services["nlp"] = "unavailable"
    
    try:
        # Test Vision service directly
        import httpx
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{config.VISION_SERVICE_URL}/health")
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
        "message": "Lost & Found API",
        "docs": "/docs",
        "health": "/health"
    }


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler for unhandled errors."""
    return JSONResponse(
        status_code=500,
        content={
            "code": "internal_error",
            "message": "An internal error occurred",
            "details": str(exc) if os.getenv("DEBUG") else None
        }
    )
