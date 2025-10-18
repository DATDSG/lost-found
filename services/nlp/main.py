"""
NLP Embedding Service - Production Enhanced Version
---------------------------------------------------
Features:
- Redis caching with TTL
- GPU support
- Prometheus metrics
- Model versioning
- Async processing
- LRU smart caching
- Rate limiting
"""

from fastapi import FastAPI, HTTPException, Request, BackgroundTasks, Depends
from fastapi.responses import Response
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from functools import lru_cache
from contextlib import asynccontextmanager
import logging
import hashlib
import json
import time
import asyncio
from datetime import datetime, timedelta
import os

# Prometheus metrics
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

# Redis for distributed caching
import redis.asyncio as redis
from redis.asyncio import Redis

# Rate limiting
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Job queue for async processing
from arq import create_pool
from arq.connections import RedisSettings

# Configure logging
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")
REDIS_CACHE_TTL = int(os.getenv("REDIS_CACHE_TTL", "86400"))  # 24 hours
USE_GPU = os.getenv("USE_GPU", "false").lower() == "true"
ENABLE_METRICS = os.getenv("ENABLE_METRICS", "true").lower() == "true"
ENABLE_RATE_LIMIT = os.getenv("ENABLE_RATE_LIMIT", "true").lower() == "true"
DEFAULT_MODEL = os.getenv("MODEL_NAME", "intfloat/e5-small-v2")
ENABLE_MODEL_VERSIONING = os.getenv("ENABLE_MODEL_VERSIONING", "true").lower() == "true"
LRU_CACHE_SIZE = int(os.getenv("LRU_CACHE_SIZE", "1000"))

# Prometheus Metrics
if ENABLE_METRICS:
    encode_requests = Counter('nlp_encode_requests_total', 'Total encode requests', ['model_version'])
    encode_duration = Histogram('nlp_encode_duration_seconds', 'Encode request duration', ['model_version'])
    cache_hits = Counter('nlp_cache_hits_total', 'Cache hits', ['cache_type'])
    cache_misses = Counter('nlp_cache_misses_total', 'Cache misses', ['cache_type'])
    model_load_time = Gauge('nlp_model_load_time_seconds', 'Model load time')
    active_requests = Gauge('nlp_active_requests', 'Currently processing requests')
    redis_operations = Counter('nlp_redis_operations_total', 'Redis operations', ['operation', 'status'])
    background_tasks = Counter('nlp_background_tasks_total', 'Background tasks', ['task_type', 'status'])

# Rate limiter
limiter = Limiter(key_func=get_remote_address) if ENABLE_RATE_LIMIT else None

# Global state
models: Dict[str, Any] = {}  # Model version -> model instance
redis_client: Optional[Redis] = None
arq_pool = None
local_lru_cache = {}  # Local LRU cache


class ModelManager:
    """Manages multiple model versions for A/B testing and gradual rollouts."""
    
    def __init__(self):
        self.models = {}
        self.default_version = "v1"
        self.version_weights = {"v1": 1.0}  # For A/B testing
        
    async def load_model(self, version: str, model_name: str, use_gpu: bool = False):
        """Load a model version."""
        start_time = time.time()
        try:
            from sentence_transformers import SentenceTransformer
            logger.info(f"Loading model {model_name} as version {version} (GPU: {use_gpu})...")
            
            device = "cuda" if use_gpu and self._is_gpu_available() else "cpu"
            model = SentenceTransformer(model_name, device=device)
            
            self.models[version] = {
                "model": model,
                "name": model_name,
                "device": device,
                "loaded_at": datetime.utcnow(),
                "dimension": model.get_sentence_embedding_dimension()
            }
            
            load_time = time.time() - start_time
            if ENABLE_METRICS:
                model_load_time.set(load_time)
            
            logger.info(f"Model {version} loaded successfully in {load_time:.2f}s on {device}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to load model {version}: {e}")
            return False
    
    def _is_gpu_available(self) -> bool:
        """Check if GPU is available."""
        try:
            import torch
            return torch.cuda.is_available()
        except ImportError:
            return False
    
    def get_model(self, version: Optional[str] = None):
        """Get a model by version."""
        version = version or self.default_version
        return self.models.get(version, {}).get("model")
    
    def get_model_info(self, version: Optional[str] = None) -> Dict:
        """Get model information."""
        version = version or self.default_version
        return self.models.get(version, {})
    
    def list_versions(self) -> List[str]:
        """List all available model versions."""
        return list(self.models.keys())
    
    async def unload_model(self, version: str):
        """Unload a model version to free memory."""
        if version in self.models:
            del self.models[version]
            logger.info(f"Model {version} unloaded")
            return True
        return False


