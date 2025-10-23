"""
Matches Domain Schemas
=====================
Pydantic schemas for the Matches domain following DDD principles.
"""

from pydantic import BaseModel, Field, ConfigDict, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


class MatchStatusEnum(str, Enum):
    """Match status enumeration for API."""
    CANDIDATE = "candidate"
    PROMOTED = "promoted"
    SUPPRESSED = "suppressed"
    DISMISSED = "dismissed"


class ConfidenceLevelEnum(str, Enum):
    """Confidence level enumeration for API."""
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


# Base Schemas
class MatchBase(BaseModel):
    """Base schema for match operations."""
    source_report_id: str = Field(..., description="Source report ID")
    candidate_report_id: str = Field(..., description="Candidate report ID")
    score_total: float = Field(..., ge=0.0, le=1.0, description="Total match score")
    score_text: Optional[float] = Field(None, ge=0.0, le=1.0, description="Text similarity score")
    score_image: Optional[float] = Field(None, ge=0.0, le=1.0, description="Image similarity score")
    score_geo: Optional[float] = Field(None, ge=0.0, le=1.0, description="Geographic proximity score")
    score_time: Optional[float] = Field(None, ge=0.0, le=1.0, description="Temporal proximity score")
    status: MatchStatusEnum = Field(MatchStatusEnum.CANDIDATE, description="Match status")
    is_notified: bool = Field(False, description="Whether user has been notified")
    confidence_level: Optional[ConfidenceLevelEnum] = Field(None, description="Confidence level")


class MatchCreate(MatchBase):
    """Schema for creating a new match."""
    pass


class MatchUpdate(BaseModel):
    """Schema for updating an existing match."""
    status: Optional[MatchStatusEnum] = None
    is_notified: Optional[bool] = None
    confidence_level: Optional[ConfidenceLevelEnum] = None


class MatchResponse(MatchBase):
    """Schema for match responses."""
    id: str
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


class MatchSummary(BaseModel):
    """Simplified match schema for lists and summaries."""
    id: str
    source_report_id: str
    candidate_report_id: str
    score_total: float
    status: MatchStatusEnum
    confidence_level: Optional[ConfidenceLevelEnum]
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


class MatchSearchRequest(BaseModel):
    """Schema for match search requests."""
    source_report_id: Optional[str] = None
    candidate_report_id: Optional[str] = None
    status: Optional[MatchStatusEnum] = None
    confidence_level: Optional[ConfidenceLevelEnum] = None
    min_score: Optional[float] = Field(None, ge=0.0, le=1.0)
    max_score: Optional[float] = Field(None, ge=0.0, le=1.0)
    is_notified: Optional[bool] = None
    page: int = Field(1, ge=1)
    page_size: int = Field(20, ge=1, le=100)


class MatchSearchResponse(BaseModel):
    """Schema for match search responses."""
    matches: List[MatchSummary]
    total: int
    page: int
    page_size: int
    has_next: bool
    has_previous: bool


class MatchStats(BaseModel):
    """Schema for match statistics."""
    total_matches: int
    candidate_matches: int
    promoted_matches: int
    suppressed_matches: int
    dismissed_matches: int
    high_confidence_matches: int
    medium_confidence_matches: int
    low_confidence_matches: int
    notified_matches: int
    average_score: float
    matches_by_status: List[Dict[str, Any]]
    matches_by_confidence: List[Dict[str, Any]]


class MatchScoreBreakdown(BaseModel):
    """Schema for detailed match score breakdown."""
    total: float
    text: Optional[float]
    image: Optional[float]
    geo: Optional[float]
    time: Optional[float]
    confidence_level: ConfidenceLevelEnum


class BulkMatchRequest(BaseModel):
    """Schema for bulk match operations."""
    match_ids: List[str] = Field(..., min_length=1, max_length=100)
    action: str = Field(..., description="Action to perform: promote, dismiss, suppress")
    reason: Optional[str] = Field(None, max_length=500, description="Reason for the action")


class BulkMatchResponse(BaseModel):
    """Schema for bulk match operation responses."""
    success_count: int
    failed_count: int
    errors: List[Dict[str, str]]
