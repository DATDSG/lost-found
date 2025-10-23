"""
MinIO Object Storage Integration
===============================
S3-compatible object storage for media files with proper error handling and caching.
"""
import os
import logging
from typing import Optional, BinaryIO, Union, Dict, Any
from datetime import datetime, timedelta
import mimetypes
import hashlib
from pathlib import Path

try:
    from minio import Minio
    from minio.error import S3Error
    MINIO_AVAILABLE = True
except ImportError:
    Minio = None
    S3Error = Exception
    MINIO_AVAILABLE = False

from .config import config

logger = logging.getLogger(__name__)


class MinIOClient:
    """MinIO client for object storage operations."""
    
    def __init__(self):
        if not MINIO_AVAILABLE:
            raise RuntimeError("minio package is required for object storage support")
        
        # Parse endpoint to remove protocol and path
        endpoint_raw = os.getenv("MINIO_ENDPOINT", "localhost:9000")
        if "://" in endpoint_raw:
            endpoint_raw = endpoint_raw.split("://", 1)[1]  # Remove protocol
        if "/" in endpoint_raw:
            endpoint_raw = endpoint_raw.split("/", 1)[0]  # Remove path
        
        self.endpoint = endpoint_raw
        self.access_key = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
        self.secret_key = os.getenv("MINIO_SECRET_KEY", "minioadmin")
        self.bucket_name = os.getenv("MINIO_BUCKET_NAME", "lost-found-media")
        self.secure = os.getenv("MINIO_SECURE", "false").lower() == "true"
        self.region = os.getenv("MINIO_REGION", "us-east-1")
        
        # Initialize MinIO client
        self.client = Minio(
            endpoint=self.endpoint,
            access_key=self.access_key,
            secret_key=self.secret_key,
            secure=self.secure
        )
        
        # Ensure bucket exists
        self._ensure_bucket_exists()
    
    def _ensure_bucket_exists(self) -> None:
        """Ensure the default bucket exists."""
        try:
            if not self.client.bucket_exists(self.bucket_name):
                self.client.make_bucket(self.bucket_name)
                logger.info(f"Created MinIO bucket: {self.bucket_name}")
        except S3Error as e:
            logger.error(f"Failed to create bucket {self.bucket_name}: {e}")
            raise
    
    def upload_file(
        self,
        file_path: str,
        object_name: str = None,
        bucket_name: str = None,
        content_type: str = None
    ) -> Dict[str, Any]:
        """Upload a file to MinIO."""
        bucket = bucket_name or self.bucket_name
        object_name = object_name or os.path.basename(file_path)
        
        # Determine content type
        if not content_type:
            content_type, _ = mimetypes.guess_type(file_path)
            content_type = content_type or "application/octet-stream"
        
        try:
            # Upload file
            self.client.fput_object(
                bucket_name=bucket,
                object_name=object_name,
                file_path=file_path,
                content_type=content_type
            )
            
            # Generate URL
            url = f"{'https' if self.secure else 'http'}://{self.endpoint}/{bucket}/{object_name}"
            
            # Get file info
            stat = self.client.stat_object(bucket_name=bucket, object_name=object_name)
            
            result = {
                "success": True,
                "url": url,
                "bucket": bucket,
                "object_name": object_name,
                "size": stat.size,
                "content_type": content_type,
                "etag": stat.etag,
                "last_modified": stat.last_modified.isoformat()
            }
            
            logger.info(f"Uploaded file to MinIO: {url}")
            return result
            
        except S3Error as e:
            logger.error(f"Failed to upload file {file_path}: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def upload_data(
        self,
        data: Union[bytes, BinaryIO],
        object_name: str,
        bucket_name: str = None,
        content_type: str = None,
        length: int = None
    ) -> Dict[str, Any]:
        """Upload data directly to MinIO."""
        bucket = bucket_name or self.bucket_name
        
        try:
            # Upload data
            self.client.put_object(
                bucket_name=bucket,
                object_name=object_name,
                data=data,
                length=length,
                content_type=content_type
            )
            
            # Generate URL
            url = f"{'https' if self.secure else 'http'}://{self.endpoint}/{bucket}/{object_name}"
            
            result = {
                "success": True,
                "url": url,
                "bucket": bucket,
                "object_name": object_name,
                "content_type": content_type
            }
            
            logger.info(f"Uploaded data to MinIO: {url}")
            return result
            
        except S3Error as e:
            logger.error(f"Failed to upload data {object_name}: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def download_file(
        self,
        object_name: str,
        file_path: str,
        bucket_name: str = None
    ) -> Dict[str, Any]:
        """Download a file from MinIO."""
        bucket = bucket_name or self.bucket_name
        
        try:
            self.client.fget_object(
                bucket_name=bucket,
                object_name=object_name,
                file_path=file_path
            )
            
            logger.info(f"Downloaded file from MinIO: {object_name}")
            return {
                "success": True,
                "file_path": file_path
            }
            
        except S3Error as e:
            logger.error(f"Failed to download file {object_name}: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def download_data(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> Dict[str, Any]:
        """Download data directly from MinIO."""
        bucket = bucket_name or self.bucket_name
        
        try:
            response = self.client.get_object(
                bucket_name=bucket,
                object_name=object_name
            )
            data = response.read()
            response.close()
            response.release_conn()
            
            logger.info(f"Downloaded data from MinIO: {object_name}")
            return {
                "success": True,
                "data": data
            }
            
        except S3Error as e:
            logger.error(f"Failed to download data {object_name}: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def delete_file(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> Dict[str, Any]:
        """Delete a file from MinIO."""
        bucket = bucket_name or self.bucket_name
        
        try:
            self.client.remove_object(
                bucket_name=bucket,
                object_name=object_name
            )
            
            logger.info(f"Deleted file from MinIO: {object_name}")
            return {
                "success": True,
                "object_name": object_name
            }
            
        except S3Error as e:
            logger.error(f"Failed to delete file {object_name}: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def file_exists(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> bool:
        """Check if a file exists in MinIO."""
        bucket = bucket_name or self.bucket_name
        
        try:
            self.client.stat_object(bucket_name=bucket, object_name=object_name)
            return True
        except S3Error:
            return False
    
    def get_file_info(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> Optional[Dict[str, Any]]:
        """Get file information from MinIO."""
        bucket = bucket_name or self.bucket_name
        
        try:
            stat = self.client.stat_object(bucket_name=bucket, object_name=object_name)
            return {
                "size": stat.size,
                "etag": stat.etag,
                "last_modified": stat.last_modified.isoformat(),
                "content_type": stat.content_type,
                "metadata": stat.metadata
            }
        except S3Error as e:
            logger.error(f"Failed to get file info {object_name}: {e}")
            return None
    
    def list_files(
        self,
        prefix: str = "",
        bucket_name: str = None,
        recursive: bool = True
    ) -> list:
        """List files in MinIO bucket."""
        bucket = bucket_name or self.bucket_name
        
        try:
            objects = self.client.list_objects(
                bucket_name=bucket,
                prefix=prefix,
                recursive=recursive
            )
            return [obj.object_name for obj in objects]
        except S3Error as e:
            logger.error(f"Failed to list files: {e}")
            return []
    
    def get_presigned_url(
        self,
        object_name: str,
        bucket_name: str = None,
        expires_in: int = 3600,
        method: str = "GET"
    ) -> Optional[str]:
        """Generate a presigned URL for object access."""
        bucket = bucket_name or self.bucket_name
        
        try:
            url = self.client.presigned_url(
                method=method,
                bucket_name=bucket,
                object_name=object_name,
                expires=expires_in
            )
            return url
        except S3Error as e:
            logger.error(f"Failed to generate presigned URL for {object_name}: {e}")
            return None
    
    def health_check(self) -> Dict[str, Any]:
        """Check MinIO service health."""
        try:
            # Try to list buckets
            buckets = self.client.list_buckets()
            bucket_names = [bucket.name for bucket in buckets]
            
            return {
                "status": "healthy",
                "endpoint": self.endpoint,
                "bucket_count": len(buckets),
                "buckets": bucket_names,
                "default_bucket_exists": self.bucket_name in bucket_names
            }
        except Exception as e:
            logger.error(f"MinIO health check failed: {e}")
            return {
                "status": "unhealthy",
                "error": str(e)
            }


# Global MinIO client instance
_minio_client: Optional[MinIOClient] = None


def get_minio_client() -> MinIOClient:
    """Get MinIO client instance."""
    global _minio_client
    if _minio_client is None:
        _minio_client = MinIOClient()
    return _minio_client


def generate_object_name(original_filename: str, prefix: str = "") -> str:
    """Generate a unique object name for storage."""
    # Get file extension
    ext = Path(original_filename).suffix.lower()
    
    # Generate unique name with timestamp and hash
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    hash_suffix = hashlib.md5(original_filename.encode()).hexdigest()[:8]
    
    # Combine prefix, timestamp, hash, and extension
    object_name = f"{prefix}{timestamp}_{hash_suffix}{ext}"
    
    return object_name


def validate_file_type(filename: str, allowed_types: list = None) -> bool:
    """Validate file type against allowed types."""
    if allowed_types is None:
        allowed_types = config.ALLOWED_IMAGE_TYPES
    
    content_type, _ = mimetypes.guess_type(filename)
    return content_type in allowed_types


def get_file_size_mb(file_path: str) -> float:
    """Get file size in MB."""
    return os.path.getsize(file_path) / (1024 * 1024)
