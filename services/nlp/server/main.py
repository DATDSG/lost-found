import os
from typing import List, Literal
from fastapi import FastAPI
from pydantic import BaseModel
from pydantic_settings import BaseSettings
import numpy as np

class Settings(BaseSettings):
    APP_NAME: str = "nlp-service"
    HOST: str = "0.0.0.0"
    PORT: int = 8090
    NLP_MODE: Literal["dummy", "real"] = "dummy"
    MODEL_NAME: str = "intfloat/multilingual-e5-small"
    NORMALIZE: bool = True

    class Config:
        env_file = ".env"

settings = Settings()
app = FastAPI(title=settings.APP_NAME)

_model = None

# --- Optional real model loader (lazy) ---
def _load_real_model():
    global _model
    if _model is not None:
        return _model
    try:
        from sentence_transformers import SentenceTransformer
        _model = SentenceTransformer(settings.MODEL_NAME)
        return _model
    except Exception as e:
        # Fallback silently to dummy if real model fails
        print(f"[nlp] Could not load real model ({e}); falling back to dummy mode.")
        settings.NLP_MODE = "dummy"
        return None


# --- Dummy embedding (deterministic, normalized) ---
def _dummy_embed(texts: List[str]) -> np.ndarray:
    # Simple hashing + n-gram counts to fixed dim (e.g., 384), seeded for determinism
    dim = 384
    mat = np.zeros((len(texts), dim), dtype=np.float32)
    for i, t in enumerate(texts):
        s = (t or "").lower().strip()
        # E5-compatible prefixes handled in API but they’re just part of text here
        for j in range(len(s)):
            h = (hash(s[j:j+3]) % dim)
            mat[i, h] += 1.0
        if settings.NORMALIZE:
            n = np.linalg.norm(mat[i])
            if n > 0:
                mat[i] = mat[i] / n
        return mat

# --- Schemas ---
class EmbedRequest(BaseModel):
    texts: List[str]
    kind: Literal["query", "passage"] = "passage" # E5 uses prefixes
    normalize: bool | None = None

class EmbedResponse(BaseModel):
    vectors: List[List[float]]
    dim: int
    mode: str
    model_name: str | None = None


@app.get("/health")
def health():
    return {"status": "ok", "mode": settings.NLP_MODE}


@app.post("/embed", response_model=EmbedResponse)
def embed(req: EmbedRequest):
    normalize = settings.NORMALIZE if req.normalize is None else req.normalize
    texts = [f"{req.kind}: " + t for t in req.texts]

    if settings.NLP_MODE == "real":
        m = _load_real_model()
        if m is not None:
            vecs = m.encode(texts, normalize_embeddings=normalize)
            arr = np.asarray(vecs, dtype=np.float32)
        else:
            arr = _dummy_embed(texts)
    else:
        arr = _dummy_embed(texts)

    return EmbedResponse(
        vectors=arr.tolist(),
        dim=int(arr.shape[1]),
        mode=settings.NLP_MODE,
        model_name=(settings.MODEL_NAME if settings.NLP_MODE == "real" else None),
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=settings.HOST, port=settings.PORT)