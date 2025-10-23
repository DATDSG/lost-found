"""
Reports Domain Schemas
=====================
Pydantic schemas for the Reports domain following DDD principles.
"""

from pydantic import BaseModel, Field, ConfigDict, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


class ReportTypeEnum(str, Enum):
    """Report type enumeration for API."""
    LOST = "lost"
    FOUND = "found"


class ReportStatusEnum(str, Enum):
    """Report status enumeration for API."""
    PENDING = "pending"
    APPROVED = "approved"
    HIDDEN = "hidden"
    REMOVED = "removed"
    REJECTED = "rejected"


# Base Schemas
class ReportBase(BaseModel):
    """Base schema for report operations."""
    type: ReportTypeEnum
    title: str = Field(..., min_length=3, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    category: str = Field(..., min_length=2, max_length=50)
    colors: Optional[List[str]] = Field(default_factory=list)
    occurred_at: datetime
    occurred_time: Optional[str] = Field(None, pattern=r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$')
    location_city: Optional[str] = Field(None, max_length=100)
    location_address: Optional[str] = Field(None, max_length=500)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    contact_info: Optional[str] = Field(None, max_length=1000)
    is_urgent: bool = False
    reward_offered: bool = False
    reward_amount: Optional[float] = Field(None, ge=0)


class ReportCreate(ReportBase):
    """Schema for creating a new report."""
    images: Optional[List[str]] = Field(default_factory=list)
    
    @validator('images')
    def validate_images(cls, v):
        if v and len(v) > 10:
            raise ValueError('Maximum 10 images allowed')
        return v
    
    @validator('colors')
    def validate_colors(cls, v):
        if v and len(v) > 5:
            raise ValueError('Maximum 5 colors allowed')
        return v


class ReportUpdate(BaseModel):
    """Schema for updating an existing report."""
    title: Optional[str] = Field(None, min_length=3, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    category: Optional[str] = Field(None, min_length=2, max_length=50)
    colors: Optional[List[str]] = None
    occurred_at: Optional[datetime] = None
    occurred_time: Optional[str] = Field(None, pattern=r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$')
    location_city: Optional[str] = Field(None, max_length=100)
    location_address: Optional[str] = Field(None, max_length=500)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    contact_info: Optional[str] = Field(None, max_length=1000)
    is_urgent: Optional[bool] = None
    reward_offered: Optional[bool] = None
    reward_amount: Optional[float] = Field(None, ge=0)
    images: Optional[List[str]] = None
    status: Optional[ReportStatusEnum] = None


class ReportResponse(ReportBase):
    """Schema for report responses."""
    id: str
    owner_id: str
    status: ReportStatusEnum
    images: Optional[List[str]] = Field(default_factory=list)
    image_hashes: Optional[List[str]] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)
    
    @validator('images', pre=True)
    def convert_images_none_to_empty_list(cls, v):
        return v if v is not None else []
    
    @validator('image_hashes', pre=True)
    def convert_image_hashes_none_to_empty_list(cls, v):
        return v if v is not None else []
    
    @validator('owner_id', pre=True)
    def convert_uuid_to_string(cls, v):
        return str(v) if v is not None else v
    
    @validator('is_urgent', pre=True)
    def convert_none_to_false(cls, v):
        return v if v is not None else False


class ReportSummary(BaseModel):
    """Simplified report schema for lists and summaries."""
    id: str
    type: ReportTypeEnum
    title: str
    category: str
    location_city: Optional[str]
    occurred_at: datetime
    is_urgent: bool
    reward_offered: bool
    image_count: int
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


class ReportSearchRequest(BaseModel):
    """Schema for report search requests."""
    query: Optional[str] = Field(None, max_length=200)
    type: Optional[ReportTypeEnum] = None
    category: Optional[str] = None
    location_city: Optional[str] = None
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    radius_km: Optional[float] = Field(5.0, ge=0.1, le=100)
    is_urgent: Optional[bool] = None
    reward_offered: Optional[bool] = None
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None
    page: int = Field(1, ge=1)
    page_size: int = Field(20, ge=1, le=100)


class ReportSearchResponse(BaseModel):
    """Schema for report search responses."""
    reports: List[ReportSummary]
    total: int
    page: int
    page_size: int
    has_next: bool
    has_previous: bool


class ReportStats(BaseModel):
    """Schema for report statistics."""
    total_reports: int
    lost_reports: int
    found_reports: int
    pending_reports: int
    approved_reports: int
    urgent_reports: int
    reports_with_rewards: int
    reports_with_images: int
    average_images_per_report: float
    most_common_categories: List[Dict[str, Any]]
    reports_by_city: List[Dict[str, Any]]
