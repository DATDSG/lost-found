"""Admin report moderation router."""

from fastapi import APIRouter, Depends, HTTPException, status, Query, Body
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, or_
from sqlalchemy.orm import selectinload
from typing import Optional
from pydantic import BaseModel
import json

from ...database import get_db
from ...models import User, Report, ReportStatus, Media
from ...dependencies import get_current_admin
from ...helpers import create_audit_log

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
    # TEMPORARY: Log the user for debugging
    print(f"DEBUG: Admin reports endpoint called by user: {current_user.email}, role: {current_user.role}")
    
    # Support both skip/limit and page/page_size pagination
    if page is not None and page_size is not None:
        skip = (page - 1) * page_size
        limit = page_size
    
    # Build query with eager loading of media and owner
    query = select(Report).options(
        selectinload(Report.media),
        selectinload(Report.owner)
    )
    
    # Apply filters
    if status_filter:
        query = query.where(Report.status == status_filter.value)
    
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
    
    # Convert to response format
    reports_data = []
    for report in reports:
        reports_data.append({
            "id": report.id,
            "title": report.title,
            "description": report.description or "",
            "type": report.type,
            "status": report.status,
            "category": report.category,
            "city": report.location_city or "Unknown",
            "location_address": report.location_address or "",
            "occurred_at": report.occurred_at.isoformat() if report.occurred_at else None,
            "created_at": report.created_at.isoformat(),
            "updated_at": report.updated_at.isoformat() if report.updated_at else None,
            "reward_offered": report.reward_offered or False,
            "is_resolved": report.is_resolved or False,
            "owner_id": report.owner_id,
            "owner": {
                "id": str(report.owner.id),
                "email": report.owner.email,
                "display_name": report.owner.display_name or "",
                "phone_number": report.owner.phone_number or ""
            } if report.owner else None,
            "media": [
                {
                    "id": m.id,
                    "url": m.url,
                    "filename": m.filename,
                    "media_type": m.media_type
                }
                for m in (report.media or [])
            ]
        })
    
    print(f"DEBUG: Returning {len(reports_data)} reports out of {total} total")
    
    return {
        "items": reports_data,
        "total": total,
        "skip": skip,
        "limit": limit,
        "page": (skip // limit) + 1 if limit > 0 else 1,
        "pages": (total + limit - 1) // limit if limit > 0 else 1
    }


@router.get("/stats")
async def get_report_stats(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get comprehensive report statistics."""
    
    from sqlalchemy import func, select
    
    # Status counts - use string literals to avoid enum casting issues
    pending_result = await db.execute(
        select(func.count()).select_from(Report).where(Report.status == "pending")
    )
    pending_count = pending_result.scalar() or 0
    
    approved_result = await db.execute(
        select(func.count()).select_from(Report).where(Report.status == "approved")
    )
    approved_count = approved_result.scalar() or 0
    
    hidden_result = await db.execute(
        select(func.count()).select_from(Report).where(Report.status == "hidden")
    )
    hidden_count = hidden_result.scalar() or 0
    
    removed_result = await db.execute(
        select(func.count()).select_from(Report).where(Report.status == "removed")
    )
    removed_count = removed_result.scalar() or 0
    
    total_count = pending_count + approved_count + hidden_count + removed_count
    
    # Type counts (best-effort, using string literals)
    lost_result = await db.execute(
        select(func.count()).select_from(Report).where(Report.type == "lost")
    )
    lost_count = lost_result.scalar() or 0

    found_result = await db.execute(
        select(func.count()).select_from(Report).where(Report.type == "found")
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


@router.get("/deprecated/{report_id}")
def get_report_details_deprecated(
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


@router.post("/deprecated/{report_id}/approve")
def approve_report_deprecated(
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
    # NOTE: deprecated synchronous path
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


@router.post("/deprecated/{report_id}/reject")
def reject_report_deprecated(
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
    # NOTE: deprecated synchronous path
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


@router.post("/deprecated/{report_id}/remove")
def remove_report_deprecated(
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


class UpdateStatusRequest(BaseModel):
    status: str
    reason: Optional[str] = None


@router.patch("/{report_id}/status")
async def update_report_status(
    report_id: str,
    request_data: UpdateStatusRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Update report status."""
    # Validate status
    valid_statuses = ["pending", "approved", "hidden", "removed"]
    if request_data.status not in valid_statuses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid status. Must be one of: {', '.join(valid_statuses)}"
        )
    
    # Get report
    result = await db.execute(select(Report).where(Report.id == report_id))
    report = result.scalar_one_or_none()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    old_status = report.status
    report.status = request_data.status
    
    # Create audit log
    await create_audit_log(
        db=db,
        user_id=str(current_user.id),
        action="report_status_updated",
        resource_type="report",
        resource_id=report_id,
        details=json.dumps({
            "moderator": current_user.email,
            "old_status": old_status,
            "new_status": request_data.status,
            "reason": request_data.reason,
            "report_title": report.title
        })
    )
    
    await db.commit()
    
    return {
        "message": "Report status updated successfully",
        "report_id": report_id,
        "old_status": old_status,
        "new_status": request_data.status
    }


@router.delete("/{report_id}")
async def delete_report(
    report_id: str,
    reason: str = Body(..., embed=True),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete a report (admin only)."""
    # Only admins can delete reports
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can delete reports"
        )
    
    # Get report
    result = await db.execute(select(Report).where(Report.id == report_id))
    report = result.scalar_one_or_none()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    # Create audit log before deletion
    await create_audit_log(
        db=db,
        user_id=str(current_user.id),
        action="report_deleted",
        resource_type="report",
        resource_id=report_id,
        details=json.dumps({
            "admin": current_user.email,
            "reason": reason,
            "report_title": report.title,
            "report_type": report.type,
            "report_status": report.status
        })
    )
    
    # Delete report
    await db.delete(report)
    await db.commit()
    
    return {
        "message": "Report deleted successfully",
        "report_id": report_id
    }


@router.post("/bulk/status")
async def bulk_update_report_status(
    data: dict = Body(...),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Bulk update status for multiple reports."""
    
    report_ids = data.get("ids", [])
    new_status = data.get("status")
    reason = data.get("reason", "Bulk status update")
    
    if not report_ids or not new_status:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Both 'ids' and 'status' are required"
        )
    
    # Validate status
    try:
        status_enum = ReportStatus(new_status)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid status: {new_status}"
        )
    
    updated_count = 0
    errors = []
    
    for report_id in report_ids:
        try:
            # Get report
            result = await db.execute(
                select(Report).where(Report.id == report_id)
            )
            report = result.scalar_one_or_none()
            
            if not report:
                errors.append(f"Report {report_id} not found")
                continue
            
            # Update status
            old_status = report.status
            report.status = status_enum
            
            # Create audit log
            await create_audit_log(
                db=db,
                user_id=str(current_user.id),
                action="bulk_update_status",
                resource_type="report",
                resource_id=report.id,
                details=json.dumps({
                    "old_status": old_status,
                    "new_status": new_status,
                    "reason": reason
                })
            )
            
            updated_count += 1
            
        except Exception as e:
            errors.append(f"Error updating report {report_id}: {str(e)}")
    
    await db.commit()
    
    return {
        "updated": updated_count,
        "total": len(report_ids),
        "errors": errors if errors else None
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


@router.get("/{report_id}")
async def get_report_details(
    report_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get detailed information about a specific report."""
    result = await db.execute(
        select(Report).options(
            selectinload(Report.media),
            selectinload(Report.owner)
        ).where(Report.id == report_id)
    )
    report = result.scalar_one_or_none()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    return {
        "id": report.id,
        "title": report.title,
        "description": report.description or "",
        "type": report.type,
        "status": report.status,
        "category": report.category,
        "colors": report.colors or [],
        "location_city": report.location_city or "Unknown",
        "location_address": report.location_address or "",
        "location_coordinates": report.location_coordinates or {},
        "occurred_at": report.occurred_at.isoformat() if report.occurred_at else None,
        "created_at": report.created_at.isoformat(),
        "updated_at": report.updated_at.isoformat() if report.updated_at else None,
        "reward_offered": report.reward_offered or False,
        "reward_amount": report.reward_amount or 0,
        "is_resolved": report.is_resolved or False,
        "resolution_notes": report.resolution_notes or "",
        "owner_id": report.owner_id,
        "owner": {
            "id": str(report.owner.id),
            "email": report.owner.email,
            "display_name": report.owner.display_name or "",
            "phone_number": report.owner.phone_number or "",
            "created_at": report.owner.created_at.isoformat(),
            "status": report.owner.status
        } if report.owner else None,
        "media": [
            {
                "id": m.id,
                "url": m.url,
                "filename": m.filename,
                "media_type": m.media_type,
                "file_size": m.file_size,
                "created_at": m.created_at.isoformat()
            }
            for m in (report.media or [])
        ],
        "moderation_notes": report.moderation_notes or "",
        "flags": report.flags or []
    }

@router.post("/{report_id}/reject")
async def reject_report(
    report_id: str,
    reason: str = Body(..., embed=True),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Reject a report as fake or inappropriate."""
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
    report.status = ReportStatus.REJECTED
    report.moderation_notes = reason
    
    # Create audit log
    await create_audit_log(
        db=db,
        user_id=str(current_user.id),
        action="reject",
        resource_type="report",
        resource_id=report.id,
        details=json.dumps({
            "old_status": old_status,
            "new_status": "REJECTED",
            "reason": reason
        })
    )
    
    await db.commit()
    
    return {"message": "Report rejected successfully", "reason": reason}

@router.post("/{report_id}/approve")
async def approve_report(
    report_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Approve a report."""
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
    report.status = ReportStatus.APPROVED
    
    # Create audit log
    await create_audit_log(
        db=db,
        user_id=str(current_user.id),
        action="approve",
        resource_type="report",
        resource_id=report.id,
        details=json.dumps({
            "old_status": old_status,
            "new_status": "APPROVED"
        })
    )
    
    await db.commit()
    
    return {"message": "Report approved successfully"}
