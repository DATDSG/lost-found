"""
MinIO Object Storage Client
==========================
S3-compatible object storage client for Lost & Found platform
"""

import os
import logging
from typing import Optional, BinaryIO, Union

try:
    from minio import Minio  # type: ignore
    from minio.error import S3Error  # type: ignore
except ImportError as exc:  # pragma: no cover - optional dependency handling
    Minio = None  # type: ignore
    S3Error = Exception  # type: ignore
    _MINIO_IMPORT_ERROR = exc
else:
    _MINIO_IMPORT_ERROR = None

try:
    import boto3  # type: ignore
    from botocore.exceptions import ClientError  # type: ignore
except ImportError as exc:  # pragma: no cover - optional dependency handling
    boto3 = None  # type: ignore
    ClientError = Exception  # type: ignore
    _BOTO_IMPORT_ERROR = exc
else:
    _BOTO_IMPORT_ERROR = None

from .config import config

logger = logging.getLogger(__name__)


class MinIOClient:
    """MinIO client for S3-compatible object storage operations."""
    
    def __init__(
        self,
        endpoint: str = None,
        access_key: str = None,
        secret_key: str = None,
        bucket_name: str = None,
        secure: bool = None,
        region: str = None
    ):
        """
        Initialize MinIO client.
        
        Args:
            endpoint: MinIO server endpoint
            access_key: Access key for authentication
            secret_key: Secret key for authentication
            bucket_name: Default bucket name
            secure: Use HTTPS (default: False)
            region: AWS region (default: us-east-1)
        """
        if _MINIO_IMPORT_ERROR:
            raise RuntimeError("minio package is required for object storage support") from _MINIO_IMPORT_ERROR
        if _BOTO_IMPORT_ERROR:
            raise RuntimeError("boto3 package is required for object storage support") from _BOTO_IMPORT_ERROR

        self.endpoint = endpoint or config.MINIO_ENDPOINT
        self.access_key = access_key or config.MINIO_ACCESS_KEY
        self.secret_key = secret_key or config.MINIO_SECRET_KEY
        self.bucket_name = bucket_name or config.MINIO_BUCKET_NAME
        self.secure = secure if secure is not None else config.MINIO_SECURE
        self.region = region or config.MINIO_REGION
        
        # Initialize MinIO client
        endpoint_host = self.endpoint.replace("http://", "").replace("https://", "")
        self.client = Minio(
            endpoint=endpoint_host,
            access_key=self.access_key,
            secret_key=self.secret_key,
            secure=self.secure
        )
        
        # Initialize boto3 client for advanced operations
        self.s3_client = boto3.client(
            's3',
            endpoint_url=self.endpoint,
            aws_access_key_id=self.access_key,
            aws_secret_access_key=self.secret_key,
            region_name=self.region,
            use_ssl=self.secure
        )
        
        # Ensure bucket exists
        self._ensure_bucket_exists()
    
    def _ensure_bucket_exists(self) -> None:
        """Ensure the default bucket exists."""
        try:
            if not self.client.bucket_exists(self.bucket_name):
                self.client.make_bucket(self.bucket_name)
                logger.info(f"Created bucket: {self.bucket_name}")
        except S3Error as e:
            logger.error(f"Failed to create bucket {self.bucket_name}: {e}")
            raise
    
    def upload_file(
        self,
        file_path: str,
        object_name: str = None,
        bucket_name: str = None,
        content_type: str = None
    ) -> str:
        """
        Upload a file to MinIO.
        
        Args:
            file_path: Path to the file to upload
            object_name: Name for the object in MinIO (default: filename)
            bucket_name: Bucket name (default: self.bucket_name)
            content_type: MIME type of the file
            
        Returns:
            URL of the uploaded object
        """
        bucket = bucket_name or self.bucket_name
        object_name = object_name or os.path.basename(file_path)
        
        try:
            # Upload file
            self.client.fput_object(
                bucket_name=bucket,
                object_name=object_name,
                file_path=file_path,
                content_type=content_type
            )
            
            # Generate URL
            url = f"{self.endpoint}/{bucket}/{object_name}"
            logger.info(f"Uploaded file: {url}")
            return url
            
        except S3Error as e:
            logger.error(f"Failed to upload file {file_path}: {e}")
            raise
    
    def upload_data(
        self,
        data: Union[bytes, BinaryIO],
        object_name: str,
        bucket_name: str = None,
        content_type: str = None,
        length: int = None
    ) -> str:
        """
        Upload data directly to MinIO.
        
        Args:
            data: Data to upload (bytes or file-like object)
            object_name: Name for the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            content_type: MIME type of the data
            length: Length of data (required for bytes)
            
        Returns:
            URL of the uploaded object
        """
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
            url = f"{self.endpoint}/{bucket}/{object_name}"
            logger.info(f"Uploaded data: {url}")
            return url
            
        except S3Error as e:
            logger.error(f"Failed to upload data {object_name}: {e}")
            raise
    
    def download_file(
        self,
        object_name: str,
        file_path: str,
        bucket_name: str = None
    ) -> str:
        """
        Download a file from MinIO.
        
        Args:
            object_name: Name of the object in MinIO
            file_path: Local path to save the file
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            Path to the downloaded file
        """
        bucket = bucket_name or self.bucket_name
        
        try:
            self.client.fget_object(
                bucket_name=bucket,
                object_name=object_name,
                file_path=file_path
            )
            logger.info(f"Downloaded file: {file_path}")
            return file_path
            
        except S3Error as e:
            logger.error(f"Failed to download file {object_name}: {e}")
            raise
    
    def download_data(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> bytes:
        """
        Download data directly from MinIO.
        
        Args:
            object_name: Name of the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            Downloaded data as bytes
        """
        bucket = bucket_name or self.bucket_name
        
        try:
            response = self.client.get_object(
                bucket_name=bucket,
                object_name=object_name
            )
            data = response.read()
            response.close()
            response.release_conn()
            
            logger.info(f"Downloaded data: {object_name}")
            return data
            
        except S3Error as e:
            logger.error(f"Failed to download data {object_name}: {e}")
            raise
    
    def delete_file(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> bool:
        """
        Delete a file from MinIO.
        
        Args:
            object_name: Name of the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            True if successful, False otherwise
        """
        bucket = bucket_name or self.bucket_name
        
        try:
            self.client.remove_object(
                bucket_name=bucket,
                object_name=object_name
            )
            logger.info(f"Deleted file: {object_name}")
            return True
            
        except S3Error as e:
            logger.error(f"Failed to delete file {object_name}: {e}")
            return False
    
    def file_exists(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> bool:
        """
        Check if a file exists in MinIO.
        
        Args:
            object_name: Name of the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            True if file exists, False otherwise
        """
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
    ) -> Optional[dict]:
        """
        Get file information from MinIO.
        
        Args:
            object_name: Name of the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            File information dict or None if not found
        """
        bucket = bucket_name or self.bucket_name
        
        try:
            stat = self.client.stat_object(bucket_name=bucket, object_name=object_name)
            return {
                "size": stat.size,
                "etag": stat.etag,
                "last_modified": stat.last_modified,
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
        """
        List files in MinIO bucket.
        
        Args:
            prefix: Object name prefix to filter
            bucket_name: Bucket name (default: self.bucket_name)
            recursive: Whether to list recursively
            
        Returns:
            List of object names
        """
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
    ) -> str:
        """
        Generate a presigned URL for object access.
        
        Args:
            object_name: Name of the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            expires_in: URL expiration time in seconds
            method: HTTP method (GET, PUT, POST, DELETE)
            
        Returns:
            Presigned URL
        """
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
            raise
    
    def create_bucket(self, bucket_name: str) -> bool:
        """
        Create a new bucket.
        
        Args:
            bucket_name: Name of the bucket to create
            
        Returns:
            True if successful, False otherwise
        """
        try:
            self.client.make_bucket(bucket_name)
            logger.info(f"Created bucket: {bucket_name}")
            return True
        except S3Error as e:
            logger.error(f"Failed to create bucket {bucket_name}: {e}")
            return False
    
    def delete_bucket(self, bucket_name: str) -> bool:
        """
        Delete a bucket (must be empty).
        
        Args:
            bucket_name: Name of the bucket to delete
            
        Returns:
            True if successful, False otherwise
        """
        try:
            self.client.remove_bucket(bucket_name)
            logger.info(f"Deleted bucket: {bucket_name}")
            return True
        except S3Error as e:
            logger.error(f"Failed to delete bucket {bucket_name}: {e}")
            return False
    
    def list_buckets(self) -> list:
        """
        List all buckets.
        
        Returns:
            List of bucket names
        """
        try:
            buckets = self.client.list_buckets()
            return [bucket.name for bucket in buckets]
        except S3Error as e:
            logger.error(f"Failed to list buckets: {e}")
            return []


_minio_client: Optional[MinIOClient] = None


def get_minio_client() -> MinIOClient:
    """Get or create the global MinIO client instance."""
    global _minio_client
    if _minio_client is None:
        _minio_client = MinIOClient()
    return _minio_client
