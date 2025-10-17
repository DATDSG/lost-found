"""Vision Service v2.0 - CPU-only image hashing, quality assessment, duplication checks.

This module implements a FastAPI service that:
- Computes perceptual hashes (pHash, dHash, aHash, wHash, colorHash)
- Assesses basic image quality (sharpness, brightness, contrast, noise)
- Detects duplicates by Hamming distance comparisons
- Optionally extracts dominant colors
- Uses Redis for optional caching
- Exposes Prometheus metrics and health endpoints
- Provides simple rate limiting via slowapi when enabled
"""

from fastapi import FastAPI, HTTPException, File, UploadFile, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Tuple, Any
from PIL import Image, ImageEnhance, ImageOps, ExifTags
from collections import Counter
from contextlib import asynccontextmanager
from functools import lru_cache
from datetime import datetime
import imagehash
import io
import logging
import time
import hashlib
import json
import os
import numpy as np
import cv2
import structlog
from tenacity import retry, stop_after_attempt, wait_exponential

from config import config
from minio_client import get_vision_minio_client

# Optional production integrations
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
import redis.asyncio as redis
from redis.asyncio import Redis
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Configuration with environment overrides
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")
REDIS_CACHE_TTL = int(os.getenv("REDIS_CACHE_TTL", "86400"))
ENABLE_METRICS = os.getenv("ENABLE_METRICS", "true").lower() == "true"
ENABLE_RATE_LIMIT = os.getenv("ENABLE_RATE_LIMIT", "true").lower() == "true"

MAX_IMAGE_SIZE_MB = 10
MAX_IMAGE_DIMENSION = 4096
SUPPORTED_FORMATS = {"JPEG", "PNG", "JPG", "WEBP"}
HASH_THRESHOLD_SIMILAR = 10
HASH_THRESHOLD_MATCH = 14
LRU_CACHE_SIZE = int(os.getenv("LRU_CACHE_SIZE", "1000"))

