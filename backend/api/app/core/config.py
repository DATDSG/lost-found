from pydantic_settings import BaseSettings
from decouple import config
import secrets
import sys

class Settings(BaseSettings):
    APP_NAME: str = "Lost & Found API"
    ENV: str = config('ENV', default='dev')
    PORT: int = 8000
    CORS_ORIGINS: str = config('CORS_ORIGINS', default='http://localhost:3000,http://localhost:3001')

    # Auth - MUST be set via environment variables in production
    JWT_SECRET: str = config('JWT_SECRET', default='')
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 43200  # 30 days for mobile

    # Database (PostgreSQL with PostGIS)
    DATABASE_URL: str = config('DATABASE_URL', default='postgresql://lostfound:lostfound@localhost:5432/lostfound')

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

    # Admin bootstrap - MUST be set via environment variables in production
    ADMIN_EMAIL: str = config('ADMIN_EMAIL', default='')
    ADMIN_PASSWORD: str = config('ADMIN_PASSWORD', default='')

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

    # Service-to-Service Authentication
    SERVICE_API_KEY: str = config('SERVICE_API_KEY', default='')

    # Notifications
    EMAIL_ENABLED: bool = config('EMAIL_ENABLED', default=False, cast=bool)
    EMAIL_FROM: str = config('EMAIL_FROM', default='noreply@lostfound.com')
    EMAIL_PROVIDER: str = config('EMAIL_PROVIDER', default='smtp')
    
    SMTP_HOST: str = config('SMTP_HOST', default='smtp.gmail.com')
    SMTP_PORT: int = config('SMTP_PORT', default=587, cast=int)
    SMTP_USERNAME: str = config('SMTP_USERNAME', default='')
    SMTP_PASSWORD: str = config('SMTP_PASSWORD', default='')
    SMTP_USE_TLS: bool = config('SMTP_USE_TLS', default=True, cast=bool)
    
    SENDGRID_API_KEY: str = config('SENDGRID_API_KEY', default='')
    
    FCM_ENABLED: bool = config('FCM_ENABLED', default=False, cast=bool)
    FCM_SERVER_KEY: str = config('FCM_SERVER_KEY', default='')
    
    SMS_ENABLED: bool = config('SMS_ENABLED', default=False, cast=bool)
    TWILIO_ACCOUNT_SID: str = config('TWILIO_ACCOUNT_SID', default='')
    TWILIO_AUTH_TOKEN: str = config('TWILIO_AUTH_TOKEN', default='')
    TWILIO_PHONE_NUMBER: str = config('TWILIO_PHONE_NUMBER', default='')

    # Monitoring
    LOG_LEVEL: str = config('LOG_LEVEL', default='INFO')
    SENTRY_ENABLED: bool = config('SENTRY_ENABLED', default=False, cast=bool)
    SENTRY_DSN: str = config('SENTRY_DSN', default='')
    SENTRY_ENVIRONMENT: str = config('SENTRY_ENVIRONMENT', default='dev')
    SENTRY_RELEASE: str = config('SENTRY_RELEASE', default='')
    PROMETHEUS_ENABLED: bool = config('PROMETHEUS_ENABLED', default=True, cast=bool)
    # Semantic / Vector search (pgvector, embeddings)
    SEMANTIC_SEARCH_ENABLED: bool = config('SEMANTIC_SEARCH_ENABLED', default=False, cast=bool)
    VECTOR_MIN_DIM: int = config('VECTOR_MIN_DIM', default=128, cast=int)

    # Rate Limiting
    RATE_LIMIT_ENABLED: bool = config('RATE_LIMIT_ENABLED', default=True, cast=bool)
    RATE_LIMIT_PER_MINUTE: int = config('RATE_LIMIT_PER_MINUTE', default=100, cast=int)
    RATE_LIMIT_PER_HOUR: int = config('RATE_LIMIT_PER_HOUR', default=1000, cast=int)

    class Config:
        env_file = ".env"

    def validate_production_config(self):
        """Validate critical configuration in production environment."""
        if self.ENV == 'production':
            errors = []
            
            if not self.JWT_SECRET or self.JWT_SECRET == 'change_me_in_production':
                errors.append("JWT_SECRET must be set in production")
            
            if len(self.JWT_SECRET) < 32:
                errors.append("JWT_SECRET must be at least 32 characters")
            
            if not self.ADMIN_EMAIL or '@lostfound.local' in self.ADMIN_EMAIL:
                errors.append("ADMIN_EMAIL must be set to a real email in production")
            
            if not self.ADMIN_PASSWORD or self.ADMIN_PASSWORD == 'admin123':
                errors.append("ADMIN_PASSWORD must be set to a strong password in production")
            
            if self.CORS_ORIGINS == '*':
                errors.append("CORS_ORIGINS must be set to specific domains in production")
            
            if not self.SERVICE_API_KEY or len(self.SERVICE_API_KEY) < 32:
                errors.append("SERVICE_API_KEY must be set and at least 32 characters")
            
            if errors:
                print("❌ CRITICAL CONFIGURATION ERRORS:", file=sys.stderr)
                for error in errors:
                    print(f"  - {error}", file=sys.stderr)
                sys.exit(1)

settings = Settings()

# Validate configuration on startup
if settings.ENV == 'production':
    settings.validate_production_config()