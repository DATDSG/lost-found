from datetime import datetime
from typing import List, Optional, Dict, Any

from pydantic import BaseModel, Field, validator

from app.schemas.common import ORMBase

class ItemCreate(BaseModel):
    # Core identification
    title: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=2000)
    language: str = Field(default="en", pattern="^(si|ta|en)$")
    status: str = Field(default="lost", pattern="^(lost|found)$")
    
    # Structured categorization (required for baseline matching)
    category: str = Field(..., min_length=1, max_length=100)
    subcategory: Optional[str] = Field(None, max_length=100)
    brand: Optional[str] = Field(None, max_length=100)
    model: Optional[str] = Field(None, max_length=100)
    color: Optional[str] = Field(None, max_length=50)
    
    # Unique identifiers for proof-of-ownership
    unique_marks: Optional[str] = Field(None, max_length=1000)
    evidence_hash: Optional[str] = Field(None, max_length=64)
    
    # Location data
    lat: Optional[float] = Field(None, ge=-90, le=90)
    lng: Optional[float] = Field(None, ge=-180, le=180)
    location_name: Optional[str] = Field(None, max_length=255)
    location_fuzzing: int = Field(default=100, ge=0, le=1000)
    
    # Temporal data
    lost_found_at: Optional[datetime] = None
    time_window_start: Optional[datetime] = None
    time_window_end: Optional[datetime] = None
    
    @validator('lng')
    def validate_coordinates(cls, v, values):
        lat = values.get('lat')
        if (lat is None) != (v is None):
            raise ValueError('Both lat and lng must be provided together or both omitted')
        return v

class ItemUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=2000)
    language: Optional[str] = Field(None, pattern="^(si|ta|en)$")
    status: Optional[str] = Field(None, pattern="^(lost|found|claimed|closed)$")
    
    category: Optional[str] = Field(None, max_length=100)
    subcategory: Optional[str] = Field(None, max_length=100)
    brand: Optional[str] = Field(None, max_length=100)
    model: Optional[str] = Field(None, max_length=100)
    color: Optional[str] = Field(None, max_length=50)
    
    unique_marks: Optional[str] = Field(None, max_length=1000)
    evidence_hash: Optional[str] = Field(None, max_length=64)
    
    lat: Optional[float] = Field(None, ge=-90, le=90)
    lng: Optional[float] = Field(None, ge=-180, le=180)
    location_name: Optional[str] = Field(None, max_length=255)
    location_fuzzing: Optional[int] = Field(None, ge=0, le=1000)
    
    lost_found_at: Optional[datetime] = None
    time_window_start: Optional[datetime] = None
    time_window_end: Optional[datetime] = None

class ItemPublic(ORMBase):
    id: int
    title: str
    description: Optional[str] = None
    language: str
    status: str
    
    # Structured fields
    category: str
    subcategory: Optional[str] = None
    brand: Optional[str] = None
    model: Optional[str] = None
    color: Optional[str] = None
    
    # Location (potentially fuzzed for privacy)
    lat: Optional[float] = None
    lng: Optional[float] = None
    location_name: Optional[str] = None
    geohash6: Optional[str] = None
    
    # Temporal data
    lost_found_at: Optional[datetime] = None
    time_window_start: Optional[datetime] = None
    time_window_end: Optional[datetime] = None
    
    # System fields
    owner_id: int
    created_at: datetime
    updated_at: datetime
    
    # Media assets
    media: List['MediaAssetPublic'] = []

class ItemPrivate(ItemPublic):
    """Extended item schema for owners with private fields."""
    unique_marks: Optional[str] = None
    evidence_hash: Optional[str] = None
    location_fuzzing: int
    
    # NLP features (if available)
    text_embedding: Optional[List[float]] = None
    extracted_entities: Optional[Dict[str, Any]] = None

class ItemSearch(BaseModel):
    """Search parameters for finding items."""
    query: Optional[str] = None
    category: Optional[str] = None
    subcategory: Optional[str] = None
    status: Optional[str] = Field(None, pattern="^(lost|found|claimed|closed)$")
    
    # Geospatial search
    lat: Optional[float] = Field(None, ge=-90, le=90)
    lng: Optional[float] = Field(None, ge=-180, le=180)
    radius_km: Optional[float] = Field(None, ge=0.1, le=100)
    
    # Temporal search
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None
    
    # Pagination
    skip: int = Field(default=0, ge=0)
    limit: int = Field(default=20, ge=1, le=100)

# Forward reference resolution
from app.schemas.media import MediaAssetPublic
ItemPublic.model_rebuild()