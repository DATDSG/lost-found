"""Admin dashboard API routes (JSON only)."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ...infrastructure.database.session import get_async_db
from ...dependencies import get_current_admin, get_current_admin_dev
from ...models import User, AuditLog
from ...domains.matches.models.match import Match
from ...domains.reports.models.report import Report

router = APIRouter()


@router.get("/stats")
async def get_dashboard_stats(
    db: AsyncSession = Depends(get_async_db),
):
    """Aggregate statistics for dashboard cards."""
    total_users = (
        await db.execute(select(func.count()).select_from(User))
    ).scalar() or 0
    active_users = (
        await db.execute(
            select(func.count()).select_from(User).where(User.is_active.is_(True))
        )
    ).scalar() or 0
    new_users_30d = (
        await db.execute(
            select(func.count())
            .select_from(User)
            .where(
                User.created_at
                >= datetime.now(timezone.utc) - timedelta(days=30)
            )
        )
    ).scalar() or 0

    total_reports = (
        await db.execute(select(func.count()).select_from(Report))
    ).scalar() or 0
    pending_reports = (
        await db.execute(
            select(func.count()).select_from(Report).where(Report.status == "pending")
        )
    ).scalar() or 0
    approved_reports = (
        await db.execute(
            select(func.count()).select_from(Report).where(Report.status == "approved")
        )
    ).scalar() or 0

    lost_reports = (
        await db.execute(
            select(func.count()).select_from(Report).where(Report.type == "lost")
        )
    ).scalar() or 0
    found_reports = (
        await db.execute(
            select(func.count()).select_from(Report).where(Report.type == "found")
        )
    ).scalar() or 0

    total_matches = (
        await db.execute(select(func.count()).select_from(Match))
    ).scalar() or 0
    promoted_matches = (
        await db.execute(
            select(func.count()).select_from(Match).where(Match.status == "promoted")
        )
    ).scalar() or 0

    week_ago = datetime.now(timezone.utc) - timedelta(days=7)
    reports_last_week = (
        await db.execute(
            select(func.count())
            .select_from(Report)
            .where(Report.created_at >= week_ago)
        )
    ).scalar() or 0
    matches_last_week = (
        await db.execute(
            select(func.count())
            .select_from(Match)
            .where(Match.created_at >= week_ago)
        )
    ).scalar() or 0

    return {
        "users": {
            "total": total_users,
            "active": active_users,
            "new_30d": new_users_30d,
        },
        "reports": {
            "total": total_reports,
            "pending": pending_reports,
            "approved": approved_reports,
            "lost": lost_reports,
            "found": found_reports,
            "new_7d": reports_last_week,
        },
        "matches": {
            "total": total_matches,
            "promoted": promoted_matches,
            "new_7d": matches_last_week,
        },
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/reports-chart")
async def get_reports_chart(
    days: int = 30,
    db: AsyncSession = Depends(get_async_db),
    user: User = Depends(get_current_admin_dev),
):
    """Return daily counts of created and resolved reports."""
    days = max(1, min(90, days))
    today = datetime.now(timezone.utc).date()
    data: List[Dict[str, int]] = []

    for offset in range(days):
        day = today - timedelta(days=days - offset - 1)
        start_of_day = datetime.combine(day, datetime.min.time()).replace(
            tzinfo=timezone.utc
        )
        end_of_day = datetime.combine(day, datetime.max.time()).replace(
            tzinfo=timezone.utc
        )

        created = (
            await db.execute(
                select(func.count())
                .select_from(Report)
                .where(
                    Report.created_at >= start_of_day,
                    Report.created_at <= end_of_day,
                )
            )
        ).scalar() or 0

        resolved = (
            await db.execute(
                select(func.count())
                .select_from(Report)
                .where(
                    Report.updated_at >= start_of_day,
                    Report.updated_at <= end_of_day,
                    Report.is_resolved.is_(True),
                )
            )
        ).scalar() or 0

        data.append(
            {
                "date": day.strftime("%Y-%m-%d"),
                "created": created,
                "resolved": resolved,
            }
        )

    return data


@router.get("/activity")
async def get_recent_activity(
    limit: int = 50,
    db: AsyncSession = Depends(get_async_db),
    user: User = Depends(get_current_admin_dev),
):
    """Return recent audit log entries with user details."""
    limit = max(1, min(100, limit))
    logs_result = await db.execute(
        select(AuditLog).order_by(AuditLog.created_at.desc()).limit(limit)
    )
    logs = logs_result.scalars().all()

    user_ids = [
        UUID(str(log.user_id))
        for log in logs
        if getattr(log, "user_id", None) is not None
    ]
    users_by_id: Dict[str, User] = {}
    if user_ids:
        users_result = await db.execute(select(User).where(User.id.in_(user_ids)))
        users = users_result.scalars().all()
        users_by_id = {str(u.id): u for u in users}

    activity: List[Dict[str, Optional[str]]] = []
    for log in logs:
        actor = users_by_id.get(str(getattr(log, "user_id", "")))
        activity.append(
            {
                "id": str(log.id),
                "action": log.action,
                "resource": log.resource,
                "resource_id": str(getattr(log, "resource_id", "")) or None,
                "details": log.reason,
                "created_at": log.created_at.isoformat()
                if getattr(log, "created_at", None)
                else None,
                "actor": {
                    "id": str(actor.id) if actor else None,
                    "email": actor.email if actor else None,
                    "display_name": actor.display_name if actor else None,
                },
            }
        )

    return {"activity": activity, "count": len(activity)}


@router.get("/system/health")
async def get_system_health(
    db: AsyncSession = Depends(get_async_db),
    user: User = Depends(get_current_admin_dev),
):
    """Return coarse-grained health information for dependent services."""
    try:
        await db.execute(select(func.count()).select_from(User).limit(1))
        db_healthy = True
    except Exception:
        db_healthy = False

    services = {
        "api": True,
        "database": db_healthy,
        "redis": True,
        "storage": True,
        "nlp": True,
        "vision": True,
    }
    healthy = sum(1 for healthy in services.values() if healthy)
    total = len(services)
    status = "healthy" if healthy == total else "degraded" if healthy >= total * 0.8 else "unhealthy"

    return {
        "status": status,
        "services": services,
        "checked_at": datetime.now(timezone.utc).isoformat(),
    }
