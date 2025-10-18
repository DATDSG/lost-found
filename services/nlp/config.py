"""
Enhanced Configuration for NLP Service
--------------------------------------
Supports:
- Redis caching
- GPU acceleration
- Prometheus metrics
- Rate limiting
- Model versioning
- Async processing
"""
import os
from typing import Optional


class Config:
    """Enhanced configuration with all production features."""
    
    # Model Configuration
    MODEL_NAME: str = os.getenv("MODEL_NAME", "intfloat/e5-small-v2")
    ALT_MODEL_NAME: Optional[str] = os.getenv("ALT_MODEL_NAME")  # For A/B testing
    MODEL_CACHE_DIR: str = os.getenv("MODEL_CACHE_DIR", "/app/.cache")
    
    # Redis Configuration
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://redis:6379/0")
    REDIS_CACHE_TTL: int = int(os.getenv("REDIS_CACHE_TTL", "86400"))  # 24 hours
    REDIS_MAX_CONNECTIONS: int = int(os.getenv("REDIS_MAX_CONNECTIONS", "10"))
    
    # Cache Configuration
    ENABLE_REDIS_CACHE: bool = os.getenv("ENABLE_REDIS_CACHE", "true").lower() == "true"
    LRU_CACHE_SIZE: int = int(os.getenv("LRU_CACHE_SIZE", "1000"))
    CACHE_EVICTION_POLICY: str = os.getenv("CACHE_EVICTION_POLICY", "lru")  # lru, fifo, lfu
    
    # GPU Configuration
    USE_GPU: bool = os.getenv("USE_GPU", "false").lower() == "true"
    GPU_DEVICE_ID: int = int(os.getenv("GPU_DEVICE_ID", "0"))
    GPU_MEMORY_FRACTION: float = float(os.getenv("GPU_MEMORY_FRACTION", "0.8"))
    
    # Server Configuration
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8001"))
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    WORKERS: int = int(os.getenv("WORKERS", "1"))
    
    # Processing Configuration
    BATCH_SIZE: int = int(os.getenv("BATCH_SIZE", "32"))
    MAX_SEQUENCE_LENGTH: int = int(os.getenv("MAX_SEQUENCE_LENGTH", "512"))
    NORMALIZE_EMBEDDINGS: bool = os.getenv("NORMALIZE_EMBEDDINGS", "true").lower() == "true"
    
    # Performance Tuning
    TORCH_NUM_THREADS: int = int(os.getenv("TORCH_NUM_THREADS", "4"))
    
    # Metrics & Monitoring
    ENABLE_METRICS: bool = os.getenv("ENABLE_METRICS", "true").lower() == "true"
    METRICS_PORT: int = int(os.getenv("METRICS_PORT", "9090"))
    
    # Rate Limiting
    ENABLE_RATE_LIMIT: bool = os.getenv("ENABLE_RATE_LIMIT", "true").lower() == "true"
    RATE_LIMIT_ENCODE: str = os.getenv("RATE_LIMIT_ENCODE", "100/minute")
    RATE_LIMIT_BATCH: str = os.getenv("RATE_LIMIT_BATCH", "50/minute")
    RATE_LIMIT_STORAGE: str = os.getenv("RATE_LIMIT_STORAGE", "redis")  # redis or memory
    
    # Model Versioning & A/B Testing
    ENABLE_MODEL_VERSIONING: bool = os.getenv("ENABLE_MODEL_VERSIONING", "true").lower() == "true"
    DEFAULT_MODEL_VERSION: str = os.getenv("DEFAULT_MODEL_VERSION", "v1")
    AB_TEST_ENABLED: bool = os.getenv("AB_TEST_ENABLED", "false").lower() == "true"
    AB_TEST_V2_TRAFFIC: float = float(os.getenv("AB_TEST_V2_TRAFFIC", "0.1"))  # 10% to v2
    
    # Async Processing
    ENABLE_ASYNC_PROCESSING: bool = os.getenv("ENABLE_ASYNC_PROCESSING", "true").lower() == "true"
    ARQ_REDIS_URL: str = os.getenv("ARQ_REDIS_URL", REDIS_URL)
    BACKGROUND_WORKER_COUNT: int = int(os.getenv("BACKGROUND_WORKER_COUNT", "2"))
    
    # Pre-warming
    ENABLE_CACHE_PREWARMING: bool = os.getenv("ENABLE_CACHE_PREWARMING", "false").lower() == "true"
    PREWARM_TEXTS_FILE: Optional[str] = os.getenv("PREWARM_TEXTS_FILE")
    
    # Security
    API_KEY_ENABLED: bool = os.getenv("API_KEY_ENABLED", "false").lower() == "true"
    API_KEYS: list = os.getenv("API_KEYS", "").split(",") if os.getenv("API_KEYS") else []
    
    # CORS
    CORS_ORIGINS: list = os.getenv("CORS_ORIGINS", "*").split(",")
    
    # Timeouts
    ENCODE_TIMEOUT: int = int(os.getenv("ENCODE_TIMEOUT", "30"))
    REDIS_TIMEOUT: int = int(os.getenv("REDIS_TIMEOUT", "5"))
    
    # Analytics
    ENABLE_ANALYTICS: bool = os.getenv("ENABLE_ANALYTICS", "true").lower() == "true"
    ANALYTICS_SAMPLE_RATE: float = float(os.getenv("ANALYTICS_SAMPLE_RATE", "0.1"))  # 10%
    
    @classmethod
    def validate(cls):
        """Validate configuration."""
        errors = []
        
        if cls.USE_GPU:
            try:
                import torch
                if not torch.cuda.is_available():
                    errors.append("GPU enabled but CUDA not available")
            except ImportError:
                errors.append("GPU enabled but PyTorch not installed")
        
        if cls.ENABLE_REDIS_CACHE and not cls.REDIS_URL:
            errors.append("Redis cache enabled but REDIS_URL not set")
        
        if cls.AB_TEST_ENABLED and not cls.ALT_MODEL_NAME:
            errors.append("A/B testing enabled but ALT_MODEL_NAME not set")
        
        if cls.LRU_CACHE_SIZE < 100:
            errors.append("LRU_CACHE_SIZE too small (minimum 100)")
        
        if errors:
            raise ValueError(f"Configuration errors: {', '.join(errors)}")
        
        return True
    
    @classmethod
    def summary(cls) -> dict:
        """Get configuration summary."""
        return {
            "model": {
                "primary": cls.MODEL_NAME,
                "alternative": cls.ALT_MODEL_NAME,
                "versioning": cls.ENABLE_MODEL_VERSIONING,
                "ab_testing": cls.AB_TEST_ENABLED
            },
            "caching": {
                "redis": cls.ENABLE_REDIS_CACHE,
                "lru_size": cls.LRU_CACHE_SIZE,
                "ttl": cls.REDIS_CACHE_TTL,
                "prewarming": cls.ENABLE_CACHE_PREWARMING
            },
            "performance": {
                "gpu": cls.USE_GPU,
                "batch_size": cls.BATCH_SIZE,
                "workers": cls.WORKERS
            },
            "monitoring": {
                "metrics": cls.ENABLE_METRICS,
                "analytics": cls.ENABLE_ANALYTICS,
                "rate_limiting": cls.ENABLE_RATE_LIMIT
            },
            "features": {
                "async_processing": cls.ENABLE_ASYNC_PROCESSING,
                "model_versioning": cls.ENABLE_MODEL_VERSIONING,
                "api_key_auth": cls.API_KEY_ENABLED
            }
        }


