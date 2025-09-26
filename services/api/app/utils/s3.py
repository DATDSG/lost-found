import boto3
from botocore.exceptions import ClientError
from app.core.config import settings

_session = boto3.session.Session()
_s3 = _session.client(
    "s3",
    endpoint_url=settings.S3_ENDPOINT_URL,
    region_name=settings.S3_REGION,
    aws_access_key_id=settings.S3_ACCESS_KEY_ID,
    aws_secret_access_key=settings.S3_SECRET_ACCESS_KEY,
)

def ensure_bucket():
    try:
        _s3.head_bucket(Bucket=settings.S3_BUCKET)
    except ClientError:
        _s3.create_bucket(Bucket=settings.S3_BUCKET)

def presign_upload(key: str, content_type: str):
    conditions = [["starts-with", "$Content-Type", content_type.split("/")[0]]] # loose example
    fields = {"Content-Type": content_type}
    url = _s3.generate_presigned_post(
        Bucket=settings.S3_BUCKET,
        Key=key,
        Fields=fields,
        Conditions=conditions,
        ExpiresIn=settings.S3_PRESIGN_EXPIRES,
    )
    return url["fields"], url["conditions"], url["url"]

def presign_download(key: str) -> str | None:
    try:
        return _s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.S3_BUCKET, "Key": key},
            ExpiresIn=settings.S3_PRESIGN_EXPIRES,
        )
    except ClientError:
        return None