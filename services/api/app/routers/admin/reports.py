"""Admin report moderation API routes."""

from __future__ import annotations

import json
from typing import Dict, List, Optional

from fastapi import APIRouter, Body, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ...infrastructure.database.session import get_async_db
from ...dependencies import get_current_admin
from ...helpers import create_audit_log
from ...models import User
from ...domains.reports.models.report import Report, ReportStatus

router = APIRouter()


class ModerationActionRequest(BaseModel):
    reason: Optional[str] = None


class UpdateReportStatusRequest(BaseModel):
    status: ReportStatus
    admin_notes: Optional[str] = None


class BulkReportRequest(BaseModel):
    report_ids: List[str]
    reason: Optional[str] = None


def _serialize_report_summary(report: Report, owner: Optional[User]) -> Dict:
    return {
        "id": report.id,
        "title": report.title,
        "description": report.description or "",
        "type": report.type,
        "status": report.status,
        "category": report.category,
        "condition": report.condition,
        "is_urgent": report.is_urgent,
        "reward_offered": report.reward_offered,
        "is_resolved": report.is_resolved,
        "location_city": report.location_city,
        "occurred_at": report.occurred_at.isoformat() if report.occurred_at else None,
        "occurred_time": report.occurred_time,
        "created_at": report.created_at.isoformat() if report.created_at else None,
        "owner": {
            "id": str(owner.id) if owner else None,
            "email": owner.email if owner else None,
            "display_name": owner.display_name if owner else None,
        },
    }


def _serialize_report_detail(report: Report) -> Dict:
    return {
        "id": report.id,
        "title": report.title,
        "description": report.description or "",
        "type": report.type,
        "status": report.status,
        "category": report.category,
        "colors": report.colors or [],
        "condition": report.condition,
        "safety_status": report.safety_status,
        "is_safe": report.is_safe,
        "is_urgent": report.is_urgent,
        "reward_offered": report.reward_offered,
        "reward_amount": report.reward_amount,
        "contact_info": report.contact_info,
        "additional_info": report.additional_info,
        "occurred_at": report.occurred_at.isoformat() if report.occurred_at else None,
        "occurred_time": report.occurred_time,
        "location_city": report.location_city,
        "location_address": report.location_address,
        "latitude": report.latitude,
        "longitude": report.longitude,
        "created_at": report.created_at.isoformat() if report.created_at else None,
        "updated_at": report.updated_at.isoformat() if report.updated_at else None,
        "is_resolved": report.is_resolved,
        "moderation_notes": report.moderation_notes,
        "owner_id": str(report.owner_id),
    }


async def _get_report_or_404(db: AsyncSession, report_id: str) -> Report:
    result = await db.execute(
        select(Report)
        .options(selectinload(Report.owner), selectinload(Report.media))
        .where(Report.id == report_id)
    )
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found",
        )
    return report


