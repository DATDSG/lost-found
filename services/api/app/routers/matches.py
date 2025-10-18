"""Matches routes."""
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Session
from sqlalchemy import select
from typing import List
import time

from ..database import get_db
from ..models import User, Match, Report, MatchStatus
from ..schemas import MatchCandidate, MatchComponent, ReportSummary
from ..dependencies import get_current_user
from ..matching import get_matching_pipeline
from ..config import config
from ..helpers import notify_match_confirmation, get_or_create_conversation

router = APIRouter()

# Import metrics from main (will be available after main.py loads)
try:
    from ..main import MATCH_LATENCY
except ImportError:
    MATCH_LATENCY = None


@router.get("/report/{report_id}", response_model=List[MatchCandidate])
async def get_matches_for_report(
    report_id: str,
    max_results: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all match candidates for a report using multi-signal scoring."""
    start_time = time.time()
    
    # Verify report exists and belongs to user
    result = await db.execute(
        select(Report).where(Report.id == report_id)
    )
    report = result.scalar_one_or_none()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    if report.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view matches for this report"
        )
    
    # Get matching pipeline
    pipeline = await get_matching_pipeline(db)
    
    # Find matches using multi-signal scoring
    matches = await pipeline.find_matches(report, max_results=max_results)
    
    # Track matching latency
    if MATCH_LATENCY:
        duration = time.time() - start_time
        MATCH_LATENCY.observe(duration)
    
    # Format response
    result_matches = []
    for match in matches:
        components = []
        
        # Add score components
        if match["scores"]["text"] is not None:
            components.append(MatchComponent(name="text", score=match["scores"]["text"]))
        if match["scores"]["image"] is not None:
            components.append(MatchComponent(name="image", score=match["scores"]["image"]))
        if match["scores"]["geo"] is not None:
            components.append(MatchComponent(name="geo", score=match["scores"]["geo"]))
        if match["scores"]["time"] is not None:
            components.append(MatchComponent(name="time", score=match["scores"]["time"]))
        
        result_matches.append(MatchCandidate(
            id=str(match["candidate_id"]),
            overall=match["score"],
            components=components,
            counterpart=match["candidate"],
            explanation=match.get("explanation")
        ))
    
    return result_matches


@router.post("/{match_id}/confirm")
def confirm_match(
    match_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Confirm a match (promote it)."""
    match = db.query(Match).filter(Match.id == match_id).first()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )
    
    # Verify user owns one of the reports
    if match.source_report.owner_id != current_user.id and match.target_report.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to confirm this match"
        )
    
    match.status = MatchStatus.PROMOTED
    db.commit()
    
    # Create notification for other user
    notify_match_confirmation(db, match, current_user.id)
    
    # Create conversation if it doesn't exist
    get_or_create_conversation(
        db,
        match.source_report.id,
        match.target_report.id
    )
    
    return {"message": "Match confirmed successfully", "match_id": match.id}


@router.post("/{match_id}/dismiss")
def dismiss_match(
    match_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Dismiss a match."""
    match = db.query(Match).filter(Match.id == match_id).first()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )
    
    # Verify user owns one of the reports
    if match.source_report.owner_id != current_user.id and match.target_report.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to dismiss this match"
        )
    
    match.status = MatchStatus.DISMISSED
    db.commit()
    
    return {"message": "Match dismissed successfully"}
