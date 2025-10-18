"""Admin matches router."""

from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select

from app.database import get_db
from app.models import User, Match, MatchStatus, Report
from app.dependencies import get_current_admin

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
    # Build query
    query = select(Match)
    
    # Apply filters
    if status:
        query = query.where(Match.status == status.value)
    
    # Get total count
    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0
    
    # Get paginated results
    query = query.order_by(Match.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    matches = result.scalars().all()
    
    # Format response
    match_list = [
        {
            "id": str(match.id),
            "source_report_id": str(match.source_report_id),
            "candidate_report_id": str(match.candidate_report_id),
            "score_total": match.score_total,
            "score_text": match.score_text,
            "score_image": match.score_image,
            "score_geo": match.score_geo,
            "score_time": match.score_time,
            "score_color": match.score_color,
            "status": match.status,
            "created_at": match.created_at.isoformat()
        }
        for match in matches
    ]
    
    return {
        "matches": match_list,
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.get("/stats")
async def get_match_stats(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get match statistics."""
    
    # Total matches
    total_matches = db.query(func.count(Match.id)).scalar()
    
    # Matches by status
    candidate_matches = db.query(func.count(Match.id)).filter(
        Match.status == MatchStatus.CANDIDATE
    ).scalar()
    
    promoted_matches = db.query(func.count(Match.id)).filter(
        Match.status == MatchStatus.PROMOTED
    ).scalar()
    
    suppressed_matches = db.query(func.count(Match.id)).filter(
        Match.status == MatchStatus.SUPPRESSED
    ).scalar()
    
    dismissed_matches = db.query(func.count(Match.id)).filter(
        Match.status == MatchStatus.DISMISSED
    ).scalar()
    
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
