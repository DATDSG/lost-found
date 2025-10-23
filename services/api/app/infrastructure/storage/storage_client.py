"""
MinIO Storage Client for Infrastructure Layer
============================================
MinIO client implementation for object storage.
"""

from minio import Minio
from minio.error import S3Error
from typing import Optional, Dict, Any, BinaryIO
import logging
from ...config import config

logger = logging.getLogger(__name__)

class MinIOClient:
    """MinIO client wrapper with connection management."""
    
    def __init__(self, endpoint: str = None, access_key: str = None, secret_key: str = None):
        # Parse endpoint to remove protocol and path
        endpoint_raw = endpoint or config.MINIO_ENDPOINT
        if "://" in endpoint_raw:
            endpoint_raw = endpoint_raw.split("://", 1)[1]  # Remove protocol
        if "/" in endpoint_raw:
            endpoint_raw = endpoint_raw.split("/", 1)[0]  # Remove path
            
        self.endpoint = endpoint_raw
        self.access_key = access_key or config.MINIO_ACCESS_KEY
        self.secret_key = secret_key or config.MINIO_SECRET_KEY
        self.client: Optional[Minio] = None
    
    def connect(self):
        """Connect to MinIO."""
        try:
            self.client = Minio(
                self.endpoint,
                access_key=self.access_key,
                secret_key=self.secret_key,
                secure=config.MINIO_SECURE
            )
            logger.info("MinIO connection established")
        except Exception as e:
            logger.error(f"MinIO connection failed: {e}")
            raise
    
    def upload_file(self, bucket: str, object_name: str, file_path: str) -> bool:
        """Upload a file to MinIO."""
        if not self.client:
            self.connect()
        
        try:
            self.client.fput_object(bucket, object_name, file_path)
            logger.info(f"File uploaded: {bucket}/{object_name}")
            return True
        except S3Error as e:
            logger.error(f"MinIO upload failed: {e}")
            return False
    
    def download_file(self, bucket: str, object_name: str, file_path: str) -> bool:
        """Download a file from MinIO."""
        if not self.client:
            self.connect()
        
        try:
            self.client.fget_object(bucket, object_name, file_path)
            logger.info(f"File downloaded: {bucket}/{object_name}")
            return True
        except S3Error as e:
            logger.error(f"MinIO download failed: {e}")
            return False
    
    def delete_file(self, bucket: str, object_name: str) -> bool:
        """Delete a file from MinIO."""
        if not self.client:
            self.connect()
        
        try:
            self.client.remove_object(bucket, object_name)
            logger.info(f"File deleted: {bucket}/{object_name}")
            return True
        except S3Error as e:
            logger.error(f"MinIO delete failed: {e}")
            return False
    
    def get_file_url(self, bucket: str, object_name: str, expires: int = 3600) -> Optional[str]:
        """Get a presigned URL for a file."""
        if not self.client:
            self.connect()
        
        try:
            url = self.client.presigned_get_object(bucket, object_name, expires=expires)
            return url
        except S3Error as e:
            logger.error(f"MinIO URL generation failed: {e}")
            return None
    
    def list_files(self, bucket: str, prefix: str = "") -> list:
        """List files in a bucket."""
        if not self.client:
            self.connect()
        
        try:
            objects = self.client.list_objects(bucket, prefix=prefix, recursive=True)
            return [obj.object_name for obj in objects]
        except S3Error as e:
            logger.error(f"MinIO list failed: {e}")
            return []
    
    async def health_check(self) -> Dict[str, Any]:
        """Check MinIO health."""
        try:
            if not self.client:
                self.connect()
            
            # Try to list buckets as a health check
            buckets = self.client.list_buckets()
            return {
                "status": "healthy",
                "bucket_count": len(buckets),
                "endpoint": self.endpoint
            }
        except Exception as e:
            logger.error(f"MinIO health check failed: {e}")
            return {
                "status": "unhealthy",
                "error": str(e)
            }

# Global MinIO client instance
_minio_client: Optional[MinIOClient] = None

def get_minio_client() -> Optional[MinIOClient]:
    """Get the global MinIO client instance."""
    global _minio_client
    if _minio_client is None:
        try:
            _minio_client = MinIOClient()
        except Exception as e:
            logger.warning(f"Failed to create MinIO client: {e}")
            return None
    return _minio_client
