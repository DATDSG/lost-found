"""
Enhanced Configuration for Vision Service
----------------------------------------
Improved configuration for better image matching:
- Multiple hash algorithms
- Image similarity analysis
- Advanced image preprocessing
- Better accuracy for Lost & Found matching
"""
import os
from typing import Optional


class Config:
    """Enhanced configuration for better image matching."""
    
    # Server Configuration
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8002"))
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    WORKERS: int = int(os.getenv("WORKERS", "1"))
    
    # Redis Configuration
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://redis:6379/3")
    REDIS_CACHE_TTL: int = int(os.getenv("REDIS_CACHE_TTL", "3600"))  # 1 hour
    REDIS_TIMEOUT: int = int(os.getenv("REDIS_TIMEOUT", "5"))
    
    # Cache Configuration
    ENABLE_REDIS_CACHE: bool = os.getenv("ENABLE_REDIS_CACHE", "true").lower() == "true"
    LRU_CACHE_SIZE: int = int(os.getenv("LRU_CACHE_SIZE", "500"))
    
    # Image Processing
    MAX_IMAGE_SIZE_MB: int = int(os.getenv("MAX_IMAGE_SIZE_MB", "10"))
    MAX_IMAGE_DIMENSION: int = int(os.getenv("MAX_IMAGE_DIMENSION", "4096"))
    SUPPORTED_FORMATS: list = os.getenv("SUPPORTED_FORMATS", "jpg,jpeg,png,webp,bmp").split(",")
    
    # Hash Configuration
    HASH_SIZE: int = int(os.getenv("HASH_SIZE", "8"))  # 8x8 = 64-bit hash
    ENABLE_MULTIPLE_HASHES: bool = os.getenv("ENABLE_MULTIPLE_HASHES", "true").lower() == "true"
    
    # Similarity Configuration
    SIMILARITY_THRESHOLD: float = float(os.getenv("SIMILARITY_THRESHOLD", "0.8"))
    HASH_THRESHOLD_SIMILAR: int = int(os.getenv("HASH_THRESHOLD_SIMILAR", "10"))
    HASH_THRESHOLD_MATCH: int = int(os.getenv("HASH_THRESHOLD_MATCH", "5"))
    MAX_MATCHES: int = int(os.getenv("MAX_MATCHES", "20"))
    
    # Image Preprocessing
    RESIZE_FOR_HASHING: bool = os.getenv("RESIZE_FOR_HASHING", "true").lower() == "true"
    HASH_RESIZE_SIZE: int = int(os.getenv("HASH_RESIZE_SIZE", "32"))
    NORMALIZE_BRIGHTNESS: bool = os.getenv("NORMALIZE_BRIGHTNESS", "true").lower() == "true"
    ENHANCE_CONTRAST: bool = os.getenv("ENHANCE_CONTRAST", "true").lower() == "true"
    
    # Quality Assessment
    QUALITY_MIN_SHARPNESS: float = float(os.getenv("QUALITY_MIN_SHARPNESS", "50.0"))
    QUALITY_MIN_BRIGHTNESS: float = float(os.getenv("QUALITY_MIN_BRIGHTNESS", "30.0"))
    QUALITY_MAX_BRIGHTNESS: float = float(os.getenv("QUALITY_MAX_BRIGHTNESS", "220.0"))
    
    # CORS
    CORS_ORIGINS: list = os.getenv("CORS_ORIGINS", "*").split(",")
    
    # Timeouts
    PROCESSING_TIMEOUT: int = int(os.getenv("PROCESSING_TIMEOUT", "15"))
    
    @classmethod
    def validate(cls):
        """Validate configuration."""
        errors = []
        
        if cls.MAX_IMAGE_SIZE_MB <= 0:
            errors.append("MAX_IMAGE_SIZE_MB must be positive")
        
        if cls.MAX_IMAGE_DIMENSION <= 0:
            errors.append("MAX_IMAGE_DIMENSION must be positive")
        
        if cls.REDIS_CACHE_TTL <= 0:
            errors.append("REDIS_CACHE_TTL must be positive")
        
        if not 0 <= cls.SIMILARITY_THRESHOLD <= 1:
            errors.append("SIMILARITY_THRESHOLD must be between 0 and 1")
        
        if cls.HASH_SIZE <= 0:
            errors.append("HASH_SIZE must be positive")
        
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
            "caching": {
                "redis": cls.ENABLE_REDIS_CACHE,
                "lru_size": cls.LRU_CACHE_SIZE,
                "ttl": cls.REDIS_CACHE_TTL,
            },
            "image_processing": {
                "max_size_mb": cls.MAX_IMAGE_SIZE_MB,
                "max_dimension": cls.MAX_IMAGE_DIMENSION,
                "supported_formats": cls.SUPPORTED_FORMATS,
                "hash_size": cls.HASH_SIZE,
                "multiple_hashes": cls.ENABLE_MULTIPLE_HASHES,
            },
            "matching": {
                "similarity_threshold": cls.SIMILARITY_THRESHOLD,
                "hash_threshold_similar": cls.HASH_THRESHOLD_SIMILAR,
                "hash_threshold_match": cls.HASH_THRESHOLD_MATCH,
                "max_matches": cls.MAX_MATCHES,
            },
            "preprocessing": {
                "resize_for_hashing": cls.RESIZE_FOR_HASHING,
                "hash_resize_size": cls.HASH_RESIZE_SIZE,
                "normalize_brightness": cls.NORMALIZE_BRIGHTNESS,
                "enhance_contrast": cls.ENHANCE_CONTRAST,
            }
        }


# Global config instance
config = Config()