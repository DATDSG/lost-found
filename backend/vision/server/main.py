import os
import logging
from io import BytesIO
from typing import List, Optional, Literal

from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings
import numpy as np
from PIL import Image, ImageEnhance
import imagehash

logger = logging.getLogger("vision")
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))


class Settings(BaseSettings):
    APP_NAME: str = "vision-service"
    HOST: str = "0.0.0.0"
    PORT: int = 8091
    IMAGE_MODEL_VERSION: str = "phash-v1"

    # Feature flags
    ENABLE_CLIP: bool = False  # heavy dependency (torch + clip) disabled by default
    CLIP_MODEL: str = "ViT-B/32"
    MAX_IMAGE_SIZE: int = 1024
    HASH_SIZE: int = 8
    ENABLE_PREPROCESSING: bool = True

    class Config:
        env_file = ".env"


settings = Settings()
app = FastAPI(title=settings.APP_NAME, version="2.0.0")

# Lazy globals for optional CLIP
_clip_model = None
_clip_preprocess = None


def _maybe_load_clip():  # pragma: no cover (optional path)
    global _clip_model, _clip_preprocess
    if not settings.ENABLE_CLIP:
        return None, None
    if _clip_model is not None:
        return _clip_model, _clip_preprocess
    try:
        import torch  # local import to keep base import fast
        import clip
        device = "cuda" if torch.cuda.is_available() else "cpu"
        _clip_model, _clip_preprocess = clip.load(settings.CLIP_MODEL, device=device)
        logger.info("Loaded CLIP model %s on %s", settings.CLIP_MODEL, device)
    except Exception as e:  # pragma: no cover
        logger.warning("CLIP unavailable: %s", e)
    return _clip_model, _clip_preprocess


def _preprocess(image: Image.Image) -> Image.Image:
    if not settings.ENABLE_PREPROCESSING:
        return image
    if image.mode != "RGB":
        image = image.convert("RGB")
    if max(image.size) > settings.MAX_IMAGE_SIZE:
        ratio = settings.MAX_IMAGE_SIZE / max(image.size)
        new_size = tuple(int(dim * ratio) for dim in image.size)
        image = image.resize(new_size, Image.Resampling.LANCZOS)
    # Light sharpening
    image = ImageEnhance.Sharpness(image).enhance(1.1)
    return image


class HashResponse(BaseModel):
    phash: str
    dhash: str
    ahash: str
    whash: str
    colorhash: str
    width: int
    height: int
    model_version: str


class CompareRequest(BaseModel):
    h1: str
    h2: str


class CompareResponse(BaseModel):
    distance: int


class CLIPEmbeddingResponse(BaseModel):
    embedding: List[float] = Field(...)
    dim: int
    model_name: str
    enabled: bool


@app.get("/healthz")
def healthz():
    """Liveness check kept minimal for fast, stable probes (tests expect only status)."""
    return {"status": "ok"}


@app.get("/readyz")
def readyz():
    """Readiness check loads optional model and reports capability flags (tests expect keys)."""
    model, _ = _maybe_load_clip()
    return {
        "ready": True,  # Add real dependency checks here if needed
        "model_version": settings.IMAGE_MODEL_VERSION,
        "clip_available": bool(model),
        "enable_clip": settings.ENABLE_CLIP,
    }


@app.get("/health")
def legacy_health():  # backward compatibility
    return {"status": "ok", "model_version": settings.IMAGE_MODEL_VERSION}


@app.post("/hash", response_model=HashResponse)
async def hash_image(file: UploadFile = File(...)):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(400, "File must be an image")
    data = await file.read()
    img = Image.open(BytesIO(data))
    img = _preprocess(img)
    ph = imagehash.phash(img, hash_size=settings.HASH_SIZE)
    dh = imagehash.dhash(img, hash_size=settings.HASH_SIZE)
    ah = imagehash.average_hash(img, hash_size=settings.HASH_SIZE)
    wh = imagehash.whash(img, hash_size=settings.HASH_SIZE)
    try:
        ch = imagehash.colorhash(img)
    except Exception:  # pragma: no cover
        ch = "0"
    w, h = img.size
    return HashResponse(
        phash=str(ph),
        dhash=str(dh),
        ahash=str(ah),
        whash=str(wh),
        colorhash=str(ch),
        width=w,
        height=h,
        model_version=settings.IMAGE_MODEL_VERSION,
    )


@app.post("/compare", response_model=CompareResponse)
async def compare(req: CompareRequest):
    h1 = imagehash.hex_to_hash(req.h1)
    h2 = imagehash.hex_to_hash(req.h2)
    return CompareResponse(distance=int(h1 - h2))


@app.post("/embed", response_model=CLIPEmbeddingResponse)
async def embed_image(file: UploadFile = File(...)):
    model, preprocess = _maybe_load_clip()
    if model is None:
        # return deterministic dummy embedding based on hash of bytes length for consistency
        data = await file.read()
        rng = np.random.default_rng(len(data))
        emb = rng.random(512).tolist()
        return CLIPEmbeddingResponse(embedding=emb, dim=512, model_name=settings.CLIP_MODEL, enabled=False)
    data = await file.read()
    img = Image.open(BytesIO(data))
    img = _preprocess(img)
    import torch  # local import
    image_tensor = preprocess(img).unsqueeze(0)
    device = next(model.parameters()).device
    image_tensor = image_tensor.to(device)
    with torch.no_grad():
        embedding = model.encode_image(image_tensor).cpu().numpy().flatten().tolist()
    return CLIPEmbeddingResponse(embedding=embedding, dim=len(embedding), model_name=settings.CLIP_MODEL, enabled=True)


if __name__ == "__main__":  # pragma: no cover
    import uvicorn
    uvicorn.run(app, host=settings.HOST, port=settings.PORT)