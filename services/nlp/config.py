"""
Enhanced Configuration for NLP Service
-------------------------------------
Improved configuration for better text matching:
- Fuzzy text matching
- Semantic similarity
- Text preprocessing
- Multiple similarity algorithms
"""
import os
from typing import Optional


class Config:
    """Enhanced configuration for better text matching."""
    
    # Server Configuration
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8001"))
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    WORKERS: int = int(os.getenv("WORKERS", "1"))
    
    # Redis Configuration
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://redis:6379/2")
    REDIS_CACHE_TTL: int = int(os.getenv("REDIS_CACHE_TTL", "3600"))  # 1 hour
    REDIS_TIMEOUT: int = int(os.getenv("REDIS_TIMEOUT", "5"))
    
    # Cache Configuration
    ENABLE_REDIS_CACHE: bool = os.getenv("ENABLE_REDIS_CACHE", "true").lower() == "true"
    LRU_CACHE_SIZE: int = int(os.getenv("LRU_CACHE_SIZE", "500"))
    
    # Text Processing Configuration
    MAX_TEXT_LENGTH: int = int(os.getenv("MAX_TEXT_LENGTH", "2000"))
    NORMALIZE_TEXT: bool = os.getenv("NORMALIZE_TEXT", "true").lower() == "true"
    REMOVE_STOPWORDS: bool = os.getenv("REMOVE_STOPWORDS", "true").lower() == "true"
    LEMMATIZE_TEXT: bool = os.getenv("LEMMATIZE_TEXT", "true").lower() == "true"
    
    # Matching Configuration
    SIMILARITY_THRESHOLD: float = float(os.getenv("SIMILARITY_THRESHOLD", "0.7"))
    FUZZY_MATCH_THRESHOLD: int = int(os.getenv("FUZZY_MATCH_THRESHOLD", "80"))
    MAX_MATCHES: int = int(os.getenv("MAX_MATCHES", "10"))
    
    # Text Preprocessing
    MIN_WORD_LENGTH: int = int(os.getenv("MIN_WORD_LENGTH", "2"))
    REMOVE_PUNCTUATION: bool = os.getenv("REMOVE_PUNCTUATION", "true").lower() == "true"
    REMOVE_NUMBERS: bool = os.getenv("REMOVE_NUMBERS", "false").lower() == "true"
    
    # CORS
    CORS_ORIGINS: list = os.getenv("CORS_ORIGINS", "*").split(",")
    
    # Timeouts
    PROCESSING_TIMEOUT: int = int(os.getenv("PROCESSING_TIMEOUT", "15"))
    
    @classmethod
    def validate(cls):
        """Validate configuration."""
        errors = []
        
        if cls.REDIS_CACHE_TTL <= 0:
            errors.append("REDIS_CACHE_TTL must be positive")
        
        if cls.MAX_TEXT_LENGTH <= 0:
            errors.append("MAX_TEXT_LENGTH must be positive")
        
        if not 0 <= cls.SIMILARITY_THRESHOLD <= 1:
            errors.append("SIMILARITY_THRESHOLD must be between 0 and 1")
        
        if not 0 <= cls.FUZZY_MATCH_THRESHOLD <= 100:
            errors.append("FUZZY_MATCH_THRESHOLD must be between 0 and 100")
        
        if errors:
            raise ValueError(f"Configuration errors: {', '.join(errors)}")
        
        return True
    
    @classmethod
    def summary(cls) -> dict:
        """Get configuration summary."""
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
            "processing": {
                "max_text_length": cls.MAX_TEXT_LENGTH,
                "normalize_text": cls.NORMALIZE_TEXT,
                "remove_stopwords": cls.REMOVE_STOPWORDS,
                "lemmatize_text": cls.LEMMATIZE_TEXT,
            },
            "matching": {
                "similarity_threshold": cls.SIMILARITY_THRESHOLD,
                "fuzzy_threshold": cls.FUZZY_MATCH_THRESHOLD,
                "max_matches": cls.MAX_MATCHES,
            }
        }


# Global config instance
config = Config()