# Configure structured logging
structlog.configure(
    processors=[
        
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger(__name__)

# Runtime state for optional services
redis_client: Optional[Redis] = None
minio_client = None

# Prometheus metrics objects (created only when enabled)
if ENABLE_METRICS:
    hash_requests = Counter('vision_hash_requests_total', 'Total hash requests')
    hash_duration = Histogram('vision_hash_duration_seconds', 'Hash generation duration')
    cache_hits = Counter('vision_cache_hits_total', 'Cache hits', ['cache_type'])
    cache_misses = Counter('vision_cache_misses_total', 'Cache misses', ['cache_type'])
    active_requests = Gauge('vision_active_requests', 'Currently processing requests')
    redis_operations = Counter('vision_redis_operations_total', 'Redis operations', ['operation', 'status'])
    quality_score_histogram = Histogram('vision_image_quality_score', 'Image quality scores')
    duplicate_detection = Counter('vision_duplicate_detection_total', 'Duplicate detection results', ['is_duplicate'])

# Optional rate limiter instance
limiter = Limiter(key_func=get_remote_address) if ENABLE_RATE_LIMIT else None

SERVICE_START_TIME = time.time()

# Lifecycle handlers: set up Redis when app starts, and clean up on shutdown.
@asynccontextmanager
async def lifespan(app: FastAPI):
    global redis_client, minio_client

    logger.info("Starting Vision Service", version="2.1.0")

    # Initialize MinIO client
    try:
        minio_client = get_vision_minio_client()
        logger.info("MinIO client initialized successfully")
    except Exception as e:
        logger.error(f"MinIO client initialization failed: {str(e)}")
        minio_client = None

    # Attempt to connect to Redis; if it fails, continue without caching.
    try:
        redis_client = redis.from_url(REDIS_URL, encoding="utf-8", decode_responses=True)
        await redis_client.ping()
        logger.info("Redis connected successfully")
    except Exception as e:
        logger.warning("Redis connection failed", error=str(e), fallback="local_cache_only")
        redis_client = None

    logger.info("Vision service ready", processing_mode="cpu_only")
    yield

    # Shutdown: close connections if present.
    logger.info("Shutting down Vision Service")
    if redis_client:
        await redis_client.close()

# FastAPI application instance with lifespan
app = FastAPI(
    title="Vision Service v2.1",
    version="2.1.0",
    description="CPU-only computer vision with enhanced image processing and performance",
    lifespan=lifespan
)

# Allow cross-origin requests from any origin (adjust for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register rate limit handler if enabled
if ENABLE_RATE_LIMIT:
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# API response and request models: structured JSON payloads for clarity
class HashResponse(BaseModel):
    phash: str
    dhash: str
    avg_hash: str
    whash: Optional[str] = None
    colorhash: Optional[str] = None
    dominant_colors: Optional[List[str]] = None
    processing_time_ms: float
    cached: bool = False

class ImageQualityResponse(BaseModel):
    overall_score: float
    sharpness: float
    brightness: float
    contrast: float
    noise_level: float
    is_acceptable: bool
    issues: List[str]

class DuplicateDetectionResponse(BaseModel):
    is_duplicate: bool
    confidence: float
    matched_hash: Optional[str] = None
    similarity_score: float

class CompareResponse(BaseModel):
    hamming_distance: int
    similarity: float
    is_similar: bool
    is_potential_match: bool
    interpretation: str

class MultiHashCompareRequest(BaseModel):
    hashes1: Dict[str, str]
    hashes2: Dict[str, str]

class MultiHashCompareResponse(BaseModel):
    comparisons: Dict[str, CompareResponse]
    weighted_similarity: float
    overall_match: bool

class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    timestamp: str
    uptime_seconds: float
    redis_connected: bool

# Utility helpers

def generate_image_hash(image_bytes: bytes) -> str:
    """Return a SHA256 hex string for the raw image bytes (used as cache key)."""
    return hashlib.sha256(image_bytes).hexdigest()

async def get_from_cache(key: str) -> Optional[Any]:
    """Fetch a JSON-serializable value from Redis, returning deserialized object or None."""
    if not redis_client:
        return None
    try:
        value = await redis_client.get(key)
        if value:
            if ENABLE_METRICS:
                cache_hits.labels(cache_type='redis').inc()
            return json.loads(value)
        else:
            if ENABLE_METRICS:
                cache_misses.labels(cache_type='redis').inc()
            return None
    except Exception as e:
        logger.warning(f"Cache get error: {e}")
        if ENABLE_METRICS:
            redis_operations.labels(operation='get', status='error').inc()
        return None

async def set_to_cache(key: str, value: Any, ttl: int = REDIS_CACHE_TTL):
    """Store a JSON-serializable value in Redis with TTL; silently ignore if Redis missing."""
    if not redis_client:
        return
    try:
        await redis_client.setex(key, ttl, json.dumps(value))
        if ENABLE_METRICS:
            redis_operations.labels(operation='set', status='success').inc()
    except Exception as e:
        logger.warning(f"Cache set error: {e}")
        if ENABLE_METRICS:
            redis_operations.labels(operation='set', status='error').inc()

def fix_image_orientation(image: Image.Image) -> Image.Image:
    """Rotate image according to EXIF Orientation tag so returned image is upright."""
    try:
        orientation_tag = None
        for tag, name in ExifTags.TAGS.items():
            if name == 'Orientation':
                orientation_tag = tag
                break

        exif = image._getexif()
        if exif is not None and orientation_tag in exif:
            orientation_value = exif.get(orientation_tag)
            if orientation_value == 3:
                image = image.rotate(180, expand=True)
            elif orientation_value == 6:
                image = image.rotate(270, expand=True)
            elif orientation_value == 8:
                image = image.rotate(90, expand=True)
    except Exception:
        # Non-fatal: many images lack EXIF or expose different interfaces.
        pass
    return image

def strip_exif(image: Image.Image) -> Image.Image:
    """Return a copy of the image without EXIF metadata for privacy."""
    try:
        data = list(image.getdata())
        image_without_exif = Image.new(image.mode, image.size)
        image_without_exif.putdata(data)
        return image_without_exif
    except Exception as e:
        logger.warning(f"Failed to strip EXIF: {e}")
        return image

def validate_image(file: UploadFile, contents: bytes) -> Image.Image:
    """Validate basic constraints (size, format, dimensions) and return a PIL Image."""
    size_mb = len(contents) / (1024 * 1024)
    if size_mb > MAX_IMAGE_SIZE_MB:
        raise HTTPException(status_code=413, detail=f"Image too large: {size_mb:.2f}MB (max {MAX_IMAGE_SIZE_MB}MB)")

    try:
        image = Image.open(io.BytesIO(contents))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image: {str(e)}")

    if image.format not in SUPPORTED_FORMATS:
        raise HTTPException(status_code=400, detail=f"Unsupported format: {image.format}")

    width, height = image.size
    if width > MAX_IMAGE_DIMENSION or height > MAX_IMAGE_DIMENSION:
        raise HTTPException(status_code=413, detail=f"Dimensions too large: {width}x{height}")

    return image

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=8))
def calculate_all_hashes(image: Image.Image) -> Dict[str, str]:
    """Compute and return several perceptual hashes as hex strings with retry logic."""
    if image.mode not in ['RGB', 'L']:
        image = image.convert('RGB')

    hashes = {
        'phash': str(imagehash.phash(image)),
        'dhash': str(imagehash.dhash(image)),
        'avg_hash': str(imagehash.average_hash(image)),
    }
    try:
        hashes['whash'] = str(imagehash.whash(image))
    except Exception:
        hashes['whash'] = None

    try:
        hashes['colorhash'] = str(imagehash.colorhash(image))
    except Exception:
        hashes['colorhash'] = None

    return hashes

