from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.deps import get_db, get_current_user
from app.db import models


router = APIRouter()


@router.get("/stats")
def stats(db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    if not user.is_superuser:
        raise HTTPException(status_code=403, detail="Forbidden")
    return {
        "users": db.query(models.User).count(),
        "items": db.query(models.Item).count(),
        "messages": db.query(models.ChatMessage).count(),
    }