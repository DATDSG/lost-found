from pydantic import BaseModel, EmailStr
from app.schemas.common import ORMBase

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str | None = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class UserPublic(ORMBase):
    id: int
    email: EmailStr
    full_name: str | None = None
    is_superuser: bool

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"