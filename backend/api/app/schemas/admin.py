from datetime import datetime
from typing import Any

from pydantic import BaseModel

from app.schemas.items import ItemPublic
from app.schemas.flags import FlagPublic, FlaggedItemSummary


class CategoryStat(BaseModel):
    category: str | None
    total: int


class DashboardStats(BaseModel):
    users: int
    items: int
    resolved_items: int
    resolution_rate: float
    open_flags: int
    average_match_score: float | None
    average_match_latency_seconds: float | None
    items_by_category: list[CategoryStat]


class ModerationAction(BaseModel):
    action: str
    notes: str | None = None


class ModerationResponse(BaseModel):
    status: str
    item: ItemPublic
    flags_closed: int
