from typing import List

from fastapi import APIRouter, Depends, HTTPException, Request
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
templates = Jinja2Templates(directory="app/templates")


def _compute_dashboard_stats(db: Session) -> DashboardStats:
    total_users = db.query(func.count(models.User.id)).scalar() or 0
    total_items = db.query(func.count(models.Item.id)).scalar() or 0
    resolved_items = (
        db.query(func.count(models.Item.id))
        .filter(models.Item.status == "resolved")
        .scalar()
        or 0
    )
    resolution_rate = (resolved_items / total_items) if total_items else 0.0

    open_flags = (
        db.query(func.count(models.Flag.id))
        .filter(models.Flag.status == "open")
        .scalar()
        or 0
    )

    average_match_score = db.query(func.avg(models.Match.score)).scalar()
    average_match_score = float(average_match_score) if average_match_score is not None else None

    lost_alias = aliased(models.Item)
    found_alias = aliased(models.Item)
    latency_rows = (
        db.query(
            models.Match.created_at,
            lost_alias.created_at,
            found_alias.created_at,
        )
        .join(lost_alias, models.Match.lost_item_id == lost_alias.id)
        .join(found_alias, models.Match.found_item_id == found_alias.id)
        .all()
    )
    latencies = []
    for match_created, lost_created, found_created in latency_rows:
        if match_created and lost_created and found_created:
            earliest = min(lost_created, found_created)
            latencies.append((match_created - earliest).total_seconds())
    average_match_latency = sum(latencies) / len(latencies) if latencies else None

    category_rows = (
        db.query(models.Item.category, func.count(models.Item.id))
        .group_by(models.Item.category)
        .all()
    )
    items_by_category = [CategoryStat(category=row[0], total=row[1]) for row in category_rows]

    return DashboardStats(
        users=total_users,
        items=total_items,
        resolved_items=resolved_items,
        resolution_rate=resolution_rate,
        open_flags=open_flags,
        average_match_score=average_match_score,
        average_match_latency_seconds=average_match_latency,
        items_by_category=items_by_category,
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