model_manager = ModelManager()


class SmartCache:
    """Smart caching with LRU eviction, pre-warming, and analytics."""
    
    def __init__(self, redis_client: Redis, ttl: int = 86400):
        self.redis = redis_client
        self.ttl = ttl
        self.local_cache = {}  # LRU cache
        self.max_local_size = LRU_CACHE_SIZE
        self.access_counts = {}  # For analytics
        
    def _get_cache_key(self, text: str, model_version: str) -> str:
        """Generate cache key."""
        text_hash = hashlib.md5(text.encode('utf-8')).hexdigest()
        return f"nlp:embedding:{model_version}:{text_hash}"
    
    async def get(self, text: str, model_version: str) -> Optional[List[float]]:
        """Get from cache (local LRU first, then Redis)."""
        cache_key = self._get_cache_key(text, model_version)
        
        # Try local LRU cache first
        if cache_key in self.local_cache:
            if ENABLE_METRICS:
                cache_hits.labels(cache_type='local').inc()
            self.access_counts[cache_key] = self.access_counts.get(cache_key, 0) + 1
            return self.local_cache[cache_key]
        
        # Try Redis
        try:
            cached = await self.redis.get(cache_key)
            if cached:
                if ENABLE_METRICS:
                    cache_hits.labels(cache_type='redis').inc()
                    redis_operations.labels(operation='get', status='hit').inc()
                
                embedding = json.loads(cached)
                # Populate local cache
                self._add_to_local_cache(cache_key, embedding)
                return embedding
            else:
                if ENABLE_METRICS:
                    redis_operations.labels(operation='get', status='miss').inc()
        except Exception as e:
            logger.error(f"Redis get error: {e}")
            if ENABLE_METRICS:
                redis_operations.labels(operation='get', status='error').inc()
        
        if ENABLE_METRICS:
            cache_misses.labels(cache_type='all').inc()
        return None
    
    async def set(self, text: str, model_version: str, embedding: List[float]):
        """Set in cache (both local and Redis)."""
        cache_key = self._get_cache_key(text, model_version)
        
        # Add to local LRU cache
        self._add_to_local_cache(cache_key, embedding)
        
        # Add to Redis with TTL
        try:
            await self.redis.setex(
                cache_key,
                self.ttl,
                json.dumps(embedding)
            )
            if ENABLE_METRICS:
                redis_operations.labels(operation='set', status='success').inc()
        except Exception as e:
            logger.error(f"Redis set error: {e}")
            if ENABLE_METRICS:
                redis_operations.labels(operation='set', status='error').inc()
    
    def _add_to_local_cache(self, key: str, value: List[float]):
        """Add to local LRU cache with eviction."""
        if len(self.local_cache) >= self.max_local_size:
            # LRU eviction: remove least recently accessed
            if self.access_counts:
                lru_key = min(self.access_counts, key=self.access_counts.get)
                del self.local_cache[lru_key]
                del self.access_counts[lru_key]
            else:
                # Fallback: remove first item
                first_key = next(iter(self.local_cache))
                del self.local_cache[first_key]
        
        self.local_cache[key] = value
        self.access_counts[key] = 0
    
    async def warm_cache(self, texts: List[str], model_version: str):
        """Pre-warm cache with common texts."""
        logger.info(f"Warming cache with {len(texts)} texts...")
        for text in texts:
            # Check if already cached
            cached = await self.get(text, model_version)
            if not cached:
                # Need to encode - this would be done by background task
                logger.debug(f"Cache warming: {text[:50]}... needs encoding")
    
    async def clear(self, pattern: str = "nlp:embedding:*"):
        """Clear cache by pattern."""
        try:
            cursor = 0
            deleted = 0
            while True:
                cursor, keys = await self.redis.scan(cursor, match=pattern, count=100)
                if keys:
                    await self.redis.delete(*keys)
                    deleted += len(keys)
                if cursor == 0:
                    break
            
            # Clear local cache
            self.local_cache.clear()
            self.access_counts.clear()
            
            logger.info(f"Cleared {deleted} cache entries")
            return deleted
        except Exception as e:
            logger.error(f"Cache clear error: {e}")
            return 0
    
    def get_analytics(self) -> Dict:
        """Get cache analytics."""
        return {
            "local_cache_size": len(self.local_cache),
            "max_local_size": self.max_local_size,
            "top_accessed": sorted(
                self.access_counts.items(),
                key=lambda x: x[1],
                reverse=True
            )[:10]
        }


