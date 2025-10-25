"""
Media Repository
================
Repository layer for media data access with proper abstraction and error handling.
"""

from typing import Optional, List, Dict, Any, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func, and_, or_, desc
from sqlalchemy.orm import selectinload
from sqlalchemy.exc import IntegrityError, NoResultFound
import logging
from datetime import datetime, timedelta
import uuid

from ..models.media import Media
from ..schemas.media_schemas import (
    MediaCreate, MediaUpdate, MediaSearchRequest, MediaType, MediaStatus
)

logger = logging.getLogger(__name__)


class MediaRepository:
    """Repository for media data access operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create(self, media_dict: Dict[str, Any]) -> Media:
        """
        Create a new media record.
        
        Args:
            media_dict: Media data dictionary
            
        Returns:
            Created media instance
            
        Raises:
            IntegrityError: If constraint violation occurs
            ValueError: If validation fails
        """
        try:
            media = Media(**media_dict)
            self.db.add(media)
            await self.db.commit()
            await self.db.refresh(media)
            
            logger.info(f"Media created successfully: {media.id}")
            return media
            
        except IntegrityError as e:
            await self.db.rollback()
            logger.error(f"Media creation failed - constraint violation: {e}")
            raise ValueError("Media creation failed due to constraint violation")
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Media creation failed: {e}")
            raise
    
    async def get_by_id(self, media_id: str) -> Optional[Media]:
        """
        Get media by ID.
        
        Args:
            media_id: Media UUID string
            
        Returns:
            Media instance or None if not found
        """
        try:
            query = select(Media).where(Media.id == media_id)
            result = await self.db.execute(query)
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Error getting media by ID {media_id}: {e}")
            return None
    
    async def update(self, media_id: str, update_dict: Dict[str, Any]) -> Optional[Media]:
        """
        Update media with validation and error handling.
        
        Args:
            media_id: Media UUID string
            update_dict: Update data dictionary
            
        Returns:
            Updated media instance or None if not found
        """
        try:
            # Get existing media
            media = await self.get_by_id(media_id)
            if not media:
                return None
            
            # Update fields
            for field, value in update_dict.items():
                if hasattr(media, field):
                    setattr(media, field, value)
            
            await self.db.commit()
            await self.db.refresh(media)
            
            logger.info(f"Media updated successfully: {media_id}")
            return media
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Media update failed for {media_id}: {e}")
            raise
    
    async def delete(self, media_id: str) -> bool:
        """
        Delete media permanently.
        
        Args:
            media_id: Media UUID string
            
        Returns:
            True if successful, False if not found
        """
        try:
            query = delete(Media).where(Media.id == media_id)
            result = await self.db.execute(query)
            await self.db.commit()
            
            if result.rowcount > 0:
                logger.info(f"Media deleted successfully: {media_id}")
                return True
            return False
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Media deletion failed for {media_id}: {e}")
            return False
    
    async def search_media(self, search_request: MediaSearchRequest) -> Tuple[List[Media], int]:
        """
        Search media with pagination and filters.
        
        Args:
            search_request: Search parameters
            
        Returns:
            Tuple of (media list, total count)
        """
        try:
            # Base query
            base_query = select(Media)
            
            # Apply filters
            conditions = []
            
            if search_request.media_type:
                conditions.append(Media.media_type == search_request.media_type)
            
            if search_request.status:
                conditions.append(Media.status == search_request.status)
            
            if search_request.report_id:
                conditions.append(Media.report_id == search_request.report_id)
            
            if search_request.file_type:
                conditions.append(Media.file_type == search_request.file_type)
            
            if search_request.min_size:
                conditions.append(Media.file_size >= search_request.min_size)
            
            if search_request.max_size:
                conditions.append(Media.file_size <= search_request.max_size)
            
            if search_request.created_after:
                conditions.append(Media.created_at >= search_request.created_after)
            
            if search_request.created_before:
                conditions.append(Media.created_at <= search_request.created_before)
            
            # Apply conditions
            if conditions:
                search_query = base_query.where(and_(*conditions))
            else:
                search_query = base_query
            
            # Get total count
            count_query = select(func.count()).select_from(search_query.subquery())
            total_result = await self.db.execute(count_query)
            total = total_result.scalar()
            
            # Get paginated results
            media_query = (
                search_query
                .offset(search_request.offset)
                .limit(search_request.limit)
                .order_by(desc(Media.created_at))
            )
            
            result = await self.db.execute(media_query)
            media_records = result.scalars().all()
            
            return list(media_records), total
            
        except Exception as e:
            logger.error(f"Media search failed: {e}")
            return [], 0
    
    async def get_media_by_report(self, report_id: str) -> List[Media]:
        """
        Get all media associated with a report.
        
        Args:
            report_id: Report UUID string
            
        Returns:
            List of media instances
        """
        try:
            query = (
                select(Media)
                .where(Media.report_id == report_id)
                .order_by(desc(Media.created_at))
            )
            result = await self.db.execute(query)
            return list(result.scalars().all())
        except Exception as e:
            logger.error(f"Error getting media by report {report_id}: {e}")
            return []
    
    async def update_media_status(self, media_id: str, status: MediaStatus) -> bool:
        """
        Update media status.
        
        Args:
            media_id: Media UUID string
            status: New media status
            
        Returns:
            True if successful, False otherwise
        """
        try:
            query = (
                update(Media)
                .where(Media.id == media_id)
                .values(
                    status=status.value,
                    updated_at=datetime.utcnow()
                )
            )
            
            result = await self.db.execute(query)
            await self.db.commit()
            
            if result.rowcount > 0:
                logger.info(f"Media status updated: {media_id} -> {status.value}")
                return True
            return False
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Media status update failed for {media_id}: {e}")
            return False
    
    async def get_media_by_type(self, media_type: MediaType, limit: int = 50) -> List[Media]:
        """
        Get media records by type.
        
        Args:
            media_type: Media type filter
            limit: Maximum number of records to return
            
        Returns:
            List of media instances
        """
        try:
            query = (
                select(Media)
                .where(Media.media_type == media_type)
                .order_by(desc(Media.created_at))
                .limit(limit)
            )
            result = await self.db.execute(query)
            return list(result.scalars().all())
        except Exception as e:
            logger.error(f"Error getting media by type {media_type}: {e}")
            return []
    
    async def get_media_statistics(self) -> Optional[Dict[str, Any]]:
        """
        Get comprehensive media statistics.
        
        Returns:
            Media statistics dictionary
        """
        try:
            # Total media
            total_media_query = select(func.count(Media.id))
            total_media = await self.db.scalar(total_media_query) or 0
            
            # Media by status
            active_media_query = select(func.count(Media.id)).where(Media.status == MediaStatus.ACTIVE)
            active_media = await self.db.scalar(active_media_query) or 0
            
            inactive_media_query = select(func.count(Media.id)).where(Media.status == MediaStatus.INACTIVE)
            inactive_media = await self.db.scalar(inactive_media_query) or 0
            
            deleted_media_query = select(func.count(Media.id)).where(Media.status == MediaStatus.DELETED)
            deleted_media = await self.db.scalar(deleted_media_query) or 0
            
            # Media by type
            image_media_query = select(func.count(Media.id)).where(Media.media_type == MediaType.IMAGE)
            image_media = await self.db.scalar(image_media_query) or 0
            
            video_media_query = select(func.count(Media.id)).where(Media.media_type == MediaType.VIDEO)
            video_media = await self.db.scalar(video_media_query) or 0
            
            document_media_query = select(func.count(Media.id)).where(Media.media_type == MediaType.DOCUMENT)
            document_media = await self.db.scalar(document_media_query) or 0
            
            # Media by file type
            jpg_media_query = select(func.count(Media.id)).where(Media.file_type == 'jpg')
            jpg_media = await self.db.scalar(jpg_media_query) or 0
            
            png_media_query = select(func.count(Media.id)).where(Media.file_type == 'png')
            png_media = await self.db.scalar(png_media_query) or 0
            
            gif_media_query = select(func.count(Media.id)).where(Media.file_type == 'gif')
            gif_media = await self.db.scalar(gif_media_query) or 0
            
            # Total storage used
            total_size_query = select(func.sum(Media.file_size))
            total_size = await self.db.scalar(total_size_query) or 0
            
            # Average file size
            avg_size_query = select(func.avg(Media.file_size))
            avg_size = await self.db.scalar(avg_size_query) or 0.0
            
            # Recent media (last 7 days)
            week_ago = datetime.utcnow() - timedelta(days=7)
            recent_media_query = select(func.count(Media.id)).where(Media.created_at >= week_ago)
            recent_media = await self.db.scalar(recent_media_query) or 0
            
            return {
                "total_media": total_media,
                "by_status": {
                    "active": active_media,
                    "inactive": inactive_media,
                    "deleted": deleted_media
                },
                "by_type": {
                    "image": image_media,
                    "video": video_media,
                    "document": document_media
                },
                "by_file_type": {
                    "jpg": jpg_media,
                    "png": png_media,
                    "gif": gif_media
                },
                "storage": {
                    "total_size_bytes": total_size,
                    "total_size_mb": round(total_size / (1024 * 1024), 2),
                    "average_size_bytes": round(avg_size, 2),
                    "average_size_mb": round(avg_size / (1024 * 1024), 2)
                },
                "activity": {
                    "recent_media_7_days": recent_media
                }
            }
            
        except Exception as e:
            logger.error(f"Error getting media statistics: {e}")
            return None
    
    async def cleanup_orphaned_media(self) -> int:
        """
        Clean up orphaned media records (media not associated with any report).
        
        Returns:
            Number of cleaned up records
        """
        try:
            # Find orphaned media (media without associated reports)
            from app.domains.reports.models.report import Report
            
            orphaned_query = (
                select(Media.id)
                .where(
                    and_(
                        Media.report_id.isnot(None),
                        ~Media.report_id.in_(
                            select(Report.id)
                        )
                    )
                )
            )
            
            result = await self.db.execute(orphaned_query)
            orphaned_ids = [row[0] for row in result.fetchall()]
            
            if not orphaned_ids:
                return 0
            
            # Delete orphaned media
            delete_query = delete(Media).where(Media.id.in_(orphaned_ids))
            await self.db.execute(delete_query)
            await self.db.commit()
            
            logger.info(f"Cleaned up {len(orphaned_ids)} orphaned media records")
            return len(orphaned_ids)
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Error cleaning up orphaned media: {e}")
            return 0
    
    async def get_media_by_filename(self, filename: str) -> Optional[Media]:
        """
        Get media by filename.
        
        Args:
            filename: Media filename
            
        Returns:
            Media instance or None if not found
        """
        try:
            query = select(Media).where(Media.filename == filename)
            result = await self.db.execute(query)
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Error getting media by filename {filename}: {e}")
            return None
    
    async def get_recent_media(self, limit: int = 20) -> List[Media]:
        """
        Get recently created media.
        
        Args:
            limit: Maximum number of media to return
            
        Returns:
            List of recent media instances
        """
        try:
            query = (
                select(Media)
                .order_by(desc(Media.created_at))
                .limit(limit)
            )
            result = await self.db.execute(query)
            return list(result.scalars().all())
        except Exception as e:
            logger.error(f"Error getting recent media: {e}")
            return []
    
    async def get_media_by_size_range(self, min_size: int, max_size: int) -> List[Media]:
        """
        Get media within a size range.
        
        Args:
            min_size: Minimum file size in bytes
            max_size: Maximum file size in bytes
            
        Returns:
            List of media instances
        """
        try:
            query = (
                select(Media)
                .where(
                    and_(
                        Media.file_size >= min_size,
                        Media.file_size <= max_size
                    )
                )
                .order_by(desc(Media.file_size))
            )
            result = await self.db.execute(query)
            return list(result.scalars().all())
        except Exception as e:
            logger.error(f"Error getting media by size range: {e}")
            return []
