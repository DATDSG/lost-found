"""
MinIO Object Storage Client for NLP Service
===========================================
S3-compatible object storage client for text processing and model caching
"""

import os
import logging
from typing import Optional, BinaryIO, Union
from minio import Minio
from minio.error import S3Error

logger = logging.getLogger(__name__)


class NLPMinIOClient:
    """MinIO client for NLP service object storage operations."""
    
    def __init__(
        self,
        endpoint: str = None,
        access_key: str = None,
        secret_key: str = None,
        bucket_name: str = None,
        secure: bool = None
    ):
        """
        Initialize MinIO client for NLP service.
        
        Args:
            endpoint: MinIO server endpoint
            access_key: Access key for authentication
            secret_key: Secret key for authentication
            bucket_name: Default bucket name for NLP data
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
                logger.info(f"NLP service created bucket: {self.bucket_name}")
        except S3Error as e:
            logger.error(f"NLP service failed to create bucket {self.bucket_name}: {e}")
            raise
    
    def upload_text_data(
        self,
        text_data: str,
        object_name: str,
        bucket_name: str = None
    ) -> str:
        """
        Upload text data to MinIO.
        
        Args:
            text_data: Text data to upload
            object_name: Name for the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            URL of the uploaded object
        """
        bucket = bucket_name or self.bucket_name
        
        try:
            # Convert text to bytes
            data = text_data.encode('utf-8')
            
            # Upload data
            self.client.put_object(
                bucket_name=bucket,
                object_name=object_name,
                data=data,
                length=len(data),
                content_type="text/plain"
            )
            
            # Generate URL
            url = f"{self.endpoint}/{bucket}/{object_name}"
            logger.info(f"NLP service uploaded text data: {url}")
            return url
            
        except S3Error as e:
            logger.error(f"NLP service failed to upload text data {object_name}: {e}")
            raise
    
    def upload_embeddings(
        self,
        embeddings_data: bytes,
        object_name: str,
        bucket_name: str = None
    ) -> str:
        """
        Upload embeddings data to MinIO.
        
        Args:
            embeddings_data: Embeddings data as bytes
            object_name: Name for the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            URL of the uploaded object
        """
        bucket = bucket_name or self.bucket_name
        
        try:
            # Upload embeddings data
            self.client.put_object(
                bucket_name=bucket,
                object_name=object_name,
                data=embeddings_data,
                length=len(embeddings_data),
                content_type="application/octet-stream"
            )
            
            # Generate URL
            url = f"{self.endpoint}/{bucket}/{object_name}"
            logger.info(f"NLP service uploaded embeddings: {url}")
            return url
            
        except S3Error as e:
            logger.error(f"NLP service failed to upload embeddings {object_name}: {e}")
            raise
    
    def download_text_data(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> str:
        """
        Download text data from MinIO.
        
        Args:
            object_name: Name of the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            Downloaded text data
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
            
            text_data = data.decode('utf-8')
            logger.info(f"NLP service downloaded text data: {object_name}")
            return text_data
            
        except S3Error as e:
            logger.error(f"NLP service failed to download text data {object_name}: {e}")
            raise
    
    def download_embeddings(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> bytes:
        """
        Download embeddings data from MinIO.
        
        Args:
            object_name: Name of the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            Downloaded embeddings data as bytes
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
            
            logger.info(f"NLP service downloaded embeddings: {object_name}")
            return data
            
        except S3Error as e:
            logger.error(f"NLP service failed to download embeddings {object_name}: {e}")
            raise
    
    def delete_object(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> bool:
        """
        Delete an object from MinIO.
        
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
            logger.info(f"NLP service deleted object: {object_name}")
            return True
            
        except S3Error as e:
            logger.error(f"NLP service failed to delete object {object_name}: {e}")
            return False
    
    def object_exists(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> bool:
        """
        Check if an object exists in MinIO.
        
        Args:
            object_name: Name of the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            True if object exists, False otherwise
        """
        bucket = bucket_name or self.bucket_name
        
        try:
            self.client.stat_object(bucket_name=bucket, object_name=object_name)
            return True
        except S3Error:
            return False
    
    def get_object_info(
        self,
        object_name: str,
        bucket_name: str = None
    ) -> Optional[dict]:
        """
        Get object information from MinIO.
        
        Args:
            object_name: Name of the object in MinIO
            bucket_name: Bucket name (default: self.bucket_name)
            
        Returns:
            Object information dict or None if not found
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
            logger.error(f"NLP service failed to get object info {object_name}: {e}")
            return None
    
    def list_text_objects(
        self,
        prefix: str = "text/",
        bucket_name: str = None
    ) -> list:
        """
        List text objects in MinIO bucket.
        
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
            logger.error(f"NLP service failed to list text objects: {e}")
            return []
    
    def list_embeddings_objects(
        self,
        prefix: str = "embeddings/",
        bucket_name: str = None
    ) -> list:
        """
        List embeddings objects in MinIO bucket.
        
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
            logger.error(f"NLP service failed to list embeddings objects: {e}")
            return []


# Global NLP MinIO client instance
nlp_minio_client = NLPMinIOClient()


def get_nlp_minio_client() -> NLPMinIOClient:
    """Get the global NLP MinIO client instance."""
    return nlp_minio_client
