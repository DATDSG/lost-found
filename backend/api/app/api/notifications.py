from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_db
from app.db import models
from app.schemas.notifications import NotificationPublic, NotificationMarkRequest

router = APIRouter()


@router.get("/", response_model=List[NotificationPublic])
def list_notifications(
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
) -> List[NotificationPublic]:
    rows = (
        db.query(models.Notification)
        .filter(models.Notification.user_id == user.id)
        .order_by(models.Notification.created_at.desc())
        .limit(100)
        .all()
    )
    return [NotificationPublic.model_validate(row) for row in rows]


@router.get("/unread", response_model=int)
def unread_count(
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
) -> int:
    return (
        db.query(models.Notification)
        .filter(models.Notification.user_id == user.id, models.Notification.is_read.is_(False))
        .count()
    )


@router.post("/{notification_id}/mark", response_model=NotificationPublic)
def mark_notification(
    notification_id: int,
    payload: NotificationMarkRequest,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
) -> NotificationPublic:
    notification = (
        db.query(models.Notification)
        .filter(
            models.Notification.id == notification_id,
            models.Notification.user_id == user.id,
        )
        .first()
    )
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")

    notification.is_read = payload.read
    db.commit()
    db.refresh(notification)
    return NotificationPublic.model_validate(notification)


@router.post("/mark-all", response_model=int)
def mark_all(
    payload: NotificationMarkRequest,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
) -> int:
    count = (
        db.query(models.Notification)
        .filter(models.Notification.user_id == user.id, models.Notification.is_read.is_(not payload.read))
        .update({models.Notification.is_read: payload.read})
    )
    db.commit()
    return count


@router.post("/demo", response_model=NotificationPublic)
def create_demo_notification(
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
) -> NotificationPublic:
    notification = models.Notification(
        user_id=user.id,
        type="demo.match",
        payload={
            "message": "You have a new potential match",
        },
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)
    return NotificationPublic.model_validate(notification)
