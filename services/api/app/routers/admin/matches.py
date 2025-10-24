"""Admin matches API routes."""

from __future__ import annotations

import json
from statistics import mean
from typing import Dict, List, Optional

from fastapi import APIRouter, Body, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ...infrastructure.database.session import get_async_db
from ...dependencies import get_current_admin
from ...helpers import create_audit_log_async
from ...models import User
from ...domains.matches.models.match import Match, MatchStatus
from ...domains.reports.models.report import Report

router = APIRouter()


class BulkMatchRequest(BaseModel):
    ids: List[str]
    reason: Optional[str] = None


class MatchStatusRequest(BaseModel):
    status: MatchStatus
    reason: Optional[str] = None


async def _get_match_or_404(db: AsyncSession, match_id: str) -> Match:
    result = await db.execute(
        select(Match)
        .options(
            selectinload(Match.source_report),
            selectinload(Match.candidate_report),
        )
        .where(Match.id == match_id)
    )
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found",
        )
    return match


def _summarize_report(report: Optional[Report]) -> Optional[Dict]:
    if not report:
        return None
    return {
        "id": report.id,
        "title": report.title,
        "description": report.description or "",
        "category": report.category,
        "status": report.status,
        "type": report.type,
        "location_city": report.location_city or "Unknown",
    }


@router.get("/stats")
async def get_match_stats(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Aggregate match statistics for dashboard cards."""
    total = (await db.execute(select(func.count()).select_from(Match))).scalar() or 0
    candidate = (
        await db.execute(
            select(func.count()).select_from(Match).where(Match.status == "candidate")
        )
    ).scalar() or 0
    promoted = (
        await db.execute(
            select(func.count()).select_from(Match).where(Match.status == "promoted")
        )
    ).scalar() or 0
    suppressed = (
        await db.execute(
            select(func.count()).select_from(Match).where(Match.status == "suppressed")
        )
    ).scalar() or 0
    dismissed = (
        await db.execute(
            select(func.count()).select_from(Match).where(Match.status == "dismissed")
        )
    ).scalar() or 0

    scores_result = await db.execute(select(Match.score_total))
    scores = [row[0] for row in scores_result if row[0] is not None]
    avg_score = round(mean(scores), 4) if scores else 0.0

    return {
        "total": total,
        "candidate": candidate,
        "promoted": promoted,
        "suppressed": suppressed,
        "dismissed": dismissed,
        "avg_score": avg_score,
        "by_status": {
            "candidate": candidate,
            "promoted": promoted,
            "suppressed": suppressed,
            "dismissed": dismissed,
        },
    }


@router.get("")
async def list_matches(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    status_filter: Optional[MatchStatus] = Query(None, alias="status"),
    min_score: Optional[float] = None,
    max_score: Optional[float] = None,
    db: AsyncSession = Depends(get_async_db),
):
    """Return paginated matches with optional filtering."""
    conditions = []
    if status_filter:
        conditions.append(Match.status == status_filter.value)
    if min_score is not None:
        conditions.append(Match.score_total >= min_score)
    if max_score is not None:
        conditions.append(Match.score_total <= max_score)

    count_query = select(func.count()).select_from(Match)
    if conditions:
        count_query = count_query.where(*conditions)
    total = (await db.execute(count_query)).scalar() or 0

    query = (
        select(Match)
        .options(
            selectinload(Match.source_report),
            selectinload(Match.candidate_report),
        )
        .order_by(Match.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    if conditions:
        query = query.where(*conditions)

    result = await db.execute(query)
    matches = result.scalars().all()

    items = [
        {
            "id": match.id,
            "source_report_id": match.source_report_id,
            "candidate_report_id": match.candidate_report_id,
            "overall_score": match.score_total,
            "text_score": match.score_text,
            "image_score": match.score_image,
            "geo_score": match.score_geo,
            "time_score": match.score_time,
            "color_score": match.score_color,
            "status": match.status,
            "created_at": match.created_at.isoformat()
            if match.created_at
            else None,
            "source_report": _summarize_report(match.source_report),
            "candidate_report": _summarize_report(match.candidate_report),
        }
        for match in matches
    ]

    return {"items": items, "total": total, "skip": skip, "limit": limit}


@router.get("/{match_id}")
async def get_match_detail(
    match_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Return detailed information for a match."""
    match = await _get_match_or_404(db, match_id)
    return {
        "id": match.id,
        "source_report_id": match.source_report_id,
        "candidate_report_id": match.candidate_report_id,
        "overall_score": match.score_total,
        "text_score": match.score_text,
        "image_score": match.score_image,
        "geo_score": match.score_geo,
        "time_score": match.score_time,
        "color_score": match.score_color,
        "status": match.status,
        "created_at": match.created_at.isoformat()
        if match.created_at
        else None,
        "source_report": _summarize_report(match.source_report),
        "candidate_report": _summarize_report(match.candidate_report),
    }


@router.patch("/{match_id}/status")
async def update_match_status(
    match_id: str,
    payload: MatchStatusRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Update the moderation status for a match."""
    match = await _get_match_or_404(db, match_id)
    old_status = match.status
    match.status = payload.status.value

    await db.commit()
    await create_audit_log_async(
        db=db,
        user_id=str(current_user.id),
        action="update_match_status",
        resource_type="match",
        resource_id=match.id,
        details=json.dumps(
            {
                "moderator": current_user.email,
                "old_status": old_status,
                "new_status": match.status,
                "reason": payload.reason,
            }
        ),
    )

    return {"match": await get_match_detail(match_id, current_user, db)}


@router.post("/bulk/approve")
async def bulk_approve_matches(
    payload: BulkMatchRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Promote multiple matches at once."""
    return await _bulk_update_matches(
        db=db,
        current_user=current_user,
        ids=payload.ids,
        new_status=MatchStatus.PROMOTED,
        reason=payload.reason,
        action="bulk_approve_matches",
    )


@router.post("/bulk/reject")
async def bulk_reject_matches(
    payload: BulkMatchRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Suppress multiple matches at once."""
    return await _bulk_update_matches(
        db=db,
        current_user=current_user,
        ids=payload.ids,
        new_status=MatchStatus.SUPPRESSED,
        reason=payload.reason,
        action="bulk_reject_matches",
    )




@router.post("/trigger/{report_id}")
async def trigger_matching(
    report_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Trigger match generation for a specific report (not yet implemented)."""
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Manual matching trigger is not implemented yet.",
    )


async def _bulk_update_matches(
    *,
    db: AsyncSession,
    current_user: User,
    ids: List[str],
    new_status: MatchStatus,
    reason: Optional[str],
    action: str,
) -> Dict:
    if not ids:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ids list cannot be empty",
        )

    success = 0
    errors: List[str] = []
    for match_id in ids:
        try:
            match = await _get_match_or_404(db, match_id)
            old_status = match.status
            match.status = new_status.value
            await db.commit()
            success += 1

            await create_audit_log_async(
                db=db,
                user_id=str(current_user.id),
                action=action,
                resource_type="match",
                resource_id=match.id,
                details=json.dumps(
                    {
                        "moderator": current_user.email,
                        "old_status": old_status,
                        "new_status": match.status,
                        "reason": reason,
                    }
                ),
            )
        except HTTPException:
            await db.rollback()
            errors.append(match_id)
        except Exception as exc:
            await db.rollback()
            errors.append(f"{match_id}:{exc}")

    return {"updated": success, "failed": len(errors), "errors": errors or None}
