"""
Enhanced Vision Service
----------------------
Improved image processing service with better matching:
- Multiple hash algorithms
- Advanced image similarity
- Image preprocessing
- Better accuracy for Lost & Found matching
"""

from fastapi import FastAPI, HTTPException, File, UploadFile, Request
from fastapi.responses import Response
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any, Tuple
from PIL import Image, ImageEnhance, ImageOps, ImageFilter
import imagehash
import io
import logging
import time
import hashlib
import json
import os
import redis
import numpy as np
import asyncio
import cv2
from datetime import datetime
from scipy.spatial.distance import hamming
from skimage import metrics
from skimage.feature import local_binary_pattern
from skimage.filters import gaussian

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

# Pydantic models
class ImageHashResponse(BaseModel):
    phash: str
    dhash: str
    ahash: str
    whash: str
    image_size: Dict[str, int]
    file_size_bytes: int
    processing_time_ms: float
    cached: bool = False
    quality_score: float = 0.0

class ImageInfoResponse(BaseModel):
    width: int
    height: int
    format: str
    mode: str
    file_size_bytes: int
    processing_time_ms: float
    cached: bool = False
    quality_metrics: Dict[str, float] = {}

class SimilarityRequest(BaseModel):
    hash1: str = Field(..., description="First image hash")
    hash2: str = Field(..., description="Second image hash")
    algorithm: str = Field("combined", description="Similarity algorithm: hamming, cosine, combined")

class SimilarityResponse(BaseModel):
    similarity_score: float
    hamming_distance: int
    algorithm: str
    processing_time_ms: float
    cached: bool = False

class MatchRequest(BaseModel):
    query_hash: str = Field(..., description="Query image hash")
    candidate_hashes: List[Dict[str, str]] = Field(..., min_items=1, max_items=100, description="List of candidate hashes with metadata")
    algorithm: str = Field("combined", description="Matching algorithm")
    threshold: float = Field(0.8, ge=0.0, le=1.0, description="Minimum similarity threshold")

class MatchResponse(BaseModel):
    matches: List[Dict[str, Any]]
    total_candidates: int
    processing_time_ms: float
    cached: bool = False

class BatchImageResponse(BaseModel):
    results: List[ImageHashResponse]
    total_processing_time_ms: float
    cached_count: int

class HealthResponse(BaseModel):
    status: str
    timestamp: str
    version: str = "2.0.0"
    redis_connected: bool
    cache_enabled: bool
    opencv_available: bool

