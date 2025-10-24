"""
Reports Domain Models
====================
Domain-specific models for the Reports bounded context.
Following Domain-Driven Design principles.
"""

from sqlalchemy import Column, String, Integer, DateTime, Float, Boolean, ForeignKey, Text, Enum as SQLEnum, ARRAY
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from pgvector.sqlalchemy import Vector
import enum
import uuid as uuid_pkg
from datetime import datetime
from typing import Optional, List

from ....infrastructure.database.base import Base


class ReportType(str, enum.Enum):
    """Report type enumeration."""
    LOST = "lost"
    FOUND = "found"


class ReportStatus(str, enum.Enum):
    """Report status enumeration."""
    PENDING = "pending"
    APPROVED = "approved"
    HIDDEN = "hidden"
    REMOVED = "removed"
    REJECTED = "rejected"
    RESOLVED = "resolved"


class Report(Base):
    """
    Report Entity - Core domain model for lost and found items.
    
    This entity represents a lost or found item report with all its
    associated metadata, location, and contact information.
    """
    __tablename__ = "reports"

    # Primary Key
    id = Column(String, primary_key=True, default=lambda: str(uuid_pkg.uuid4()))
    
    # Domain Identity
    owner_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    type = Column(String, nullable=False, index=True)
    status = Column(String, default="pending", index=True)
    
    # Core Domain Attributes
    title = Column(String, nullable=False)
    description = Column(Text)
    category = Column(String, nullable=False, index=True)
    colors = Column(ARRAY(String))
    
    # Temporal Information
    occurred_at = Column(DateTime(timezone=True), nullable=False)
    occurred_time = Column(String)  # Store time as string (HH:MM format)
    
    # Location Information
    geo = Column(Text)  # TEXT column for geographic data
    location_city = Column(String, index=True)
    location_address = Column(Text)
    latitude = Column(Float)
    longitude = Column(Float)
    
    # Contact and Additional Information
    contact_info = Column(Text)
    additional_info = Column(Text)
    attributes = Column(Text)
    condition = Column(String)
    is_urgent = Column(Boolean, default=False)
    reward_offered = Column(Boolean, default=False)
    reward_amount = Column(String)  # Changed from Float to String to match DB
    
    # Safety and Resolution
    safety_status = Column(String)
    is_safe = Column(Boolean, default=True)
    is_resolved = Column(Boolean, default=False)
    moderation_notes = Column(Text)
    
    # Media and Processing
    images = Column(ARRAY(String))
    image_hashes = Column(ARRAY(String))
    text_embedding = Column(Vector(384))  # For semantic search
    
    # Audit Fields
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Domain Relationships
    owner = relationship("User", back_populates="reports", foreign_keys=[owner_id])
    source_matches = relationship("Match", back_populates="source_report", foreign_keys="Match.source_report_id")
    candidate_matches = relationship("Match", back_populates="candidate_report", foreign_keys="Match.candidate_report_id")
    fraud_detection_results = relationship("FraudDetectionResult", back_populates="report")
    
    def __repr__(self):
        return f"<Report(id='{self.id}', type='{self.type}', title='{self.title}')>"
    
    def is_active(self) -> bool:
        """Check if report is active (approved and not removed)."""
        return self.status == ReportStatus.APPROVED.value
    
    def can_be_matched(self) -> bool:
        """Check if report can participate in matching."""
        return self.is_active() and self.type == ReportType.LOST.value
    
    def get_location_summary(self) -> str:
        """Get a summary of the location information."""
        parts = []
        if self.location_city:
            parts.append(self.location_city)
        if self.location_address:
            parts.append(self.location_address)
        return ", ".join(parts) if parts else "Location not specified"
    
    def get_contact_summary(self) -> str:
        """Get a summary of contact information."""
        if self.contact_info:
            return self.contact_info[:100] + "..." if len(self.contact_info) > 100 else self.contact_info
        return "No contact information provided"
    
    def has_images(self) -> bool:
        """Check if report has associated images."""
        return bool(self.images and len(self.images) > 0)
    
    def get_image_count(self) -> int:
        """Get the number of images associated with this report."""
        return len(self.images) if self.images else 0