def get_dominant_colors(image: Image.Image, num_colors: int = 5) -> List[str]:
    """Return a list of dominant color hex strings; operates on a downsized copy."""
    try:
        image_small = image.copy()
        image_small.thumbnail((150, 150))
        if image_small.mode != 'RGB':
            image_small = image_small.convert('RGB')

        pixels = list(image_small.getdata())
        color_counts = Counter(pixels)
        most_common = color_counts.most_common(num_colors)

        hex_colors = ['#{:02x}{:02x}{:02x}'.format(r, g, b) for (r, g, b), _ in most_common]
        return hex_colors
    except Exception as e:
        logger.warning(f"Color extraction failed: {e}")
        return []

def assess_image_quality(image: Image.Image) -> ImageQualityResponse:
    """Compute simple quality metrics and return an ImageQualityResponse.

    Metrics:
      - Sharpness: variance of Laplacian (higher is sharper)
      - Brightness: mean grayscale value measured against mid-point
      - Contrast: grayscale standard deviation
      - Noise: stddev of Laplacian (proxy)
      - Overall: weighted average of the above scores
    """
    try:
        img_array = np.array(image.convert('RGB'))
        gray = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)

        # Sharpness via Laplacian variance; scaled to 0-100 with a heuristic denominator.
        laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
        sharpness = min(100, (laplacian_var / 500) * 100)

        # Brightness centered at ~127; convert to 0-100
        brightness = np.mean(gray)
        brightness_score = 100 - abs(brightness - 127) / 1.27

        # Contrast as standard deviation mapped to 0-100
        contrast = np.std(gray)
        contrast_score = min(100, (contrast / 64) * 100)

        # Noise proxy: stddev of Laplacian; convert to 0-100
        noise_level = np.std(cv2.Laplacian(gray, cv2.CV_64F))
        noise_score = max(0, 100 - (noise_level / 10))

        # Weighted overall score
        overall_score = sharpness * 0.4 + brightness_score * 0.2 + contrast_score * 0.2 + noise_score * 0.2

        issues = []
        if sharpness < 30:
            issues.append("Blurry image")
        if brightness < 40 or brightness > 215:
            issues.append("Poor lighting")
        if contrast < 20:
            issues.append("Low contrast")
        if noise_level > 50:
            issues.append("High noise")

        is_acceptable = overall_score >= 50 and len(issues) == 0

        if ENABLE_METRICS:
            quality_score_histogram.observe(overall_score)

        return ImageQualityResponse(
            overall_score=round(overall_score, 2),
            sharpness=round(sharpness, 2),
            brightness=round(float(brightness), 2),
            contrast=round(float(contrast), 2),
            noise_level=round(float(noise_level), 2),
            is_acceptable=is_acceptable,
            issues=issues
        )

    except Exception as e:
        logger.error(f"Quality assessment failed: {e}")
        # Return a conservative default quality response on unexpected error
        return ImageQualityResponse(
            overall_score=50.0,
            sharpness=50.0,
            brightness=127.0,
            contrast=50.0,
            noise_level=0.0,
            is_acceptable=True,
            issues=[]
        )

