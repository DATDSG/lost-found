"""Admin matches router."""

from typing import Optional
from fastapi import APIRouter, Depends, Query, HTTPException, status, Body
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select
from sqlalchemy.orm import selectinload
from pydantic import BaseModel
import json

from ...database import get_db
from ...models import User, Match, MatchStatus, Report, AuditLog, Media
from ...dependencies import get_current_admin

router = APIRouter()

@router.get("")
async def list_matches(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    status: Optional[MatchStatus] = None,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """List matches with pagination and filters."""
    # Build query with eager loading of reports and their media
    query = select(Match).options(
        selectinload(Match.source_report).selectinload(Report.media),
        selectinload(Match.candidate_report).selectinload(Report.media)
    )
    
    # Apply status filter
    if status:
        query = query.where(Match.status == status.value)
    
    # Get total count
    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0
    
    # Apply pagination and ordering
    query = query.order_by(Match.created_at.desc()).offset(skip).limit(limit)
    
    # Execute query
    result = await db.execute(query)
    matches = result.scalars().all()
    
    # Convert to response format
    matches_data = []
    for match in matches:
        matches_data.append({
            "id": match.id,
            "source_report_id": match.source_report_id,
            "candidate_report_id": match.candidate_report_id,
            "status": match.status,
            "score_total": match.score_total,
            "score_text": match.score_text,
            "score_image": match.score_image,
            "score_geo": match.score_geo,
            "score_time": match.score_time,
            "score_color": match.score_color,
            "created_at": match.created_at.isoformat(),
            "reviewed_by": getattr(match, 'reviewed_by', None),
            "reviewed_at": match.reviewed_at.isoformat() if hasattr(match, 'reviewed_at') and match.reviewed_at else None,
            "source_report": {
                "id": match.source_report.id,
                "title": match.source_report.title,
                "type": match.source_report.type,
                "status": match.source_report.status,
                "category": match.source_report.category,
                "city": match.source_report.location_city or "Unknown",
                "created_at": match.source_report.created_at.isoformat(),
                "media": [
                    {
                        "id": m.id,
                        "url": m.url,
                        "filename": m.filename,
                        "media_type": m.media_type
                    }
                    for m in (match.source_report.media or [])
                ]
            },
            "candidate_report": {
                "id": match.candidate_report.id,
                "title": match.candidate_report.title,
                "type": match.candidate_report.type,
                "status": match.candidate_report.status,
                "category": match.candidate_report.category,
                "city": match.candidate_report.location_city or "Unknown",
                "created_at": match.candidate_report.created_at.isoformat(),
                "media": [
                    {
                        "id": m.id,
                        "url": m.url,
                        "filename": m.filename,
                        "media_type": m.media_type
                    }
                    for m in (match.candidate_report.media or [])
                ]
            }
        })
    
    return {
        "items": matches_data,
        "total": total,
        "skip": skip,
        "limit": limit
    }


class UpdateMatchStatusRequest(BaseModel):
    status: str
    reason: Optional[str] = None


@router.patch("/{match_id}/status")
async def update_match_status(
    match_id: str,
    request: dict,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Update match status."""
    # Validate status
    valid_statuses = ["candidate", "promoted", "suppressed", "dismissed", "confirmed"]
    if "status" not in request or request["status"] not in valid_statuses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid status. Must be one of: {', '.join(valid_statuses)}"
        )
    
    # Get match
    result = await db.execute(select(Match).where(Match.id == match_id))
    match = result.scalar_one_or_none()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )
    
    old_status = match.status
    match.status = request["status"]
    match.reviewed_by = current_user.id
    
    from datetime import datetime, timezone
    match.reviewed_at = datetime.now(timezone.utc)
    
    # Create audit log
    await create_audit_log(
        db=db,
        actor_id=current_user.id,
        action="update_status",
        resource="match",
        resource_id=match.id,
        changes={
            "old_status": old_status,
            "new_status": request["status"],
            "reason": request.get("reason")
        }
    )
    
    await db.commit()
    
    return {
        "message": "Match status updated successfully",
        "match_id": match_id,
        "old_status": old_status,
        "new_status": request_data.status
    }


@router.delete("/{match_id}")
async def delete_match(
    match_id: str,
    reason: str = Body(..., embed=True),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete a match (admin only)."""
    # Only admins can delete matches
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can delete matches"
        )
    
    # Get match
    result = await db.execute(select(Match).where(Match.id == match_id))
    match = result.scalar_one_or_none()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )
    
    # Create audit log before deletion
    audit_log = AuditLog(
        actor_id=current_user.id,
        action="match_deleted",
        resource="match",
        resource_id=match_id,
        reason=reason,
        metadata={
            "source_report_id": match.source_report_id,
            "candidate_report_id": match.candidate_report_id,
            "score_total": match.score_total,
            "status": match.status
        }
    )
    db.add(audit_log)
    
    # Delete match
    await db.delete(match)
    await db.commit()
    
    return {
        "message": "Match deleted successfully",
        "match_id": match_id
    }


