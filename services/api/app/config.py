"""
Configuration for Lost & Found API Service
------------------------------------------
Centralized configuration management for:
- Database connections
- JWT authentication
- Service integrations (NLP, Vision)
- Media storage
- Rate limiting
- Monitoring & metrics
- CORS & security
"""
import os
from typing import Optional, List
from pathlib import Path


class Config:
    """Production configuration for API service."""
    
    # ========== Server Configuration ==========
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    WORKERS: int = int(os.getenv("WORKERS", "1"))
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")  # development, staging, production
    
    # ========== Database Configuration ==========
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql+asyncpg://postgres:postgres@db:5432/lostfound"
    )
    DB_POOL_SIZE: int = int(os.getenv("DB_POOL_SIZE", "10"))
    DB_MAX_OVERFLOW: int = int(os.getenv("DB_MAX_OVERFLOW", "20"))
    DB_POOL_TIMEOUT: int = int(os.getenv("DB_POOL_TIMEOUT", "30"))
    DB_ECHO: bool = os.getenv("DB_ECHO", "false").lower() == "true"
    
    # ========== JWT Authentication ==========
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = int(os.getenv("JWT_REFRESH_TOKEN_EXPIRE_DAYS", "7"))
    
    # ========== Service Integration ==========
    # NLP Service
    NLP_SERVICE_URL: str = os.getenv("NLP_SERVICE_URL", "http://nlp:8001")
    NLP_SERVICE_TIMEOUT: int = int(os.getenv("NLP_SERVICE_TIMEOUT", "30"))
    NLP_BATCH_SIZE: int = int(os.getenv("NLP_BATCH_SIZE", "32"))
    ENABLE_NLP_CACHE: bool = os.getenv("ENABLE_NLP_CACHE", "true").lower() == "true"
    
    # Vision Service
    VISION_SERVICE_URL: str = os.getenv("VISION_SERVICE_URL", "http://vision:8002")
    VISION_SERVICE_TIMEOUT: int = int(os.getenv("VISION_SERVICE_TIMEOUT", "60"))
    VISION_BATCH_SIZE: int = int(os.getenv("VISION_BATCH_SIZE", "16"))
    ENABLE_VISION_CACHE: bool = os.getenv("ENABLE_VISION_CACHE", "true").lower() == "true"
    
    # ========== Redis Configuration ==========
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://:LF_Redis_2025_Pass!@redis:6379/0")
    REDIS_CACHE_TTL: int = int(os.getenv("REDIS_CACHE_TTL", "3600"))  # 1 hour
    REDIS_MAX_CONNECTIONS: int = int(os.getenv("REDIS_MAX_CONNECTIONS", "10"))
    ENABLE_REDIS_CACHE: bool = os.getenv("ENABLE_REDIS_CACHE", "true").lower() == "true"
    
    # ========== Media Storage ==========
    MEDIA_ROOT: str = os.getenv("MEDIA_ROOT", "/app/media")
    MEDIA_URL: str = os.getenv("MEDIA_URL", "/media")
    MAX_UPLOAD_SIZE_MB: int = int(os.getenv("MAX_UPLOAD_SIZE_MB", "10"))
    MAX_FILE_SIZE: int = MAX_UPLOAD_SIZE_MB * 1024 * 1024  # Convert MB to bytes
    ALLOWED_IMAGE_TYPES: List[str] = ["image/jpeg", "image/png", "image/webp"]
    STRIP_EXIF: bool = os.getenv("STRIP_EXIF", "true").lower() == "true"
    
    # MinIO Object Storage
    MINIO_ENDPOINT: str = os.getenv("MINIO_ENDPOINT", "minio:9000")
    MINIO_ACCESS_KEY: str = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
    MINIO_SECRET_KEY: str = os.getenv("MINIO_SECRET_KEY", "minioadmin123")
    MINIO_BUCKET_NAME: str = os.getenv("MINIO_BUCKET_NAME", "lost-found-media")
    MINIO_SECURE: bool = os.getenv("MINIO_SECURE", "false").lower() == "true"
    MINIO_REGION: str = os.getenv("MINIO_REGION", "us-east-1")
    
    # ========== Matching Configuration ==========
    # Match scoring weights (must sum to ~1.0)
    MATCH_WEIGHT_TEXT: float = float(os.getenv("MATCH_WEIGHT_TEXT", "0.45"))
    MATCH_WEIGHT_IMAGE: float = float(os.getenv("MATCH_WEIGHT_IMAGE", "0.35"))
    MATCH_WEIGHT_GEO: float = float(os.getenv("MATCH_WEIGHT_GEO", "0.15"))
    MATCH_WEIGHT_TIME: float = float(os.getenv("MATCH_WEIGHT_TIME", "0.05"))
    
    # Match thresholds
    MATCH_MIN_SCORE: float = float(os.getenv("MATCH_MIN_SCORE", "0.65"))
    MATCH_TEXT_THRESHOLD: float = float(os.getenv("MATCH_TEXT_THRESHOLD", "0.70"))
    MATCH_IMAGE_THRESHOLD: float = float(os.getenv("MATCH_IMAGE_THRESHOLD", "0.75"))
    MATCH_GEO_RADIUS_KM: float = float(os.getenv("MATCH_GEO_RADIUS_KM", "5.0"))
    MATCH_TIME_WINDOW_DAYS: int = int(os.getenv("MATCH_TIME_WINDOW_DAYS", "30"))
    
    # ANN search parameters
    ANN_TOP_K: int = int(os.getenv("ANN_TOP_K", "50"))  # Initial candidates from text similarity
    MATCH_MAX_RESULTS: int = int(os.getenv("MATCH_MAX_RESULTS", "20"))  # Final matches returned
    
    # ========== Pagination ==========
    DEFAULT_PAGE_SIZE: int = int(os.getenv("DEFAULT_PAGE_SIZE", "20"))
    MAX_PAGE_SIZE: int = int(os.getenv("MAX_PAGE_SIZE", "100"))
    
    # ========== Rate Limiting ==========
    ENABLE_RATE_LIMIT: bool = os.getenv("ENABLE_RATE_LIMIT", "true").lower() == "true"
    RATE_LIMIT_AUTH: str = os.getenv("RATE_LIMIT_AUTH", "5/minute")  # Login attempts
    RATE_LIMIT_UPLOAD: str = os.getenv("RATE_LIMIT_UPLOAD", "10/minute")  # Media uploads
    RATE_LIMIT_CREATE_REPORT: str = os.getenv("RATE_LIMIT_CREATE_REPORT", "20/hour")
    RATE_LIMIT_SEARCH: str = os.getenv("RATE_LIMIT_SEARCH", "60/minute")
    RATE_LIMIT_STORAGE: str = os.getenv("RATE_LIMIT_STORAGE", "redis")  # redis or memory
    
    # ========== Security & CORS ==========
    CORS_ORIGINS: List[str] = os.getenv(
        "CORS_ORIGINS",
        "http://localhost:3000,http://localhost:3001,http://localhost:8080,http://admin:3000,http://172.104.40.189:3000,http://172.104.40.189:8080,http://172.104.40.189:8000,http://172.104.40.189:8001,http://172.104.40.189:8002"
    ).split(",")
    CORS_ALLOW_CREDENTIALS: bool = os.getenv("CORS_ALLOW_CREDENTIALS", "true").lower() == "true"
    
    # Security headers
    ENABLE_SECURITY_HEADERS: bool = os.getenv("ENABLE_SECURITY_HEADERS", "true").lower() == "true"
    
    # ========== Monitoring & Metrics ==========
    ENABLE_METRICS: bool = os.getenv("ENABLE_METRICS", "true").lower() == "true"
    METRICS_PORT: int = int(os.getenv("METRICS_PORT", "9090"))
    
    # ========== Admin Panel ==========
    ADMIN_SESSION_SECRET: str = os.getenv("ADMIN_SESSION_SECRET", "change-in-production")
    ADMIN_SESSION_LIFETIME_HOURS: int = int(os.getenv("ADMIN_SESSION_LIFETIME_HOURS", "8"))
    ENABLE_ADMIN_PANEL: bool = os.getenv("ENABLE_ADMIN_PANEL", "true").lower() == "true"
    
    # ========== Localization ==========
    SUPPORTED_LANGUAGES: List[str] = ["en", "si", "ta"]  # English, Sinhala, Tamil
    DEFAULT_LANGUAGE: str = os.getenv("DEFAULT_LANGUAGE", "en")
    
    # ========== Background Tasks ==========
    ENABLE_BACKGROUND_TASKS: bool = os.getenv("ENABLE_BACKGROUND_TASKS", "true").lower() == "true"
    ARQ_REDIS_URL: str = os.getenv("ARQ_REDIS_URL", REDIS_URL)
    
    # ========== Feature Flags ==========
    ENABLE_WEBSOCKETS: bool = os.getenv("ENABLE_WEBSOCKETS", "false").lower() == "true"
    ENABLE_AUDIT_LOG: bool = os.getenv("ENABLE_AUDIT_LOG", "true").lower() == "true"
    
    # ========== Timeouts ==========
    REQUEST_TIMEOUT: int = int(os.getenv("REQUEST_TIMEOUT", "30"))
    BACKGROUND_TASK_TIMEOUT: int = int(os.getenv("BACKGROUND_TASK_TIMEOUT", "300"))
    
    @classmethod
    def validate(cls) -> bool:
        """Validate configuration."""
        errors = []
        
        # Validate database URL
        if not cls.DATABASE_URL:
            errors.append("DATABASE_URL is required")
        
        # Validate JWT secret in production
        if cls.ENVIRONMENT == "production" and cls.JWT_SECRET_KEY == "your-secret-key-change-in-production":
            errors.append("JWT_SECRET_KEY must be changed in production")
        
        # Validate service URLs
        if not cls.NLP_SERVICE_URL.startswith(("http://", "https://")):
            errors.append("NLP_SERVICE_URL must be a valid HTTP(S) URL")
        
        if not cls.VISION_SERVICE_URL.startswith(("http://", "https://")):
            errors.append("VISION_SERVICE_URL must be a valid HTTP(S) URL")
        
        # Validate match weights sum to ~1.0
        total_weight = (
            cls.MATCH_WEIGHT_TEXT +
            cls.MATCH_WEIGHT_IMAGE +
            cls.MATCH_WEIGHT_GEO +
            cls.MATCH_WEIGHT_TIME
        )
        if not (0.99 <= total_weight <= 1.01):
            errors.append(f"Match weights must sum to 1.0 (current: {total_weight})")
        
        # Validate media root exists or can be created
        media_path = Path(cls.MEDIA_ROOT)
        if not media_path.exists():
            try:
                media_path.mkdir(parents=True, exist_ok=True)
            except Exception as e:
                errors.append(f"Cannot create MEDIA_ROOT directory: {e}")
        
        if errors:
            raise ValueError(f"Configuration errors: {', '.join(errors)}")
        
        return True
    
    @classmethod
    def get_db_url_sync(cls) -> str:
        """Get synchronous database URL (for Alembic migrations)."""
        return cls.DATABASE_URL.replace("+asyncpg", "")
    
    @classmethod
    def summary(cls) -> dict:
        """Return configuration summary (safe for logging)."""
        return {
            "environment": cls.ENVIRONMENT,
            "server": {
                "host": cls.HOST,
                "port": cls.PORT,
                "workers": cls.WORKERS,
                "debug": cls.DEBUG,
            },
            "services": {
                "nlp": cls.NLP_SERVICE_URL,
                "vision": cls.VISION_SERVICE_URL,
                "redis": "enabled" if cls.ENABLE_REDIS_CACHE else "disabled",
            },
            "features": {
                "metrics": cls.ENABLE_METRICS,
                "rate_limit": cls.ENABLE_RATE_LIMIT,
                "admin_panel": cls.ENABLE_ADMIN_PANEL,
                "audit_log": cls.ENABLE_AUDIT_LOG,
            },
            "matching": {
                "weights": {
                    "text": cls.MATCH_WEIGHT_TEXT,
                    "image": cls.MATCH_WEIGHT_IMAGE,
                    "geo": cls.MATCH_WEIGHT_GEO,
                    "time": cls.MATCH_WEIGHT_TIME,
                },
                "min_score": cls.MATCH_MIN_SCORE,
                "geo_radius_km": cls.MATCH_GEO_RADIUS_KM,
                "time_window_days": cls.MATCH_TIME_WINDOW_DAYS,
            },
            "media": {
                "root": cls.MEDIA_ROOT,
                "max_size_mb": cls.MAX_UPLOAD_SIZE_MB,
                "strip_exif": cls.STRIP_EXIF,
            }
        }


# Global config instance
config = Config()
