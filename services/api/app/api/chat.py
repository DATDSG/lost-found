from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.deps import get_db, get_current_user
from app.db import models
from app.schemas.chat import ChatCreate, ChatPublic


router = APIRouter()


@router.post("/messages", response_model=ChatPublic, status_code=201)
def send_message(payload: ChatCreate, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    msg = models.ChatMessage(room=payload.room, sender_id=user.id, message=payload.message)
    db.add(msg)
    db.commit()
    db.refresh(msg)
    return ChatPublic.model_validate(msg)


@router.get("/messages", response_model=List[ChatPublic])
def list_messages(room: str, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    rows = db.query(models.ChatMessage).filter(models.ChatMessage.room == room).order_by(models.ChatMessage.id.desc()).limit(50).all()
    return [ChatPublic.model_validate(r) for r in rows] 