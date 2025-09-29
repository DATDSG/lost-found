from datetime import datetime
from typing import Any

from pydantic import BaseModel

from app.schemas.items import ItemPublic


class FlagCreate(BaseModel):
    reason: str
    source: str = "user"
    metadata: dict[str, Any] | None = None


class FlagPublic(BaseModel):
    id: int
    item_id: int
    reporter_id: int | None
    source: str
    reason: str
    status: str
    metadata: dict[str, Any] | None
    created_at: datetime

    class Config:
        from_attributes = True


class FlaggedItemSummary(BaseModel):
    item: ItemPublic
    flags: list[FlagPublic]

    class Config:
        from_attributes = True
