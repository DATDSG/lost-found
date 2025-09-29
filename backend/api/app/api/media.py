from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.deps import get_db, get_current_user
from app.utils.s3 import ensure_bucket, presign_upload, presign_download
from app.db import models
from app.schemas.media import PresignUploadRequest, PresignUploadResponse, PresignDownloadResponse

router = APIRouter()

@router.post("/presign-upload", response_model=PresignUploadResponse)
def get_upload_url(req: PresignUploadRequest, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    ensure_bucket()
    key = f"users/{user.id}/items/{req.item_id}/{req.filename}"
    fields, conditions, url = presign_upload(key=key, content_type=req.content_type)
    # Optionally persist a placeholder MediaAsset row
    asset = models.MediaAsset(item_id=req.item_id, s3_key=key, mime_type=req.content_type)
    db.add(asset)
    db.commit()
    db.refresh(asset)
    return PresignUploadResponse(url=url, fields=fields, conditions=conditions, key=key, asset_id=asset.id)


@router.get("/presign-download", response_model=PresignDownloadResponse)
def get_download_url(key: str, user: models.User = Depends(get_current_user)):
    # (Optional) enforce ACL/ownership here
    url = presign_download(key)
    if not url:
        raise HTTPException(status_code=404, detail="Object not found")
    return PresignDownloadResponse(url=url)