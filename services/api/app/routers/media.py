"""Media upload routes."""
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional
from uuid import uuid4
import os
import logging
from PIL import Image
import io

from ..database import get_db
from ..models import User, Media, Report
from ..schemas import MediaResponse
from ..dependencies import get_current_user
from ..config import config
from ..minio_client import get_minio_client

router = APIRouter()
logger = logging.getLogger(__name__)

# Import limiter from main
try:
    from ..main import limiter
except ImportError:
    limiter = None


@router.post("/upload", response_model=MediaResponse, status_code=status.HTTP_201_CREATED)
async def upload_media(
    file: UploadFile = File(...),
    report_id: Optional[str] = Form(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Upload media file (image)."""
    
    # Validate file type
    if not file.content_type or not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only image files are allowed"
        )
    
    # Validate file size
    file_size = 0
    content = b""
    for chunk in file.file:
        file_size += len(chunk)
        if file_size > config.MAX_UPLOAD_SIZE_MB * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File too large. Maximum size: {config.MAX_UPLOAD_SIZE_MB}MB"
            )
        content += chunk
    
    try:
        # Process image
        image = Image.open(io.BytesIO(content))
        
        # Get image dimensions
        width, height = image.size
        
        # Generate unique filename
        file_extension = file.filename.split('.')[-1] if '.' in file.filename else 'jpg'
        media_id = str(uuid4())
        filename = f"{media_id}.{file_extension}"
        
        # Create media directory if it doesn't exist
        media_dir = config.MEDIA_ROOT
        os.makedirs(media_dir, exist_ok=True)
        
        # Save file to MinIO
        minio_client = get_minio_client()
        object_name = f"uploads/{filename}"
        
        try:
            # Upload to MinIO
            url = minio_client.upload_data(
                data=content,
                object_name=object_name,
                content_type=file.content_type,
                length=len(content)
            )
            logger.info(f"File uploaded to MinIO: {url}")
        except Exception as e:
            logger.error(f"MinIO upload failed: {e}")
            # Fallback to local storage
            file_path = os.path.join(media_dir, filename)
            image.save(file_path, format='JPEG', quality=85)
            url = f"{config.MEDIA_URL}/{filename}"
        
        # Create media record
        media = Media(
            id=media_id,
            report_id=report_id,
            filename=filename,
            url=f"{config.MEDIA_URL}/{filename}",
            media_type="image",
            mime_type=file.content_type,
            size_bytes=len(content),
            width=width,
            height=height
        )
        
        db.add(media)
        await db.commit()
        await db.refresh(media)
        
        logger.info(f"Media uploaded: {filename} by user {current_user.id}")
        
        return MediaResponse.from_orm(media)
        
    except Exception as e:
        logger.error(f"Media upload error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to upload media"
        )


@router.get("/{media_id}", response_model=MediaResponse)
async def get_media(
    media_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Get media by ID."""
    result = await db.execute(
        select(Media).where(Media.id == media_id)
    )
    media = result.scalar_one_or_none()
    
    if not media:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Media not found"
        )
    
    return MediaResponse.from_orm(media)


@router.delete("/{media_id}")
async def delete_media(
    media_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete media file."""
    result = await db.execute(
        select(Media).where(Media.id == media_id)
    )
    media = result.scalar_one_or_none()
    
    if not media:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Media not found"
        )
    
    # Check if user owns the report (if media is associated with a report)
    if media.report_id:
        result = await db.execute(
            select(Report).where(Report.id == media.report_id)
        )
        report = result.scalar_one_or_none()
        if report and report.owner_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this media"
            )
    
    try:
        # Delete file from MinIO
        minio_client = get_minio_client()
        object_name = f"uploads/{media.filename}"
        
        try:
            minio_client.delete_file(object_name)
            logger.info(f"File deleted from MinIO: {object_name}")
        except Exception as e:
            logger.error(f"MinIO delete failed: {e}")
            # Fallback to local filesystem deletion
            file_path = os.path.join(config.MEDIA_ROOT, media.filename)
            if os.path.exists(file_path):
                os.remove(file_path)
        
        # Delete database record
        await db.delete(media)
        await db.commit()
        
        logger.info(f"Media deleted: {media.filename} by user {current_user.id}")
        
        return {"message": "Media deleted successfully"}
        
    except Exception as e:
        logger.error(f"Media deletion error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete media"
        )


@router.get("/", response_model=List[MediaResponse])
async def list_media(
    report_id: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """List media files."""
    query = select(Media)
    
    if report_id:
        query = query.where(Media.report_id == report_id)
    
    result = await db.execute(query)
    media_list = result.scalars().all()
    return [MediaResponse.from_orm(media) for media in media_list]