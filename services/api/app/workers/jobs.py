from PIL import Image
from io import BytesIO
import boto3
from app.core.config import settings
from app.utils.hash import phash_hex

s3 = boto3.client(
    "s3",
    endpoint_url=settings.S3_ENDPOINT_URL,
    region_name=settings.S3_REGION,
    aws_access_key_id=settings.S3_ACCESS_KEY_ID,
    aws_secret_access_key=settings.S3_SECRET_ACCESS_KEY,
)

def make_thumbnail(bucket: str, key: str, thumb_key: str, size: int = 256):
    obj = s3.get_object(Bucket=bucket, Key=key)
    img = Image.open(obj["Body"]).convert("RGB")
    img.thumbnail((size, size))
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=85)
    buf.seek(0)
    s3.put_object(Bucket=bucket, Key=thumb_key, Body=buf, ContentType="image/jpeg")
    return {"thumb_key": thumb_key}

def compute_phash(bucket: str, key: str) -> str:
    obj = s3.get_object(Bucket=bucket, Key=key)
    return phash_hex(Image.open(obj["Body"]))

def dummy_embed_text(text: str) -> list[float]:
    # Placeholder lightweight embedding for demo/testing
    return [float(len(text) % 7), 0.0, 1.0]