import os
import subprocess
import logging
from typing import List, Literal, Optional, Dict, Any
from functools import lru_cache

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings
import numpy as np
try:
    from backend.common.health import readiness  # type: ignore
except Exception:  # pragma: no cover - fallback if path not yet set
    readiness = None  # runtime safe fallback
from langdetect import detect, DetectorFactory
from langdetect.lang_detect_exception import LangDetectException

# Set seed for consistent language detection
DetectorFactory.seed = 0

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    APP_NAME: str = "nlp-service"
    HOST: str = "0.0.0.0"
    PORT: int = 8090
    
    # Model configuration
    NLP_MODE: Literal["dummy", "real"] = "real"
    EMBEDDING_MODEL: str = "intfloat/multilingual-e5-small"
    NER_MODEL: str = "xx_ent_wiki_sm"  # Multilingual NER
    FALLBACK_NER_MODEL: str = "en_core_web_sm"
    SPACY_EN_MODEL_VERSION: str = os.getenv("SPACY_EN_MODEL_VERSION", "3.7.1")
    SPACY_XX_MODEL_VERSION: str = os.getenv("SPACY_XX_MODEL_VERSION", "3.7.0")
    NORMALIZE_EMBEDDINGS: bool = True
    MODEL_NAME: str = "multilingual-e5-small"
    MODEL_VERSION: str = "1"
    
    # Language support
    SUPPORTED_LANGUAGES: List[str] = ["en", "si", "ta"]
    DEFAULT_LANGUAGE: str = "en"
    
    # Translation settings
    ENABLE_TRANSLATION: bool = True
    TRANSLATION_SERVICE: Literal["google", "libre"] = "google"
    
    # Performance settings
    MAX_TEXT_LENGTH: int = 512
    BATCH_SIZE: int = 32
    CACHE_SIZE: int = 1000
    
    # Redis cache (optional)
    REDIS_URL: Optional[str] = None
    CACHE_TTL: int = 3600  # 1 hour

    class Config:
        env_file = ".env"
        extra = "ignore"  # Ignore extra environment variables

settings = Settings()
app = FastAPI(
    title=settings.APP_NAME,
    description="Multilingual NLP service for Lost & Found system",
    version="2.0.0"
)

# Global model instances
_embedding_model = None
_ner_model = None
_translator = None
_models_ready = {"embedding": False, "ner": False}
_cache = {}

# Reused description literals (avoid duplication lint warnings)
DESC_DETECTED_LANGUAGES = "Detected languages"
DESC_EMBEDDING_DIM = "Embedding dimension"
DESC_EMBEDDING_VECTORS = "Embedding vectors"

# --- Model loaders (lazy loading) ---
def _load_embedding_model():
    """Load E5-multilingual embedding model"""
    global _embedding_model
    if _embedding_model is not None:
        return _embedding_model
    
    try:
        from sentence_transformers import SentenceTransformer
        logger.info(f"Loading embedding model: {settings.EMBEDDING_MODEL}")
        _embedding_model = SentenceTransformer(settings.EMBEDDING_MODEL)
        _models_ready["embedding"] = True
        logger.info("Embedding model loaded successfully")
        return _embedding_model
    except Exception as e:
        logger.error(f"Could not load embedding model: {e}")
        return None

