"""Pydantic schemas for request/response validation."""
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class ReportType(str, Enum):
    LOST = "lost"
    FOUND = "found"


class ReportStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    HIDDEN = "hidden"
    REMOVED = "removed"


# Auth schemas
class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    display_name: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: str
    email: str
    display_name: Optional[str] = None
    phone_number: Optional[str] = None
    avatar_url: Optional[str] = None
    role: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# Media schemas
class MediaResponse(BaseModel):
    id: str
    url: str
    type: str
    filename: str
    width: Optional[int] = None
    height: Optional[int] = None
    size_bytes: Optional[int] = None

    @classmethod
    def from_orm(cls, obj):
        """Convert ORM Media object to response schema."""
        return cls(
            id=obj.id,
            url=obj.url,
            type=obj.media_type,  # Map from database field
            filename=obj.filename,
            width=obj.width,
            height=obj.height,
            size_bytes=obj.size_bytes
        )

    class Config:
        from_attributes = True


# Report schemas
class ReportCreate(BaseModel):
    type: ReportType
    title: str = Field(min_length=3, max_length=200)
    description: str
    category: str
    colors: Optional[List[str]] = []
    occurred_at: datetime
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    location_city: Optional[str] = None
    location_address: Optional[str] = None
    reward_offered: Optional[bool] = False
    media_ids: Optional[List[str]] = []


class ReportSummary(BaseModel):
    id: str
    title: str
    status: ReportStatus
    type: ReportType
    category: str
    city: str
    media: List[MediaResponse]
    created_at: datetime

    @classmethod
    def from_orm(cls, obj):
        """Convert ORM Report object to response schema."""
        # Handle media relationship safely
        media_list = []
        try:
            # Check if media relationship is loaded and accessible
            if hasattr(obj, 'media') and obj.media is not None:
                media_list = [MediaResponse.from_orm(m) for m in obj.media]
        except Exception:
            # If there's any issue accessing media, just use empty list
            media_list = []
        
        return cls(
            id=obj.id,
            title=obj.title,
            status=obj.status,
            type=obj.type,
            category=obj.category,
            city=obj.location_city or "Unknown",
            media=media_list,
            created_at=obj.created_at
        )

    class Config:
        from_attributes = True


class ReportDetail(ReportSummary):
    description: str
    colors: Optional[List[str]]
    occurred_at: datetime
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    location_address: Optional[str]
    reward_offered: Optional[bool]
    is_resolved: bool

    @classmethod
    def from_orm(cls, obj):
        """Convert ORM Report object to response schema."""
        # Parse latitude/longitude from geo field if available
        latitude = None
        longitude = None
        if obj.geo and obj.geo.startswith('POINT('):
            try:
                # Extract coordinates from POINT(lng lat) format
                coords = obj.geo.replace('POINT(', '').replace(')', '').split()
                if len(coords) == 2:
                    longitude, latitude = float(coords[0]), float(coords[1])
            except (ValueError, IndexError):
                pass
        
        # Handle media relationship safely
        media_list = []
        try:
            # Check if media relationship is loaded and accessible
            if hasattr(obj, 'media') and obj.media is not None:
                media_list = [MediaResponse.from_orm(m) for m in obj.media]
        except Exception:
            # If there's any issue accessing media, just use empty list
            media_list = []
        
        return cls(
            id=obj.id,
            title=obj.title,
            status=obj.status,
            type=obj.type,
            category=obj.category,
            city=obj.location_city or "Unknown",
            media=media_list,
            created_at=obj.created_at,
            description=obj.description or "",
            colors=obj.colors or [],
            occurred_at=obj.occurred_at,
            latitude=latitude,
            longitude=longitude,
            location_address=obj.location_address,
            reward_offered=obj.reward_offered or False,
            is_resolved=obj.is_resolved or False
        )

    class Config:
        from_attributes = True


# Match schemas
class MatchComponent(BaseModel):
    name: str
    score: float


class MatchCandidate(BaseModel):
    id: str
    overall: float
    components: List[MatchComponent]
    counterpart: ReportSummary
    explanation: Optional[str] = None

    class Config:
        from_attributes = True


# Message schemas
class MessageCreate(BaseModel):
    conversation_id: str
    content: str = Field(min_length=1, max_length=2000)


class MessageDetail(BaseModel):
    id: str
    conversation_id: str
    sender_id: str
    content: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


class ConversationSummary(BaseModel):
    id: str
    match_id: Optional[str]
    participant_one_id: str
    participant_two_id: str
    last_message: Optional[MessageDetail]
    unread_count: int
    updated_at: datetime


class ConversationDetail(BaseModel):
    id: str
    match_id: Optional[str]
    participant_one_id: str
    participant_two_id: str
    messages: List[MessageDetail]
    created_at: datetime
    updated_at: datetime


# Pagination
class PaginatedResponse(BaseModel):
    items: List[dict]
    total: int
    page: int
    page_size: int
    has_next: bool


# Error response
class ErrorResponse(BaseModel):
    code: str
    message: str
    details: Optional[dict] = None


# Bulk operation schemas
class BulkOperationRequest(BaseModel):
    """Request body for bulk operations."""
    ids: List[str] = Field(min_items=1, max_items=100, description="List of IDs to operate on")


class BulkOperationError(BaseModel):
    """Individual error in bulk operation."""
    id: str
    error: str


class BulkOperationResult(BaseModel):
    """Result of a bulk operation."""
    success: int = Field(description="Number of successfully processed items")
    failed: int = Field(description="Number of failed items")
    errors: List[BulkOperationError] = Field(default_factory=list, description="List of errors for failed items")


# Taxonomy schemas
class CategoryResponse(BaseModel):
    """Category taxonomy response."""
    id: str
    name: str
    icon: Optional[str]
    sort_order: int
    is_active: bool

    class Config:
        from_attributes = True


class ColorResponse(BaseModel):
    """Color taxonomy response."""
    id: str
    name: str
    hex_code: Optional[str]
    sort_order: int
    is_active: bool

    class Config:
        from_attributes = True


# Notification schemas  
class NotificationResponse(BaseModel):
    """Notification response."""
    id: str
    type: str
    title: str
    content: Optional[str]
    reference_id: Optional[str]
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True
