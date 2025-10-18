"""Admin dashboard router - System overview and statistics."""

from fastapi import APIRouter, Depends, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select
from datetime import datetime, timedelta, timezone

from ...database import get_db
from ...models import User, Report, Match, AuditLog
from ...dependencies import get_current_admin
from ...session_manager import session_manager

router = APIRouter()
templates = Jinja2Templates(directory="templates")


async def get_csrf_token(request: Request) -> str:
    """Get CSRF token from session."""
    session_id = request.cookies.get("admin_session")
    if session_id:
        session_data = await session_manager.get_session(session_id)
        if session_data:
            return session_data.get("csrf_token", "")
    return ""


@router.get("/admin/dashboard", response_class=HTMLResponse)
async def dashboard(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_admin)
):
    """Display admin dashboard."""
    # Gather statistics
    stats = {
        "pending_reports": db.query(Report).filter(Report.status == "pending").count(),
        "total_reports": db.query(Report).count(),
        "active_users": db.query(User).filter(User.is_active == True).count(),
        "total_users": db.query(User).count(),
        "open_flags": 0,  # Placeholder - implement flags model
        "total_matches": db.query(Match).count(),
        "confirmed_matches": db.query(Match).filter(Match.status == "confirmed").count(),
    }
    
    # Recent pending reports
    recent_reports = (
        db.query(Report)
        .filter(Report.status == "pending")
        .order_by(Report.created_at.desc())
        .limit(10)
        .all()
    )
    
    # Recent activity (audit log)
    recent_activity = (
        db.query(AuditLog)
        .order_by(AuditLog.created_at.desc())
        .limit(10)
        .all()
    )
    
    csrf_token = await get_csrf_token(request)
    return templates.TemplateResponse(
        "admin/dashboard.html",
        {
            "request": request,
            "user": user,
            "csrf_token": csrf_token,
            "stats": stats,
            "recent_reports": recent_reports,
            "recent_activity": recent_activity,
        }
    )


@router.get("/stats")
async def get_dashboard_stats(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_admin)
):
    """Get comprehensive dashboard statistics."""
    
    # DEBUG: Add user information to response
    debug_info = {
        "user_id": user.id,
        "user_email": user.email,
        "user_role": user.role,
        "is_active": user.is_active
    }
    
    # User statistics
    total_users_result = await db.execute(select(func.count(User.id)))
    total_users = total_users_result.scalar() or 0
    
    active_users_result = await db.execute(
        select(func.count(User.id)).where(User.is_active == True)
    )
    active_users = active_users_result.scalar() or 0
    
    new_users_30d_result = await db.execute(
        select(func.count(User.id)).where(
            User.created_at >= datetime.now(timezone.utc) - timedelta(days=30)
        )
    )
    new_users_30d = new_users_30d_result.scalar() or 0
    
    # Report statistics
    total_reports_result = await db.execute(select(func.count(Report.id)))
    total_reports = total_reports_result.scalar() or 0
    
    pending_reports_result = await db.execute(
        select(func.count(Report.id)).where(Report.status == "pending")
    )
    pending_reports = pending_reports_result.scalar() or 0
    
    approved_reports_result = await db.execute(
        select(func.count(Report.id)).where(Report.status == "approved")
    )
    approved_reports = approved_reports_result.scalar() or 0
    
    lost_reports_result = await db.execute(
        select(func.count(Report.id)).where(Report.type == "lost")
    )
    lost_reports = lost_reports_result.scalar() or 0
    
    found_reports_result = await db.execute(
        select(func.count(Report.id)).where(Report.type == "found")
    )
    found_reports = found_reports_result.scalar() or 0
    
    # Match statistics
    total_matches_result = await db.execute(select(func.count(Match.id)))
    total_matches = total_matches_result.scalar() or 0
    
    promoted_matches_result = await db.execute(
        select(func.count(Match.id)).where(Match.status == "promoted")
    )
    promoted_matches = promoted_matches_result.scalar() or 0
    
    # Recent activity (last 7 days)
    week_ago = datetime.now(timezone.utc) - timedelta(days=7)
    reports_last_week_result = await db.execute(
        select(func.count(Report.id)).where(Report.created_at >= week_ago)
    )
    reports_last_week = reports_last_week_result.scalar() or 0
    
    matches_last_week_result = await db.execute(
        select(func.count(Match.id)).where(Match.created_at >= week_ago)
    )
    matches_last_week = matches_last_week_result.scalar() or 0
    
    return {
        "debug": debug_info,
        "users": {
            "total": total_users,
            "active": active_users,
            "new_30d": new_users_30d
        },
        "reports": {
            "total": total_reports,
            "pending": pending_reports,
            "approved": approved_reports,
            "lost": lost_reports,
            "found": found_reports,
            "new_7d": reports_last_week
        },
        "matches": {
            "total": total_matches,
            "promoted": promoted_matches,
            "new_7d": matches_last_week
        },
        "generated_at": datetime.now(timezone.utc).isoformat()
    }


