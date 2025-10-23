"""
Enhanced NLP Service
--------------------
Improved text processing service with better matching:
- Fuzzy text matching
- Semantic similarity
- Advanced text preprocessing
- Multiple similarity algorithms
- Better accuracy for Lost & Found matching
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

# Enhanced text processing imports
from fuzzywuzzy import fuzz, process
from textdistance import levenshtein, jaro_winkler, cosine
import nltk
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

# Configure logging
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Import configuration
from config import config

# Initialize Redis connection
redis_client = None

# Download NLTK data (only once)
try:
    nltk.download('punkt', quiet=True)
    nltk.download('stopwords', quiet=True)
    nltk.download('wordnet', quiet=True)
    nltk.download('omw-1.4', quiet=True)
except:
    logger.warning("NLTK data download failed, some features may not work")

# Initialize NLTK components
try:
    from nltk.corpus import stopwords
    from nltk.tokenize import word_tokenize
    from nltk.stem import WordNetLemmatizer
    
    STOPWORDS = set(stopwords.words('english'))
    LEMMATIZER = WordNetLemmatizer()
except:
    STOPWORDS = set()
    LEMMATIZER = None
    logger.warning("NLTK components not available, using basic processing")

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
    algorithm: str = Field("combined", description="Similarity algorithm: fuzzy, cosine, levenshtein, jaro_winkler, combined")

class SimilarityResponse(BaseModel):
    similarity_score: float
    algorithm: str
    processing_time_ms: float
    cached: bool = False

class MatchRequest(BaseModel):
    query_text: str = Field(..., min_length=1, max_length=2000, description="Query text to match")
    candidate_texts: List[str] = Field(..., min_items=1, max_items=50, description="List of candidate texts")
    algorithm: str = Field("combined", description="Matching algorithm")
    threshold: float = Field(0.7, ge=0.0, le=1.0, description="Minimum similarity threshold")

class MatchResponse(BaseModel):
    matches: List[Dict[str, Any]]
    total_candidates: int
    processing_time_ms: float
    cached: bool = False

class BatchTextRequest(BaseModel):
    texts: List[str] = Field(..., min_items=1, max_items=20, description="List of texts to process")
    normalize: bool = Field(True, description="Whether to normalize the texts")
    remove_stopwords: bool = Field(True, description="Whether to remove stopwords")
    lemmatize: bool = Field(True, description="Whether to lemmatize words")

class BatchTextResponse(BaseModel):
    results: List[TextResponse]
    total_processing_time_ms: float
    cached_count: int

class HealthResponse(BaseModel):
    status: str
    timestamp: str
    version: str = "2.0.0"
    redis_connected: bool
    cache_enabled: bool
    nltk_available: bool

# Initialize FastAPI app
app = FastAPI(
    title="Enhanced NLP Service",
    description="Enhanced NLP service for better text matching and similarity",
    version="2.0.0"
)

@app.on_event("startup")
async def startup_event():
    """Initialize Redis connection on startup."""
    global redis_client
    try:
        if config.ENABLE_REDIS_CACHE:
            redis_client = redis.from_url(
                config.REDIS_URL,
                decode_responses=True,
                socket_timeout=config.REDIS_TIMEOUT
            )
            redis_client.ping()  # Remove await - this is synchronous
            logger.info("Redis connection established")
        else:
            logger.info("Redis caching disabled")
    except Exception as e:
        logger.error(f"Failed to connect to Redis: {e}")
        redis_client = None

@app.on_event("shutdown")
async def shutdown_event():
    """Close Redis connection on shutdown."""
    global redis_client
    if redis_client:
        redis_client.close()  # Remove await - this is synchronous
        logger.info("Redis connection closed")

def preprocess_text(text: str, normalize: bool = True, remove_stopwords: bool = True, lemmatize: bool = True) -> Tuple[str, List[str]]:
    """Enhanced text preprocessing."""
    if not text:
        return "", []
    
    original_text = text
    
    # Basic normalization
    if normalize:
        # Remove extra whitespace
        text = " ".join(text.split())
        # Convert to lowercase
        text = text.lower()
        # Remove punctuation if configured
        if config.REMOVE_PUNCTUATION:
            text = text.translate(str.maketrans('', '', string.punctuation))
        # Remove numbers if configured
        if config.REMOVE_NUMBERS:
            text = re.sub(r'\d+', '', text)
    
    # Tokenize
    try:
        tokens = word_tokenize(text) if LEMMATIZER else text.split()
    except:
        tokens = text.split()
    
    # Remove stopwords
    if remove_stopwords and STOPWORDS:
        tokens = [token for token in tokens if token.lower() not in STOPWORDS]
    
    # Filter by minimum word length
    tokens = [token for token in tokens if len(token) >= config.MIN_WORD_LENGTH]
    
    # Lemmatize
    if lemmatize and LEMMATIZER:
        try:
            tokens = [LEMMATIZER.lemmatize(token) for token in tokens]
        except:
            pass
    
    processed_text = " ".join(tokens)
    return processed_text.strip(), tokens

def calculate_similarity(text1: str, text2: str, algorithm: str = "combined") -> float:
    """Calculate similarity between two texts using various algorithms."""
    if not text1 or not text2:
        return 0.0
    
    if algorithm == "fuzzy":
        return fuzz.ratio(text1, text2) / 100.0
    
    elif algorithm == "levenshtein":
        max_len = max(len(text1), len(text2))
        if max_len == 0:
            return 1.0
        distance = levenshtein(text1, text2)
        return 1.0 - (distance / max_len)
    
    elif algorithm == "jaro_winkler":
        return jaro_winkler(text1, text2)
    
    elif algorithm == "cosine":
        try:
            vectorizer = TfidfVectorizer()
            tfidf_matrix = vectorizer.fit_transform([text1, text2])
            similarity = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])[0][0]
            return similarity
        except:
            return 0.0
    
    elif algorithm == "combined":
        # Combine multiple algorithms for better accuracy
        fuzzy_score = fuzz.ratio(text1, text2) / 100.0
        jaro_score = jaro_winkler(text1, text2)
        
        try:
            vectorizer = TfidfVectorizer()
            tfidf_matrix = vectorizer.fit_transform([text1, text2])
            cosine_score = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])[0][0]
        except:
            cosine_score = 0.0
        
        # Weighted combination
        combined_score = (fuzzy_score * 0.4 + jaro_score * 0.3 + cosine_score * 0.3)
        return combined_score
    
    else:
        return fuzz.ratio(text1, text2) / 100.0

def get_cache_key(data: str, prefix: str = "nlp") -> str:
    """Generate cache key for text processing."""
    return f"{prefix}:{hashlib.md5(data.encode()).hexdigest()}"

async def get_from_cache(key: str) -> Optional[Dict]:
    """Get data from Redis cache."""
    if not redis_client:
        return None
    
    try:
        cached_data = redis_client.get(key)  # Remove await - this is synchronous
        if cached_data:
            return json.loads(cached_data)
    except Exception as e:
        logger.error(f"Cache get error: {e}")
    
    return None

async def set_cache(key: str, data: Dict) -> None:
    """Set data in Redis cache."""
    if not redis_client:
        return
    
    try:
        redis_client.setex(  # Remove await - this is synchronous
            key, 
            config.REDIS_CACHE_TTL, 
            json.dumps(data)
        )
    except Exception as e:
        logger.error(f"Cache set error: {e}")

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    redis_connected = False
    if redis_client:
        try:
            redis_client.ping()  # Remove await - this is synchronous
            redis_connected = True
        except:
            pass
    
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        redis_connected=redis_connected,
        cache_enabled=config.ENABLE_REDIS_CACHE,
        nltk_available=LEMMATIZER is not None
    )

@app.post("/process", response_model=TextResponse)
async def process_text(request: TextRequest):
    """Process a single text with enhanced preprocessing."""
    start_time = time.time()
    
    # Check cache first
    cache_data = f"{request.text}:{request.normalize}:{request.remove_stopwords}:{request.lemmatize}"
    cache_key = get_cache_key(cache_data, "process")
    cached_result = await get_from_cache(cache_key)
    
    if cached_result:
        cached_result["cached"] = True
        return TextResponse(**cached_result)
    
    # Process text
    original_length = len(request.text)
    processed_text, tokens = preprocess_text(
        request.text, 
        request.normalize, 
        request.remove_stopwords, 
        request.lemmatize
    )
    processed_length = len(processed_text)
    
    processing_time = (time.time() - start_time) * 1000
    
    result = {
        "processed_text": processed_text,
        "original_length": original_length,
        "processed_length": processed_length,
        "processing_time_ms": processing_time,
        "cached": False,
        "tokens": tokens,
        "word_count": len(tokens)
    }
    
    # Cache result
    await set_cache(cache_key, result)
    
    return TextResponse(**result)

@app.post("/similarity", response_model=SimilarityResponse)
async def calculate_text_similarity(request: SimilarityRequest):
    """Calculate similarity between two texts."""
    start_time = time.time()
    
    # Check cache first
    cache_data = f"{request.text1}:{request.text2}:{request.algorithm}"
    cache_key = get_cache_key(cache_data, "similarity")
    cached_result = await get_from_cache(cache_key)
    
    if cached_result:
        cached_result["cached"] = True
        return SimilarityResponse(**cached_result)
    
    # Preprocess texts
    text1_processed, _ = preprocess_text(request.text1)
    text2_processed, _ = preprocess_text(request.text2)
    
    # Calculate similarity
    similarity_score = calculate_similarity(text1_processed, text2_processed, request.algorithm)
    
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

@app.post("/match", response_model=MatchResponse)
async def find_best_matches(request: MatchRequest):
    """Find best matches for a query text against candidate texts."""
    start_time = time.time()
    
    # Check cache first
    cache_data = f"{request.query_text}:{':'.join(request.candidate_texts)}:{request.algorithm}:{request.threshold}"
    cache_key = get_cache_key(cache_data, "match")
    cached_result = await get_from_cache(cache_key)
    
    if cached_result:
        cached_result["cached"] = True
        return MatchResponse(**cached_result)
    
    # Preprocess query text
    query_processed, _ = preprocess_text(request.query_text)
    
    matches = []
    
    # Process each candidate
    for i, candidate_text in enumerate(request.candidate_texts):
        candidate_processed, _ = preprocess_text(candidate_text)
        
        # Calculate similarity
        similarity_score = calculate_similarity(query_processed, candidate_processed, request.algorithm)
        
        if similarity_score >= request.threshold:
            matches.append({
                "index": i,
                "text": candidate_text,
                "processed_text": candidate_processed,
                "similarity_score": similarity_score,
                "algorithm": request.algorithm
            })
    
    # Sort by similarity score (descending)
    matches.sort(key=lambda x: x["similarity_score"], reverse=True)
    
    # Limit results
    matches = matches[:config.MAX_MATCHES]
    
    processing_time = (time.time() - start_time) * 1000
    
    result = {
        "matches": matches,
        "total_candidates": len(request.candidate_texts),
        "processing_time_ms": processing_time,
        "cached": False
    }
    
    # Cache result
    await set_cache(cache_key, result)
    
    return MatchResponse(**result)

@app.post("/process/batch", response_model=BatchTextResponse)
async def process_batch(request: BatchTextRequest):
    """Process multiple texts."""
    start_time = time.time()
    results = []
    cached_count = 0
    
    for text in request.texts:
        # Check cache first
        cache_data = f"{text}:{request.normalize}:{request.remove_stopwords}:{request.lemmatize}"
        cache_key = get_cache_key(cache_data, "process")
        cached_result = await get_from_cache(cache_key)
        
        if cached_result:
            cached_result["cached"] = True
            results.append(TextResponse(**cached_result))
            cached_count += 1
        else:
            # Process text
            original_length = len(text)
            processed_text, tokens = preprocess_text(
                text, 
                request.normalize, 
                request.remove_stopwords, 
                request.lemmatize
            )
            processed_length = len(processed_text)
            
            processing_time = (time.time() - start_time) * 1000
            
            result = {
                "processed_text": processed_text,
                "original_length": original_length,
                "processed_length": processed_length,
                "processing_time_ms": processing_time,
                "cached": False,
                "tokens": tokens,
                "word_count": len(tokens)
            }
            
            # Cache result
            await set_cache(cache_key, result)
            results.append(TextResponse(**result))
    
    total_time = (time.time() - start_time) * 1000
    
    return BatchTextResponse(
        results=results,
        total_processing_time_ms=total_time,
        cached_count=cached_count
    )

@app.get("/config")
async def get_config():
    """Get current configuration."""
    return config.summary()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=config.HOST,
        port=config.PORT,
        log_level=config.LOG_LEVEL.lower(),
        workers=config.WORKERS
    )