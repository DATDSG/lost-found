"""
Media Domain Controller
=======================
FastAPI controller for the Media domain.
Handles HTTP requests and responses for media operations.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, Path, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import logging
import uuid
import os
from datetime import datetime

from ....infrastructure.database.session import get_async_db
from ....infrastructure.monitoring.metrics import get_metrics_collector
from ....dependencies import get_current_user
from ....models import User
from ....storage import get_minio_client, generate_object_name, validate_file_type
from ....config import config

logger = logging.getLogger(__name__)

router = APIRouter(tags=["media"])


@router.post("/upload")
async def upload_media(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db),
    metrics = Depends(get_metrics_collector)
):
    """
    Upload a media file.
    """
    try:
        # Validate file type
        if not validate_file_type(file.content_type):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid file type. Only images are allowed."
            )
        
        # Check file size
        file_content = await file.read()
        if len(file_content) > config.MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File too large. Maximum size is {config.MAX_FILE_SIZE} bytes."
            )
        
        # Generate unique filename
        file_id = str(uuid.uuid4())
        file_extension = os.path.splitext(file.filename)[1] if file.filename else '.jpg'
        object_name = generate_object_name(f"{file_id}{file_extension}")
        
        # Upload to MinIO
        minio_client = get_minio_client()
        
        # Convert bytes to BytesIO for MinIO
        import io
        data_stream = io.BytesIO(file_content)
        
        upload_result = minio_client.upload_data(
            data=data_stream,
            object_name=object_name,
            bucket_name=config.MINIO_BUCKET_NAME,
            content_type=file.content_type,
            length=len(file_content)
        )
        
        if not upload_result.get("success", False):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to upload file to storage: {upload_result.get('error', 'Unknown error')}"
            )
        
        # Generate public URL
        file_url = upload_result.get("url", f"{config.MINIO_ENDPOINT}/{config.MINIO_BUCKET_NAME}/{object_name}")
        
        logger.info(f"File uploaded successfully: {file_id}")
        
        return {
            "message": "File uploaded successfully",
            "file_id": file_id,
            "filename": file.filename,
            "size": len(file_content),
            "content_type": file.content_type,
            "url": file_url,
            "uploaded_at": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"File upload failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="File upload failed"
        )


@router.get("/{file_id}")
async def get_media(
    file_id: str = Path(..., description="File ID"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db),
    metrics = Depends(get_metrics_collector)
):
    """
    Get media file information.
    """
    # Placeholder implementation
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Media file not found"
    )


@router.delete("/{file_id}")
async def delete_media(
    file_id: str = Path(..., description="File ID"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db),
    metrics = Depends(get_metrics_collector)
):
    """
    Delete a media file.
    """
    # Placeholder implementation
    return {"message": "Media file deleted successfully", "file_id": file_id}