def enhance_image(image: Image.Image) -> Image.Image:
    """Apply light automatic enhancements: autocontrast, slight sharpening and color boost."""
    try:
        image = ImageOps.autocontrast(image, cutoff=2)
        enhancer = ImageEnhance.Sharpness(image)
        image = enhancer.enhance(1.2)
        enhancer = ImageEnhance.Color(image)
        image = enhancer.enhance(1.1)
        return image
    except Exception as e:
        logger.warning(f"Enhancement failed: {e}")
        return image

def interpret_similarity(distance: int) -> str:
    """Return a human-readable interpretation for a Hamming distance value."""
    if distance == 0:
        return "Identical"
    elif distance <= 5:
        return "Nearly identical (very high confidence match)"
    elif distance <= 10:
        return "Very similar (high confidence match)"
    elif distance <= 14:
        return "Similar (potential match)"
    elif distance <= 20:
        return "Somewhat similar (low confidence)"
    elif distance <= 30:
        return "Different (likely not a match)"
    else:
        return "Very different (not a match)"

# Cached comparison to avoid repeated expensive hash-to-hash computations.
@lru_cache(maxsize=LRU_CACHE_SIZE)
def cached_hash_comparison(hash1: str, hash2: str) -> Tuple[int, float]:
    """Compute Hamming distance and normalized similarity between two hex hash strings."""
    try:
        h1 = imagehash.hex_to_hash(hash1)
        h2 = imagehash.hex_to_hash(hash2)
        distance = int(h1 - h2)
        similarity = 1.0 - (distance / 64.0)
        return distance, max(0.0, similarity)
    except Exception as e:
        logger.error(f"Hash comparison failed: {e}")
        raise

# API endpoints

