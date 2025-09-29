from pydantic import BaseModel
from app.schemas.common import ORMBase

class ChatCreate(BaseModel):
    room: str
    message: str

class ChatPublic(ORMBase):
    id: int
    room: str
    sender_id: int | None
    message: str