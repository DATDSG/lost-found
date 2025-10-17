"""
Simplified Configuration for NLP Service
--------------------------------------
Supports:
- Single model (CPU-only)
- Redis caching
- Prometheus metrics
- Rate limiting
"""
import os


class Config:
    """Simplified configuration for CPU-only, single-model processing."""
    
    # Model Configuration
    MODEL_NAME: str = os.getenv("MODEL_NAME", "intfloat/e5-small-v2")
    MODEL_CACHE_DIR: str = os.getenv("MODEL_CACHE_DIR", "/app/.cache")
    
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
    
    # Server Configuration
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8001"))
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    WORKERS: int = int(os.getenv("WORKERS", "1"))
    
    # Processing Configuration
    BATCH_SIZE: int = int(os.getenv("BATCH_SIZE", "32"))
    MAX_SEQUENCE_LENGTH: int = int(os.getenv("MAX_SEQUENCE_LENGTH", "512"))
    NORMALIZE_EMBEDDINGS: bool = os.getenv("NORMALIZE_EMBEDDINGS", "true").lower() == "true"
    
    # Metrics & Monitoring
    ENABLE_METRICS: bool = os.getenv("ENABLE_METRICS", "true").lower() == "true"
    
    # Rate Limiting
    ENABLE_RATE_LIMIT: bool = os.getenv("ENABLE_RATE_LIMIT", "true").lower() == "true"
    RATE_LIMIT_ENCODE: str = os.getenv("RATE_LIMIT_ENCODE", "100/minute")
    RATE_LIMIT_BATCH: str = os.getenv("RATE_LIMIT_BATCH", "50/minute")
    
    # CORS
    CORS_ORIGINS: list = os.getenv("CORS_ORIGINS", "*").split(",")
    
    # Timeouts
    ENCODE_TIMEOUT: int = int(os.getenv("ENCODE_TIMEOUT", "30"))
    REDIS_TIMEOUT: int = int(os.getenv("REDIS_TIMEOUT", "5"))
    
    @classmethod
    def validate(cls):
        """Validate configuration."""
        errors = []
        
        if cls.ENABLE_REDIS_CACHE and not cls.REDIS_URL:
            errors.append("Redis cache enabled but REDIS_URL not set")
        
        if cls.LRU_CACHE_SIZE < 100:
            errors.append("LRU_CACHE_SIZE too small (minimum 100)")
        
        if errors:
            raise ValueError(f"Configuration errors: {', '.join(errors)}")
        
        return True
    
    @classmethod
    def summary(cls) -> dict:
        """Get configuration summary."""
        return {
            "model": cls.MODEL_NAME,
            "caching": {
                "redis": cls.ENABLE_REDIS_CACHE,
                "lru_size": cls.LRU_CACHE_SIZE,
                "ttl": cls.REDIS_CACHE_TTL
            },
            "minio": {
                "endpoint": cls.MINIO_ENDPOINT,
                "bucket": cls.MINIO_BUCKET_NAME,
                "secure": cls.MINIO_SECURE,
            },
            "performance": {
                "batch_size": cls.BATCH_SIZE,
                "workers": cls.WORKERS,
                "cpu_only": True
            },
            "monitoring": {
                "metrics": cls.ENABLE_METRICS,
                "rate_limiting": cls.ENABLE_RATE_LIMIT
            }
        }


# Global config instance
config = Config()
