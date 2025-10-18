"""Media upload routes."""
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from uuid import uuid4
import os
import shutil
from pathlib import Path

from ..database import get_db
from ..models import User, Media
from ..schemas import MediaResponse
from ..dependencies import get_current_user
from ..worker import enqueue_vision_hash_generation, enqueue_thumbnail_generation

router = APIRouter()

MEDIA_ROOT = os.getenv("MEDIA_ROOT", "./data/media")
ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"]
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB


@router.post("/upload", response_model=MediaResponse, status_code=status.HTTP_201_CREATED)
async def upload_media(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Upload a media file."""
    # Validate MIME type
    if file.content_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file type. Allowed types: {', '.join(ALLOWED_MIME_TYPES)}"
        )
    
    # Generate unique filename
    media_id = str(uuid4())
    extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    filename = f"{media_id}.{extension}"
    
    # Create directory structure
    upload_dir = Path(MEDIA_ROOT) / "originals"
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    file_path = upload_dir / filename
    
    # Save file
    try:
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to save file: {str(e)}"
        )
    finally:
        file.file.close()
    
    # Create media record
    media = Media(
        id=media_id,
        report_id="",  # Will be set when report is created
        filename=filename,
        url=f"/media/originals/{filename}",
        media_type="image",
        mime_type=file.content_type
    )
    
    db.add(media)
    db.commit()
    db.refresh(media)
    
    # Trigger vision hash generation in background
    await enqueue_vision_hash_generation(media_id, str(file_path))
    
    # Generate thumbnail in background
    await enqueue_thumbnail_generation(media_id, str(file_path))
    
    return media


@router.get("/{media_id}", response_model=MediaResponse)
def get_media(media_id: str, db: Session = Depends(get_db)):
    """Get media metadata."""
    media = db.query(Media).filter(Media.id == media_id).first()
    
    if not media:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Media not found"
        )
    
    return media
