"""
User Domain Schemas
==================
Pydantic schemas for user-related operations with comprehensive validation.
"""

from pydantic import BaseModel, EmailStr, Field, field_validator, model_validator
from typing import Optional, Dict, Any, List
from datetime import datetime
from enum import Enum
import re


class UserRole(str, Enum):
    """User role enumeration."""
    USER = "user"
    ADMIN = "admin"
    MODERATOR = "moderator"


class UserStatus(str, Enum):
    """User status enumeration."""
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"
    PENDING = "pending"


class PrivacyLevel(str, Enum):
    """Privacy level enumeration."""
    PUBLIC = "public"
    FRIENDS = "friends"
    PRIVATE = "private"


# Base User Schemas
class UserBase(BaseModel):
    """Base user schema with common fields."""
    email: EmailStr
    display_name: Optional[str] = Field(None, min_length=2, max_length=100)
    phone_number: Optional[str] = Field(None, max_length=20)
    avatar_url: Optional[str] = Field(None, max_length=500)
    bio: Optional[str] = Field(None, max_length=500)
    location: Optional[str] = Field(None, max_length=100)
    gender: Optional[str] = Field(None, max_length=20)
    date_of_birth: Optional[datetime] = None
    
    @field_validator('display_name')
    @classmethod
    def validate_display_name(cls, v):
        if v is not None:
            # Remove extra whitespace
            v = v.strip()
            if not v:
                raise ValueError('Display name cannot be empty')
            # Check for valid characters (letters, numbers, spaces, hyphens, underscores)
            if not re.match(r'^[a-zA-Z0-9\s\-_]+$', v):
                raise ValueError('Display name can only contain letters, numbers, spaces, hyphens, and underscores')
        return v
    
    @field_validator('phone_number')
    @classmethod
    def validate_phone_number(cls, v):
        if v is not None:
            # Remove all non-digit characters except + at the beginning
            cleaned = re.sub(r'[^\d+]', '', v)
            if not re.match(r'^\+?[\d]{7,15}$', cleaned):
                raise ValueError('Invalid phone number format')
            return cleaned
        return v
    
    @field_validator('avatar_url')
    @classmethod
    def validate_avatar_url(cls, v):
        if v is not None:
            # Basic URL validation
            if not re.match(r'^https?://.+', v):
                raise ValueError('Avatar URL must be a valid HTTP/HTTPS URL')
        return v
    
    @field_validator('bio')
    @classmethod
    def validate_bio(cls, v):
        if v is not None:
            v = v.strip()
            if len(v) > 500:
                raise ValueError('Bio must be less than 500 characters')
        return v
    
    @field_validator('location')
    @classmethod
    def validate_location(cls, v):
        if v is not None:
            v = v.strip()
            if len(v) < 2:
                raise ValueError('Location must be at least 2 characters')
            if len(v) > 100:
                raise ValueError('Location must be less than 100 characters')
        return v
    
    @field_validator('gender')
    @classmethod
    def validate_gender(cls, v):
        if v is not None:
            valid_genders = ['male', 'female', 'other', 'prefer_not_to_say']
            if v not in valid_genders:
                raise ValueError(f'Gender must be one of: {", ".join(valid_genders)}')
        return v
    
    @field_validator('date_of_birth')
    @classmethod
    def validate_date_of_birth(cls, v):
        if v is not None:
            # Check if date is not in the future
            if v > datetime.now():
                raise ValueError('Date of birth cannot be in the future')
            # Check if date is not too old (before 1900)
            if v < datetime(1900, 1, 1):
                raise ValueError('Date of birth cannot be before 1900')
        return v


class UserCreate(UserBase):
    """Schema for creating a new user."""
    password: str = Field(..., min_length=8, max_length=128)
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v):
        # Password strength validation
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not re.search(r'[a-z]', v):
            raise ValueError('Password must contain at least one lowercase letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one number')
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            raise ValueError('Password must contain at least one special character')
        return v


