from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from loguru import logger

from app.core.deps import get_db, get_current_user
from app.db import models
from app.schemas.claims import ClaimCreate, ClaimUpdate, ClaimPublic, ClaimPrivate


router = APIRouter()


@router.post("/", response_model=ClaimPublic, status_code=201)
def create_claim(
    payload: ClaimCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user)
):
    """Create a new claim for a match."""
    
    # Get the match and verify it exists
    match = db.query(models.Match).filter(models.Match.id == payload.match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    
    # Determine who is the claimant and who is the owner
    # The claimant is claiming the item, so they should be the owner of the opposite item
    if match.lost_item.owner_id == user.id:
        # User owns the lost item, so they're claiming the found item
        claimant_id = user.id
        owner_id = match.found_item.owner_id
    elif match.found_item.owner_id == user.id:
        # User owns the found item, so they're claiming the lost item
        claimant_id = user.id
        owner_id = match.lost_item.owner_id
    else:
        raise HTTPException(status_code=403, detail="You can only claim matches for your own items")
    
    # Check if claim already exists
    existing_claim = db.query(models.Claim).filter(
        models.Claim.match_id == payload.match_id,
        models.Claim.claimant_id == claimant_id
    ).first()
    
    if existing_claim:
        raise HTTPException(status_code=400, detail="Claim already exists for this match")
    
    # Create the claim
    claim = models.Claim(
        match_id=payload.match_id,
        claimant_id=claimant_id,
        owner_id=owner_id,
        evidence_provided=payload.evidence_provided,
        evidence_hash=payload.evidence_hash
    )
    
    db.add(claim)
    db.commit()
    db.refresh(claim)
    
    logger.info(f"Created claim {claim.id} for match {payload.match_id} by user {user.id}")
    
    # Send notification to the owner
    try:
        from app.services.notifications import notification_service, NotificationType
        import asyncio
        
        notification_data = {
            "claim_id": claim.id,
            "match_id": payload.match_id,
            "item_type": match.lost_item.category if match.lost_item else "item",
            "claimant_name": user.name if hasattr(user, 'name') else "Someone"
        }
        
        asyncio.create_task(
            notification_service.send_notification(
                user_id=owner_id,
                notification_type=NotificationType.CLAIM_SUBMITTED,
                data=notification_data
            )
        )
        
        logger.info(f"Scheduled notification for owner {owner_id} about new claim")
        
    except Exception as e:
        logger.error(f"Failed to send claim notification: {e}")
        # Don't fail the request if notification fails
    
    return ClaimPublic.model_validate(claim)


@router.get("/", response_model=List[ClaimPublic])
def list_claims(
    status: str = None,
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user)
):
    """List claims where user is either claimant or owner."""
    
    query = db.query(models.Claim).filter(
        (models.Claim.claimant_id == user.id) | (models.Claim.owner_id == user.id)
    )
    
    if status:
        query = query.filter(models.Claim.status == status)
    
    claims = query.order_by(models.Claim.created_at.desc()).offset(skip).limit(limit).all()
    
    return [ClaimPublic.model_validate(claim) for claim in claims]


@router.get("/{claim_id}", response_model=ClaimPrivate)
def get_claim(
    claim_id: int,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user)
):
    """Get claim details (private view for involved parties)."""
    
    claim = db.query(models.Claim).filter(models.Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")
    
    # Check if user is involved in this claim
    if claim.claimant_id != user.id and claim.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    return ClaimPrivate.model_validate(claim)


@router.patch("/{claim_id}", response_model=ClaimPublic)
def update_claim(
    claim_id: int,
    payload: ClaimUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user)
):
    """Update claim status (approve/reject/dispute)."""
    
    claim = db.query(models.Claim).filter(models.Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")
    
    # Only the owner can approve/reject claims
    if claim.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Only the item owner can update claim status")
    
    # Update claim
    claim.status = payload.status
    
    if payload.status in ["approved", "rejected"]:
        claim.resolved_at = datetime.utcnow()
        
        # If approved, update the match and item statuses
        if payload.status == "approved":
            # Update match status
            match = claim.match
            match.status = "claimed"
            
            # Update item statuses
            match.lost_item.status = "claimed"
            match.found_item.status = "claimed"
    
    db.commit()
    db.refresh(claim)
    
    logger.info(f"Updated claim {claim_id} status to {payload.status} by user {user.id}")
    
    # Send notification to claimant about status change
    try:
        from app.services.notifications import notification_service, NotificationType
        import asyncio
        
        # Determine notification type based on status
        if payload.status == "approved":
            notif_type = NotificationType.CLAIM_APPROVED
        elif payload.status == "rejected":
            notif_type = NotificationType.CLAIM_REJECTED
        else:
            notif_type = NotificationType.ITEM_STATUS_CHANGED
        
        notification_data = {
            "claim_id": claim.id,
            "status": payload.status,
            "item_type": match.lost_item.category if match.lost_item else "item",
            "rejection_reason": payload.notes if payload.status == "rejected" else None
        }
        
        asyncio.create_task(
            notification_service.send_notification(
                user_id=claim.claimant_id,
                notification_type=notif_type,
                data=notification_data
            )
        )
        
        logger.info(f"Scheduled notification for claimant {claim.claimant_id} about claim status change")
        
    except Exception as e:
        logger.error(f"Failed to send claim status notification: {e}")
        # Don't fail the request if notification fails
    
    return ClaimPublic.model_validate(claim)


@router.get("/match/{match_id}", response_model=List[ClaimPublic])
def get_claims_for_match(
    match_id: int,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user)
):
    """Get all claims for a specific match."""
    
    # Verify user has access to this match
    match = db.query(models.Match).filter(models.Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    
    # Check if user owns either item in the match
    if match.lost_item.owner_id != user.id and match.found_item.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    claims = db.query(models.Claim).filter(models.Claim.match_id == match_id).all()
    
    return [ClaimPublic.model_validate(claim) for claim in claims]


@router.delete("/{claim_id}")
def delete_claim(
    claim_id: int,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user)
):
    """Delete a claim (only by claimant and only if pending)."""
    
    claim = db.query(models.Claim).filter(models.Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")
    
    # Only claimant can delete their own claim
    if claim.claimant_id != user.id:
        raise HTTPException(status_code=403, detail="Only the claimant can delete their claim")
    
    # Can only delete pending claims
    if claim.status != "pending":
        raise HTTPException(status_code=400, detail="Can only delete pending claims")
    
    db.delete(claim)
    db.commit()
    
    logger.info(f"Deleted claim {claim_id} by user {user.id}")
    
    return {"message": "Claim deleted successfully"}
