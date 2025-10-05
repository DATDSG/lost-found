from typing import List

from fastapi import APIRouter, Depends, HTTPException, Request
import os
from datetime import datetime
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import func
from sqlalchemy.orm import Session, aliased

from app.core.deps import get_db, require_admin
from app.db import models
from app.schemas.items import ItemPublic
from app.schemas.flags import FlagPublic, FlaggedItemSummary
from app.schemas.admin import DashboardStats, CategoryStat, ModerationAction, ModerationResponse


router = APIRouter()
@router.get("/queue/metrics")
def queue_metrics(_: models.User = Depends(require_admin)):
    """Lightweight queue / background metrics.

    Currently surfaces Redis queue depth (if broker URL available) and timestamp.
    Extend in future with Celery inspect stats or Prometheus counters.
    """
    metrics = {"timestamp": datetime.utcnow().isoformat() + "Z"}
    redis_url = os.getenv("REDIS_URL")
    if redis_url:
        try:
            import redis  # type: ignore
            r = redis.from_url(redis_url)
            metrics["redis_ping"] = r.ping()
            # Celery default queue list length (approx) - list name 'celery'
            qlen = r.llen("celery")
            metrics["default_queue_length"] = qlen
        except Exception as e:  # pragma: no cover
            metrics["redis_error"] = str(e)
    return metrics
templates = Jinja2Templates(directory="app/templates")


def _compute_dashboard_stats(db: Session) -> DashboardStats:
    total_users = db.query(func.count(models.User.id)).scalar() or 0
    total_items = db.query(func.count(models.Item.id)).scalar() or 0
    total_matches = db.query(func.count(models.Match.id)).scalar() or 0
    total_claims = db.query(func.count(models.Claim.id)).scalar() or 0

    # Items by status
    items_lost = db.query(func.count(models.Item.id)).filter(models.Item.status == "lost").scalar() or 0
    items_found = db.query(func.count(models.Item.id)).filter(models.Item.status == "found").scalar() or 0
    items_claimed = db.query(func.count(models.Item.id)).filter(models.Item.status == "claimed").scalar() or 0
    items_closed = db.query(func.count(models.Item.id)).filter(models.Item.status == "closed").scalar() or 0

    # Matches by status
    matches_pending = db.query(func.count(models.Match.id)).filter(models.Match.status == "pending").scalar() or 0
    matches_accepted = db.query(func.count(models.Match.id)).filter(models.Match.status == "viewed").scalar() or 0
    matches_rejected = db.query(func.count(models.Match.id)).filter(models.Match.status == "dismissed").scalar() or 0

    # Claims by status
    claims_pending = db.query(func.count(models.Claim.id)).filter(models.Claim.status == "pending").scalar() or 0
    claims_approved = db.query(func.count(models.Claim.id)).filter(models.Claim.status == "approved").scalar() or 0
    claims_rejected = db.query(func.count(models.Claim.id)).filter(models.Claim.status == "rejected").scalar() or 0

    # Recent activity (last 7 days)
    from datetime import timedelta
    recent_date = datetime.utcnow() - timedelta(days=7)
    new_items = db.query(func.count(models.Item.id)).filter(models.Item.created_at >= recent_date).scalar() or 0
    new_matches = db.query(func.count(models.Match.id)).filter(models.Match.created_at >= recent_date).scalar() or 0
    new_claims = db.query(func.count(models.Claim.id)).filter(models.Claim.created_at >= recent_date).scalar() or 0

    return DashboardStats(
        totalUsers=total_users,
        totalItems=total_items,
        totalMatches=total_matches,
        totalClaims=total_claims,
        itemsByStatus={
            "lost": items_lost,
            "found": items_found,
            "claimed": items_claimed,
            "closed": items_closed,
        },
        matchesByStatus={
            "pending": matches_pending,
            "accepted": matches_accepted,
            "rejected": matches_rejected,
        },
        claimsByStatus={
            "pending": claims_pending,
            "approved": claims_approved,
            "rejected": claims_rejected,
        },
        recentActivity={
            "newItems": new_items,
            "newMatches": new_matches,
            "newClaims": new_claims,
        },
    )


def _get_flagged_items(db: Session) -> List[FlaggedItemSummary]:
    open_flags = (
        db.query(models.Flag)
        .filter(models.Flag.status == "open")
        .order_by(models.Flag.created_at.desc())
        .all()
    )
    grouped: dict[int, list[models.Flag]] = {}
    for flag in open_flags:
        grouped.setdefault(flag.item_id, []).append(flag)

    if not grouped:
        return []

    items = (
        db.query(models.Item)
        .filter(models.Item.id.in_(grouped.keys()))
        .all()
    )
    item_map = {item.id: item for item in items}

    summaries: list[FlaggedItemSummary] = []
    for item_id, flags in grouped.items():
        item = item_map.get(item_id)
        if not item:
            continue
        summaries.append(
            FlaggedItemSummary(
                item=ItemPublic.model_validate(item),
                flags=[FlagPublic.model_validate(flag) for flag in flags],
            )
        )
    return summaries


@router.get("/stats", response_model=DashboardStats)
def stats(db: Session = Depends(get_db), _: models.User = Depends(require_admin)):
    return _compute_dashboard_stats(db)


@router.get("/flagged", response_model=List[FlaggedItemSummary])
def list_flagged_items(db: Session = Depends(get_db), _: models.User = Depends(require_admin)):
    return _get_flagged_items(db)


@router.post("/items/{item_id}/action", response_model=ModerationResponse)
def moderate_item(
    item_id: int,
    payload: ModerationAction,
    db: Session = Depends(get_db),
    user: models.User = Depends(require_admin),
):
    if payload.action not in {"hide", "resolve", "feature", "dismiss"}:
        raise HTTPException(status_code=400, detail="Invalid action")

    item = db.query(models.Item).filter(models.Item.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    if payload.action in {"hide", "resolve"}:
        item.status = "resolved"
    elif payload.action == "feature":
        if item.description and "[FEATURED]" not in item.description:
            item.description += "\n[FEATURED]"
        elif not item.description:
            item.description = "[FEATURED]"

    open_flags = (
        db.query(models.Flag)
        .filter(models.Flag.item_id == item.id, models.Flag.status == "open")
        .all()
    )
    for flag in open_flags:
        flag.status = "closed"

    log = models.ModerationLog(
        item_id=item.id,
        moderator_id=user.id,
        action=payload.action,
        notes=payload.notes,
        metadata={"source": "admin_api"},
    )
    db.add(log)

    db.commit()
    db.refresh(item)

    return ModerationResponse(
        status="ok",
        item=ItemPublic.model_validate(item),
        flags_closed=len(open_flags),
    )


@router.get("/ui/dashboard", response_class=HTMLResponse)
def ui_dashboard(request: Request, db: Session = Depends(get_db), _: models.User = Depends(require_admin)):
    stats = _compute_dashboard_stats(db)
    return templates.TemplateResponse(
        "dashboard.html",
        {"request": request, "stats": stats},
    )


@router.get("/ui/flagged", response_class=HTMLResponse)
def ui_flagged(request: Request, db: Session = Depends(get_db), _: models.User = Depends(require_admin)):
    flagged = _get_flagged_items(db)
    return templates.TemplateResponse(
        "flagged.html",
        {"request": request, "flagged": flagged},
    )