import os
import logging
from typing import List, Optional, Literal, Dict, Any
from functools import lru_cache
from io import BytesIO
import base64

from fastapi import FastAPI, UploadFile, File, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter
import imagehash
import cv2
import torch
from torchvision import transforms

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    APP_NAME: str = "vision-service"
    HOST: str = "0.0.0.0"
    PORT: int = 8091
    
    # Model configuration
    CV_MODE: Literal["dummy", "real"] = "real"
    CLIP_MODEL: str = "ViT-B/32"
    HASH_SIZE: int = 8
    
    # Image processing settings
    MAX_IMAGE_SIZE: int = 1024
    SUPPORTED_FORMATS: List[str] = ["JPEG", "PNG", "WEBP", "BMP"]
    ENABLE_PREPROCESSING: bool = True
    
    # Performance settings
    BATCH_SIZE: int = 16
    CACHE_SIZE: int = 1000
    
    # Redis cache (optional)
    REDIS_URL: Optional[str] = None
    CACHE_TTL: int = 3600  # 1 hour

    class Config:
        env_file = ".env"

settings = Settings()
app = FastAPI(
    title=settings.APP_NAME,
    description="Computer Vision service for Lost & Found system",
    version="2.0.0"
)

# Global model instances
_clip_model = None
_clip_preprocess = None
_cache = {}

# --- Model loaders (lazy loading) ---
def _load_clip_model():
    """Load CLIP model for semantic image understanding"""
    global _clip_model, _clip_preprocess
    if _clip_model is not None:
        return _clip_model, _clip_preprocess
    
    try:
        import clip
        logger.info(f"Loading CLIP model: {settings.CLIP_MODEL}")
        device = "cuda" if torch.cuda.is_available() else "cpu"
        _clip_model, _clip_preprocess = clip.load(settings.CLIP_MODEL, device=device)
        logger.info(f"CLIP model loaded successfully on {device}")
        return _clip_model, _clip_preprocess
    except Exception as e:
        logger.error(f"Could not load CLIP model: {e}")
        return None, None

# --- Image preprocessing pipeline ---
def _preprocess_image(image: Image.Image) -> Image.Image:
    """Comprehensive image preprocessing pipeline"""
    if not settings.ENABLE_PREPROCESSING:
        return image
    
    # Convert to RGB if needed
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    # Resize if too large
    if max(image.size) > settings.MAX_IMAGE_SIZE:
        ratio = settings.MAX_IMAGE_SIZE / max(image.size)
        new_size = tuple(int(dim * ratio) for dim in image.size)
        image = image.resize(new_size, Image.Resampling.LANCZOS)
    
    # Enhance image quality
    enhancer = ImageEnhance.Sharpness(image)
    image = enhancer.enhance(1.2)
    
    enhancer = ImageEnhance.Contrast(image)
    image = enhancer.enhance(1.1)
    
    return image

def _extract_multiple_hashes(image: Image.Image) -> Dict[str, str]:
    """Extract multiple types of perceptual hashes"""
    hashes = {
        'phash': str(imagehash.phash(image, hash_size=settings.HASH_SIZE)),
        'dhash': str(imagehash.dhash(image, hash_size=settings.HASH_SIZE)),
        'ahash': str(imagehash.average_hash(image, hash_size=settings.HASH_SIZE)),
        'whash': str(imagehash.whash(image, hash_size=settings.HASH_SIZE)),
        'colorhash': str(imagehash.colorhash(image))
    }
    return hashes

# --- Pydantic Models ---
class ImageHashResponse(BaseModel):
    phash: str = Field(..., description="Perceptual hash")
    dhash: str = Field(..., description="Difference hash")
    ahash: str = Field(..., description="Average hash")
    whash: str = Field(..., description="Wavelet hash")
    colorhash: str = Field(..., description="Color hash")
    width: int = Field(..., description="Image width")
    height: int = Field(..., description="Image height")
    file_size: int = Field(..., description="File size in bytes")
    format: str = Field(..., description="Image format")
    mode: str = Field(..., description="Processing mode")

class CLIPEmbeddingResponse(BaseModel):
    embedding: List[float] = Field(..., description="CLIP embedding vector")
    dim: int = Field(..., description="Embedding dimension")
    model_name: str = Field(..., description="CLIP model used")
    mode: str = Field(..., description="Processing mode")

class CompareHashRequest(BaseModel):
    hash1: str = Field(..., description="First hash")
    hash2: str = Field(..., description="Second hash")
    hash_type: Literal["phash", "dhash", "ahash", "whash", "colorhash"] = Field(default="phash")

class CompareHashResponse(BaseModel):
    distance: int = Field(..., description="Hamming distance")
    similarity: float = Field(..., description="Similarity score (0-1)")
    hash_type: str = Field(..., description="Hash type used")

class CompareEmbeddingRequest(BaseModel):
    embedding1: List[float] = Field(..., description="First embedding")
    embedding2: List[float] = Field(..., description="Second embedding")

class CompareEmbeddingResponse(BaseModel):
    cosine_similarity: float = Field(..., description="Cosine similarity (-1 to 1)")
    euclidean_distance: float = Field(..., description="Euclidean distance")
    similarity_score: float = Field(..., description="Normalized similarity (0-1)")

class BatchProcessRequest(BaseModel):
    image_urls: List[str] = Field(..., description="List of image URLs")
    include_embeddings: bool = Field(default=True, description="Include CLIP embeddings")
    include_hashes: bool = Field(default=True, description="Include perceptual hashes")

