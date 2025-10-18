"""Lost & Found API main application."""
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

from .routers import auth, reports, media, matches, notifications, messages, taxonomy
from .routers.admin import router as admin_router
from .config import config
from .clients import get_nlp_client, get_vision_client
from .error_handlers import register_exception_handlers

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

app = FastAPI(
    title="Lost & Found API",
    version="2.0.0",
    description="API for Lost & Found matching system with multi-signal scoring"
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


@app.on_event("startup")
async def startup():
    """Startup event handler."""
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
        from .database import engine
        from sqlalchemy import text
        
        with engine.connect() as conn:
            result = conn.execute(text("SELECT version()"))
            version = result.fetchone()[0]
            logger.info(f"✅ Database connected: {version.split(',')[0]}")
            
            # Check if tables exist
            result = conn.execute(text("""
                SELECT COUNT(*) FROM information_schema.tables 
                WHERE table_schema = 'public'
            """))
            table_count = result.fetchone()[0]
            logger.info(f"📊 Found {table_count} tables in database")
            
            if table_count == 0:
                logger.warning("⚠️  No tables found! Run: python test_db_connection.py")
                
    except Exception as e:
        logger.error(f"❌ Database connection failed: {e}")
        logger.error("   Make sure PostgreSQL is running and DATABASE_URL is correct")
        logger.error(f"   DATABASE_URL: {config.DATABASE_URL.split('@')[1] if '@' in config.DATABASE_URL else 'not set'}")
    
    # Test NLP service connection
    try:
        async with await get_nlp_client() as nlp:
            if await nlp.health_check():
                logger.info("✅ NLP service is healthy")
            else:
                logger.warning("⚠️ NLP service is unavailable")
    except Exception as e:
        logger.warning(f"⚠️ NLP service connection failed: {e}")
    
    # Test Vision service connection
    try:
        async with await get_vision_client() as vision:
            if await vision.health_check():
                logger.info("✅ Vision service is healthy")
            else:
                logger.warning("⚠️ Vision service is unavailable")
    except Exception as e:
        logger.warning(f"⚠️ Vision service connection failed: {e}")


# Include routers
app.include_router(auth.router, prefix="/v1/auth", tags=["auth"])
app.include_router(reports.router, prefix="/v1/reports", tags=["reports"])
app.include_router(media.router, prefix="/v1/media", tags=["media"])
app.include_router(matches.router, prefix="/v1/matches", tags=["matches"])
app.include_router(notifications.router, prefix="/v1/notifications", tags=["notifications"])
app.include_router(messages.router, prefix="/v1/messages", tags=["messages"])
app.include_router(taxonomy.router, prefix="/v1/taxonomy", tags=["taxonomy"])

# Include admin router (requires admin/moderator authentication)
app.include_router(admin_router, prefix="/v1/admin", tags=["admin"])


@app.get("/health")
async def health_root():
    """Health check endpoint with service status."""
    from .database import engine
    from sqlalchemy import text
    
    health_status = {
        "status": "ok",
        "service": "api",
        "version": "2.0.0",
        "environment": config.ENVIRONMENT,
        "features": {
            "metrics": config.ENABLE_METRICS,
            "rate_limit": config.ENABLE_RATE_LIMIT,
            "redis_cache": config.ENABLE_REDIS_CACHE,
            "notifications": config.ENABLE_NOTIFICATIONS,
        }
    }
    
    # Check database health
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
            health_status["database"] = "healthy"
    except Exception as e:
        health_status["database"] = f"unhealthy: {str(e)}"
        health_status["status"] = "degraded"
    
    # Check service health
    services = {}
    try:
        async with await get_nlp_client() as nlp:
            services["nlp"] = "healthy" if await nlp.health_check() else "unhealthy"
    except Exception:
        services["nlp"] = "unavailable"
    
    try:
        async with await get_vision_client() as vision:
            services["vision"] = "healthy" if await vision.health_check() else "unhealthy"
    except Exception:
        services["vision"] = "unavailable"
    
    health_status["services"] = services
    
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
