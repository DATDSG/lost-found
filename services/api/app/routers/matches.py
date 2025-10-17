"""Matches routes."""
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_
from typing import List
from uuid import uuid4
import time

from ..database import get_db
from ..models import User, Match, Report, MatchStatus, Notification, Conversation
from ..schemas import MatchCandidate, MatchComponent, ReportSummary
from ..dependencies import get_current_user
from ..matching import get_matching_pipeline
from ..config import config

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
            counterpart=ReportSummary.from_orm(match["candidate"]),
            explanation=match.get("explanation")
        ))
    
    return result_matches


@router.post("/{match_id}/confirm")
async def confirm_match(
    match_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Confirm a match (promote it)."""
    result = await db.execute(
        select(Match).where(Match.id == match_id)
    )
    match = result.scalar_one_or_none()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )
    
    # Verify user owns one of the reports
    if match.source_report.owner_id != current_user.id and match.candidate_report.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to confirm this match"
        )
    
    match.status = MatchStatus.PROMOTED
    await db.commit()
    
    # Create notification for the other user in the match
    other_user_id = (
        match.source_report.owner_id 
        if match.candidate_report.owner_id == current_user.id 
        else match.candidate_report.owner_id
    )
    
    notification = Notification(
        id=str(uuid4()),
        user_id=str(other_user_id),
        type="match_confirmed",
        title="Match Confirmed",
        content=f"A user confirmed a match for your report",
        reference_id=match.id
    )
    db.add(notification)
    
    # Create conversation between the two users if it doesn't exist
    participant_ids = sorted([str(match.source_report.owner_id), str(match.candidate_report.owner_id)])
    result = await db.execute(
        select(Conversation).where(
            or_(
                and_(
                    Conversation.participant_one_id == participant_ids[0],
                    Conversation.participant_two_id == participant_ids[1]
                ),
                and_(
                    Conversation.participant_one_id == participant_ids[1],
                    Conversation.participant_two_id == participant_ids[0]
                )
            )
        )
    )
    conversation = result.scalar_one_or_none()
    
    if not conversation:
        conversation = Conversation(
            id=str(uuid4()),
            participant_one_id=participant_ids[0],
            participant_two_id=participant_ids[1],
            match_id=match.id
        )
        db.add(conversation)
    
    await db.commit()
    
    return {"message": "Match confirmed successfully", "match_id": match.id}


@router.post("/{match_id}/dismiss")
async def dismiss_match(
    match_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Dismiss a match."""
    result = await db.execute(
        select(Match).where(Match.id == match_id)
    )
    match = result.scalar_one_or_none()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )
    
    # Verify user owns one of the reports
    if match.source_report.owner_id != current_user.id and match.candidate_report.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to dismiss this match"
        )
    
    match.status = MatchStatus.DISMISSED
    await db.commit()
    
    return {"message": "Match dismissed successfully"}