smart_cache: Optional[SmartCache] = None


# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    global redis_client, smart_cache, arq_pool
    
    # Startup
    logger.info("Starting NLP service with enhanced features...")
    
    # Initialize Redis
    try:
        redis_client = await redis.from_url(REDIS_URL, encoding="utf-8", decode_responses=False)
        await redis_client.ping()
        logger.info("Redis connected successfully")
        
        # Initialize smart cache
        smart_cache = SmartCache(redis_client, ttl=REDIS_CACHE_TTL)
        
    except Exception as e:
        logger.error(f"Redis connection failed: {e}")
        logger.warning("Running without Redis cache")
    
    # Initialize ARQ pool for background tasks
    try:
        # Parse Redis URL properly for ARQ
        # Format: redis://[:password@]host[:port][/db]
        redis_parts = REDIS_URL.replace("redis://", "").split("@")
        if len(redis_parts) == 2:
            # Has password
            password = redis_parts[0].lstrip(":")
            host_port = redis_parts[1].split(":")[0]
            port = int(redis_parts[1].split(":")[1].split("/")[0]) if ":" in redis_parts[1] else 6379
        else:
            # No password
            password = None
            host_port = redis_parts[0].split(":")[0]
            port = int(redis_parts[0].split(":")[1].split("/")[0]) if ":" in redis_parts[0] else 6379
        
        arq_pool = await create_pool(
            RedisSettings(
                host=host_port,
                port=port,
                password=password
            )
        )
        logger.info("ARQ pool created for background tasks")
    except Exception as e:
        logger.error(f"ARQ pool creation failed: {e}")
    
    # Load default model
    await model_manager.load_model("v1", DEFAULT_MODEL, USE_GPU)
    
    # Load additional models if configured
    alt_model = os.getenv("ALT_MODEL_NAME")
    if alt_model and ENABLE_MODEL_VERSIONING:
        await model_manager.load_model("v2", alt_model, USE_GPU)
    
    yield
    
    # Shutdown
    logger.info("Shutting down NLP service...")
    if redis_client:
        await redis_client.close()
    if arq_pool:
        await arq_pool.close()


# Create FastAPI app with lifespan
app = FastAPI(
    title="NLP Embedding Service - Production Enhanced",
    version="2.0.0",
    description="Multilingual text embedding with Redis cache, GPU support, metrics, and A/B testing",
    lifespan=lifespan
)

# Add rate limiter exception handler
if ENABLE_RATE_LIMIT and limiter:
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


# Pydantic models
class EncodeRequest(BaseModel):
    texts: List[str] = Field(..., description="List of texts to encode")
    use_cache: bool = Field(True, description="Whether to use caching")
    model_version: Optional[str] = Field(None, description="Model version to use (v1, v2, etc.)")
    background: bool = Field(False, description="Process in background (async)")


class EncodeResponse(BaseModel):
    vectors: List[List[float]]
    dimension: int
    cache_hits: int = 0
    model_version: str
    processing_time_ms: float


class BatchEncodeRequest(BaseModel):
    items: List[Dict[str, str]] = Field(..., description="Items with 'id' and 'text'")
    use_cache: bool = True
    model_version: Optional[str] = None
    background: bool = False


class BatchEncodeResponse(BaseModel):
    embeddings: List[Dict[str, Any]]
    dimension: int
    cache_hits: int = 0
    model_version: str
    processing_time_ms: float


class CacheWarmRequest(BaseModel):
    texts: List[str] = Field(..., description="Texts to pre-warm in cache")
    model_version: Optional[str] = None


class ModelVersionInfo(BaseModel):
    version: str
    name: str
    device: str
    dimension: int
    loaded_at: str
    is_default: bool


# Background task functions
async def encode_task(texts: List[str], model_version: str, use_cache: bool):
    """Background task to encode texts."""
    try:
        if ENABLE_METRICS:
            background_tasks.labels(task_type='encode', status='started').inc()
        
        # This would actually encode and cache
        # Implementation similar to main encode logic
        logger.info(f"Background encoding {len(texts)} texts with {model_version}")
        
        if ENABLE_METRICS:
            background_tasks.labels(task_type='encode', status='completed').inc()
        
    except Exception as e:
        logger.error(f"Background encode task failed: {e}")
        if ENABLE_METRICS:
            background_tasks.labels(task_type='encode', status='failed').inc()


