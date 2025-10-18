from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from prometheus_client import make_asgi_app, Counter, Histogram
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import os
import time
import json
import logging
import structlog
from pathlib import Path
from tenacity import retry, stop_after_attempt, wait_exponential
from contextlib import asynccontextmanager

from .routers import auth, reports, media, matches, notifications, taxonomy, messages, health, websocket, items
from .routers.admin import router as admin_router
from .config import config
from .clients import get_nlp_client, get_vision_client
from .session_manager import session_manager
from .minio_client import get_minio_client

# Setup structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger(__name__)

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
    """Application lifespan manager for startup/shutdown."""
    # Startup
    logger.info("Starting Lost & Found API", version="2.1.0")
    
    # Validate configuration
    try:
        config.validate()
        logger.info("Configuration validated successfully")
    except Exception as e:
        logger.error("Configuration validation failed", error=str(e))
        raise
    
    # Test service connections
    try:
        nlp_client = get_nlp_client()
        vision_client = get_vision_client()
        logger.info("Service connections established")
    except Exception as e:
        logger.warning("Service connection test failed", error=str(e))
    
    # Initialize MinIO client
    try:
        minio_client = get_minio_client()
        logger.info("MinIO client initialized", 
                   endpoint=config.MINIO_ENDPOINT, 
                   bucket=config.MINIO_BUCKET_NAME)
    except Exception as e:
        logger.error("Failed to initialize MinIO client", error=str(e))
        raise
    
    # Initialize Redis session manager
    try:
        await session_manager.initialize()
        logger.info("Redis session manager initialized")
    except Exception as e:
        logger.error("Failed to initialize Redis session manager", error=str(e))
        # Continue without Redis sessions (fallback to in-memory)
    
    yield
    
    # Shutdown
    logger.info("Shutting down Lost & Found API")
    
    # Close Redis session manager
    try:
        await session_manager.close()
        logger.info("Redis session manager closed")
    except Exception as e:
        logger.error("Error closing Redis session manager", error=str(e))

app = FastAPI(
    title="Lost & Found API",
    version="2.1.0",
    description="API for Lost & Found matching system with multi-signal scoring",
    lifespan=lifespan
)

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
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept", "Origin", "X-Requested-With"],
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


# Startup/shutdown handled by lifespan manager above


# Mount static files for admin panel if available
static_dir = Path(__file__).resolve().parent / "static"
if static_dir.exists():
    app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")
else:
    logger.warning("Static directory missing; skipping mount", static_dir=str(static_dir))

# Setup Jinja2 templates for admin panel if available
templates_dir = Path(__file__).resolve().parent / "templates"
if templates_dir.exists():
    templates = Jinja2Templates(directory=str(templates_dir))
else:
    templates = None  # type: ignore[assignment]
    logger.warning("Templates directory missing; skipping setup", templates_dir=str(templates_dir))

# Include health check router (no authentication required)
app.include_router(health.router, tags=["health"])

# Include WebSocket router for real-time features
app.include_router(websocket.router, tags=["websocket"])

# Include routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(reports.router, prefix="/api/v1/reports", tags=["reports"])
app.include_router(items.router, prefix="/api/v1/items", tags=["items"])
app.include_router(media.router, prefix="/api/v1/media", tags=["media"])
app.include_router(matches.router, prefix="/api/v1/matches", tags=["matches"])
app.include_router(notifications.router, prefix="/api/v1/notifications", tags=["notifications"])
app.include_router(messages.router, prefix="/api/v1/messages", tags=["messages"])
app.include_router(taxonomy.router, prefix="/api/v1/taxonomy", tags=["taxonomy"])

# Include admin router (requires admin/moderator authentication)
app.include_router(admin_router, prefix="/api/v1/admin", tags=["admin"])


@app.get("/health")
async def health_root():
    """Enhanced health check endpoint."""
    try:
        # Test service connections
        nlp_client = get_nlp_client()
        vision_client = get_vision_client()
        
        return {
            "status": "ok",
            "service": "api",
            "version": "2.1.0",
            "environment": config.ENVIRONMENT,
            "services": {
                "nlp": "connected",
                "vision": "connected"
            },
            "timestamp": time.time()
        }
    except Exception as e:
        logger.warning("Health check failed", error=str(e))
        return JSONResponse(
            status_code=503,
            content={
                "status": "degraded",
                "service": "api",
                "version": "2.1.0",
                "error": str(e),
                "timestamp": time.time()
            }
        )


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
