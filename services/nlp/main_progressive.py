"""
Progressive NLP Service for Lost & Found
---------------------------------------
Starts fast with basic functionality, then loads advanced features
"""

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import Response
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any, Tuple
import logging
import hashlib
import json
import time
import os
import redis
import re
import string
from datetime import datetime
from collections import Counter
import asyncio

# Configure logging
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Progressive NLP Service",
    description="NLP service that starts fast and loads advanced features progressively",
    version="2.1.0"
)

# Global state
redis_client = None
advanced_features_loaded = False
STOPWORDS = set()
LEMMATIZER = None

# Pydantic models
class TextRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000, description="Text to process")
    normalize: bool = Field(True, description="Whether to normalize the text")
    remove_stopwords: bool = Field(True, description="Whether to remove stopwords")
    lemmatize: bool = Field(True, description="Whether to lemmatize words")

class TextResponse(BaseModel):
    processed_text: str
    original_length: int
    processed_length: int
    processing_time_ms: float
    cached: bool = False
    tokens: List[str] = []
    word_count: int = 0

class SimilarityRequest(BaseModel):
    text1: str = Field(..., min_length=1, max_length=2000, description="First text")
    text2: str = Field(..., min_length=1, max_length=2000, description="Second text")
    algorithm: str = Field("basic", description="Similarity algorithm: basic, fuzzy, combined")

class SimilarityResponse(BaseModel):
    similarity_score: float
    algorithm: str
    processing_time_ms: float
    cached: bool = False

class HealthResponse(BaseModel):
    status: str
    timestamp: str
    version: str = "2.1.0"
    redis_connected: bool
    cache_enabled: bool
    advanced_features_loaded: bool
    nltk_available: bool

# Basic text processing (always available)
def basic_preprocess_text(text: str, normalize: bool = True, remove_stopwords: bool = True, lemmatize: bool = True) -> Tuple[str, List[str]]:
    """Basic text preprocessing that works without NLTK."""
    if not text:
        return "", []
    
    original_text = text
    
    # Basic normalization
    if normalize:
        # Remove extra whitespace
        text = " ".join(text.split())
        # Convert to lowercase
        text = text.lower()
        # Remove punctuation
        text = text.translate(str.maketrans('', '', string.punctuation))
    
    # Basic tokenization
    tokens = text.split()
    
    # Basic stopword removal (common English words)
    basic_stopwords = {
        'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from',
        'has', 'he', 'in', 'is', 'it', 'its', 'of', 'on', 'that', 'the',
        'to', 'was', 'will', 'with', 'i', 'you', 'we', 'they', 'this',
        'these', 'those', 'or', 'but', 'if', 'when', 'where', 'why',
        'how', 'what', 'who', 'which', 'can', 'could', 'should', 'would'
    }
    
    if remove_stopwords:
        tokens = [token for token in tokens if token not in basic_stopwords]
    
    processed_text = " ".join(tokens)
    return processed_text, tokens

# Basic similarity calculation
def basic_similarity(text1: str, text2: str) -> float:
    """Basic similarity calculation using word overlap."""
    words1 = set(text1.lower().split())
    words2 = set(text2.lower().split())
    
    if not words1 and not words2:
        return 1.0
    if not words1 or not words2:
        return 0.0
    
    intersection = len(words1.intersection(words2))
    union = len(words1.union(words2))
    
    return intersection / union if union > 0 else 0.0

# Background task to load advanced features
async def load_advanced_features():
    """Load advanced NLP features in the background."""
    global advanced_features_loaded, STOPWORDS, LEMMATIZER
    
    try:
        logger.info("Loading advanced NLP features...")
        
        # Import NLTK components
        import nltk
        from nltk.corpus import stopwords
        from nltk.tokenize import word_tokenize
        from nltk.stem import WordNetLemmatizer
        
        # Download NLTK data
        nltk.download('punkt', quiet=True)
        nltk.download('stopwords', quiet=True)
        nltk.download('wordnet', quiet=True)
        
        # Initialize components
        STOPWORDS = set(stopwords.words('english'))
        LEMMATIZER = WordNetLemmatizer()
        
        advanced_features_loaded = True
        logger.info("✅ Advanced NLP features loaded successfully")
        
    except Exception as e:
        logger.warning(f"Failed to load advanced features: {e}")
        advanced_features_loaded = False

# Redis connection
async def get_cache(key: str) -> Optional[Dict]:
    """Get value from cache."""
    if not redis_client:
        return None
    try:
        value = redis_client.get(key)
        return json.loads(value) if value else None
    except:
        return None

