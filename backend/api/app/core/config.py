from pydantic_settings import BaseSettings
from decouple import config

class Settings(BaseSettings):
    APP_NAME: str = "Lost & Found API"
    ENV: str = "dev"
    PORT: int = 8000
    CORS_ORIGINS: str = "*"

    # Auth
    JWT_SECRET: str = "change_me_in_production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 43200  # 30 days for mobile

    # Database (PostgreSQL with PostGIS)
    DATABASE_URL: str = "postgresql://lostfound:lostfound@localhost:5432/lostfound"

    # Feature Flags - Core Architecture Decision
    NLP_ON: bool = config('NLP_ON', default=False, cast=bool)  # Enable NLP features
    CV_ON: bool = config('CV_ON', default=True, cast=bool)    # Enable Computer Vision features
    
    # S3/MinIO for media storage
    S3_ENDPOINT_URL: str | None = None
    S3_REGION: str = "us-east-1"
    S3_ACCESS_KEY_ID: str | None = None
    S3_SECRET_ACCESS_KEY: str | None = None
    S3_BUCKET: str = "media"
    S3_PRESIGN_EXPIRES: int = 3600

    # Redis for caching and job queues
    REDIS_URL: str = "redis://localhost:6379/0"
    RQ_DEFAULT_QUEUE: str = "lostfound"

    # Admin bootstrap
    ADMIN_EMAIL: str = "admin@lostfound.local"
    ADMIN_PASSWORD: str = "admin123"

    # Tri-lingual support
    SUPPORTED_LANGUAGES: list[str] = ["si", "ta", "en"]
    DEFAULT_LANGUAGE: str = "en"

    # Geospatial configuration
    GEOHASH_PRECISION: int = 6  # ~1.2km precision
    MAX_SEARCH_RADIUS_KM: float = 50.0
    LOCATION_FUZZING_METERS: int = 100  # Privacy protection

    # Temporal matching windows
    DEFAULT_TIME_WINDOW_DAYS: int = 14
    MAX_TIME_WINDOW_DAYS: int = 90

    # Baseline matching weights (always active)
    WEIGHT_CATEGORY: float = 0.35
    WEIGHT_DISTANCE: float = 0.25
    WEIGHT_TIME: float = 0.20
    WEIGHT_ATTRIBUTES: float = 0.20  # brand, color, etc.

    # Optional ML weights (when NLP_ON/CV_ON)
    WEIGHT_TEXT_SIMILARITY: float = 0.30  # Only when NLP_ON
    WEIGHT_IMAGE_SIMILARITY: float = 0.25  # Only when CV_ON

    # External services (optional microservices)
    NLP_SERVICE_URL: str = "http://embedder:8010"
    VISION_SERVICE_URL: str = "http://vision:8091"

    # Matching thresholds
    MIN_MATCH_SCORE: float = 0.3
    TOP_K_MATCHES: int = 10

    # Privacy and safety
    ENABLE_COORDINATE_FUZZING: bool = True
    ENABLE_MASKED_CHAT: bool = True
    ENABLE_AUDIT_LOGGING: bool = True

    class Config:
        env_file = ".env"

settings = Settings()