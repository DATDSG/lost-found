from datetime import datetime
from typing import Any, Dict

from pydantic import BaseModel


class NotificationPublic(BaseModel):
    id: int
    type: str
    payload: Dict[str, Any] | None = None
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


class NotificationMarkRequest(BaseModel):
    read: bool = True
