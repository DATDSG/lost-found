"""Reports routes."""
from fastapi import APIRouter, Depends, HTTPException, status, Query, Request, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import or_, and_, func, select
from typing import List, Optional
from uuid import uuid4
from datetime import datetime
import logging
import json

from ..database import get_db
from ..models import User, Report, Media, ReportType, ReportStatus
from ..schemas import ReportCreate, ReportSummary, ReportDetail
from ..dependencies import get_current_user, get_current_admin
from ..clients import get_nlp_client, get_vision_client
from ..config import config
from ..helpers import create_audit_log

router = APIRouter()
logger = logging.getLogger(__name__)

# Import limiter from main
try:
    from ..main import limiter
except ImportError:
    limiter = None


@router.post("/", response_model=ReportDetail, status_code=status.HTTP_201_CREATED)
async def create_report(
    report_data: ReportCreate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new report with automatic embedding and hash generation."""
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
        # Store as TEXT for now (PostGIS not required)
        report.geo = f'POINT({report_data.longitude} {report_data.latitude})'
    
    db.add(report)
    await db.flush()  # Get the ID without committing
    
    await db.commit()
    await db.refresh(report)
    
    # Trigger background processing for embedding and matching
    from ..background import process_report_background_task
    background_tasks.add_task(process_report_background_task, report.id)
    
    logger.info(f"Created report {report.id} by user {current_user.id}, background processing queued")
    
    return ReportDetail.from_orm(report)


@router.get("/me", response_model=List[ReportSummary])
async def get_my_reports(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get current user's reports."""
    result = await db.execute(
        select(Report)
        .where(Report.owner_id == current_user.id)
        .order_by(Report.created_at.desc())
    )
    reports = result.scalars().all()
    return [ReportSummary.from_orm(report) for report in reports]


@router.get("/", response_model=List[ReportSummary])
async def list_reports(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: Optional[str] = None,
    type: Optional[ReportType] = None,
    category: Optional[str] = None,
    status: Optional[ReportStatus] = None,
    db: AsyncSession = Depends(get_db)
):
    """List reports with filters and pagination."""
    query = select(Report)
    
    # Apply filters
    if status:
        query = query.where(Report.status == status)
    else:
        query = query.where(Report.status == ReportStatus.APPROVED)
    
    if type:
        query = query.where(Report.type == type)
    
    if category:
        query = query.where(Report.category == category)
    
    if search:
        search_pattern = f"%{search}%"
        query = query.where(
            or_(
                Report.title.ilike(search_pattern),
                Report.description.ilike(search_pattern)
            )
        )
    
    # Order by most recent
    query = query.order_by(Report.created_at.desc())
    
    # Pagination
    offset = (page - 1) * page_size
    query = query.offset(offset).limit(page_size)
    
    result = await db.execute(query)
    reports = result.scalars().all()
    
    return [ReportSummary.from_orm(report) for report in reports]


@router.get("/{report_id}", response_model=ReportDetail)
async def get_report(report_id: str, db: AsyncSession = Depends(get_db)):
    """Get a specific report by ID."""
    result = await db.execute(
        select(Report).where(Report.id == report_id)
    )
    report = result.scalar_one_or_none()
    
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
    
    return ReportDetail.from_orm(report)


@router.get("/my/reports", response_model=List[ReportSummary])
async def get_my_reports_alt(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all reports created by the current user (alternative endpoint)."""
    result = await db.execute(
        select(Report)
        .where(Report.owner_id == current_user.id)
        .order_by(Report.created_at.desc())
    )
    reports = result.scalars().all()
    
    return [ReportSummary.from_orm(report) for report in reports]


@router.patch("/{report_id}/status")
async def update_report_status(
    report_id: str,
    new_status: ReportStatus,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Update report status (moderator only)."""
    result = await db.execute(
        select(Report).where(Report.id == report_id)
    )
    report = result.scalar_one_or_none()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    old_status = report.status
    report.status = new_status
    await db.commit()
    
    # Create audit log entry
    await create_audit_log(
        db=db,
        user_id=str(current_user.id),
        action="report_status_updated",
        resource_type="report",
        resource_id=report_id,
        details=json.dumps({
            "old_status": str(old_status),
            "new_status": str(new_status),
            "moderator": current_user.email
        })
    )
    
    return {"message": "Report status updated", "new_status": new_status}