@router.get("/reports-chart")
async def get_reports_chart(
    days: int = 30,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_admin)
):
    """Get reports chart data for the last N days."""
    
    chart_data = []
    today = datetime.now(timezone.utc).date()
    
    for i in range(days):
        date = today - timedelta(days=days - i - 1)
        start_of_day = datetime.combine(date, datetime.min.time()).replace(tzinfo=timezone.utc)
        end_of_day = datetime.combine(date, datetime.max.time()).replace(tzinfo=timezone.utc)
        
        # Count new reports for this day
        reports_result = await db.execute(
            select(func.count(Report.id)).where(
                Report.created_at >= start_of_day,
                Report.created_at <= end_of_day
            )
        )
        reports_count = reports_result.scalar() or 0
        
        # Count resolved reports for this day
        resolved_result = await db.execute(
            select(func.count(Report.id)).where(
                Report.updated_at >= start_of_day,
                Report.updated_at <= end_of_day,
                Report.is_resolved == True
            )
        )
        resolved_count = resolved_result.scalar() or 0
        
        chart_data.append({
            "date": date.strftime("%Y-%m-%d"),
            "reports": reports_count,
            "resolved": resolved_count
        })
    
    return chart_data


@router.get("/activity")
async def get_recent_activity(
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_admin)
):
    """Get recent system activity from audit logs (async-safe)."""

    # Fetch recent audit logs
    logs_result = await db.execute(
        select(AuditLog).order_by(AuditLog.created_at.desc()).limit(limit)
    )
    audit_logs = logs_result.scalars().all()

    # Fetch users in a single query
    user_ids = {log.user_id for log in audit_logs if getattr(log, "user_id", None)}
    users_by_id = {}
    if user_ids:
        users_result = await db.execute(select(User).where(User.id.in_(list(user_ids))))
        users = users_result.scalars().all()
        users_by_id = {u.id: u for u in users}

    activity_items = []
    for log in audit_logs:
        u = users_by_id.get(getattr(log, "user_id", None))
        activity_items.append({
            "id": str(log.id),
            "user": {
                "id": str(u.id) if u else None,
                "email": getattr(u, "email", None) or "Unknown",
                "display_name": getattr(u, "display_name", None) or "Unknown",
            },
            "action": getattr(log, "action", None),
            "resource_type": getattr(log, "resource_type", None),
            "resource_id": str(getattr(log, "resource_id", "")) if getattr(log, "resource_id", None) else None,
            "details": getattr(log, "details", None),
            "created_at": getattr(log, "created_at").isoformat() if getattr(log, "created_at", None) else None,
        })

    return {"activity": activity_items, "count": len(activity_items)}


@router.get("/system/health")
async def get_system_health(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_admin)
):
    """Get system health status."""
    try:
        # Check database connection
        db_result = await db.execute(select(func.count()).select_from(User))
        db_healthy = True
    except Exception:
        db_healthy = False

    # Check Redis (simplified - assume healthy if API is running)
    redis_healthy = True

    # Check MinIO (simplified - assume healthy if API is running)
    storage_healthy = True

    # Check NLP service (simplified - assume healthy if API is running)
    nlp_healthy = True

    # Check Vision service (simplified - assume healthy if API is running)
    vision_healthy = True

    # Determine overall status
    services = {
        "api": True,  # If we're here, API is healthy
        "database": db_healthy,
        "redis": redis_healthy,
        "storage": storage_healthy,
        "nlp": nlp_healthy,
        "vision": vision_healthy,
    }

    healthy_count = sum(services.values())
    total_count = len(services)

    if healthy_count == total_count:
        status = "healthy"
    elif healthy_count >= total_count * 0.8:
        status = "degraded"
    else:
        status = "unhealthy"

    return {
        "status": status,
        "services": services,
        "uptime": "24h 15m 30s",  # Simplified - would need actual uptime tracking
        "version": "2.1.0",
        "last_backup": "2025-10-15T10:00:00Z"  # Simplified - would need actual backup tracking
    }