class BatchProcessResponse(BaseModel):
    results: List[Dict[str, Any]] = Field(..., description="Processing results")
    processed_count: int = Field(..., description="Number of successfully processed images")
    failed_count: int = Field(..., description="Number of failed images")
    errors: List[str] = Field(default=[], description="Error messages")

# --- API Endpoints ---
@app.get("/health")
def health():
    clip_available = _load_clip_model()[0] is not None
    return {
        "status": "ok",
        "mode": settings.CV_MODE,
        "clip_model": settings.CLIP_MODEL,
        "clip_available": clip_available,
        "hash_size": settings.HASH_SIZE,
        "max_image_size": settings.MAX_IMAGE_SIZE,
        "supported_formats": settings.SUPPORTED_FORMATS
    }

@app.post("/hash", response_model=ImageHashResponse)
async def hash_image(file: UploadFile = File(...)):
    """Extract multiple perceptual hashes from image"""
    try:
        # Validate file type
        if not file.content_type or not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        data = await file.read()
        file_size = len(data)
        
        # Open and preprocess image
        img = Image.open(BytesIO(data))
        original_format = img.format
        original_size = img.size
        
        # Preprocess image
        processed_img = _preprocess_image(img)
        
        # Extract multiple hashes
        hashes = _extract_multiple_hashes(processed_img)
        
        return ImageHashResponse(
            **hashes,
            width=original_size[0],
            height=original_size[1],
            file_size=file_size,
            format=original_format or "Unknown",
            mode=settings.CV_MODE
        )
    except Exception as e:
        logger.error(f"Error processing image: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/embed", response_model=CLIPEmbeddingResponse)
async def embed_image(file: UploadFile = File(...)):
    """Generate CLIP embedding for semantic image understanding"""
    try:
        if settings.CV_MODE == "dummy":
            # Return dummy embedding
            dummy_embedding = np.random.rand(512).tolist()
            return CLIPEmbeddingResponse(
                embedding=dummy_embedding,
                dim=512,
                model_name=settings.CLIP_MODEL,
                mode="dummy"
            )
        
        model, preprocess = _load_clip_model()
        if model is None:
            raise HTTPException(status_code=503, detail="CLIP model not available")
        
        # Process image
        data = await file.read()
        img = Image.open(BytesIO(data))
        processed_img = _preprocess_image(img)
        
        # Generate embedding
        image_tensor = preprocess(processed_img).unsqueeze(0)
        device = next(model.parameters()).device
        image_tensor = image_tensor.to(device)
        
        with torch.no_grad():
            embedding = model.encode_image(image_tensor)
            embedding = embedding.cpu().numpy().flatten()
        
        return CLIPEmbeddingResponse(
            embedding=embedding.tolist(),
            dim=len(embedding),
            model_name=settings.CLIP_MODEL,
            mode="real"
        )
    except Exception as e:
        logger.error(f"Error generating embedding: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/compare-hash", response_model=CompareHashResponse)
async def compare_hashes(req: CompareHashRequest):
    """Compare two perceptual hashes"""
    try:
        h1 = imagehash.hex_to_hash(req.hash1)
        h2 = imagehash.hex_to_hash(req.hash2)
        distance = int(h1 - h2)
        
        # Calculate similarity score (0-1, where 1 is identical)
        max_distance = settings.HASH_SIZE * settings.HASH_SIZE
        similarity = max(0, 1 - (distance / max_distance))
        
        return CompareHashResponse(
            distance=distance,
            similarity=similarity,
            hash_type=req.hash_type
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid hash format: {e}")

@app.post("/compare-embedding", response_model=CompareEmbeddingResponse)
async def compare_embeddings(req: CompareEmbeddingRequest):
    """Compare two CLIP embeddings"""
    try:
        emb1 = np.array(req.embedding1)
        emb2 = np.array(req.embedding2)
        
        # Cosine similarity
        cosine_sim = np.dot(emb1, emb2) / (np.linalg.norm(emb1) * np.linalg.norm(emb2))
        
        # Euclidean distance
        euclidean_dist = np.linalg.norm(emb1 - emb2)
        
        # Normalize similarity to 0-1 range
        similarity_score = (cosine_sim + 1) / 2
        
        return CompareEmbeddingResponse(
            cosine_similarity=float(cosine_sim),
            euclidean_distance=float(euclidean_dist),
            similarity_score=float(similarity_score)
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error comparing embeddings: {e}")

@app.post("/batch-process", response_model=BatchProcessResponse)
async def batch_process_images(req: BatchProcessRequest):
    """Process multiple images in batch"""
    results = []
    errors = []
    processed_count = 0
    failed_count = 0
    
    for i, url in enumerate(req.image_urls):
        try:
            # This is a placeholder - in real implementation, you'd fetch the image from URL
            # For now, we'll simulate processing
            result = {
                "url": url,
                "index": i,
                "processed": True
            }
            
            if req.include_hashes:
                # Simulate hash extraction
                result["hashes"] = {
                    "phash": "dummy_phash",
                    "dhash": "dummy_dhash",
                    "ahash": "dummy_ahash"
                }
            
            if req.include_embeddings:
                # Simulate embedding generation
                result["embedding"] = np.random.rand(512).tolist()
            
            results.append(result)
            processed_count += 1
            
        except Exception as e:
            errors.append(f"Failed to process image {i}: {str(e)}")
            failed_count += 1
    
    return BatchProcessResponse(
        results=results,
        processed_count=processed_count,
        failed_count=failed_count,
        errors=errors
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=settings.HOST, port=settings.PORT)
