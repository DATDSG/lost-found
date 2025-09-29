from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

from app.schemas.common import ORMBase


class ClaimCreate(BaseModel):
    """Create a new claim for a match."""
    match_id: int
    evidence_provided: Optional[str] = Field(None, max_length=2000)
    evidence_hash: Optional[str] = Field(None, max_length=64)


class ClaimUpdate(BaseModel):
    """Update claim status (for owners/moderators)."""
    status: str = Field(..., pattern="^(pending|approved|rejected|disputed)$")
    notes: Optional[str] = Field(None, max_length=1000)


class ClaimPublic(ORMBase):
    id: int
    match_id: int
    claimant_id: int
    owner_id: int
    status: str
    evidence_provided: Optional[str] = None
    created_at: datetime
    resolved_at: Optional[datetime] = None
    
    # Related objects (populated when needed)
    match: Optional['MatchPublic'] = None
    claimant: Optional['UserPublic'] = None
    owner: Optional['UserPublic'] = None


class ClaimPrivate(ClaimPublic):
    """Extended claim schema with sensitive fields for owners."""
    evidence_hash: Optional[str] = None


# Forward reference resolution
from app.schemas.matches import MatchPublic
from app.schemas.auth import UserPublic
ClaimPublic.model_rebuild()
ClaimPrivate.model_rebuild()