# Initialize FastAPI app
app = FastAPI(
    title="Enhanced Vision Service",
    description="Enhanced Vision service for better image matching and similarity",
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
            await asyncio.to_thread(redis_client.ping)
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
        await asyncio.to_thread(redis_client.close)
        logger.info("Redis connection closed")

def validate_image_format(filename: str) -> bool:
    """Validate image format."""
    if not filename:
        return False
    
    extension = filename.lower().split('.')[-1]
    return extension in config.SUPPORTED_FORMATS

def validate_image_size(file_size_bytes: int) -> bool:
    """Validate image size."""
    max_size_bytes = config.MAX_IMAGE_SIZE_MB * 1024 * 1024
    return file_size_bytes <= max_size_bytes

def preprocess_image(image: Image.Image) -> Image.Image:
    """Enhanced image preprocessing for better hashing."""
    # Convert to RGB if necessary
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    # Resize for consistent hashing
    if config.RESIZE_FOR_HASHING:
        image = image.resize((config.HASH_RESIZE_SIZE, config.HASH_RESIZE_SIZE), Image.Resampling.LANCZOS)
    
    # Normalize brightness
    if config.NORMALIZE_BRIGHTNESS:
        # Convert to numpy array for processing
        img_array = np.array(image)
        
        # Calculate mean brightness
        mean_brightness = np.mean(img_array)
        target_brightness = 128
        
        # Adjust brightness
        if mean_brightness != 0:
            brightness_factor = target_brightness / mean_brightness
            img_array = np.clip(img_array * brightness_factor, 0, 255)
        
        image = Image.fromarray(img_array.astype(np.uint8))
    
    # Enhance contrast
    if config.ENHANCE_CONTRAST:
        enhancer = ImageEnhance.Contrast(image)
        image = enhancer.enhance(1.2)  # Slight contrast enhancement
    
    return image

def calculate_image_quality(image: Image.Image) -> Dict[str, float]:
    """Calculate image quality metrics."""
    try:
        # Convert to grayscale for analysis
        gray = image.convert('L')
        img_array = np.array(gray)
        
        # Calculate sharpness using Laplacian variance
        laplacian_var = cv2.Laplacian(img_array, cv2.CV_64F).var()
        
        # Calculate brightness
        brightness = np.mean(img_array)
        
        # Calculate contrast (standard deviation)
        contrast = np.std(img_array)
        
        # Calculate noise level
        noise_level = np.std(cv2.GaussianBlur(img_array, (5, 5), 0) - img_array)
        
        return {
            "sharpness": float(laplacian_var),
            "brightness": float(brightness),
            "contrast": float(contrast),
            "noise_level": float(noise_level)
        }
    except Exception as e:
        logger.error(f"Quality calculation error: {e}")
        return {
            "sharpness": 0.0,
            "brightness": 0.0,
            "contrast": 0.0,
            "noise_level": 0.0
        }

def generate_multiple_hashes(image: Image.Image) -> Dict[str, str]:
    """Generate multiple types of perceptual hashes."""
    try:
        # Preprocess image
        processed_image = preprocess_image(image)
        
        # Generate different types of hashes
        hashes = {
            "phash": str(imagehash.phash(processed_image, hash_size=config.HASH_SIZE)),
            "dhash": str(imagehash.dhash(processed_image, hash_size=config.HASH_SIZE)),
            "ahash": str(imagehash.average_hash(processed_image, hash_size=config.HASH_SIZE)),
            "whash": str(imagehash.whash(processed_image, hash_size=config.HASH_SIZE))
        }
        
        return hashes
    except Exception as e:
        logger.error(f"Hash generation error: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate image hashes")

def calculate_hash_similarity(hash1: str, hash2: str, algorithm: str = "combined") -> Tuple[float, int]:
    """Calculate similarity between two hashes."""
    try:
        # Convert hex strings to binary
        hash1_bin = bin(int(hash1, 16))[2:].zfill(len(hash1) * 4)
        hash2_bin = bin(int(hash2, 16))[2:].zfill(len(hash2) * 4)
        
        # Calculate Hamming distance
        hamming_dist = hamming_distance(hash1_bin, hash2_bin)
        
        if algorithm == "hamming":
            # Normalize Hamming distance to similarity score
            max_distance = len(hash1_bin)
            similarity = 1.0 - (hamming_dist / max_distance)
            return similarity, hamming_dist
        
        elif algorithm == "cosine":
            # Convert to vectors for cosine similarity
            vec1 = np.array([int(b) for b in hash1_bin])
            vec2 = np.array([int(b) for b in hash2_bin])
            
            # Calculate cosine similarity
            dot_product = np.dot(vec1, vec2)
            norm1 = np.linalg.norm(vec1)
            norm2 = np.linalg.norm(vec2)
            
            if norm1 == 0 or norm2 == 0:
                similarity = 0.0
            else:
                similarity = dot_product / (norm1 * norm2)
            
            return similarity, hamming_dist
        
        elif algorithm == "combined":
            # Combine Hamming and cosine similarity
            max_distance = len(hash1_bin)
            hamming_sim = 1.0 - (hamming_dist / max_distance)
            
            vec1 = np.array([int(b) for b in hash1_bin])
            vec2 = np.array([int(b) for b in hash2_bin])
            
            dot_product = np.dot(vec1, vec2)
            norm1 = np.linalg.norm(vec1)
            norm2 = np.linalg.norm(vec2)
            
            if norm1 == 0 or norm2 == 0:
                cosine_sim = 0.0
            else:
                cosine_sim = dot_product / (norm1 * norm2)
            
            # Weighted combination
            combined_sim = (hamming_sim * 0.7 + cosine_sim * 0.3)
            return combined_sim, hamming_dist
        
        else:
            # Default to Hamming similarity
            max_distance = len(hash1_bin)
            similarity = 1.0 - (hamming_dist / max_distance)
            return similarity, hamming_dist
    
    except Exception as e:
        logger.error(f"Similarity calculation error: {e}")
        return 0.0, 0

def hamming_distance(s1: str, s2: str) -> int:
    """Calculate Hamming distance between two binary strings."""
    if len(s1) != len(s2):
        return max(len(s1), len(s2))
    
    return sum(c1 != c2 for c1, c2 in zip(s1, s2))

def get_cache_key(data: str, prefix: str = "vision") -> str:
    """Generate cache key for image processing."""
    return f"{prefix}:{hashlib.md5(data.encode()).hexdigest()}"

async def get_from_cache(key: str) -> Optional[Dict]:
    """Get data from Redis cache."""
    if not redis_client:
        return None
    
    try:
        cached_data = await asyncio.to_thread(redis_client.get, key)
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
        await asyncio.to_thread(
            redis_client.setex, 
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
            await asyncio.to_thread(redis_client.ping)
            redis_connected = True
        except:
            pass
    
    opencv_available = True
    try:
        cv2.Laplacian(np.zeros((10, 10), dtype=np.uint8), cv2.CV_64F)
    except:
        opencv_available = False
    
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        redis_connected=redis_connected,
        cache_enabled=config.ENABLE_REDIS_CACHE,
        opencv_available=opencv_available
    )

@app.post("/hash", response_model=ImageHashResponse)
async def generate_image_hash(file: UploadFile = File(...)):
    """Generate multiple perceptual hashes for uploaded image."""
    start_time = time.time()
    
    # Validate file
    if not validate_image_format(file.filename):
        raise HTTPException(status_code=400, detail="Invalid image file")
    
    # Read file content
    file_content = await file.read()
    file_size = len(file_content)
    
    # Check file size
    if not validate_image_size(file_size):
        raise HTTPException(
            status_code=400, 
            detail=f"Image too large. Max size: {config.MAX_IMAGE_SIZE_MB}MB"
        )
    
    # Check cache first
    cache_key = get_cache_key(str(file_content), "hash")
    cached_result = await get_from_cache(cache_key)
    
    if cached_result:
        cached_result["cached"] = True
        return ImageHashResponse(**cached_result)
    
    try:
        # Open image
        image = Image.open(io.BytesIO(file_content))
        
        # Validate image dimensions
        if image.width > config.MAX_IMAGE_DIMENSION or image.height > config.MAX_IMAGE_DIMENSION:
            raise HTTPException(
                status_code=400,
                detail=f"Image too large. Max dimension: {config.MAX_IMAGE_DIMENSION}px"
            )
        
        # Generate hashes
        hashes = generate_multiple_hashes(image)
        
        # Calculate quality metrics
        quality_metrics = calculate_image_quality(image)
        quality_score = quality_metrics["sharpness"] / 1000.0  # Normalize sharpness
        
        processing_time = (time.time() - start_time) * 1000
        
        result = {
            "phash": hashes["phash"],
            "dhash": hashes["dhash"],
            "ahash": hashes["ahash"],
            "whash": hashes["whash"],
            "image_size": {
                "width": image.width,
                "height": image.height
            },
            "file_size_bytes": file_size,
            "processing_time_ms": processing_time,
            "cached": False,
            "quality_score": quality_score
        }
        
        # Cache result
        await set_cache(cache_key, result)
        
        return ImageHashResponse(**result)
        
    except Exception as e:
        logger.error(f"Image processing error: {e}")
        raise HTTPException(status_code=500, detail="Failed to process image")

@app.post("/similarity", response_model=SimilarityResponse)
async def calculate_image_similarity(request: SimilarityRequest):
    """Calculate similarity between two image hashes."""
    start_time = time.time()
    
    # Check cache first
    cache_data = f"{request.hash1}:{request.hash2}:{request.algorithm}"
    cache_key = get_cache_key(cache_data, "similarity")
    cached_result = await get_from_cache(cache_key)
    
    if cached_result:
        cached_result["cached"] = True
        return SimilarityResponse(**cached_result)
    
    # Calculate similarity
    similarity_score, hamming_dist = calculate_hash_similarity(
        request.hash1, 
        request.hash2, 
        request.algorithm
    )
    
    processing_time = (time.time() - start_time) * 1000
    
    result = {
        "similarity_score": similarity_score,
        "hamming_distance": hamming_dist,
        "algorithm": request.algorithm,
        "processing_time_ms": processing_time,
        "cached": False
    }
    
    # Cache result
    await set_cache(cache_key, result)
    
    return SimilarityResponse(**result)

@app.post("/match", response_model=MatchResponse)
async def find_best_matches(request: MatchRequest):
    """Find best matches for a query image hash against candidate hashes."""
    start_time = time.time()
    
    # Check cache first
    cache_data = f"{request.query_hash}:{len(request.candidate_hashes)}:{request.algorithm}:{request.threshold}"
    cache_key = get_cache_key(cache_data, "match")
    cached_result = await get_from_cache(cache_key)
    
    if cached_result:
        cached_result["cached"] = True
        return MatchResponse(**cached_result)
    
    matches = []
    
    # Process each candidate
    for i, candidate in enumerate(request.candidate_hashes):
        # Use phash for matching (most reliable)
        candidate_hash = candidate.get("phash", candidate.get("hash", ""))
        
        if not candidate_hash:
            continue
        
        # Calculate similarity
        similarity_score, hamming_dist = calculate_hash_similarity(
            request.query_hash, 
            candidate_hash, 
            request.algorithm
        )
        
        if similarity_score >= request.threshold:
            matches.append({
                "index": i,
                "hash": candidate_hash,
                "similarity_score": similarity_score,
                "hamming_distance": hamming_dist,
                "algorithm": request.algorithm,
                "metadata": candidate.get("metadata", {})
            })
    
    # Sort by similarity score (descending)
    matches.sort(key=lambda x: x["similarity_score"], reverse=True)
    
    # Limit results
    matches = matches[:config.MAX_MATCHES]
    
    processing_time = (time.time() - start_time) * 1000
    
    result = {
        "matches": matches,
        "total_candidates": len(request.candidate_hashes),
        "processing_time_ms": processing_time,
        "cached": False
    }
    
    # Cache result
    await set_cache(cache_key, result)
    
    return MatchResponse(**result)

@app.post("/info", response_model=ImageInfoResponse)
async def get_image_info(file: UploadFile = File(...)):
    """Get detailed information about uploaded image."""
    start_time = time.time()
    
    # Validate file
    if not validate_image_format(file.filename):
        raise HTTPException(status_code=400, detail="Invalid image file")
    
    # Read file content
    file_content = await file.read()
    file_size = len(file_content)
    
    # Check file size
    if not validate_image_size(file_size):
        raise HTTPException(
            status_code=400, 
            detail=f"Image too large. Max size: {config.MAX_IMAGE_SIZE_MB}MB"
        )
    
    try:
        # Open image
        image = Image.open(io.BytesIO(file_content))
        
        # Calculate quality metrics
        quality_metrics = calculate_image_quality(image)
        
        processing_time = (time.time() - start_time) * 1000
        
        return ImageInfoResponse(
            width=image.width,
            height=image.height,
            format=image.format or "unknown",
            mode=image.mode,
            file_size_bytes=file_size,
            processing_time_ms=processing_time,
            cached=False,
            quality_metrics=quality_metrics
        )
        
    except Exception as e:
        logger.error(f"Image info error: {e}")
        raise HTTPException(status_code=500, detail="Failed to get image info")

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