class UserUpdate(BaseModel):
    """Schema for updating user profile."""
    display_name: Optional[str] = Field(None, min_length=2, max_length=100)
    phone_number: Optional[str] = Field(None, max_length=20)
    avatar_url: Optional[str] = Field(None, max_length=500)
    bio: Optional[str] = Field(None, max_length=500)
    location: Optional[str] = Field(None, max_length=100)
    gender: Optional[str] = Field(None, max_length=20)
    date_of_birth: Optional[datetime] = None
    
    @field_validator('display_name')
    @classmethod
    def validate_display_name(cls, v):
        if v is not None:
            v = v.strip()
            if not v:
                raise ValueError('Display name cannot be empty')
            if not re.match(r'^[a-zA-Z0-9\s\-_]+$', v):
                raise ValueError('Display name can only contain letters, numbers, spaces, hyphens, and underscores')
        return v
    
    @field_validator('phone_number')
    @classmethod
    def validate_phone_number(cls, v):
        if v is not None:
            cleaned = re.sub(r'[^\d+]', '', v)
            if not re.match(r'^\+?[\d]{7,15}$', cleaned):
                raise ValueError('Invalid phone number format')
            return cleaned
        return v
    
    @field_validator('avatar_url')
    @classmethod
    def validate_avatar_url(cls, v):
        if v is not None:
            if not re.match(r'^https?://.+', v):
                raise ValueError('Avatar URL must be a valid HTTP/HTTPS URL')
        return v
    
    @field_validator('bio')
    @classmethod
    def validate_bio(cls, v):
        if v is not None:
            v = v.strip()
            if len(v) > 500:
                raise ValueError('Bio must be less than 500 characters')
        return v
    
    @field_validator('location')
    @classmethod
    def validate_location(cls, v):
        if v is not None:
            v = v.strip()
            if len(v) < 2:
                raise ValueError('Location must be at least 2 characters')
            if len(v) > 100:
                raise ValueError('Location must be less than 100 characters')
        return v
    
    @field_validator('gender')
    @classmethod
    def validate_gender(cls, v):
        if v is not None:
            valid_genders = ['male', 'female', 'other', 'prefer_not_to_say']
            if v not in valid_genders:
                raise ValueError(f'Gender must be one of: {", ".join(valid_genders)}')
        return v
    
    @field_validator('date_of_birth')
    @classmethod
    def validate_date_of_birth(cls, v):
        if v is not None:
            # Check if date is not in the future
            if v > datetime.now():
                raise ValueError('Date of birth cannot be in the future')
            # Check if date is not too old (before 1900)
            if v < datetime(1900, 1, 1):
                raise ValueError('Date of birth cannot be before 1900')
        return v


class PasswordChange(BaseModel):
    """Schema for password change requests."""
    current_password: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=8, max_length=128)
    
    @field_validator('new_password')
    @classmethod
    def validate_new_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not re.search(r'[a-z]', v):
            raise ValueError('Password must contain at least one lowercase letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one number')
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            raise ValueError('Password must contain at least one special character')
        return v
    
    @model_validator(mode='after')
    def validate_passwords_different(self):
        if self.current_password and self.new_password and self.current_password == self.new_password:
            raise ValueError('New password must be different from current password')
        return self


class PrivacySettings(BaseModel):
    """Schema for user privacy settings."""
    profile_visibility: PrivacyLevel = PrivacyLevel.PUBLIC
    show_email: bool = False
    show_phone: bool = True
    allow_messages: bool = True
    show_location: bool = True
    allow_notifications: bool = True
    data_sharing: bool = False
    
    class Config:
        use_enum_values = True


class UserProfile(BaseModel):
    """Schema for user profile response."""
    id: str
    email: str
    display_name: Optional[str]
    phone_number: Optional[str]
    avatar_url: Optional[str]
    bio: Optional[str]
    location: Optional[str]
    gender: Optional[str]
    date_of_birth: Optional[datetime]
    role: UserRole
    status: UserStatus
    privacy_settings: Optional[PrivacySettings]
    created_at: datetime
    updated_at: Optional[datetime]
    last_login: Optional[datetime]
    
    class Config:
        use_enum_values = True


