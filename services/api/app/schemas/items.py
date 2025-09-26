from pydantic import BaseModel, Field
from app.schemas.common import ORMBase

class ItemCreate(BaseModel):
    title: str
    description: str | None = None
    status: str = Field(default="lost", pattern="^(lost|found)$")
    lat: float | None = None
    lng: float | None = None

class ItemUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    status: str | None = Field(default=None, pattern="^(lost|found)$")
    lat: float | None = None
    lng: float | None = None

class ItemPublic(ORMBase):
    id: int
    title: str
    description: str | None = None
    status: str
    owner_id: int
    lat: float | None = None
    lng: float | None = None