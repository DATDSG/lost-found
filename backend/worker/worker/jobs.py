from __future__ import annotations

import os
from io import BytesIO
from typing import Any, Dict

import boto3
import imagehash
import requests
from PIL import Image
from loguru import logger

# --- Optional S3 client (only used if env vars are set) ---
S3_ENDPOINT_URL = os.getenv("S3_ENDPOINT_URL")
S3_REGION = os.getenv("S3_REGION")
S3_ACCESS_KEY_ID = os.getenv("S3_ACCESS_KEY_ID")
S3_SECRET_ACCESS_KEY = os.getenv("S3_SECRET_ACCESS_KEY")
S3_BUCKET = os.getenv("S3_BUCKET")

_s3 = None
if S3_BUCKET:
    _s3 = boto3.client(
        "s3",
        endpoint_url=S3_ENDPOINT_URL,
        region_name=S3_REGION,
        aws_access_key_id=S3_ACCESS_KEY_ID,
        aws_secret_access_key=S3_SECRET_ACCESS_KEY,
    )


NLP_URL = os.getenv("NLP_URL", "http://127.0.0.1:8090")
NLP_MODEL_VERSION = os.getenv("NLP_MODEL_VERSION", "intfloat/multilingual-e5-small")
VISION_URL = os.getenv("VISION_URL")
VISION_MODEL_VERSION = os.getenv("VISION_MODEL_VERSION", "phash-v1")


# -------------------
# Image helpers
# -------------------

def make_thumbnail(bucket: str, key: str, thumb_key: str, size: int = 256) -> Dict[str, Any]:
    """Create a thumbnail for the given object and upload to S3."""
    assert _s3 is not None, "S3 is not configured"
    obj = _s3.get_object(Bucket=bucket, Key=key)
    img = Image.open(obj["Body"]).convert("RGB")
    img.thumbnail((size, size))
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=85)
    buf.seek(0)
    _s3.put_object(Bucket=bucket, Key=thumb_key, Body=buf, ContentType="image/jpeg")
    logger.info("Thumbnail uploaded to s3://%s/%s", bucket, thumb_key)
    return {"thumb_key": thumb_key}


def compute_hashes_from_s3(bucket: str, key: str) -> Dict[str, Any]:
    """Compute perceptual hashes directly from an S3 object."""
    assert _s3 is not None, "S3 is not configured"
    obj = _s3.get_object(Bucket=bucket, Key=key)
    img = Image.open(obj["Body"]).convert("RGB")
    return {
        "phash": str(imagehash.phash(img)),
        "dhash": str(imagehash.dhash(img)),
        "ahash": str(imagehash.average_hash(img)),
        "image_model_version": VISION_MODEL_VERSION,
    }


def compute_hashes_via_service(image_bytes: bytes) -> Dict[str, Any]:
    """Delegate hash computation to the vision microservice."""
    assert VISION_URL, "VISION_URL not set"
    response = requests.post(f"{VISION_URL}/hash", files={"file": ("image.jpg", image_bytes)})
    response.raise_for_status()
    payload = response.json()
    return {
        "phash": payload["phash"],
        "dhash": payload["dhash"],
        "ahash": payload["ahash"],
        "image_model_version": payload.get("model_version", VISION_MODEL_VERSION),
    }


# -------------------
# NLP helpers
# -------------------

def embed_text(text: str, kind: str = "passage") -> Dict[str, Any]:
    payload = {"texts": [text], "kind": kind}
    response = requests.post(f"{NLP_URL}/embed", json=payload)
    response.raise_for_status()
    body = response.json()
    return {
        "vector": body["vectors"][0],
        "dim": body["dim"],
        "mode": body["mode"],
        "model_name": body.get("model_name"),
        "model_version": body.get("model_version", NLP_MODEL_VERSION),
    }


# -------------------
# Demo job that ties it together
# -------------------

def process_new_asset(bucket: str, key: str, thumb_key: str | None = None) -> Dict[str, Any]:
    """Example pipeline: thumbnail -> hashes -> caption embedding."""
    assert _s3 is not None, "S3 is not configured"
    result: Dict[str, Any] = {}

    if thumb_key:
        result.update(make_thumbnail(bucket, key, thumb_key))

    obj = _s3.get_object(Bucket=bucket, Key=key)
    data = obj["Body"].read()
    if VISION_URL:
        result.update(compute_hashes_via_service(data))
    else:
        # Fallback to local hashing when service is unavailable
        img = Image.open(BytesIO(data)).convert("RGB")
        result.update({
            "phash": str(imagehash.phash(img)),
            "dhash": str(imagehash.dhash(img)),
            "ahash": str(imagehash.average_hash(img)),
            "image_model_version": VISION_MODEL_VERSION,
        })

    caption = f"photo with hashes {result['phash'][:8]}.."
    result["embedding"] = embed_text(caption, kind="passage")

    logger.info("Processed %s/%s: %s", bucket, key, result)
    return result