@app.post("/hash", response_model=HashResponse)
@limiter.limit("100/minute") if ENABLE_RATE_LIMIT else lambda x: x
async def hash_image(
    request: Request,
    file: UploadFile = File(...),
    extract_colors: bool = Query(False),
    num_colors: int = Query(5, ge=1, le=10)
):
    """Compute perceptual hashes for an uploaded image and optionally cache the result.

    Returns multiple hash types and optional dominant color extraction.
    """
    start_time = time.time()
    if ENABLE_METRICS:
        hash_requests.inc()
        active_requests.inc()

    try:
        contents = await file.read()
        image_hash_key = generate_image_hash(contents)
        cache_key = f"hash:{image_hash_key}:{extract_colors}:{num_colors}"

        # Try Redis cache first for faster responses
        cached_result = await get_from_cache(cache_key)
        if cached_result:
            cached_result['cached'] = True
            return HashResponse(**cached_result)

        image = validate_image(file, contents)
        image = fix_image_orientation(image)
        image = strip_exif(image)

        hashes = calculate_all_hashes(image)

        dominant_colors = None
        if extract_colors:
            dominant_colors = get_dominant_colors(image, num_colors)

        processing_time_ms = (time.time() - start_time) * 1000

        result = {
            'phash': hashes['phash'],
            'dhash': hashes['dhash'],
            'avg_hash': hashes['avg_hash'],
            'whash': hashes.get('whash'),
            'colorhash': hashes.get('colorhash'),
            'dominant_colors': dominant_colors,
            'processing_time_ms': processing_time_ms,
            'cached': False
        }

        # Store computed result in Redis for future reuse
        await set_to_cache(cache_key, result)
        
        # Store hash data in MinIO if available
        if minio_client:
            try:
                import json
                hash_data = json.dumps(result).encode('utf-8')
                object_name = f"hashes/{image_hash_key}.json"
                minio_client.upload_hash_data(hash_data, object_name)
                
                # Also store the original image
                image_object_name = f"images/{image_hash_key}.jpg"
                minio_client.upload_image(contents, image_object_name, content_type="image/jpeg")
            except Exception as e:
                logger.warning(f"Failed to store data in MinIO: {e}")

        if ENABLE_METRICS:
            hash_duration.observe(time.time() - start_time)

        logger.info(f"Hashed: {file.filename} in {processing_time_ms:.2f}ms")
        return HashResponse(**result)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Hash error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if ENABLE_METRICS:
            active_requests.dec()