@router.get("/stats")
async def get_match_stats(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get match statistics."""
    
    # Total matches
    total_result = await db.execute(select(func.count()).select_from(Match))
    total_matches = total_result.scalar() or 0
    
    # Matches by status - use string literals to avoid enum casting issues
    candidate_result = await db.execute(
        select(func.count()).select_from(Match).where(Match.status == "candidate")
    )
    candidate_matches = candidate_result.scalar() or 0
    
    promoted_result = await db.execute(
        select(func.count()).select_from(Match).where(Match.status == "promoted")
    )
    promoted_matches = promoted_result.scalar() or 0
    
    suppressed_result = await db.execute(
        select(func.count()).select_from(Match).where(Match.status == "suppressed")
    )
    suppressed_matches = suppressed_result.scalar() or 0
    
    dismissed_result = await db.execute(
        select(func.count()).select_from(Match).where(Match.status == "dismissed")
    )
    dismissed_matches = dismissed_result.scalar() or 0
    
    return {
        "total": total_matches,
        "candidate": candidate_matches,
        "promoted": promoted_matches,
        "suppressed": suppressed_matches,
        "dismissed": dismissed_matches,
        "by_status": {
            "candidate": candidate_matches,
            "promoted": promoted_matches,
            "suppressed": suppressed_matches,
            "dismissed": dismissed_matches
        }
    }


@router.get("/{match_id}")
async def get_match_details(
    match_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get detailed information about a specific match."""
    result = await db.execute(
        select(Match).options(
            selectinload(Match.source_report).selectinload(Report.media),
            selectinload(Match.candidate_report).selectinload(Report.media)
        ).where(Match.id == match_id)
    )
    match = result.scalar_one_or_none()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )
    
    return {
        "id": match.id,
        "source_report_id": match.source_report_id,
        "candidate_report_id": match.candidate_report_id,
        "status": match.status,
        "score_total": match.score_total,
        "score_text": match.score_text,
        "score_image": match.score_image,
        "score_geo": match.score_geo,
        "score_time": match.score_time,
        "score_color": match.score_color,
        "created_at": match.created_at.isoformat(),
        "reviewed_by": getattr(match, 'reviewed_by', None),
        "reviewed_at": match.reviewed_at.isoformat() if hasattr(match, 'reviewed_at') and match.reviewed_at else None,
        "source_report": {
            "id": match.source_report.id,
            "title": match.source_report.title,
            "description": match.source_report.description or "",
            "type": match.source_report.type,
            "status": match.source_report.status,
            "category": match.source_report.category,
            "colors": match.source_report.colors or [],
            "location_city": match.source_report.location_city or "Unknown",
            "location_address": match.source_report.location_address or "",
            "occurred_at": match.source_report.occurred_at.isoformat() if match.source_report.occurred_at else None,
            "created_at": match.source_report.created_at.isoformat(),
            "owner": {
                "id": str(match.source_report.owner_id),
                "email": getattr(match.source_report, 'owner_email', ''),
                "display_name": getattr(match.source_report, 'owner_name', '')
            },
            "media": [
                {
                    "id": m.id,
                    "url": m.url,
                    "filename": m.filename,
                    "media_type": m.media_type
                }
                for m in (match.source_report.media or [])
            ]
        },
        "candidate_report": {
            "id": match.candidate_report.id,
            "title": match.candidate_report.title,
            "description": match.candidate_report.description or "",
            "type": match.candidate_report.type,
            "status": match.candidate_report.status,
            "category": match.candidate_report.category,
            "colors": match.candidate_report.colors or [],
            "location_city": match.candidate_report.location_city or "Unknown",
            "location_address": match.candidate_report.location_address or "",
            "occurred_at": match.candidate_report.occurred_at.isoformat() if match.candidate_report.occurred_at else None,
            "created_at": match.candidate_report.created_at.isoformat(),
            "owner": {
                "id": str(match.candidate_report.owner_id),
                "email": getattr(match.candidate_report, 'owner_email', ''),
                "display_name": getattr(match.candidate_report, 'owner_name', '')
            },
            "media": [
                {
                    "id": m.id,
                    "url": m.url,
                    "filename": m.filename,
                    "media_type": m.media_type
                }
                for m in (match.candidate_report.media or [])
            ]
        }
    }

@router.post("/{match_id}/promote")
async def promote_match(
    match_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Promote a match to confirmed status."""
    result = await db.execute(
        select(Match).where(Match.id == match_id)
    )
    match = result.scalar_one_or_none()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )
    
    old_status = match.status
    match.status = "promoted"
    match.reviewed_by = current_user.id
    match.reviewed_at = func.now()
    
    # Create audit log
    from ...helpers import create_audit_log
    await create_audit_log(
        db=db,
        actor_id=current_user.id,
        action="promote",
        resource="match",
        resource_id=match.id,
        changes={
            "old_status": old_status,
            "new_status": "promoted"
        }
    )
    
    await db.commit()
    
    return {"message": "Match promoted successfully"}

@router.post("/{match_id}/suppress")
async def suppress_match(
    match_id: str,
    reason: str = Body(..., embed=True),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Suppress a match."""
    result = await db.execute(
        select(Match).where(Match.id == match_id)
    )
    match = result.scalar_one_or_none()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )
    
    old_status = match.status
    match.status = "suppressed"
    match.reviewed_by = current_user.id
    match.reviewed_at = func.now()
    
    # Create audit log
    from ...helpers import create_audit_log
    await create_audit_log(
        db=db,
        actor_id=current_user.id,
        action="suppress",
        resource="match",
        resource_id=match.id,
        changes={
            "old_status": old_status,
            "new_status": "suppressed",
            "reason": reason
        }
    )
    
    await db.commit()
    
    return {"message": "Match suppressed successfully", "reason": reason}
