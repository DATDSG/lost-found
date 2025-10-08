"""Reports routes."""
from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, func, select
from typing import List, Optional
from uuid import uuid4
from datetime import datetime
import logging

from ..database import get_db
from ..models import User, Report, Media, ReportType, ReportStatus
from ..schemas import ReportCreate, ReportSummary, ReportDetail, PaginatedResponse
from ..dependencies import get_current_user, get_current_admin
from ..clients import get_nlp_client, get_vision_client
from ..config import config
from ..helpers import create_audit_log
import json

router = APIRouter()
logger = logging.getLogger(__name__)

# Import limiter from main
try:
    from ..main import limiter
except ImportError:
    limiter = None


@router.post("/", response_model=ReportDetail, status_code=status.HTTP_201_CREATED)
async def create_report(
    request: Request,
    report_data: ReportCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new report with automatic embedding and hash generation."""
    # Apply rate limiting if available
    if limiter and config.ENABLE_RATE_LIMIT:
        await limiter.check_limit(request, config.RATE_LIMIT_CREATE_REPORT)
    
    report = Report(
        id=str(uuid4()),
        owner_id=current_user.id,
        type=report_data.type,
        status=ReportStatus.PENDING,
        title=report_data.title,
        description=report_data.description,
        category=report_data.category,
        colors=report_data.colors,
        occurred_at=report_data.occurred_at,
        location_city=report_data.location_city or "Unknown",
        location_address=report_data.location_address
    )
    
    # Set geolocation if provided
    if report_data.latitude and report_data.longitude:
        from geoalchemy2.elements import WKTElement
        report.location_point = WKTElement(
            f'POINT({report_data.longitude} {report_data.latitude})',
            srid=4326
        )
    
    db.add(report)
    await db.flush()  # Get the ID without committing
    
    # Generate text embedding using NLP service
    if report.description and config.ENABLE_NLP_CACHE:
        try:
            async with await get_nlp_client() as nlp:
                embedding = await nlp.get_embedding(report.description)
                if embedding:
                    report.embedding = embedding
                    logger.info(f"Generated embedding for report {report.id}")
                else:
                    logger.warning(f"Failed to generate embedding for report {report.id}")
        except Exception as e:
            logger.error(f"Error generating embedding for report {report.id}: {e}")
    
    # Generate image hash using Vision service (if image URL provided)
    # Note: In real implementation, this would be called after media upload
    # For now, we'll add a placeholder for the media upload flow
    
    await db.commit()
    await db.refresh(report)
    
    return report


@router.get("/", response_model=List[ReportSummary])
def list_reports(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: Optional[str] = None,
    type: Optional[ReportType] = None,
    category: Optional[str] = None,
    status: Optional[ReportStatus] = None,
    db: Session = Depends(get_db)
):
    """List reports with filters and pagination."""
    query = db.query(Report)
    
    # Apply filters
    if status:
        query = query.filter(Report.status == status)
    else:
        query = query.filter(Report.status == ReportStatus.APPROVED)
    
    if type:
        query = query.filter(Report.type == type)
    
    if category:
        query = query.filter(Report.category == category)
    
    if search:
        search_pattern = f"%{search}%"
        query = query.filter(
            or_(
                Report.title.ilike(search_pattern),
                Report.description.ilike(search_pattern)
            )
        )
    
    # Order by most recent
    query = query.order_by(Report.created_at.desc())
    
    # Pagination
    offset = (page - 1) * page_size
    reports = query.offset(offset).limit(page_size).all()
    
    return reports


@router.get("/{report_id}", response_model=ReportDetail)
def get_report(report_id: str, db: Session = Depends(get_db)):
    """Get a specific report by ID."""
    report = db.query(Report).filter(Report.id == report_id).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    if report.status not in [ReportStatus.APPROVED, ReportStatus.PENDING]:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not available"
        )
    
    return report


@router.get("/my/reports", response_model=List[ReportSummary])
def get_my_reports(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all reports created by the current user."""
    reports = db.query(Report).filter(
        Report.owner_id == current_user.id
    ).order_by(Report.created_at.desc()).all()
    
    return reports


@router.patch("/{report_id}/status")
def update_report_status(
    report_id: str,
    new_status: ReportStatus,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Update report status (moderator only)."""
    report = db.query(Report).filter(Report.id == report_id).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    report.status = new_status
    db.commit()
    
    # Create audit log entry
    create_audit_log(
        db=db,
        user_id=current_user.id,
        action="report_status_updated",
        resource_type="report",
        resource_id=report_id,
        details=json.dumps({
            "old_status": str(report.status),
            "new_status": str(new_status),
            "moderator": current_user.email
        })
    )
    
    return {"message": "Report status updated", "new_status": new_status}
