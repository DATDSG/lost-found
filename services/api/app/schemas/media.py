from pydantic import BaseModel

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