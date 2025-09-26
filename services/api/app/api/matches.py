from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.deps import get_db, get_current_user
from app.db import models
from app.schemas.matches import MatchPublic

router = APIRouter()

@router.get("/{item_id}", response_model=List[MatchPublic])
def get_matches(item_id: int, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    # Simple demo: return recent matches for this item (either side)
    rows = (
        db.query(models.Match)
        .filter((models.Match.lost_item_id == item_id) | (models.Match.found_item_id == item_id))
        .order_by(models.Match.id.desc())
        .limit(10)
        .all()
    )
    return [MatchPublic.model_validate(r) for r in rows]