# Global config instance
config = Config()


# Pre-warming texts for common queries
COMMON_TEXTS = [
    # English
    "lost phone",
    "found wallet",
    "lost keys",
    "found bag",
    "lost laptop",
    "found documents",
    
    # Sinhala
    "දුරකථනයක් අතුරුදහන් විය",
    "පසුම්බියක් හමු විය",
    "යතුරු අතුරුදහන් විය",
    
    # Tamil
    "தொலைபேசி காணவில்லை",
    "பணப்பை கிடைத்தது",
    "சாவி தொலைந்தது"
]


# Rate limit tiers for different user types
RATE_LIMIT_TIERS = {
    "free": "20/minute",
    "basic": "100/minute",
    "premium": "500/minute",
    "enterprise": "unlimited"
}


# Model version configurations
MODEL_VERSIONS = {
    "v1": {
        "name": "intfloat/e5-small-v2",
        "dimension": 384,
        "description": "Default multilingual model",
        "max_seq_length": 512
    },
    "v2": {
        "name": os.getenv("ALT_MODEL_NAME", "sentence-transformers/paraphrase-multilingual-mpnet-base-v2"),
        "dimension": 768,
        "description": "Alternative model for A/B testing",
        "max_seq_length": 128
    }
}


# Prometheus metric labels
METRIC_LABELS = {
    "service": "nlp-embedding",
    "environment": os.getenv("ENVIRONMENT", "production"),
    "version": "2.0.0"
}