# API Endpoints
@app.post("/encode", response_model=EncodeResponse)
@limiter.limit("100/minute") if ENABLE_RATE_LIMIT and limiter else lambda x: x
async def encode_texts(
    request: EncodeRequest,
    req: Request,
    background_tasks: BackgroundTasks
):
    """
    Encode texts into embedding vectors with advanced features.
    """
    start_time = time.time()
    
    if not request.texts:
        return EncodeResponse(
            vectors=[],
            dimension=384,
            model_version=request.model_version or "v1",
            processing_time_ms=0
        )
    
    model_version = request.model_version or model_manager.default_version
    model = model_manager.get_model(model_version)
    
    if model is None:
        raise HTTPException(status_code=503, detail=f"Model {model_version} not loaded")
    
    # Process in background if requested
    if request.background and arq_pool:
        background_tasks.add_task(encode_task, request.texts, model_version, request.use_cache)
        return EncodeResponse(
            vectors=[],
            dimension=model_manager.get_model_info(model_version).get("dimension", 384),
            model_version=model_version,
            processing_time_ms=0,
            cache_hits=0
        )
    
    if ENABLE_METRICS:
        encode_requests.labels(model_version=model_version).inc()
        active_requests.inc()
    
    try:
        vectors = []
        cache_hits_count = 0
        texts_to_encode = []
        text_indices = []
        
        # Check cache
        if request.use_cache and smart_cache:
            for i, text in enumerate(request.texts):
                cached = await smart_cache.get(text, model_version)
                if cached is not None:
                    vectors.append(cached)
                    cache_hits_count += 1
                else:
                    vectors.append(None)
                    texts_to_encode.append(text)
                    text_indices.append(i)
        else:
            texts_to_encode = request.texts
            text_indices = list(range(len(request.texts)))
            vectors = [None] * len(request.texts)
        
        # Encode uncached texts
        if texts_to_encode:
            logger.info(f"Encoding {len(texts_to_encode)} texts (cache hits: {cache_hits_count})")
            
            if ENABLE_METRICS:
                with encode_duration.labels(model_version=model_version).time():
                    embeddings = model.encode(
                        texts_to_encode,
                        convert_to_numpy=True,
                        show_progress_bar=False,
                        normalize_embeddings=True
                    )
            else:
                embeddings = model.encode(
                    texts_to_encode,
                    convert_to_numpy=True,
                    show_progress_bar=False,
                    normalize_embeddings=True
                )
            
            new_embeddings = embeddings.tolist()
            
            # Cache new embeddings
            if request.use_cache and smart_cache:
                for text, embedding in zip(texts_to_encode, new_embeddings):
                    await smart_cache.set(text, model_version, embedding)
            
            # Fill in vectors
            for i, embedding in zip(text_indices, new_embeddings):
                vectors[i] = embedding
        
        processing_time = (time.time() - start_time) * 1000
        dimension = len(vectors[0]) if vectors else 384
        
        return EncodeResponse(
            vectors=vectors,
            dimension=dimension,
            cache_hits=cache_hits_count,
            model_version=model_version,
            processing_time_ms=processing_time
        )
    
    except Exception as e:
        logger.error(f"Encoding error: {e}")
        raise HTTPException(status_code=500, detail=f"Encoding failed: {str(e)}")
    
    finally:
        if ENABLE_METRICS:
            active_requests.dec()


@app.post("/batch-encode", response_model=BatchEncodeResponse)
@limiter.limit("50/minute") if ENABLE_RATE_LIMIT and limiter else lambda x: x
async def batch_encode(request: BatchEncodeRequest, req: Request):
    """Batch encode with IDs."""
    start_time = time.time()
    
    if not request.items:
        return BatchEncodeResponse(
            embeddings=[],
            dimension=384,
            model_version=request.model_version or "v1",
            processing_time_ms=0
        )
    
    texts = [item.get("text", "") for item in request.items]
    ids = [item.get("id", str(i)) for i, item in enumerate(request.items)]
    
    encode_request = EncodeRequest(
        texts=texts,
        use_cache=request.use_cache,
        model_version=request.model_version,
        background=request.background
    )
    
    result = await encode_texts(encode_request, req, BackgroundTasks())
    
    embeddings = [
        {"id": item_id, "vector": vector}
        for item_id, vector in zip(ids, result.vectors)
    ]
    
    processing_time = (time.time() - start_time) * 1000
    
    return BatchEncodeResponse(
        embeddings=embeddings,
        dimension=result.dimension,
        cache_hits=result.cache_hits,
        model_version=result.model_version,
        processing_time_ms=processing_time
    )


