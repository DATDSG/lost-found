import os
import logging
from typing import List, Literal, Optional, Dict, Any
from functools import lru_cache

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings
import numpy as np
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
    NORMALIZE_EMBEDDINGS: bool = True
    
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
_cache = {}

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
        logger.info("Embedding model loaded successfully")
        return _embedding_model
    except Exception as e:
        logger.error(f"Could not load embedding model: {e}")
        return None

def _load_ner_model():
    """Load multilingual NER model"""
    global _ner_model
    if _ner_model is not None:
        return _ner_model
    
    try:
        import spacy
        logger.info(f"Loading NER model: {settings.NER_MODEL}")
        _ner_model = spacy.load(settings.NER_MODEL)
        logger.info("NER model loaded successfully")
        return _ner_model
    except Exception as e:
        logger.error(f"Could not load NER model: {e}")
        try:
            # Fallback to English model
            import spacy
            _ner_model = spacy.load("en_core_web_sm")
            logger.info("Loaded fallback English NER model")
            return _ner_model
        except Exception as e2:
            logger.error(f"Could not load fallback NER model: {e2}")
            return None

def _load_translator():
    """Load translation service"""
    global _translator
    if _translator is not None or not settings.ENABLE_TRANSLATION:
        return _translator
    
    try:
        if settings.TRANSLATION_SERVICE == "google":
            from googletrans import Translator
            _translator = Translator()
        else:
            from deep_translator import LibreTranslator
            _translator = LibreTranslator(source='auto', target='en')
        logger.info(f"Translation service loaded: {settings.TRANSLATION_SERVICE}")
    except Exception as e:
        logger.error(f"Could not load translator: {e}")
        return None


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
    vectors: List[List[float]] = Field(..., description="Embedding vectors")
    dim: int = Field(..., description="Embedding dimension")
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
    languages_detected: List[str] = Field(default=[], description="Detected languages")

class LanguageDetectionRequest(BaseModel):
    texts: List[str] = Field(..., description="Texts for language detection")

class LanguageDetectionResponse(BaseModel):
    languages: List[str] = Field(..., description="Detected languages")
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
    languages: List[str] = Field(..., description="Detected languages")


@app.get("/health")
def health():
    return {
        "status": "ok",
        "mode": settings.NLP_MODE,
        "model_name": settings.MODEL_NAME,
        "model_version": settings.MODEL_VERSION,
    }


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
        model_name=settings.MODEL_NAME,
        model_version=settings.MODEL_VERSION,
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=settings.HOST, port=settings.PORT)