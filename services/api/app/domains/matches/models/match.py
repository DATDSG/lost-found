"""
Matches Domain Models
====================
Domain-specific models for the Matches bounded context.
Following Domain-Driven Design principles.
"""

from sqlalchemy import Column, String, Float, Boolean, ForeignKey, DateTime, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
import uuid as uuid_pkg
from datetime import datetime
from typing import Optional

from ....infrastructure.database.base import Base


class MatchStatus(str, enum.Enum):
    """Match status enumeration."""
    CANDIDATE = "candidate"
    PROMOTED = "promoted"
    SUPPRESSED = "suppressed"
    DISMISSED = "dismissed"


class Match(Base):
    """
    Match Entity - Core domain model for potential matches between reports.
    
    This entity represents a potential match between a lost item and a found item,
    with scoring and status information.
    """
    __tablename__ = "matches"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid_pkg.uuid4)
    
    # Domain Identity
    source_report_id = Column(UUID(as_uuid=True), ForeignKey("reports.id"), nullable=False, index=True)
    candidate_report_id = Column(UUID(as_uuid=True), ForeignKey("reports.id"), nullable=False, index=True)
    
    # Match Scoring
    score_total = Column(Float, nullable=False, index=True)
    score_text = Column(Float)
    score_image = Column(Float)
    score_geo = Column(Float)
    score_time = Column(Float)
    score_color = Column(Float)
    
    # Match Status and Metadata
    status = Column(String, default="candidate", index=True)
    is_notified = Column(Boolean, default=False)
    confidence_level = Column(String)  # high, medium, low
    
    # Audit Fields
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Domain Relationships
    source_report = relationship("Report", back_populates="source_matches", foreign_keys=[source_report_id])
    candidate_report = relationship("Report", back_populates="candidate_matches", foreign_keys=[candidate_report_id])
    
    def __repr__(self):
        return f"<Match(id='{self.id}', score={self.score_total}, status='{self.status}')>"
    
    def is_high_confidence(self) -> bool:
        """Check if match has high confidence score."""
        return self.score_total >= 0.8
    
    def is_medium_confidence(self) -> bool:
        """Check if match has medium confidence score."""
        return 0.5 <= self.score_total < 0.8
    
    def is_low_confidence(self) -> bool:
        """Check if match has low confidence score."""
        return self.score_total < 0.5
    
    def get_confidence_level(self) -> str:
        """Get confidence level based on score."""
        if self.is_high_confidence():
            return "high"
        elif self.is_medium_confidence():
            return "medium"
        else:
            return "low"
    
    def can_be_promoted(self) -> bool:
        """Check if match can be promoted."""
        return self.status == MatchStatus.CANDIDATE.value and self.is_high_confidence()
    
    def can_be_dismissed(self) -> bool:
        """Check if match can be dismissed."""
        return self.status in [MatchStatus.CANDIDATE.value, MatchStatus.PROMOTED.value]
    
    def get_score_breakdown(self) -> dict:
        """Get detailed score breakdown."""
        return {
            "total": self.score_total,
            "text": self.score_text,
            "image": self.score_image,
            "geo": self.score_geo,
            "time": self.score_time,
            "color": self.score_color
        }
    
    def update_status(self, new_status: MatchStatus) -> bool:
        """Update match status with validation."""
        if new_status == MatchStatus.PROMOTED and not self.can_be_promoted():
            return False
        
        if new_status == MatchStatus.DISMISSED and not self.can_be_dismissed():
            return False
        
        self.status = new_status.value
        self.updated_at = datetime.utcnow()
        return True
