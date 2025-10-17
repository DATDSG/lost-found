"""
Simplified Configuration for Vision Service v2.0
--------------------------------------
Supports:
- CPU-only processing
- Redis caching
- Prometheus metrics
- Rate limiting
- Image hashing and quality assessment
"""
import os


class Config:
    """Simplified configuration for CPU-only Vision service."""
    
    # Server Configuration
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8002"))
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    WORKERS: int = int(os.getenv("WORKERS", "1"))
    
    # Redis Configuration
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://redis:6379/0")
    REDIS_CACHE_TTL: int = int(os.getenv("REDIS_CACHE_TTL", "86400"))  # 24 hours
    
    # MinIO Object Storage Configuration
    MINIO_ENDPOINT: str = os.getenv("MINIO_ENDPOINT", "http://localhost:9000")
    MINIO_ACCESS_KEY: str = os.getenv("MINIO_ACCESS_KEY", "admin")
    MINIO_SECRET_KEY: str = os.getenv("MINIO_SECRET_KEY", "admin")
    MINIO_BUCKET_NAME: str = os.getenv("MINIO_BUCKET_NAME", "lost-found-media")
    MINIO_SECURE: bool = os.getenv("MINIO_SECURE", "false").lower() == "true"
    
    # Cache Configuration
    ENABLE_REDIS_CACHE: bool = os.getenv("ENABLE_REDIS_CACHE", "true").lower() == "true"
    LRU_CACHE_SIZE: int = int(os.getenv("LRU_CACHE_SIZE", "1000"))
    
    # Feature Toggles
    ENABLE_METRICS: bool = os.getenv("ENABLE_METRICS", "true").lower() == "true"
    ENABLE_RATE_LIMIT: bool = os.getenv("ENABLE_RATE_LIMIT", "true").lower() == "true"
    
    # Rate Limiting
    RATE_LIMIT_HASH: str = os.getenv("RATE_LIMIT_HASH", "100/minute")
    
    # Image Processing
    MAX_IMAGE_SIZE_MB: int = int(os.getenv("MAX_IMAGE_SIZE_MB", "10"))
    MAX_IMAGE_DIMENSION: int = int(os.getenv("MAX_IMAGE_DIMENSION", "4096"))
    SUPPORTED_FORMATS: set = {"JPEG", "PNG", "JPG", "WEBP"}
    
    # Hash Thresholds
    HASH_THRESHOLD_SIMILAR: int = int(os.getenv("HASH_THRESHOLD_SIMILAR", "10"))
    HASH_THRESHOLD_MATCH: int = int(os.getenv("HASH_THRESHOLD_MATCH", "14"))
    
    # CORS
    CORS_ORIGINS: list = os.getenv("CORS_ORIGINS", "*").split(",")
    
    # Timeouts
    PROCESSING_TIMEOUT: int = int(os.getenv("PROCESSING_TIMEOUT", "30"))
    
    @classmethod
    def validate(cls):
        """Validate configuration."""
        errors = []
        
        if cls.MAX_IMAGE_SIZE_MB <= 0:
            errors.append("MAX_IMAGE_SIZE_MB must be positive")
        
        if cls.REDIS_CACHE_TTL <= 0:
            errors.append("REDIS_CACHE_TTL must be positive")
        
        if errors:
            raise ValueError(f"Configuration errors: {', '.join(errors)}")
        
        return True
    
    @classmethod
    def summary(cls):
        """Return configuration summary."""
        return {
            "server": {
                "host": cls.HOST,
                "port": cls.PORT,
                "workers": cls.WORKERS,
                "log_level": cls.LOG_LEVEL,
            },
            "features": {
                "redis_cache": cls.ENABLE_REDIS_CACHE,
                "metrics": cls.ENABLE_METRICS,
                "rate_limit": cls.ENABLE_RATE_LIMIT,
                "cpu_only": True,
                "image_hashing": True,
                "quality_assessment": True,
                "duplicate_detection": True
            },
            "minio": {
                "endpoint": cls.MINIO_ENDPOINT,
                "bucket": cls.MINIO_BUCKET_NAME,
                "secure": cls.MINIO_SECURE,
            },
            "limits": {
                "max_image_size_mb": cls.MAX_IMAGE_SIZE_MB,
                "max_image_dimension": cls.MAX_IMAGE_DIMENSION,
                "cache_ttl": cls.REDIS_CACHE_TTL,
                "supported_formats": list(cls.SUPPORTED_FORMATS)
            }
        }


# Global config instance
config = Config()
