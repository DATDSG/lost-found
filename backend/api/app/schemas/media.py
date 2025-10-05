from pydantic import BaseModel
from datetime import datetime

class MediaAssetPublic(BaseModel):
    id: int
    item_id: int
    s3_url: str
    thumbnail_url: str | None = None
    file_type: str
    file_size: int | None = None
    uploaded_at: datetime
    
    class Config:
        from_attributes = True

class PresignUploadRequest(BaseModel):
    item_id: int
    filename: str
    content_type: str

class PresignUploadResponse(BaseModel):
    url: str
    fields: dict
    conditions: list
    key: str
    asset_id: int

class PresignDownloadResponse(BaseModel):
    url: str