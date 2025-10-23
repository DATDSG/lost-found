"""
Legacy Schemas for Backward Compatibility
========================================
These are temporary schemas to maintain backward compatibility
while the full domain migration is completed.
"""

from pydantic import BaseModel, EmailStr, validator
from typing import Optional, List, Dict, Any
from datetime import datetime


class UserRegister(BaseModel):
    email: EmailStr
    password: str
    display_name: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    refresh_token: str = ""
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: str
    email: str
    display_name: Optional[str] = None
    role: str
    status: str
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True
    
    @validator('id', pre=True)
    def convert_uuid_to_str(cls, v):
        return str(v) if v is not None else v




class BulkOperationRequest(BaseModel):
    operation: str
    resource_ids: List[str]
    parameters: Optional[Dict[str, Any]] = None


class BulkOperationResult(BaseModel):
    success_count: int
    failed_count: int
    errors: List[str] = []


class BulkOperationError(BaseModel):
    resource_id: str
    error: str
