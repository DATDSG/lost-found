from datetime import datetime
from typing import Any

from pydantic import BaseModel

from app.schemas.items import ItemPublic
from app.schemas.flags import FlagPublic, FlaggedItemSummary


class CategoryStat(BaseModel):
    category: str | None
    total: int


class DashboardStats(BaseModel):
    totalUsers: int
    totalItems: int
    totalMatches: int
    totalClaims: int
    itemsByStatus: dict[str, int]
    matchesByStatus: dict[str, int]
    claimsByStatus: dict[str, int]
    recentActivity: dict[str, int]


class ModerationAction(BaseModel):
    action: str
    notes: str | None = None


class ModerationResponse(BaseModel):
    status: str
    item: ItemPublic
    flags_closed: int
