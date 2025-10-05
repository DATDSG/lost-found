from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api import auth, items, media, matches, chat, admin, notifications, claims
import logging

# Initialize Sentry for error tracking
from app.core.sentry import init_sentry
init_sentry()

# Setup logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

try:
    from backend.common.health import readiness
except ImportError:  # pragma: no cover
    readiness = None

app = FastAPI(
    title=settings.APP_NAME,
    description="Tri-lingual Lost & Found System with baseline geo-time matching and optional NLP/CV enhancements",
    version="2.0.0"
)

# Setup rate limiting
from app.core.rate_limit import setup_rate_limiting
limiter = setup_rate_limiting(app)

# Setup Prometheus metrics
from app.core.metrics import setup_prometheus
setup_prometheus(app)

# Parse CORS origins
cors_origins = [origin.strip() for origin in settings.CORS_ORIGINS.split(",") if origin.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logger.info(f"Starting {settings.APP_NAME} in {settings.ENV} environment")
logger.info(f"CORS origins: {cors_origins}")


@app.get("/healthz")
def healthz():
    """Liveness check endpoint."""
    return {"status": "ok"}


def _db_ready():
    """Check if database connection is healthy."""
    try:
        from sqlalchemy import text
        from app.db.session import SessionLocal
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        return True
    except Exception:
        return False


if readiness is not None:
    try:
        readiness.register("database", _db_ready)
    except Exception:  # pragma: no cover
        pass


@app.get("/readyz")
def readyz():
    """Readiness check endpoint including optional vector extension detection."""
    from sqlalchemy import text
    db_ok = _db_ready()
    vector_ok = False
    if db_ok and settings.SEMANTIC_SEARCH_ENABLED:
        try:
            from app.db.session import SessionLocal
            db = SessionLocal()
            res = db.execute(text("SELECT extname FROM pg_extension WHERE extname='vector'")).scalar()
            vector_ok = bool(res)
            db.close()
        except Exception:  # pragma: no cover
            vector_ok = False
    overall = db_ok and (vector_ok if settings.SEMANTIC_SEARCH_ENABLED else True)
    return {
        "ready": overall,
        "database": db_ok,
        "vector_extension": vector_ok if settings.SEMANTIC_SEARCH_ENABLED else None,
        "app": settings.APP_NAME,
        "version": "2.0.0",
        "features": {
            "nlp_enabled": settings.NLP_ON,
            "cv_enabled": settings.CV_ON,
            "semantic_search_enabled": settings.SEMANTIC_SEARCH_ENABLED,
            "languages": settings.SUPPORTED_LANGUAGES
        }
    }


@app.get("/health")
def health():
    """Legacy health check endpoint (deprecated, use /healthz or /readyz)."""
    return {
        "status": "ok",
        "app": settings.APP_NAME,
        "version": "2.0.0",
        "features": {
            "nlp_enabled": settings.NLP_ON,
            "cv_enabled": settings.CV_ON,
            "languages": settings.SUPPORTED_LANGUAGES
        }
    }


@app.get("/")
def root():
    """Root endpoint with API information."""
    return {
        "message": "Lost & Found API",
        "version": "2.0.0",
        "docs": "/docs",
        "health": "/health",
        "features": {
            "baseline_matching": True,
            "geospatial_search": True,
            "multilingual": True,
            "nlp_optional": settings.NLP_ON,
            "cv_optional": settings.CV_ON
        }
    }


# Mount static files for admin UI
app.mount("/admin/static", StaticFiles(directory="app/static"), name="static")


# API Routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(items.router, prefix="/items", tags=["Items"])
app.include_router(media.router, prefix="/media", tags=["Media"])
app.include_router(matches.router, prefix="/matches", tags=["Matching"])
app.include_router(claims.router, prefix="/claims", tags=["Claims"])
app.include_router(chat.router, prefix="/chat", tags=["Chat"])
app.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
app.include_router(admin.router, prefix="/admin", tags=["Administration"])