@app.post("/assess-quality", response_model=ImageQualityResponse)
async def assess_quality(file: UploadFile = File(...)):
    """Return image quality metrics for an uploaded image."""
    try:
        contents = await file.read()
        image = validate_image(file, contents)
        quality = assess_image_quality(image)
        return quality
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Quality assessment error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/detect-duplicate", response_model=DuplicateDetectionResponse)
async def detect_duplicate(
    file: UploadFile = File(...),
    existing_hashes: List[str] = Query(..., description="List of existing pHashes")
):
    """Check whether the uploaded image matches any provided existing pHash values.

    Returns the best match and a confidence score derived from Hamming distance.
    """
    try:
        contents = await file.read()
        image = validate_image(file, contents)

        hashes = calculate_all_hashes(image)
        current_phash = hashes['phash']

        min_distance = float('inf')
        matched_hash = None

        for existing_hash in existing_hashes:
            distance, similarity = cached_hash_comparison(current_phash, existing_hash)
            if distance < min_distance:
                min_distance = distance
                matched_hash = existing_hash

        # Consider "duplicate" only for very close matches
        is_duplicate = min_distance <= 5
        confidence = 1.0 - (min_distance / 64.0)
        similarity_score = confidence

        if ENABLE_METRICS:
            duplicate_detection.labels(is_duplicate=str(is_duplicate)).inc()

        return DuplicateDetectionResponse(
            is_duplicate=is_duplicate,
            confidence=confidence,
            matched_hash=matched_hash if is_duplicate else None,
            similarity_score=similarity_score
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Duplicate detection error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/enhance", response_model=HashResponse)
async def enhance_and_hash(
    file: UploadFile = File(...),
    extract_colors: bool = Query(False)
):
    """Apply light auto-enhancements and return perceptual hashes for the enhanced image."""
    try:
        contents = await file.read()
        image = validate_image(file, contents)

        image = fix_image_orientation(image)
        image = enhance_image(image)
        image = strip_exif(image)

        hashes = calculate_all_hashes(image)

        dominant_colors = None
        if extract_colors:
            dominant_colors = get_dominant_colors(image)

        return HashResponse(
            phash=hashes['phash'],
            dhash=hashes['dhash'],
            avg_hash=hashes['avg_hash'],
            whash=hashes.get('whash'),
            colorhash=hashes.get('colorhash'),
            dominant_colors=dominant_colors,
            processing_time_ms=0.0,
            cached=False
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Enhancement error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Backwards-compatible comparison endpoints

@app.post("/compare", response_model=CompareResponse)
async def compare_hashes(hash1: str, hash2: str, hash_type: str = "phash"):
    """Compare two hex hash strings and return distance, similarity and an interpretation."""
    try:
        distance, similarity = cached_hash_comparison(hash1, hash2)
        interpretation = interpret_similarity(distance)
        return CompareResponse(
            hamming_distance=distance,
            similarity=similarity,
            is_similar=distance <= HASH_THRESHOLD_SIMILAR,
            is_potential_match=distance <= HASH_THRESHOLD_MATCH,
            interpretation=interpretation
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/compare-multi", response_model=MultiHashCompareResponse)
async def compare_multi_hashes(request: MultiHashCompareRequest):
    """Compare multiple hash types between two items and produce a weighted similarity score."""
    try:
        comparisons = {}
        weights = {'phash': 0.5, 'dhash': 0.3, 'avg_hash': 0.2}

        weighted_sum = 0.0
        total_weight = 0.0

        for hash_type in request.hashes1.keys():
            if hash_type in request.hashes2:
                hash1 = request.hashes1[hash_type]
                hash2 = request.hashes2[hash_type]

                if hash1 and hash2:
                    distance, similarity = cached_hash_comparison(hash1, hash2)
                    interpretation = interpret_similarity(distance)

                    comparisons[hash_type] = CompareResponse(
                        hamming_distance=distance,
                        similarity=similarity,
                        is_similar=distance <= HASH_THRESHOLD_SIMILAR,
                        is_potential_match=distance <= HASH_THRESHOLD_MATCH,
                        interpretation=interpretation
                    )

                    weight = weights.get(hash_type, 0.0)
                    if weight > 0:
                        weighted_sum += similarity * weight
                        total_weight += weight

        weighted_similarity = weighted_sum / total_weight if total_weight > 0 else 0.0
        overall_match = weighted_similarity >= 0.85

        return MultiHashCompareResponse(
            comparisons=comparisons,
            weighted_similarity=weighted_similarity,
            overall_match=overall_match
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Monitoring endpoints

@app.get("/metrics")
async def metrics():
    """Expose Prometheus metrics when enabled."""
    if not ENABLE_METRICS:
        raise HTTPException(status_code=404, detail="Metrics disabled")
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.get("/health", response_model=HealthResponse)
async def health():
    """Return a small health payload including uptime and Redis connection state."""
    uptime = time.time() - SERVICE_START_TIME
    redis_status = redis_client is not None
    if redis_client:
        try:
            await redis_client.ping()
        except Exception:
            redis_status = False
    
    return HealthResponse(
        status="ok",
        service="vision-v2.1",
        version="2.1.0",
        timestamp=datetime.utcnow().isoformat(),
        uptime_seconds=round(uptime, 2),
        redis_connected=redis_status
    )

@app.get("/")
async def root():
    """Basic service information useful for discovery or simple checks."""
    return {
        "service": "Vision Service v2.1",
        "version": "2.1.0",
        "description": "CPU-only computer vision with enhanced image processing",
        "features": {
            "perceptual_hashing": "pHash, dHash, aHash, wHash, colorHash",
            "quality_assessment": "Enabled",
            "auto_enhancement": "Enabled",
            "duplicate_detection": "Enabled",
            "redis_caching": "Enabled" if redis_client else "Disabled",
            "rate_limiting": "Enabled" if ENABLE_RATE_LIMIT else "Disabled",
            "metrics": "Enabled" if ENABLE_METRICS else "Disabled",
            "retry_logic": "Enabled"
        },
        "endpoints": {
            "hash": "POST /hash",
            "assess_quality": "POST /assess-quality",
            "detect_duplicate": "POST /detect-duplicate",
            "enhance": "POST /enhance",
            "compare": "POST /compare",
            "compare_multi": "POST /compare-multi",
            "metrics": "GET /metrics",
            "health": "GET /health"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
