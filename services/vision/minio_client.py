"""
MinIO Object Storage Client for Vision Service
=============================================
S3-compatible object storage client for image processing and storage
"""

import os
import logging
from typing import Optional, BinaryIO, Union
from minio import Minio
from minio.error import S3Error

logger = logging.getLogger(__name__)


class VisionMinIOClient:
    """MinIO client for Vision service object storage operations."""
    
    def __init__(
        self,
        endpoint: str = None,
        access_key: str = None,
        secret_key: str = None,
        bucket_name: str = None,
        secure: bool = None
    ):
        """
        Initialize MinIO client for Vision service.
        
        Args:
            endpoint: MinIO server endpoint
            access_key: Access key for authentication
            secret_key: Secret key for authentication
            bucket_name: Default bucket name for vision data
            secure: Use HTTPS (default: False)
        """
        self.endpoint = endpoint or os.getenv("MINIO_ENDPOINT", "http://localhost:9000")
        self.access_key = access_key or os.getenv("MINIO_ACCESS_KEY", "admin")
        self.secret_key = secret_key or os.getenv("MINIO_SECRET_KEY", "admin")
        self.bucket_name = bucket_name or os.getenv("MINIO_BUCKET_NAME", "lost-found-media")
        self.secure = secure if secure is not None else os.getenv("MINIO_SECURE", "false").lower() == "true"
        
        # Initialize MinIO client
        self.client = Minio(
            endpoint=self.endpoint.replace("http://", "").replace("https://", ""),
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
                logger.info(f"Vision service created bucket: {self.bucket_name}")
        except S3Error as e:
            logger.error(f"Vision service failed to create bucket {self.bucket_name}: {e}")
            raise
    
    def upload_image(
        self,
        image_data: bytes,
        object_name: str,
        bucket_name: str = None,
        content_type: str = "image/jpeg"
    ) -> str:
        """
        Upload image data to MinIO.
        
        Args:
            image_data: Image data as bytes
            object_name: Name for the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            content_type: MIME type of the image
            
        Returns:
            URL of the uploaded object
        """
        bucket = bucket_name or self.bucket_name
        
        try:
            # Upload image data
            self.client.put_object(
                bucket_name=bucket,
                object_name=object_name,
                data=image_data,
                length=len(image_data),
                content_type=content_type
            )
            
            # Generate URL
            url = f"{self.endpoint}/{bucket}/{object_name}"
            logger.info(f"Vision service uploaded image: {url}")
            return url
            
        except S3Error as e:
            logger.error(f"Vision service failed to upload image {object_name}: {e}")
            raise
    
    def upload_image_file(
        self,
        file_path: str,
        object_name: str = None,
        bucket_name: str = None,
        content_type: str = None
    ) -> str:
        """
        Upload image file to MinIO.
        
        Args:
            file_path: Path to the image file to upload
            object_name: Name for the object in MinIO (default: filename)
            bucket_name: Bucket name (default: self.bucket_name)
            content_type: MIME type of the image
            
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
            logger.info(f"Vision service uploaded image file: {url}")
            return url
            
        except S3Error as e:
            logger.error(f"Vision service failed to upload image file {file_path}: {e}")
            raise
    
    def upload_hash_data(
        self,
        hash_data: bytes,
        object_name: str,
        bucket_name: str = None
    ) -> str:
        """
        Upload image hash data to MinIO.
        
        Args:
            hash_data: Hash data as bytes
            object_name: Name for the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            URL of the uploaded object
        """
        bucket = bucket_name or self.bucket_name
        
        try:
            # Upload hash data
            self.client.put_object(
                bucket_name=bucket,
                object_name=object_name,
                data=hash_data,
                length=len(hash_data),
                content_type="application/octet-stream"
            )
            
            # Generate URL
            url = f"{self.endpoint}/{bucket}/{object_name}"
            logger.info(f"Vision service uploaded hash data: {url}")
            return url
            
        except S3Error as e:
            logger.error(f"Vision service failed to upload hash data {object_name}: {e}")
            raise
    
    def download_image(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> bytes:
        """
        Download image data from MinIO.
        
        Args:
            object_name: Name of the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            Downloaded image data as bytes
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
            
            logger.info(f"Vision service downloaded image: {object_name}")
            return data
            
        except S3Error as e:
            logger.error(f"Vision service failed to download image {object_name}: {e}")
            raise
    
    def download_image_to_file(
        self,
        object_name: str,
        file_path: str,
        bucket_name: str = None
    ) -> str:
        """
        Download image from MinIO to local file.
        
        Args:
            object_name: Name of the object in MinIO
            file_path: Local path to save the image
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
            logger.info(f"Vision service downloaded image to file: {file_path}")
            return file_path
            
        except S3Error as e:
            logger.error(f"Vision service failed to download image {object_name}: {e}")
            raise
    
    def download_hash_data(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> bytes:
        """
        Download hash data from MinIO.
        
        Args:
            object_name: Name of the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            Downloaded hash data as bytes
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
            
            logger.info(f"Vision service downloaded hash data: {object_name}")
            return data
            
        except S3Error as e:
            logger.error(f"Vision service failed to download hash data {object_name}: {e}")
            raise
    
    def delete_image(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> bool:
        """
        Delete an image from MinIO.
        
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
            logger.info(f"Vision service deleted image: {object_name}")
            return True
            
        except S3Error as e:
            logger.error(f"Vision service failed to delete image {object_name}: {e}")
            return False
    
    def image_exists(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> bool:
        """
        Check if an image exists in MinIO.
        
        Args:
            object_name: Name of the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            True if image exists, False otherwise
        """
        bucket = bucket_name or self.bucket_name
        
        try:
            self.client.stat_object(bucket_name=bucket, object_name=object_name)
            return True
        except S3Error:
            return False
    
    def get_image_info(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> Optional[dict]:
        """
        Get image information from MinIO.
        
        Args:
            object_name: Name of the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            Image information dict or None if not found
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
            logger.error(f"Vision service failed to get image info {object_name}: {e}")
            return None
    
    def list_images(
        self,
        prefix: str = "images/",
        bucket_name: str = None
    ) -> list:
        """
        List images in MinIO bucket.
        
        Args:
            prefix: Object name prefix to filter
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            List of object names
        """
        bucket = bucket_name or self.bucket_name
        
        try:
            objects = self.client.list_objects(
                bucket_name=bucket,
                prefix=prefix,
                recursive=True
            )
            return [obj.object_name for obj in objects]
        except S3Error as e:
            logger.error(f"Vision service failed to list images: {e}")
            return []
    
    def list_hash_data(
        self,
        prefix: str = "hashes/",
        bucket_name: str = None
    ) -> list:
        """
        List hash data objects in MinIO bucket.
        
        Args:
            prefix: Object name prefix to filter
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            List of object names
        """
        bucket = bucket_name or self.bucket_name
        
        try:
            objects = self.client.list_objects(
                bucket_name=bucket,
                prefix=prefix,
                recursive=True
            )
            return [obj.object_name for obj in objects]
        except S3Error as e:
            logger.error(f"Vision service failed to list hash data: {e}")
            return []
    
    def get_presigned_url(
        self,
        object_name: str,
        bucket_name: str = None,
        expires_in: int = 3600,
        method: str = "GET"
    ) -> str:
        """
        Generate a presigned URL for image access.
        
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
            logger.error(f"Vision service failed to generate presigned URL for {object_name}: {e}")
            raise


# Global Vision MinIO client instance
vision_minio_client = VisionMinIOClient()


def get_vision_minio_client() -> VisionMinIOClient:
    """Get the global Vision MinIO client instance."""
    return vision_minio_client
