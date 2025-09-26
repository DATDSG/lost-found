from __future__ import annotations
import os
from io import BytesIO
from typing import Any, Dict
from loguru import logger
import requests
from PIL import Image
import imagehash
import boto3

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
VISION_URL = os.getenv("VISION_URL")

# -------------------
# Image helpers
# -------------------

def make_thumbnail(bucket: str, key: str, thumb_key: str, size: int = 256) -> Dict[str, Any]:
    assert _s3 is not None, "S3 is not configured"
    obj = _s3.get_object(Bucket=bucket, Key=key)
    img = Image.open(obj["Body"]).convert("RGB")
    img.thumbnail((size, size))
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=85)
    buf.seek(0)
    _s3.put_object(Bucket=bucket, Key=thumb_key, Body=buf, ContentType="image/jpeg")
    logger.info(f"Thumbnail uploaded to s3://{bucket}/{thumb_key}")
    return {"thumb_key": thumb_key}

def compute_hashes_from_s3(bucket: str, key: str) -> Dict[str, Any]:
    assert _s3 is not None, "S3 is not configured"
    obj = _s3.get_object(Bucket=bucket, Key=key)
    img = Image.open(obj["Body"]).convert("RGB")
    ph = str(imagehash.phash(img))
    dh = str(imagehash.dhash(img))
    ah = str(imagehash.average_hash(img))
    return {"phash": ph, "dhash": dh, "ahash": ah}

def compute_hashes_via_service(image_bytes: bytes) -> Dict[str, Any]:
    assert VISION_URL, "VISION_URL not set"
    r = requests.post(f"{VISION_URL}/hash", files={"file": ("image.jpg", image_bytes)})
    r.raise_for_status()
    j = r.json()
    return {"phash": j["phash"], "dhash": j["dhash"], "ahash": j["ahash"]}

# -------------------
# NLP helpers
# -------------------

def embed_text(text: str, kind: str = "passage") -> Dict[str, Any]:
    payload = {"texts": [text], "kind": kind}
    r = requests.post(f"{NLP_URL}/embed", json=payload)
    r.raise_for_status()
    j = r.json()
    return {"vector": j["vectors"][0], "dim": j["dim"], "mode": j["mode"]}

# -------------------
# Demo job that ties it together
# -------------------

def process_new_asset(bucket: str, key: str, thumb_key: str | None = None) -> Dict[str, Any]:
    """Example pipeline: thumbnail -> hashes -> trivial caption embedding."""
    assert _s3 is not None, "S3 is not configured"
    out: Dict[str, Any] = {}

    if thumb_key:
        out.update(make_thumbnail(bucket, key, thumb_key))

    # Hashes
    obj = _s3.get_object(Bucket=bucket, Key=key)
    data = obj["Body"].read()
    if VISION_URL:
        out.update(compute_hashes_via_service(data))
    else:
        img = Image.open(BytesIO(data)).convert("RGB")
        out.update({
            "phash": str(imagehash.phash(img)),
            "dhash": str(imagehash.dhash(img)),
            "ahash": str(imagehash.average_hash(img)),
        })

    # Tiny example NLP call
    caption = f"photo with hashes {out['phash'][:8]}.."
    out["embedding"] = embed_text(caption, kind="passage")

    logger.info(f"Processed {bucket}/{key}: {out}")
    return out