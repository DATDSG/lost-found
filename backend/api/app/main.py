from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api import auth, items, media, matches, chat, admin, notifications, claims

try:
    from backend.common.health import readiness
except ImportError:  # pragma: no cover
    readiness = None

app = FastAPI(
    title=settings.APP_NAME,
    description="Tri-lingual Lost & Found System with baseline geo-time matching and optional NLP/CV enhancements",
    version="2.0.0"
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.CORS_ORIGINS.split(",") if o] if settings.CORS_ORIGINS else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/healthz")
def healthz():
    """Liveness check endpoint."""
    return {"status": "ok"}


def _db_ready():
    """Check if database connection is healthy."""
    try:
        from app.db.session import SessionLocal
        db = SessionLocal()
        db.execute("SELECT 1")
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
    """Readiness check endpoint."""
    db_ok = _db_ready()
    return {
        "ready": db_ok,
        "database": db_ok,
        "app": settings.APP_NAME,
        "version": "2.0.0",
        "features": {
            "nlp_enabled": settings.NLP_ON,
            "cv_enabled": settings.CV_ON,
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