@router.get("")
async def list_reports(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    status_filter: Optional[ReportStatus] = None,
    report_type: Optional[str] = None,
    search: Optional[str] = None,
    db: AsyncSession = Depends(get_async_db),
):
    """List reports for moderation with filtering and pagination."""
    conditions = []
    if status_filter:
        conditions.append(Report.status == status_filter.value)
    if report_type:
        conditions.append(Report.type == report_type)
    if search:
        pattern = f"%{search}%"
        conditions.append(
            or_(
                Report.title.ilike(pattern),
                Report.description.ilike(pattern),
            )
        )

    count_query = select(func.count()).select_from(Report)
    if conditions:
        count_query = count_query.where(*conditions)
    total = (await db.execute(count_query)).scalar() or 0

    query = (
        select(Report)
        .options(selectinload(Report.owner))
        .order_by(Report.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    if conditions:
        query = query.where(*conditions)

    result = await db.execute(query)
    reports = result.scalars().all()

    items = [_serialize_report_summary(report, report.owner) for report in reports]

    return {
        "items": items,
        "total": total,
        "skip": skip,
        "limit": limit,
    }


@router.get("/stats")
async def get_report_stats(
    db: AsyncSession = Depends(get_async_db),
):
    """Aggregate report statistics by status and type."""
    pending = (
        await db.execute(
            select(func.count()).select_from(Report).where(Report.status == "pending")
        )
    ).scalar() or 0
    approved = (
        await db.execute(
            select(func.count()).select_from(Report).where(Report.status == "approved")
        )
    ).scalar() or 0
    hidden = (
        await db.execute(
            select(func.count()).select_from(Report).where(Report.status == "hidden")
        )
    ).scalar() or 0
    removed = (
        await db.execute(
            select(func.count()).select_from(Report).where(Report.status == "removed")
        )
    ).scalar() or 0

    lost = (
        await db.execute(
            select(func.count()).select_from(Report).where(Report.type == "lost")
        )
    ).scalar() or 0
    found = (
        await db.execute(
            select(func.count()).select_from(Report).where(Report.type == "found")
        )
    ).scalar() or 0

    total = pending + approved + hidden + removed

    return {
        "total": total,
        "pending": pending,
        "approved": approved,
        "hidden": hidden,
        "removed": removed,
        "lost": lost,
        "found": found,
        "by_status": {
            "pending": pending,
            "approved": approved,
            "hidden": hidden,
            "removed": removed,
        },
        "by_type": {
            "lost": lost,
            "found": found,
        },
    }


@router.get("/{report_id}")
async def get_report_detail(
    report_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Return a single report with details."""
    report = await _get_report_or_404(db, report_id)
    payload = _serialize_report_detail(report)
    if report.owner:
        payload["owner"] = {
            "id": str(report.owner.id),
            "email": report.owner.email,
            "display_name": report.owner.display_name,
        }
    if report.media:
        payload["media"] = [
            {
                "id": media.id,
                "url": media.url,
                "filename": media.filename,
                "media_type": media.media_type,
            }
            for media in report.media
        ]
    return payload


@router.post("/{report_id}/approve")
async def approve_report(
    report_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Approve a pending report."""
    report = await _get_report_or_404(db, report_id)

    old_status = report.status
    report.status = ReportStatus.APPROVED.value

    await db.commit()

    await create_audit_log(
        db=db,
        user_id=str(current_user.id),
        action="approve_report",
        resource_type="report",
        resource_id=report.id,
        details=json.dumps(
            {
                "moderator": current_user.email,
                "old_status": old_status,
                "new_status": report.status,
                "report_title": report.title,
            }
        ),
    )

    return {"message": "Report approved", "report_id": report.id}


@router.post("/{report_id}/reject")
async def reject_report(
    report_id: str,
    payload: ModerationActionRequest = Body(default_factory=ModerationActionRequest),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Reject (hide) a report that violates guidelines."""
    report = await _get_report_or_404(db, report_id)

    old_status = report.status
    report.status = ReportStatus.HIDDEN.value
    report.moderation_notes = payload.reason

    await db.commit()

    await create_audit_log(
        db=db,
        user_id=str(current_user.id),
        action="reject_report",
        resource_type="report",
        resource_id=report.id,
        details=json.dumps(
            {
                "moderator": current_user.email,
                "old_status": old_status,
                "new_status": report.status,
                "reason": payload.reason,
            }
        ),
    )

    return {"message": "Report rejected", "report_id": report.id}


@router.post("/{report_id}/remove")
async def remove_report(
    report_id: str,
    payload: ModerationActionRequest = Body(default_factory=ModerationActionRequest),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Remove a report (admin-only)."""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can remove reports",
        )

    report = await _get_report_or_404(db, report_id)
    old_status = report.status
    report.status = ReportStatus.REMOVED.value
    report.moderation_notes = payload.reason

    await db.commit()

    await create_audit_log(
        db=db,
        user_id=str(current_user.id),
        action="remove_report",
        resource_type="report",
        resource_id=report.id,
        details=json.dumps(
            {
                "admin": current_user.email,
                "old_status": old_status,
                "new_status": report.status,
                "reason": payload.reason,
            }
        ),
    )

    return {"message": "Report removed", "report_id": report.id}


@router.patch("/{report_id}/status")
async def update_report_status(
    report_id: str,
    payload: UpdateReportStatusRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Generic status update endpoint to support admin UI."""
    report = await _get_report_or_404(db, report_id)

    old_status = report.status
    report.status = payload.status.value
    if payload.admin_notes is not None:
        report.moderation_notes = payload.admin_notes

    await db.commit()
    await create_audit_log(
        db=db,
        user_id=str(current_user.id),
        action="update_report_status",
        resource_type="report",
        resource_id=report.id,
        details=json.dumps(
            {
                "moderator": current_user.email,
                "old_status": old_status,
                "new_status": report.status,
                "notes": payload.admin_notes,
            }
        ),
    )

    return {"report": _serialize_report_detail(report)}


@router.delete("/{report_id}")
async def delete_report(
    report_id: str,
    payload: ModerationActionRequest = Body(default_factory=ModerationActionRequest),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Soft delete a report by marking it removed."""
    report = await _get_report_or_404(db, report_id)
    old_status = report.status
    report.status = ReportStatus.REMOVED.value
    report.moderation_notes = payload.reason

    await db.commit()
    await create_audit_log(
        db=db,
        user_id=str(current_user.id),
        action="delete_report",
        resource_type="report",
        resource_id=report.id,
        details=json.dumps(
            {
                "moderator": current_user.email,
                "old_status": old_status,
                "new_status": report.status,
                "reason": payload.reason,
            }
        ),
    )

    return {"message": "Report removed", "report_id": report.id}


@router.post("/bulk-approve")
async def bulk_approve_reports(
    payload: BulkReportRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Approve a batch of reports."""
    return await _bulk_update_status(
        db=db,
        current_user=current_user,
        report_ids=payload.report_ids,
        new_status=ReportStatus.APPROVED,
        reason=payload.reason,
        action="bulk_approve_reports",
    )


@router.post("/bulk-reject")
async def bulk_reject_reports(
    payload: BulkReportRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Reject a batch of reports."""
    return await _bulk_update_status(
        db=db,
        current_user=current_user,
        report_ids=payload.report_ids,
        new_status=ReportStatus.HIDDEN,
        reason=payload.reason,
        action="bulk_reject_reports",
    )


@router.post("/bulk-delete")
async def bulk_delete_reports(
    payload: BulkReportRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Soft delete a batch of reports."""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can bulk delete reports",
        )

    return await _bulk_update_status(
        db=db,
        current_user=current_user,
        report_ids=payload.report_ids,
        new_status=ReportStatus.REMOVED,
        reason=payload.reason,
        action="bulk_delete_reports",
    )


async def _bulk_update_status(
    *,
    db: AsyncSession,
    current_user: User,
    report_ids: List[str],
    new_status: ReportStatus,
    reason: Optional[str],
    action: str,
) -> Dict:
    if not report_ids:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="report_ids list cannot be empty",
        )

    success = 0
    errors: List[str] = []
    for report_id in report_ids:
        try:
            report = await _get_report_or_404(db, report_id)
            old_status = report.status
            report.status = new_status.value
            if reason:
                report.moderation_notes = reason
            await db.commit()
            success += 1

            await create_audit_log(
                db=db,
                user_id=str(current_user.id),
                action=action,
                resource_type="report",
                resource_id=report.id,
                details=json.dumps(
                    {
                        "moderator": current_user.email,
                        "old_status": old_status,
                        "new_status": report.status,
                        "reason": reason,
                    }
                ),
            )
        except HTTPException:
            await db.rollback()
            errors.append(report_id)
        except Exception as exc:
            await db.rollback()
            errors.append(f"{report_id}:{exc}")

    return {
        "updated": success,
        "failed": len(errors),
        "errors": errors or None,
    }