class UserStats(BaseModel):
    """Schema for user statistics."""
    reports: Dict[str, int] = Field(default_factory=dict)
    matches: Dict[str, int] = Field(default_factory=dict)
    activity: Dict[str, Any] = Field(default_factory=dict)
    
    class Config:
        json_schema_extra = {
            "example": {
                "reports": {
                    "total": 15,
                    "active": 8,
                    "resolved": 5,
                    "draft": 2
                },
                "matches": {
                    "total": 12,
                    "successful": 7,
                    "pending": 3,
                    "dismissed": 2
                },
                "activity": {
                    "last_activity": "2024-01-15T10:30:00Z",
                    "success_rate": 58.3
                }
            }
        }


class UserSearch(BaseModel):
    """Schema for user search requests."""
    query: str = Field(..., min_length=2, max_length=100)
    limit: int = Field(10, ge=1, le=50)
    offset: int = Field(0, ge=0)
    
    @field_validator('query')
    @classmethod
    def validate_query(cls, v):
        v = v.strip()
        if not v:
            raise ValueError('Search query cannot be empty')
        return v


class UserList(BaseModel):
    """Schema for user list response."""
    users: List[UserProfile]
    total: int
    limit: int
    offset: int
    has_next: bool
    has_previous: bool


class AccountDeletion(BaseModel):
    """Schema for account deletion requests."""
    password: str = Field(..., min_length=1)
    reason: Optional[str] = Field(None, max_length=500)
    confirm_deletion: bool = Field(False)
    
    @field_validator('confirm_deletion')
    @classmethod
    def validate_confirmation(cls, v):
        if not v:
            raise ValueError('You must confirm account deletion')
        return v


class DataExport(BaseModel):
    """Schema for data export requests."""
    format: str = Field("json", pattern="^(json|csv|pdf)$")
    include_reports: bool = True
    include_matches: bool = True
    include_messages: bool = False
    include_analytics: bool = False
    
    class Config:
        json_schema_extra = {
            "example": {
                "format": "json",
                "include_reports": True,
                "include_matches": True,
                "include_messages": False,
                "include_analytics": False
            }
        }


class UserActivity(BaseModel):
    """Schema for user activity tracking."""
    action: str
    resource_type: str
    resource_id: Optional[str]
    metadata: Optional[Dict[str, Any]]
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class UserPreferences(BaseModel):
    """Schema for user preferences."""
    language: str = Field("en", pattern="^[a-z]{2}$")
    timezone: str = Field("UTC", max_length=50)
    theme: str = Field("light", pattern="^(light|dark|auto)$")
    notifications: Dict[str, bool] = Field(default_factory=dict)
    
    class Config:
        json_schema_extra = {
            "example": {
                "language": "en",
                "timezone": "UTC",
                "theme": "light",
                "notifications": {
                    "email": True,
                    "push": True,
                    "sms": False
                }
            }
        }


# Response Schemas
class UserResponse(BaseModel):
    """Standard user response schema."""
    success: bool = True
    message: str
    data: Optional[UserProfile] = None
    errors: Optional[List[str]] = None


class UserStatsResponse(BaseModel):
    """User statistics response schema."""
    success: bool = True
    message: str
    data: Optional[UserStats] = None
    errors: Optional[List[str]] = None


class PrivacySettingsResponse(BaseModel):
    """Privacy settings response schema."""
    success: bool = True
    message: str
    data: Optional[PrivacySettings] = None
    errors: Optional[List[str]] = None


class DataExportResponse(BaseModel):
    """Data export response schema."""
    success: bool = True
    message: str
    download_url: Optional[str] = None
    expires_at: Optional[datetime] = None
    errors: Optional[List[str]] = None