async def set_cache(key: str, value: Dict, ttl: int = 3600):
    """Set value in cache."""
    if not redis_client:
        return
    try:
        redis_client.setex(key, ttl, json.dumps(value))
    except:
        pass

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup."""
    global redis_client
    
    # Initialize Redis connection
    try:
        redis_url = os.getenv("REDIS_URL", "redis://:LF_Redis_2025_Pass!@redis:6379/2")
        redis_client = redis.from_url(
            redis_url,
            decode_responses=True,
            socket_timeout=2,
            socket_connect_timeout=2,
            retry_on_timeout=True,
            health_check_interval=30
        )
        redis_client.ping()
        logger.info("Redis connection established")
    except Exception as e:
        logger.warning(f"Redis connection failed, continuing without cache: {e}")
        redis_client = None
    
    # Start loading advanced features in background
    asyncio.create_task(load_advanced_features())

@app.on_event("shutdown")
async def shutdown_event():
    """Close connections on shutdown."""
    global redis_client
    if redis_client:
        redis_client.close()
        logger.info("Redis connection closed")

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    redis_connected = False
    if redis_client:
        try:
            redis_client.ping()
            redis_connected = True
        except:
            pass
    
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now().isoformat(),
        redis_connected=redis_connected,
        cache_enabled=redis_client is not None,
        advanced_features_loaded=advanced_features_loaded,
        nltk_available=LEMMATIZER is not None
    )

@app.post("/process", response_model=TextResponse)
async def process_text(request: TextRequest):
    """Process text with basic or advanced features."""
    start_time = time.time()
    
    # Generate cache key
    cache_key = f"process:{hashlib.md5(request.text.encode()).hexdigest()}"
    
    # Try to get from cache
    cached_result = await get_cache(cache_key)
    if cached_result:
        cached_result["cached"] = True
        return TextResponse(**cached_result)
    
    # Process text
    if advanced_features_loaded and LEMMATIZER:
        # Use advanced processing
        processed_text, tokens = advanced_preprocess_text(
            request.text,
            request.normalize,
            request.remove_stopwords,
            request.lemmatize
        )
    else:
        # Use basic processing
        processed_text, tokens = basic_preprocess_text(
            request.text,
            request.normalize,
            request.remove_stopwords,
            request.lemmatize
        )
    
    processing_time = (time.time() - start_time) * 1000
    
    result = {
        "processed_text": processed_text,
        "original_length": len(request.text),
        "processed_length": len(processed_text),
        "processing_time_ms": processing_time,
        "cached": False,
        "tokens": tokens,
        "word_count": len(tokens)
    }
    
    # Cache result
    await set_cache(cache_key, result)
    
    return TextResponse(**result)

@app.post("/similarity", response_model=SimilarityResponse)
async def calculate_similarity(request: SimilarityRequest):
    """Calculate similarity between two texts."""
    start_time = time.time()
    
    # Generate cache key
    cache_key = f"similarity:{hashlib.md5(f'{request.text1}|{request.text2}|{request.algorithm}'.encode()).hexdigest()}"
    
    # Try to get from cache
    cached_result = await get_cache(cache_key)
    if cached_result:
        cached_result["cached"] = True
        return SimilarityResponse(**cached_result)
    
    # Calculate similarity
    if request.algorithm == "basic":
        similarity_score = basic_similarity(request.text1, request.text2)
    elif request.algorithm == "fuzzy" and advanced_features_loaded:
        # Use fuzzy matching if available
        try:
            from fuzzywuzzy import fuzz
            similarity_score = fuzz.ratio(request.text1, request.text2) / 100.0
        except:
            similarity_score = basic_similarity(request.text1, request.text2)
    else:
        similarity_score = basic_similarity(request.text1, request.text2)
    
    processing_time = (time.time() - start_time) * 1000
    
    result = {
        "similarity_score": similarity_score,
        "algorithm": request.algorithm,
        "processing_time_ms": processing_time,
        "cached": False
    }
    
    # Cache result
    await set_cache(cache_key, result)
    
    return SimilarityResponse(**result)

def advanced_preprocess_text(text: str, normalize: bool = True, remove_stopwords: bool = True, lemmatize: bool = True) -> Tuple[str, List[str]]:
    """Advanced text preprocessing using NLTK."""
    if not text or not LEMMATIZER:
        return basic_preprocess_text(text, normalize, remove_stopwords, lemmatize)
    
    original_text = text
    
    # Advanced normalization
    if normalize:
        text = " ".join(text.split())
        text = text.lower()
        text = text.translate(str.maketrans('', '', string.punctuation))
    
    # Advanced tokenization
    try:
        from nltk.tokenize import word_tokenize
        tokens = word_tokenize(text)
    except:
        tokens = text.split()
    
    # Advanced stopword removal
    if remove_stopwords and STOPWORDS:
        tokens = [token for token in tokens if token not in STOPWORDS]
    
    # Lemmatization
    if lemmatize and LEMMATIZER:
        tokens = [LEMMATIZER.lemmatize(token) for token in tokens]
    
    processed_text = " ".join(tokens)
    return processed_text, tokens

@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "Progressive NLP Service is running",
        "version": "2.1.0",
        "advanced_features_loaded": advanced_features_loaded,
        "redis_connected": redis_client is not None
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
