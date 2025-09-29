from datetime import datetime
from typing import Dict, Any, Optional
from pydantic import BaseModel, Field

from app.schemas.common import ORMBase


class MatchPublic(ORMBase):
    id: int
    lost_item_id: int
    found_item_id: int
    
    # Explainable scoring
    score_final: float = Field(..., ge=0, le=1)
    score_breakdown: Optional[Dict[str, float]] = None
    
    # Match metadata
    distance_km: Optional[float] = None
    time_diff_hours: Optional[float] = None
    status: str = Field(default="pending")
    
    created_at: datetime
    updated_at: datetime
    
    # Related items (populated when needed)
    lost_item: Optional['ItemPublic'] = None
    found_item: Optional['ItemPublic'] = None


class MatchWithItems(MatchPublic):
    """Match with full item details included."""
    lost_item: 'ItemPublic'
    found_item: 'ItemPublic'


class MatchUpdate(BaseModel):
    """Update match status."""
    status: str = Field(..., pattern="^(pending|viewed|dismissed|claimed)$")


class MatchExplanation(BaseModel):
    """Detailed match explanation for UI."""
    final_score: float = Field(..., ge=0, le=1)
    confidence_level: str = Field(..., pattern="^(low|medium|high)$")
    explanation_text: str
    
    # Component scores
    category_score: Optional[float] = None
    distance_score: Optional[float] = None
    time_score: Optional[float] = None
    attribute_score: Optional[float] = None
    text_score: Optional[float] = None  # Only when NLP_ON
    image_score: Optional[float] = None  # Only when CV_ON
    
    # Metadata
    distance_km: Optional[float] = None
    time_diff_hours: Optional[float] = None


class MatchRequest(BaseModel):
    """Request to find matches for an item."""
    item_id: int
    limit: Optional[int] = Field(default=10, ge=1, le=50)
    min_score: Optional[float] = Field(default=None, ge=0, le=1)


# Forward reference resolution
from app.schemas.items import ItemPublic
MatchPublic.model_rebuild()
MatchWithItems.model_rebuild()