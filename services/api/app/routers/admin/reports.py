"""Admin report moderation router."""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select
from typing import Optional
import json

from app.database import get_db
from app.models import User, Report, ReportStatus
from app.dependencies import get_current_admin
from app.helpers import create_audit_log

router = APIRouter()


@router.get("")
async def list_reports_for_moderation(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(10, ge=1, le=100, description="Number of records to return"),
    page: Optional[int] = Query(None, ge=1, description="Page number (alternative to skip)"),
    page_size: Optional[int] = Query(None, ge=1, le=100, description="Page size (alternative to limit)"),
    status_filter: Optional[ReportStatus] = None,
    report_type: Optional[str] = None,
    search: Optional[str] = None,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """List reports for moderation with filtering."""
    
    # Support both skip/limit and page/page_size pagination
    if page is not None and page_size is not None:
        skip = (page - 1) * page_size
        limit = page_size
    
    # Build query with filters
    query = select(Report)
    
    # Apply filters
    if status_filter:
        query = query.where(Report.status == status_filter.value)
    else:
        # Default to pending reports for moderation
        query = query.where(Report.status == "pending")
        
    if report_type:
        query = query.where(Report.type == report_type)
        
    if search:
        search_pattern = f"%{search}%"
        query = query.where(
            or_(
                Report.title.ilike(search_pattern),
                Report.description.ilike(search_pattern)
            )
        )
    
    # Get total count
    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0
    
    # Apply pagination and ordering
    query = query.order_by(Report.created_at.desc()).offset(skip).limit(limit)
    
    # Execute query
    result = await db.execute(query)
    reports = result.scalars().all()
    
    # Get all owner IDs for batch loading
    owner_ids = [report.owner_id for report in reports]
    owners_result = await db.execute(select(User).where(User.id.in_(owner_ids)))
    owners = {owner.id: owner for owner in owners_result.scalars().all()}
    
    # Format response
    report_list = []
    for report in reports:
        owner = owners.get(report.owner_id)
        report_list.append({
            "id": report.id,
            "title": report.title,
            "description": report.description[:200] + "..." if report.description and len(report.description) > 200 else report.description or "",
            "type": report.type,
            "status": report.status,
            "category": report.category,
            "owner": {
                "id": str(owner.id) if owner else None,
                "email": owner.email if owner else "Unknown",
                "display_name": owner.display_name if owner else "Unknown"
            },
            "created_at": report.created_at.isoformat() if report.created_at else None,
            "location_city": report.location_city
        })
    
    return {
        "reports": report_list,
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.get("/stats")
async def get_report_stats(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get comprehensive report statistics."""
    
    # Status counts using async queries
    pending_result = await db.execute(
        select(func.count(Report.id)).where(Report.status == "pending")
    )
    pending_count = pending_result.scalar() or 0
    
    approved_result = await db.execute(
        select(func.count(Report.id)).where(Report.status == "approved")
    )
    approved_count = approved_result.scalar() or 0
    
    hidden_result = await db.execute(
        select(func.count(Report.id)).where(Report.status == "hidden")
    )
    hidden_count = hidden_result.scalar() or 0
    
    removed_result = await db.execute(
        select(func.count(Report.id)).where(Report.status == "removed")
    )
    removed_count = removed_result.scalar() or 0
    
    total_count = pending_count + approved_count + hidden_count + removed_count
    
    # Type counts
    lost_result = await db.execute(
        select(func.count(Report.id)).where(Report.type == "lost")
    )
    lost_count = lost_result.scalar() or 0
    
    found_result = await db.execute(
        select(func.count(Report.id)).where(Report.type == "found")
    )
    found_count = found_result.scalar() or 0
    
    return {
        "total": total_count,
        "pending": pending_count,
        "approved": approved_count,
        "hidden": hidden_count,
        "removed": removed_count,
        "lost": lost_count,
        "found": found_count,
        "by_status": {
            "pending": pending_count,
            "approved": approved_count,
            "hidden": hidden_count,
            "removed": removed_count
        },
        "by_type": {
            "lost": lost_count,
            "found": found_count
        }
    }


@router.get("/{report_id}")
def get_report_details(
    report_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get detailed information about a report for moderation."""
    
    report = db.query(Report).filter(Report.id == report_id).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    owner = db.query(User).filter(User.id == report.owner_id).first()
    
    return {
        "id": report.id,
        "title": report.title,
        "description": report.description,
        "type": report.type,
        "status": report.status,
        "category": report.category,
        "colors": report.colors,
        "owner": {
            "id": owner.id if owner else None,
            "email": owner.email if owner else "Unknown",
            "display_name": owner.display_name if owner else "Unknown",
            "role": owner.role if owner else None
        },
        "location": {
            "city": report.location_city,
            "address": report.location_address
        },
        "occurred_at": report.occurred_at.isoformat() if report.occurred_at else None,
        "created_at": report.created_at.isoformat() if report.created_at else None,
        "updated_at": report.updated_at.isoformat() if report.updated_at else None,
        "has_embedding": report.embedding is not None,
        "has_image_hash": report.image_hash is not None
    }


@router.post("/{report_id}/approve")
def approve_report(
    report_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Approve a pending report."""
    
    report = db.query(Report).filter(Report.id == report_id).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    old_status = report.status
    report.status = ReportStatus.APPROVED
    db.commit()
    
    # Create audit log
    create_audit_log(
        db=db,
        user_id=current_user.id,
        action="report_approved",
        resource_type="report",
        resource_id=report_id,
        details=json.dumps({
            "moderator": current_user.email,
            "old_status": str(old_status),
            "new_status": "approved",
            "report_title": report.title
        })
    )
    
    return {
        "message": "Report approved successfully",
        "report_id": report_id,
        "new_status": "approved"
    }


@router.post("/{report_id}/reject")
def reject_report(
    report_id: str,
    reason: Optional[str] = None,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Reject a pending report (hide it)."""
    
    report = db.query(Report).filter(Report.id == report_id).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    old_status = report.status
    report.status = ReportStatus.HIDDEN
    db.commit()
    
    # Create audit log
    create_audit_log(
        db=db,
        user_id=current_user.id,
        action="report_rejected",
        resource_type="report",
        resource_id=report_id,
        details=json.dumps({
            "moderator": current_user.email,
            "old_status": str(old_status),
            "new_status": "hidden",
            "reason": reason,
            "report_title": report.title
        })
    )
    
    return {
        "message": "Report rejected successfully",
        "report_id": report_id,
        "new_status": "hidden"
    }


@router.post("/{report_id}/remove")
def remove_report(
    report_id: str,
    reason: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Remove a report (for policy violations)."""
    
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can remove reports"
        )
    
    report = db.query(Report).filter(Report.id == report_id).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    old_status = report.status
    report.status = ReportStatus.REMOVED
    db.commit()
    
    # Create audit log
    create_audit_log(
        db=db,
        user_id=current_user.id,
        action="report_removed",
        resource_type="report",
        resource_id=report_id,
        details=json.dumps({
            "admin": current_user.email,
            "old_status": str(old_status),
            "new_status": "removed",
            "reason": reason,
            "report_title": report.title
        })
    )
    
    return {
        "message": "Report removed successfully",
        "report_id": report_id,
        "new_status": "removed"
    }


@router.get("/stats/moderation")
def get_moderation_stats(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get moderation queue statistics."""
    
    from sqlalchemy import func
    
    pending_count = db.query(func.count(Report.id)).filter(
        Report.status == ReportStatus.PENDING
    ).scalar()
    
    approved_count = db.query(func.count(Report.id)).filter(
        Report.status == ReportStatus.APPROVED
    ).scalar()
    
    hidden_count = db.query(func.count(Report.id)).filter(
        Report.status == ReportStatus.HIDDEN
    ).scalar()
    
    removed_count = db.query(func.count(Report.id)).filter(
        Report.status == ReportStatus.REMOVED
    ).scalar()
    
    return {
        "pending": pending_count,
        "approved": approved_count,
        "hidden": hidden_count,
        "removed": removed_count,
        "total": pending_count + approved_count + hidden_count + removed_count
    }
