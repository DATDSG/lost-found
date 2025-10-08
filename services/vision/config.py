"""
Configuration for Vision Service v2.0
--------------------------------------
Supports:
- Redis caching
- GPU acceleration
- Prometheus metrics
- Rate limiting
- Multiple ML models (YOLO, OCR, CLIP, NSFW)
- Async processing
"""
import os
from typing import Optional


class Config:
    """Production configuration for Vision service."""
    
    # Server Configuration
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8002"))
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    WORKERS: int = int(os.getenv("WORKERS", "1"))
    
    # Redis Configuration
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://redis:6379/0")
    REDIS_CACHE_TTL: int = int(os.getenv("REDIS_CACHE_TTL", "86400"))  # 24 hours
    REDIS_MAX_CONNECTIONS: int = int(os.getenv("REDIS_MAX_CONNECTIONS", "10"))
    REDIS_TIMEOUT: int = int(os.getenv("REDIS_TIMEOUT", "5"))
    
    # Cache Configuration
    ENABLE_REDIS_CACHE: bool = os.getenv("ENABLE_REDIS_CACHE", "true").lower() == "true"
    LRU_CACHE_SIZE: int = int(os.getenv("LRU_CACHE_SIZE", "1000"))
    
    # GPU Configuration
    USE_GPU: bool = os.getenv("USE_GPU", "false").lower() == "true"
    GPU_DEVICE_ID: int = int(os.getenv("GPU_DEVICE_ID", "0"))
    
    # Feature Toggles
    ENABLE_METRICS: bool = os.getenv("ENABLE_METRICS", "true").lower() == "true"
    ENABLE_RATE_LIMIT: bool = os.getenv("ENABLE_RATE_LIMIT", "true").lower() == "true"
    ENABLE_OBJECT_DETECTION: bool = os.getenv("ENABLE_OBJECT_DETECTION", "true").lower() == "true"
    ENABLE_OCR: bool = os.getenv("ENABLE_OCR", "true").lower() == "true"
    ENABLE_CLIP: bool = os.getenv("ENABLE_CLIP", "true").lower() == "true"
    ENABLE_NSFW_DETECTION: bool = os.getenv("ENABLE_NSFW_DETECTION", "true").lower() == "true"
    
    # Rate Limiting
    RATE_LIMIT_HASH: str = os.getenv("RATE_LIMIT_HASH", "100/minute")
    RATE_LIMIT_OBJECTS: str = os.getenv("RATE_LIMIT_OBJECTS", "50/minute")
    RATE_LIMIT_OCR: str = os.getenv("RATE_LIMIT_OCR", "30/minute")
    RATE_LIMIT_CLIP: str = os.getenv("RATE_LIMIT_CLIP", "50/minute")
    RATE_LIMIT_ANALYZE: str = os.getenv("RATE_LIMIT_ANALYZE", "20/minute")
    
    # Model Configuration
    YOLO_MODEL: str = os.getenv("YOLO_MODEL", "yolov8n.pt")  # nano model
    CLIP_MODEL: str = os.getenv("CLIP_MODEL", "ViT-B/32")
    OCR_LANGUAGES: str = os.getenv("OCR_LANGUAGES", "en")  # comma-separated
    MODEL_CACHE_DIR: str = os.getenv("MODEL_CACHE_DIR", "/root/.cache")
    
    # Image Processing
    MAX_IMAGE_SIZE_MB: int = int(os.getenv("MAX_IMAGE_SIZE_MB", "10"))
    MAX_IMAGE_DIMENSION: int = int(os.getenv("MAX_IMAGE_DIMENSION", "4096"))
    
    # Hash Thresholds
    HASH_THRESHOLD_SIMILAR: int = int(os.getenv("HASH_THRESHOLD_SIMILAR", "10"))
    HASH_THRESHOLD_MATCH: int = int(os.getenv("HASH_THRESHOLD_MATCH", "5"))
    
    # CLIP Configuration
    CLIP_SIMILARITY_THRESHOLD: float = float(os.getenv("CLIP_SIMILARITY_THRESHOLD", "0.85"))
    
    # Object Detection
    YOLO_CONFIDENCE_THRESHOLD: float = float(os.getenv("YOLO_CONFIDENCE_THRESHOLD", "0.25"))
    YOLO_IOU_THRESHOLD: float = float(os.getenv("YOLO_IOU_THRESHOLD", "0.45"))
    
    # Quality Assessment
    QUALITY_MIN_SHARPNESS: float = float(os.getenv("QUALITY_MIN_SHARPNESS", "100.0"))
    QUALITY_MIN_BRIGHTNESS: float = float(os.getenv("QUALITY_MIN_BRIGHTNESS", "50.0"))
    QUALITY_MAX_BRIGHTNESS: float = float(os.getenv("QUALITY_MAX_BRIGHTNESS", "200.0"))
    
    # NSFW Detection
    NSFW_THRESHOLD: float = float(os.getenv("NSFW_THRESHOLD", "0.5"))
    
    # Async Processing
    ENABLE_ASYNC_PROCESSING: bool = os.getenv("ENABLE_ASYNC_PROCESSING", "true").lower() == "true"
    ARQ_REDIS_URL: str = os.getenv("ARQ_REDIS_URL", REDIS_URL)
    BACKGROUND_WORKER_COUNT: int = int(os.getenv("BACKGROUND_WORKER_COUNT", "2"))
    
    # CORS
    CORS_ORIGINS: list = os.getenv("CORS_ORIGINS", "*").split(",")
    
    # Timeouts
    PROCESSING_TIMEOUT: int = int(os.getenv("PROCESSING_TIMEOUT", "30"))
    
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
        
        if cls.MAX_IMAGE_SIZE_MB <= 0:
            errors.append("MAX_IMAGE_SIZE_MB must be positive")
        
        if cls.REDIS_CACHE_TTL <= 0:
            errors.append("REDIS_CACHE_TTL must be positive")
        
        if errors:
            raise ValueError(f"Configuration errors: {', '.join(errors)}")
        
        return True
    
    @classmethod
    def get_device(cls):
        """Get the appropriate device (CPU or GPU)."""
        if cls.USE_GPU:
            try:
                import torch
                if torch.cuda.is_available():
                    return f"cuda:{cls.GPU_DEVICE_ID}"
            except ImportError:
                pass
        return "cpu"
    
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
                "object_detection": cls.ENABLE_OBJECT_DETECTION,
                "ocr": cls.ENABLE_OCR,
                "clip": cls.ENABLE_CLIP,
                "nsfw_detection": cls.ENABLE_NSFW_DETECTION,
            },
            "models": {
                "yolo": cls.YOLO_MODEL,
                "clip": cls.CLIP_MODEL,
                "ocr_languages": cls.OCR_LANGUAGES,
                "device": cls.get_device(),
            },
            "limits": {
                "max_image_size_mb": cls.MAX_IMAGE_SIZE_MB,
                "max_image_dimension": cls.MAX_IMAGE_DIMENSION,
                "cache_ttl": cls.REDIS_CACHE_TTL,
            }
        }


# Global config instance
config = Config()
