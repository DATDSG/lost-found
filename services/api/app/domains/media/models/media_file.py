"""
Media Domain Models
==================
Domain-specific models for the Media bounded context.
Following Domain-Driven Design principles.
"""

from sqlalchemy import Column, String, Integer, DateTime, Boolean, Enum as SQLEnum, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
import uuid as uuid_pkg
from datetime import datetime
from typing import Optional

from ....infrastructure.database.base import Base


class MediaType(str, enum.Enum):
    """Media type enumeration."""
    IMAGE = "image"
    DOCUMENT = "document"
    AUDIO = "audio"
    VIDEO = "video"


class MediaStatus(str, enum.Enum):
    """Media status enumeration."""
    UPLOADING = "uploading"
    PROCESSING = "processing"
    READY = "ready"
    FAILED = "failed"
    DELETED = "deleted"


class MediaFile(Base):
    """
    MediaFile Entity - Core domain model for uploaded media files.
    
    This entity represents a media file with metadata, processing status,
    and storage information.
    """
    __tablename__ = "media_files"

    # Primary Key
    id = Column(String, primary_key=True, default=lambda: str(uuid_pkg.uuid4()))
    
    # File Information
    filename = Column(String, nullable=False)
    original_filename = Column(String, nullable=False)
    file_size = Column(Integer, nullable=False)
    mime_type = Column(String, nullable=False)
    file_extension = Column(String)
    
    # Media Classification
    media_type = Column(String, nullable=False, index=True)
    status = Column(String, default="uploading", index=True)
    
    # Storage Information
    storage_path = Column(String, nullable=False)
    storage_url = Column(String)
    thumbnail_url = Column(String)
    
    # Processing Information
    processing_metadata = Column(Text)  # JSON string with processing details
    image_hash = Column(String)  # For duplicate detection
    image_width = Column(Integer)
    image_height = Column(Integer)
    
    # Relationships
    owner_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    report_id = Column(String, ForeignKey("reports.id"), nullable=True, index=True)
    
    # Audit Fields
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Domain Relationships
    owner = relationship("User", foreign_keys=[owner_id])
    report = relationship("Report", foreign_keys=[report_id])
    
    def __repr__(self):
        return f"<MediaFile(id='{self.id}', filename='{self.filename}', type='{self.media_type}')>"
    
    def is_image(self) -> bool:
        """Check if media file is an image."""
        return self.media_type == MediaType.IMAGE.value
    
    def is_document(self) -> bool:
        """Check if media file is a document."""
        return self.media_type == MediaType.DOCUMENT.value
    
    def is_audio(self) -> bool:
        """Check if media file is audio."""
        return self.media_type == MediaType.AUDIO.value
    
    def is_video(self) -> bool:
        """Check if media file is video."""
        return self.media_type == MediaType.VIDEO.value
    
    def is_ready(self) -> bool:
        """Check if media file is ready for use."""
        return self.status == MediaStatus.READY.value
    
    def is_processing(self) -> bool:
        """Check if media file is being processed."""
        return self.status in [MediaStatus.UPLOADING.value, MediaStatus.PROCESSING.value]
    
    def is_failed(self) -> bool:
        """Check if media file processing failed."""
        return self.status == MediaStatus.FAILED.value
    
    def get_file_size_mb(self) -> float:
        """Get file size in megabytes."""
        return round(self.file_size / (1024 * 1024), 2)
    
    def get_dimensions(self) -> Optional[tuple]:
        """Get image dimensions if available."""
        if self.is_image() and self.image_width and self.image_height:
            return (self.image_width, self.image_height)
        return None
    
    def get_aspect_ratio(self) -> Optional[float]:
        """Get image aspect ratio if available."""
        dimensions = self.get_dimensions()
        if dimensions:
            return round(dimensions[0] / dimensions[1], 2)
        return None
    
    def is_portrait(self) -> bool:
        """Check if image is portrait orientation."""
        dimensions = self.get_dimensions()
        return dimensions and dimensions[1] > dimensions[0]
    
    def is_landscape(self) -> bool:
        """Check if image is landscape orientation."""
        dimensions = self.get_dimensions()
        return dimensions and dimensions[0] > dimensions[1]
    
    def is_square(self) -> bool:
        """Check if image is square."""
        dimensions = self.get_dimensions()
        return dimensions and dimensions[0] == dimensions[1]
    
    def get_processing_status(self) -> dict:
        """Get processing status information."""
        return {
            "status": self.status,
            "is_ready": self.is_ready(),
            "is_processing": self.is_processing(),
            "is_failed": self.is_failed(),
            "has_thumbnail": bool(self.thumbnail_url),
            "has_hash": bool(self.image_hash)
        }
    
    def mark_as_processing(self):
        """Mark media file as processing."""
        self.status = MediaStatus.PROCESSING.value
        self.updated_at = datetime.utcnow()
    
    def mark_as_ready(self, storage_url: str, thumbnail_url: Optional[str] = None):
        """Mark media file as ready with URLs."""
        self.status = MediaStatus.READY.value
        self.storage_url = storage_url
        if thumbnail_url:
            self.thumbnail_url = thumbnail_url
        self.updated_at = datetime.utcnow()
    
    def mark_as_failed(self, error_message: Optional[str] = None):
        """Mark media file as failed."""
        self.status = MediaStatus.FAILED.value
        if error_message:
            self.processing_metadata = error_message
        self.updated_at = datetime.utcnow()
    
    def soft_delete(self):
        """Soft delete media file."""
        self.status = MediaStatus.DELETED.value
        self.updated_at = datetime.utcnow()
