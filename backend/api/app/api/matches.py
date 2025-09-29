from typing import List
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from loguru import logger

from app.core.deps import get_db, get_current_user
from app.db import models
from app.schemas.matches import (
    MatchPublic, MatchWithItems, MatchUpdate, MatchExplanation, MatchRequest
)
from app.services.matching import MatchingService
from app.workers.matching_tasks import trigger_matching_job


router = APIRouter()


@router.get("/item/{item_id}", response_model=List[MatchWithItems])
def get_matches_for_item(
    item_id: int, 
    include_dismissed: bool = False,
    db: Session = Depends(get_db), 
    user: models.User = Depends(get_current_user)
):
    """Get all matches for a specific item owned by the user."""
    
    # Verify item ownership
    item = db.query(models.Item).filter(
        models.Item.id == item_id,
        models.Item.owner_id == user.id
    ).first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    # Build query based on item status
    if item.status == "lost":
        query = db.query(models.Match).filter(models.Match.lost_item_id == item_id)
    else:  # found
        query = db.query(models.Match).filter(models.Match.found_item_id == item_id)
    
    # Filter out dismissed matches unless requested
    if not include_dismissed:
        query = query.filter(models.Match.status != "dismissed")
    
    matches = query.order_by(models.Match.score_final.desc()).all()
    
    # Convert to response format with item details
    result = []
    for match in matches:
        match_dict = MatchWithItems.model_validate(match)
        
        # Populate related items
        from app.schemas.items import ItemPublic
        match_dict.lost_item = ItemPublic.model_validate(match.lost_item)
        match_dict.found_item = ItemPublic.model_validate(match.found_item)
        
        result.append(match_dict)
    
    return result


@router.get("/", response_model=List[MatchWithItems])
def get_user_matches(
    status: str = "pending",
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user)
):
    """Get all matches for items owned by the user."""
    
    # Get user's items
    user_item_ids = db.query(models.Item.id).filter(models.Item.owner_id == user.id).subquery()
    
    # Find matches involving user's items
    query = db.query(models.Match).filter(
        or_(
            models.Match.lost_item_id.in_(user_item_ids),
            models.Match.found_item_id.in_(user_item_ids)
        )
    )
    
    if status:
        query = query.filter(models.Match.status == status)
    
    matches = query.order_by(models.Match.score_final.desc()).offset(skip).limit(limit).all()
    
    # Convert to response format
    result = []
    for match in matches:
        from app.schemas.items import ItemPublic
        match_dict = MatchWithItems.model_validate(match)
        match_dict.lost_item = ItemPublic.model_validate(match.lost_item)
        match_dict.found_item = ItemPublic.model_validate(match.found_item)
        result.append(match_dict)
    
    return result


@router.post("/find", response_model=List[MatchWithItems])
def find_matches_now(
    request: MatchRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user)
):
    """Manually trigger matching for an item and return results."""
    
    # Verify item ownership
    item = db.query(models.Item).filter(
        models.Item.id == request.item_id,
        models.Item.owner_id == user.id
    ).first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    # Run matching service
    matching_service = MatchingService(db)
    matches = matching_service.find_matches(item, limit=request.limit)
    
    if not matches:
        return []
    
    # Save matches and trigger background processing
    saved_matches = matching_service.save_matches(item, matches)
    background_tasks.add_task(trigger_matching_job, item.id)
    
    # Convert to response format
    result = []
    for match in saved_matches:
        from app.schemas.items import ItemPublic
        match_dict = MatchWithItems.model_validate(match)
        match_dict.lost_item = ItemPublic.model_validate(match.lost_item)
        match_dict.found_item = ItemPublic.model_validate(match.found_item)
        result.append(match_dict)
    
    return result


@router.patch("/{match_id}", response_model=MatchPublic)
def update_match_status(
    match_id: int,
    update: MatchUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user)
):
    """Update match status (view, dismiss, etc.)."""
    
    # Get match and verify user has access
    match = db.query(models.Match).filter(models.Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    
    # Check if user owns either item in the match
    user_item_ids = [item.id for item in user.items]
    if match.lost_item_id not in user_item_ids and match.found_item_id not in user_item_ids:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Update status
    match.status = update.status
    match.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(match)
    
    logger.info(f"Updated match {match_id} status to {update.status} by user {user.id}")
    
    return MatchPublic.model_validate(match)


@router.get("/{match_id}/explanation", response_model=MatchExplanation)
def get_match_explanation(
    match_id: int,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user)
):
    """Get detailed explanation of match score."""
    
    # Get match and verify access
    match = db.query(models.Match).filter(models.Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    
    # Check if user owns either item in the match
    user_item_ids = [item.id for item in user.items]
    if match.lost_item_id not in user_item_ids and match.found_item_id not in user_item_ids:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Build explanation from score breakdown
    breakdown = match.score_breakdown or {}
    
    # Determine confidence level
    if match.score_final >= 0.8:
        confidence = "high"
    elif match.score_final >= 0.5:
        confidence = "medium"
    else:
        confidence = "low"
    
    # Generate explanation text
    explanations = []
    if breakdown.get('category', 0) > 0.8:
        explanations.append("Strong category match")
    if breakdown.get('distance', 0) > 0.8:
        explanations.append("Very close location")
    if breakdown.get('time', 0) > 0.8:
        explanations.append("Similar timeframe")
    if breakdown.get('attributes', 0) > 0.7:
        explanations.append("Matching attributes")
    
    explanation_text = f"{confidence.title()} confidence match"
    if explanations:
        explanation_text += f": {', '.join(explanations)}"
    
    return MatchExplanation(
        final_score=match.score_final,
        confidence_level=confidence,
        explanation_text=explanation_text,
        category_score=breakdown.get('category'),
        distance_score=breakdown.get('distance'),
        time_score=breakdown.get('time'),
        attribute_score=breakdown.get('attributes'),
        text_score=breakdown.get('text'),
        image_score=breakdown.get('image'),
        distance_km=match.distance_km,
        time_diff_hours=match.time_diff_hours
    )