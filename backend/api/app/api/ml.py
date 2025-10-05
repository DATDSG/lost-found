"""ML integration router exposing stable contracts for embeddings and vision signatures.

These endpoints do NOT implement heavy ML locally; they proxy to dedicated
microservices (NLP / Vision) or provide graceful fallbacks when disabled or
unavailable. This ensures the rest of the system can rely on a unified,
versioned contract irrespective of backend deployment topology.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from loguru import logger

from app.core.config import settings
from app.schemas.integrations import (
    EmbeddingRequest,
    EmbeddingResponse,
    VisionSignatureRequest,
    VisionSignatureResponse,
)
from app.integrations.nlp_provider import HTTPEmbeddingProvider, EmbeddingProvider
from app.integrations.vision_provider import HTTPVisionProvider, VisionProvider

router = APIRouter(prefix="/ml", tags=["ML Integrations"])  # Tag groups in OpenAPI


def get_embedding_provider() -> EmbeddingProvider:
    return HTTPEmbeddingProvider()


def get_vision_provider() -> VisionProvider:
    return HTTPVisionProvider()


@router.post("/embed", response_model=EmbeddingResponse, summary="Get text embeddings")
async def embed_texts(
    req: EmbeddingRequest,
    provider: EmbeddingProvider = Depends(get_embedding_provider),
):
    if not settings.NLP_ON:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="NLP features disabled",
        )
    resp = await provider.embed(req)
    return resp


@router.post(
    "/vision/signatures",
    response_model=VisionSignatureResponse,
    summary="Extract vision signatures / perceptual hashes",
)
async def vision_signatures(
    req: VisionSignatureRequest,
    provider: VisionProvider = Depends(get_vision_provider),
):
    if not settings.CV_ON:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Computer Vision features disabled",
        )
    try:
        if req.image_urls is None and req.image_keys is None:
            raise HTTPException(status_code=422, detail="Provide image_urls or image_keys")
        resp = await provider.signatures(req)
        return resp
    except HTTPException:
        raise
    except Exception as e:  # pragma: no cover - defensive
        logger.exception("Unexpected error in vision signatures endpoint")
        raise HTTPException(status_code=500, detail=str(e))


__all__ = ["router"]