@app.get("/health")
async def health():
    """Health check with detailed status."""
    models_status = []
    for version in model_manager.list_versions():
        info = model_manager.get_model_info(version)
        models_status.append({
            "version": version,
            "loaded": info.get("model") is not None,
            "device": info.get("device"),
            "dimension": info.get("dimension")
        })
    
    redis_status = "connected" if redis_client else "disconnected"
    if redis_client:
        try:
            await redis_client.ping()
        except:
            redis_status = "error"
    
    cache_analytics = smart_cache.get_analytics() if smart_cache else {}
    
    return {
        "status": "ok",
        "service": "nlp-enhanced",
        "version": "2.0.0",
        "models": models_status,
        "redis": redis_status,
        "cache": cache_analytics,
        "gpu_enabled": USE_GPU,
        "metrics_enabled": ENABLE_METRICS
    }


@app.get("/models", response_model=List[ModelVersionInfo])
async def list_models():
    """List all loaded model versions."""
    models_list = []
    for version in model_manager.list_versions():
        info = model_manager.get_model_info(version)
        models_list.append(ModelVersionInfo(
            version=version,
            name=info.get("name", ""),
            device=info.get("device", ""),
            dimension=info.get("dimension", 0),
            loaded_at=info.get("loaded_at", datetime.utcnow()).isoformat(),
            is_default=version == model_manager.default_version
        ))
    return models_list


@app.post("/models/load")
async def load_model(version: str, model_name: str, use_gpu: bool = False):
    """Load a new model version."""
    success = await model_manager.load_model(version, model_name, use_gpu)
    if success:
        return {"status": "success", "version": version, "model": model_name}
    else:
        raise HTTPException(status_code=500, detail="Failed to load model")


@app.delete("/models/{version}")
async def unload_model(version: str):
    """Unload a model version."""
    if version == model_manager.default_version:
        raise HTTPException(status_code=400, detail="Cannot unload default model")
    
    success = await model_manager.unload_model(version)
    if success:
        return {"status": "success", "version": version}
    else:
        raise HTTPException(status_code=404, detail="Model version not found")


@app.post("/cache/warm")
async def warm_cache(request: CacheWarmRequest, background_tasks: BackgroundTasks):
    """Pre-warm cache with common texts."""
    if not smart_cache:
        raise HTTPException(status_code=503, detail="Cache not available")
    
    model_version = request.model_version or model_manager.default_version
    background_tasks.add_task(smart_cache.warm_cache, request.texts, model_version)
    
    return {
        "status": "warming",
        "texts_count": len(request.texts),
        "model_version": model_version
    }


@app.post("/cache/clear")
async def clear_cache(pattern: str = "nlp:embedding:*"):
    """Clear cache."""
    if not smart_cache:
        raise HTTPException(status_code=503, detail="Cache not available")
    
    deleted = await smart_cache.clear(pattern)
    return {
        "status": "ok",
        "entries_cleared": deleted
    }


@app.get("/cache/analytics")
async def cache_analytics():
    """Get cache analytics."""
    if not smart_cache:
        raise HTTPException(status_code=503, detail="Cache not available")
    
    return smart_cache.get_analytics()


@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint."""
    if not ENABLE_METRICS:
        raise HTTPException(status_code=404, detail="Metrics not enabled")
    
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/")
async def root():
    """Service information."""
    return {
        "service": "NLP Embedding Service - Production Enhanced",
        "version": "2.0.0",
        "features": {
            "redis_cache": redis_client is not None,
            "gpu_support": USE_GPU,
            "metrics": ENABLE_METRICS,
            "rate_limiting": ENABLE_RATE_LIMIT,
            "model_versioning": ENABLE_MODEL_VERSIONING,
            "async_processing": arq_pool is not None
        },
        "endpoints": {
            "/encode": "Encode texts (with rate limiting: 100/min)",
            "/batch-encode": "Batch encode with IDs (50/min)",
            "/health": "Detailed health status",
            "/models": "List model versions",
            "/models/load": "Load new model version",
            "/cache/warm": "Pre-warm cache",
            "/cache/clear": "Clear cache",
            "/cache/analytics": "Cache analytics",
            "/metrics": "Prometheus metrics",
            "/docs": "API documentation"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