def _ensure_spacy_model(model_name: str) -> bool:
    """Ensure a spaCy model is installed; attempt runtime download if missing.
    Returns True if available after the check, else False."""
    try:
        import importlib
        import spacy
        # If already loadable, return
        spacy.load(model_name)
        return True
    except Exception:
        # Attempt a controlled download using exact wheel URL if version known
        version_map = {
            'en_core_web_sm': settings.SPACY_EN_MODEL_VERSION,
            'xx_ent_wiki_sm': settings.SPACY_XX_MODEL_VERSION,
        }
        ver = version_map.get(model_name)
        wheel_url = None
        if ver:
            wheel_url = f"https://github.com/explosion/spacy-models/releases/download/{model_name}-{ver}/{model_name}-{ver}-py3-none-any.whl"
        try:
            if wheel_url:
                logger.info(f"Attempting runtime wheel install for {model_name} ({ver})")
                subprocess.run(["pip", "install", "--no-cache-dir", wheel_url], check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            else:
                logger.info(f"Attempting runtime spacy download for {model_name}")
                subprocess.run(["python", "-m", "spacy", "download", model_name], check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            import spacy as _sp
            _sp.load(model_name)
            logger.info(f"Model {model_name} available after runtime install")
            return True
        except Exception as e:
            logger.warning(f"Runtime installation failed for {model_name}: {e}")
            return False

def _load_ner_model():
    """Load multilingual NER model"""
    global _ner_model
    if _ner_model is not None:
        return _ner_model
    
    import spacy
    target = settings.NER_MODEL
    if not _ensure_spacy_model(target):
        logger.error(f"Primary NER model {target} unavailable, attempting fallback {settings.FALLBACK_NER_MODEL}")
        if not _ensure_spacy_model(settings.FALLBACK_NER_MODEL):
            logger.error("No spaCy NER model could be loaded")
            return None
        target = settings.FALLBACK_NER_MODEL
    try:
        _ner_model = spacy.load(target)
        _models_ready["ner"] = True
        logger.info(f"NER model loaded: {target}")
        return _ner_model
    except Exception as e:
        logger.error(f"Unexpected failure loading model {target}: {e}")
        return None

def _load_translator():
    """Load translation service"""
    global _translator
    if _translator is not None or not settings.ENABLE_TRANSLATION:
        return _translator
    
    try:
        from deep_translator import GoogleTranslator
        _translator = GoogleTranslator(source='auto', target='en')
        logger.info(f"Translation service loaded: GoogleTranslator (via deep-translator)")
    except Exception as e:
        logger.error(f"Could not load translator: {e}")
        return None
    
    return _translator


# --- Utility functions ---
@lru_cache(maxsize=settings.CACHE_SIZE)
def _detect_language(text: str) -> str:
    """Detect language of text with caching"""
    try:
        detected = detect(text)
        return detected if detected in settings.SUPPORTED_LANGUAGES else settings.DEFAULT_LANGUAGE
    except (LangDetectException, Exception):
        return settings.DEFAULT_LANGUAGE

def _preprocess_text(text: str, max_length: int = None) -> str:
    """Preprocess text for embedding"""
    if not text:
        return ""
    
    # Truncate if too long
    max_len = max_length or settings.MAX_TEXT_LENGTH
    if len(text) > max_len:
        text = text[:max_len]
    
    # Basic cleaning
    text = text.strip()
    return text

def _dummy_embed(texts: List[str]) -> np.ndarray:
    """Dummy embedding for fallback mode"""
    dim = 384
    mat = np.zeros((len(texts), dim), dtype=np.float32)
    for i, t in enumerate(texts):
        s = (t or "").lower().strip()
        for j in range(len(s)):
            h = (hash(s[j:j+3]) % dim)
            mat[i, h] += 1.0
        if settings.NORMALIZE_EMBEDDINGS:
            n = np.linalg.norm(mat[i])
            if n > 0:
                mat[i] = mat[i] / n
    return mat

# --- Pydantic Models ---
class EmbedRequest(BaseModel):
    texts: List[str] = Field(..., description="List of texts to embed")
    kind: Literal["query", "passage"] = Field(default="passage", description="E5 prefix type")
    normalize: Optional[bool] = Field(default=None, description="Whether to normalize embeddings")
    language: Optional[str] = Field(default=None, description="Language hint for text")

class EmbedResponse(BaseModel):
    vectors: List[List[float]] = Field(..., description=DESC_EMBEDDING_VECTORS)
    dim: int = Field(..., description=DESC_EMBEDDING_DIM)
    mode: str = Field(..., description="Model mode (real/dummy)")
    model_name: Optional[str] = Field(default=None, description="Model name used")
    languages_detected: List[str] = Field(default=[], description="Detected languages")

class Entity(BaseModel):
    text: str = Field(..., description="Entity text")
    label: str = Field(..., description="Entity label/type")
    start: int = Field(..., description="Start position in text")
    end: int = Field(..., description="End position in text")
    confidence: float = Field(..., description="Confidence score")

class NERRequest(BaseModel):
    texts: List[str] = Field(..., description="List of texts for NER")
    language: Optional[str] = Field(default=None, description="Language hint")
    extract_attributes: bool = Field(default=True, description="Extract item attributes")

class NERResponse(BaseModel):
    entities: List[List[Entity]] = Field(..., description="Entities for each text")
    attributes: List[Dict[str, Any]] = Field(..., description="Extracted attributes")
    languages_detected: List[str] = Field(default=[], description=DESC_DETECTED_LANGUAGES)

class LanguageDetectionRequest(BaseModel):
    texts: List[str] = Field(..., description="Texts for language detection")

class LanguageDetectionResponse(BaseModel):
    languages: List[str] = Field(..., description=DESC_DETECTED_LANGUAGES)
    confidences: List[float] = Field(..., description="Detection confidences")

class TranslationRequest(BaseModel):
    texts: List[str] = Field(..., description="Texts to translate")
    target_language: str = Field(default="en", description="Target language")
    source_language: Optional[str] = Field(default=None, description="Source language (auto-detect if None)")

class TranslationResponse(BaseModel):
    translations: List[str] = Field(..., description="Translated texts")
    source_languages: List[str] = Field(..., description="Detected source languages")
    target_language: str = Field(..., description="Target language")

class AttributeExtractionRequest(BaseModel):
    texts: List[str] = Field(..., description="Item descriptions")
    categories: Optional[List[str]] = Field(default=None, description="Item categories for context")

class AttributeExtractionResponse(BaseModel):
    attributes: List[Dict[str, Any]] = Field(..., description="Extracted attributes per text")
    entities: List[List[Entity]] = Field(..., description="All entities found")
    languages: List[str] = Field(..., description=DESC_DETECTED_LANGUAGES)


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


def _embedding_ready():
    return _models_ready["embedding"]

def _ner_ready():
    return _models_ready["ner"]

if readiness is not None:
    try:
        readiness.register("embedding_model", _embedding_ready)
        readiness.register("ner_model", _ner_ready)
    except Exception:  # pragma: no cover
        pass

@app.get("/readyz")
def readyz():
    # Opportunistically trigger lazy loads without blocking too long
    if not _models_ready["embedding"]:
        _load_embedding_model()
    if not _models_ready["ner"]:
        _load_ner_model()
    details = {
        "embedding_model_loaded": _models_ready["embedding"],
        "ner_model_loaded": _models_ready["ner"],
    }
    overall = all(details.values())
    return {"ready": overall, **details}


@app.post("/embed", response_model=EmbedResponse)
def embed(req: EmbedRequest):
    # Backwards compatibility for normalize flag naming
    requested_normalize = req.normalize if req.normalize is not None else settings.NORMALIZE_EMBEDDINGS
    texts = [f"{req.kind}: " + t for t in req.texts]

    arr = None
    if settings.NLP_MODE == "real":
        model = _load_embedding_model()
        if model is not None:
            try:
                vecs = model.encode(texts, normalize_embeddings=requested_normalize)
                arr = np.asarray(vecs, dtype=np.float32)
            except Exception as e:
                logger.error(f"Embedding model encode failed, falling back to dummy embeddings: {e}")
    if arr is None:
        arr = _dummy_embed(texts)

    return EmbedResponse(
        vectors=arr.tolist(),
        dim=int(arr.shape[1]),
        mode=settings.NLP_MODE,
        model_name=settings.EMBEDDING_MODEL,
        model_version="unknown",
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=settings.HOST, port=settings.PORT)