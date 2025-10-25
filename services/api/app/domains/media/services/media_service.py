"""
Media Service
=============
Business logic layer for media operations with proper validation and error handling.
"""

from typing import Optional, Dict, Any, Tuple, List
from sqlalchemy.ext.asyncio import AsyncSession
import logging
from datetime import datetime
import uuid
import os
from pathlib import Path

from ..schemas.media_schemas import (
    MediaCreate, MediaUpdate, MediaResponse, MediaSearchRequest,
    MediaSearchResponse, MediaStats, MediaType, MediaStatus
)
from ..repositories.media_repository import MediaRepository
from ..models.media import Media
from app.storage import MinIOClient
from app.config import config

logger = logging.getLogger(__name__)


class MediaService:
    """Service layer for media business logic."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repository = MediaRepository(db)
        self.storage = MinIOClient()
    
    async def create_media(self, media_data: MediaCreate, file_content: bytes, filename: str) -> Tuple[bool, Optional[MediaResponse], Optional[str]]:
        """
        Create a new media record with file upload.
        
        Args:
            media_data: Media creation data
            file_content: File content bytes
            filename: Original filename
            
        Returns:
            Tuple of (success, media_response, error_message)
        """
        try:
            # Validate file type and size
            file_extension = Path(filename).suffix.lower()
            if file_extension not in ['.jpg', '.jpeg', '.png', '.gif', '.webp']:
                return False, None, "Unsupported file type"
            
            if len(file_content) > 10 * 1024 * 1024:  # 10MB limit
                return False, None, "File size too large"
            
            # Generate unique filename
            media_id = str(uuid.uuid4())
            file_extension = Path(filename).suffix.lower()
            unique_filename = f"{media_id}{file_extension}"
            
            # Upload file to storage
            upload_success = await self.storage.upload_file(
                bucket_name="media",
                object_name=unique_filename,
                file_data=file_content,
                content_type=f"image/{file_extension[1:]}"
            )
            
            if not upload_success:
                return False, None, "Failed to upload file"
            
            # Create media record
            media_dict = media_data.model_dump()
            media_dict["id"] = media_id
            media_dict["filename"] = unique_filename
            media_dict["original_filename"] = filename
            media_dict["file_size"] = len(file_content)
            media_dict["file_type"] = file_extension[1:]
            media_dict["status"] = MediaStatus.ACTIVE.value
            media_dict["created_at"] = datetime.utcnow()
            media_dict["updated_at"] = datetime.utcnow()
            
            media = await self.repository.create(media_dict)
            media_response = MediaResponse.model_validate(media)
            
            logger.info(f"Media created successfully: {media.id}")
            return True, media_response, None
            
        except ValueError as e:
            return False, None, str(e)
        except Exception as e:
            logger.error(f"Media creation failed: {e}")
            return False, None, "Failed to create media"
    
    async def get_media(self, media_id: str) -> Tuple[bool, Optional[MediaResponse], Optional[str]]:
        """
        Get a specific media record by ID.
        
        Args:
            media_id: Media UUID string
            
        Returns:
            Tuple of (success, media_response, error_message)
        """
        try:
            media = await self.repository.get_by_id(media_id)
            if not media:
                return False, None, "Media not found"
            
            media_response = MediaResponse.model_validate(media)
            return True, media_response, None
            
        except Exception as e:
            logger.error(f"Error getting media {media_id}: {e}")
            return False, None, "Failed to get media"
    
    async def update_media(self, media_id: str, update_data: MediaUpdate) -> Tuple[bool, Optional[MediaResponse], Optional[str]]:
        """
        Update a media record.
        
        Args:
            media_id: Media UUID string
            update_data: Update data
            
        Returns:
            Tuple of (success, updated_media_response, error_message)
        """
        try:
            # Get existing media
            media = await self.repository.get_by_id(media_id)
            if not media:
                return False, None, "Media not found"
            
            # Update media
            update_dict = update_data.model_dump(exclude_unset=True)
            update_dict["updated_at"] = datetime.utcnow()
            
            updated_media = await self.repository.update(media_id, update_dict)
            if not updated_media:
                return False, None, "Failed to update media"
            
            media_response = MediaResponse.model_validate(updated_media)
            
            logger.info(f"Media updated successfully: {media_id}")
            return True, media_response, None
            
        except Exception as e:
            logger.error(f"Error updating media {media_id}: {e}")
            return False, None, "Failed to update media"
    
    async def delete_media(self, media_id: str) -> Tuple[bool, Optional[str]]:
        """
        Delete a media record and its associated file.
        
        Args:
            media_id: Media UUID string
            
        Returns:
            Tuple of (success, error_message)
        """
        try:
            # Get media record
            media = await self.repository.get_by_id(media_id)
            if not media:
                return False, "Media not found"
            
            # Delete file from storage
            delete_success = await self.storage.delete_file("media", media.filename)
            if not delete_success:
                logger.warning(f"Failed to delete file from storage: {media.filename}")
            
            # Delete media record
            success = await self.repository.delete(media_id)
            if not success:
                return False, "Failed to delete media record"
            
            logger.info(f"Media deleted successfully: {media_id}")
            return True, None
            
        except Exception as e:
            logger.error(f"Error deleting media {media_id}: {e}")
            return False, "Failed to delete media"
    
    async def search_media(self, search_request: MediaSearchRequest) -> Tuple[bool, Optional[MediaSearchResponse], Optional[str]]:
        """
        Search media records with pagination and filters.
        
        Args:
            search_request: Search parameters
            
        Returns:
            Tuple of (success, search_response, error_message)
        """
        try:
            media_records, total = await self.repository.search_media(search_request)
            
            # Convert to MediaResponse schemas
            media_responses = []
            for media in media_records:
                media_response = MediaResponse.model_validate(media)
                media_responses.append(media_response)
            
            search_response = MediaSearchResponse(
                media=media_responses,
                total=total,
                page=search_request.page,
                page_size=search_request.page_size,
                has_next=total > (search_request.page * search_request.page_size),
                has_prev=search_request.page > 1
            )
            
            return True, search_response, None
            
        except Exception as e:
            logger.error(f"Error searching media: {e}")
            return False, None, "Failed to search media"
    
    async def get_media_statistics(self) -> Tuple[bool, Optional[MediaStats], Optional[str]]:
        """
        Get comprehensive media statistics.
        
        Returns:
            Tuple of (success, media_stats, error_message)
        """
        try:
            stats_data = await self.repository.get_media_statistics()
            if not stats_data:
                return False, None, "Failed to get media statistics"
            
            stats = MediaStats(**stats_data)
            return True, stats, None
            
        except Exception as e:
            logger.error(f"Error getting media statistics: {e}")
            return False, None, "Failed to get media statistics"
    
    async def get_media_url(self, media_id: str, expires_in: int = 3600) -> Tuple[bool, Optional[str], Optional[str]]:
        """
        Get a presigned URL for media access.
        
        Args:
            media_id: Media UUID string
            expires_in: URL expiration time in seconds
            
        Returns:
            Tuple of (success, presigned_url, error_message)
        """
        try:
            # Get media record
            media = await self.repository.get_by_id(media_id)
            if not media:
                return False, None, "Media not found"
            
            # Generate presigned URL
            presigned_url = await self.storage.get_presigned_url(
                bucket_name="media",
                object_name=media.filename,
                expires_in=expires_in
            )
            
            if not presigned_url:
                return False, None, "Failed to generate presigned URL"
            
            return True, presigned_url, None
            
        except Exception as e:
            logger.error(f"Error getting media URL {media_id}: {e}")
            return False, None, "Failed to get media URL"
    
    async def get_media_by_report(self, report_id: str) -> Tuple[bool, List[MediaResponse], Optional[str]]:
        """
        Get all media associated with a report.
        
        Args:
            report_id: Report UUID string
            
        Returns:
            Tuple of (success, media_list, error_message)
        """
        try:
            media_records = await self.repository.get_media_by_report(report_id)
            
            # Convert to MediaResponse schemas
            media_responses = []
            for media in media_records:
                media_response = MediaResponse.model_validate(media)
                media_responses.append(media_response)
            
            return True, media_responses, None
            
        except Exception as e:
            logger.error(f"Error getting media for report {report_id}: {e}")
            return False, [], "Failed to get media for report"
    
    async def update_media_status(self, media_id: str, status: MediaStatus) -> Tuple[bool, Optional[str]]:
        """
        Update media status.
        
        Args:
            media_id: Media UUID string
            status: New media status
            
        Returns:
            Tuple of (success, error_message)
        """
        try:
            success = await self.repository.update_media_status(media_id, status)
            if not success:
                return False, "Media not found"
            
            logger.info(f"Media status updated: {media_id} -> {status.value}")
            return True, None
            
        except Exception as e:
            logger.error(f"Error updating media status {media_id}: {e}")
            return False, "Failed to update media status"
    
    async def get_media_by_type(self, media_type: MediaType, limit: int = 50) -> Tuple[bool, List[MediaResponse], Optional[str]]:
        """
        Get media records by type.
        
        Args:
            media_type: Media type filter
            limit: Maximum number of records to return
            
        Returns:
            Tuple of (success, media_list, error_message)
        """
        try:
            media_records = await self.repository.get_media_by_type(media_type, limit)
            
            # Convert to MediaResponse schemas
            media_responses = []
            for media in media_records:
                media_response = MediaResponse.model_validate(media)
                media_responses.append(media_response)
            
            return True, media_responses, None
            
        except Exception as e:
            logger.error(f"Error getting media by type {media_type}: {e}")
            return False, [], "Failed to get media by type"
    
    async def cleanup_orphaned_media(self) -> Tuple[bool, int, Optional[str]]:
        """
        Clean up orphaned media records (media not associated with any report).
        
        Returns:
            Tuple of (success, cleaned_count, error_message)
        """
        try:
            cleaned_count = await self.repository.cleanup_orphaned_media()
            
            logger.info(f"Cleaned up {cleaned_count} orphaned media records")
            return True, cleaned_count, None
            
        except Exception as e:
            logger.error(f"Error cleaning up orphaned media: {e}")
            return False, 0, "Failed to cleanup orphaned media"
    
    async def validate_media_file(self, file_content: bytes, filename: str) -> Tuple[bool, Optional[str]]:
        """
        Validate media file before upload.
        
        Args:
            file_content: File content bytes
            filename: Original filename
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        try:
            # Check file size
            if len(file_content) > 10 * 1024 * 1024:  # 10MB limit
                return False, "File size exceeds 10MB limit"
            
            # Check file extension
            file_extension = Path(filename).suffix.lower()
            allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp']
            if file_extension not in allowed_extensions:
                return False, f"Unsupported file type. Allowed: {', '.join(allowed_extensions)}"
            
            # Basic file header validation
            if file_extension in ['.jpg', '.jpeg']:
                if not file_content.startswith(b'\xff\xd8\xff'):
                    return False, "Invalid JPEG file format"
            elif file_extension == '.png':
                if not file_content.startswith(b'\x89PNG\r\n\x1a\n'):
                    return False, "Invalid PNG file format"
            elif file_extension == '.gif':
                if not file_content.startswith(b'GIF87a') and not file_content.startswith(b'GIF89a'):
                    return False, "Invalid GIF file format"
            
            return True, None
            
        except Exception as e:
            logger.error(f"Error validating media file: {e}")
            return False, "File validation failed"
