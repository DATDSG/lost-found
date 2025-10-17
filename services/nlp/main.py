"""
Simplified NLP Service - Mock Implementation

This is a temporary mock implementation that provides the same API
as the full NLP service but returns dummy embeddings.
This allows the project to run while we fix the dependency issues.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from contextlib import asynccontextmanager
import logging
import time
import os

from config import config
from minio_client import get_nlp_minio_client

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Environment-driven configuration
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")
ENABLE_METRICS = os.getenv("ENABLE_METRICS", "true").lower() == "true"
MODEL_NAME = os.getenv("MODEL_NAME", "mock-model")

# Global state
model_loaded = True  # Mock model is always "loaded"
redis_client = None
minio_client = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan context."""
    global redis_client, minio_client
    
    logger.info("Starting Mock NLP service v2.1.0")
    
    # Initialize MinIO client
    try:
        minio_client = get_nlp_minio_client()
        logger.info("MinIO client initialized successfully")
    except Exception as e:
        logger.error(f"MinIO client initialization failed: {str(e)}")
        minio_client = None
    
    # Try to connect to Redis
    try:
        import redis.asyncio as redis
        redis_client = await redis.from_url(REDIS_URL, encoding="utf-8", decode_responses=False)
        await redis_client.ping()
        logger.info("Redis connected successfully")
    except Exception as e:
        logger.warning(f"Redis connection failed: {str(e)}")
        redis_client = None
    
    logger.info("Mock NLP service ready")
    yield
    
    # Graceful shutdown
    logger.info("Shutting down Mock NLP service...")
    if redis_client:
        await redis_client.close()

# Create FastAPI application
app = FastAPI(
    title="Mock NLP Embedding Service",
    version="2.1.0",
    description="Mock implementation for testing",
    lifespan=lifespan
)

# Request/response schemas
class EncodeRequest(BaseModel):
    texts: List[str] = Field(..., description="List of texts to encode")
    use_cache: bool = Field(True, description="Whether to use caching")

class EncodeResponse(BaseModel):
    vectors: List[List[float]]
    dimension: int
    cache_hits: int = 0
    processing_time_ms: float

class BatchEncodeRequest(BaseModel):
    items: List[Dict[str, str]] = Field(..., description="Items with 'id' and 'text'")
    use_cache: bool = True

class BatchEncodeResponse(BaseModel):
    embeddings: List[Dict[str, Any]]
    dimension: int
    cache_hits: int = 0
    processing_time_ms: float

def generate_mock_embedding(text: str, dimension: int = 384) -> List[float]:
    """Generate a mock embedding based on text content."""
    import hashlib
    # Use text hash to generate consistent "embeddings"
    text_hash = hashlib.md5(text.encode('utf-8')).hexdigest()
    # Convert hash to float values
    embedding = []
    for i in range(0, len(text_hash), 2):
        val = int(text_hash[i:i+2], 16) / 255.0  # Normalize to 0-1
        embedding.append(val)
    
    # Pad or truncate to desired dimension
    while len(embedding) < dimension:
        embedding.append(0.0)
    return embedding[:dimension]

@app.post("/encode", response_model=EncodeResponse)
async def encode_texts(request: EncodeRequest):
    """Encode texts into mock embedding vectors."""
    start_time = time.time()
    
    if not request.texts:
        return EncodeResponse(
            vectors=[],
            dimension=384,
            processing_time_ms=0,
            cache_hits=0
        )
    
    vectors = []
    cache_hits_count = 0
    
    for text in request.texts:
        # Generate mock embedding
        embedding = generate_mock_embedding(text)
        vectors.append(embedding)
        
        # Store in MinIO if available
        if minio_client:
            try:
                import json
                embeddings_data = json.dumps(embedding).encode('utf-8')
                object_name = f"embeddings/{hash(text)}.json"
                minio_client.upload_embeddings(embeddings_data, object_name)
            except Exception as e:
                logger.warning(f"Failed to store embedding in MinIO: {e}")
    
    processing_time = (time.time() - start_time) * 1000
    
    return EncodeResponse(
        vectors=vectors,
        dimension=384,
        cache_hits=cache_hits_count,
        processing_time_ms=processing_time
    )

@app.post("/batch-encode", response_model=BatchEncodeResponse)
async def batch_encode(request: BatchEncodeRequest):
    """Encode a batch of items."""
    start_time = time.time()
    
    if not request.items:
        return BatchEncodeResponse(
            embeddings=[],
            dimension=384,
            processing_time_ms=0,
            cache_hits=0
        )
    
    embeddings = []
    for item in request.items:
        text = item.get("text", "")
        item_id = item.get("id", "")
        vector = generate_mock_embedding(text)
        embeddings.append({"id": item_id, "vector": vector})
    
    processing_time = (time.time() - start_time) * 1000
    
    return BatchEncodeResponse(
        embeddings=embeddings,
        dimension=384,
        cache_hits=0,
        processing_time_ms=processing_time
    )

@app.get("/health")
async def health():
    """Health endpoint."""
    redis_status = "connected" if redis_client else "disconnected"
    if redis_client:
        try:
            await redis_client.ping()
        except:
            redis_status = "error"
    
    return {
        "status": "ok",
        "service": "nlp",
        "version": "2.1.0",
        "model_loaded": model_loaded,
        "model_name": MODEL_NAME,
        "redis": redis_status,
        "cache_size": 0,
        "metrics_enabled": ENABLE_METRICS,
        "mock_mode": True
    }

@app.get("/metrics")
async def metrics():
    """Mock metrics endpoint."""
    if not ENABLE_METRICS:
        raise HTTPException(status_code=404, detail="Metrics not enabled")
    
    # Return empty metrics
    return "# Mock metrics\n"

@app.get("/")
async def root():
    """Service metadata."""
    return {
        "service": "Mock NLP Embedding Service",
        "version": "2.1.0",
        "model": MODEL_NAME,
        "features": {
            "redis_cache": redis_client is not None,
            "metrics": ENABLE_METRICS,
            "rate_limiting": False,
            "cpu_only": True,
            "mock_mode": True
        },
        "endpoints": {
            "/encode": "Encode texts (mock)",
            "/batch-encode": "Batch encode with IDs (mock)",
            "/health": "Health status",
            "/metrics": "Prometheus metrics",
            "/docs": "API documentation"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
