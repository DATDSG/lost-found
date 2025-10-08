"""Admin audit log router."""

from fastapi import APIRouter, Depends, Request, Query
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional
from math import ceil

from app.database import get_db
from app.models import User, AuditLog
from .auth import require_admin, sessions
from app.dependencies import get_current_admin

router = APIRouter()
templates = Jinja2Templates(directory="templates")


@router.get("")
async def list_audit_logs(
    skip: int = Query(0, ge=0),
    limit: int = Query(25, ge=1, le=100),
    action: Optional[str] = None,
    actor_email: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """List audit logs with pagination and filters."""
    query = db.query(AuditLog)
    
    # Apply filters
    if action:
        query = query.filter(AuditLog.action == action)
    if actor_email:
        actor_users = db.query(User.id).filter(User.email.ilike(f"%{actor_email}%")).all()
        actor_ids = [u[0] for u in actor_users]
        query = query.filter(AuditLog.actor_id.in_(actor_ids))
    if date_from:
        date_from_dt = datetime.fromisoformat(date_from)
        query = query.filter(AuditLog.created_at >= date_from_dt)
    if date_to:
        date_to_dt = datetime.fromisoformat(date_to)
        query = query.filter(AuditLog.created_at <= date_to_dt)
    
    # Get total count
    total = query.count()
    
    # Get paginated results
    logs = query.order_by(AuditLog.created_at.desc()).offset(skip).limit(limit).all()
    
    # Format response with actor details
    log_list = []
    for log in logs:
        actor = db.query(User).filter(User.id == log.actor_id).first() if log.actor_id else None
        log_list.append({
            "id": str(log.id),
            "action": log.action,
            "resource": log.resource,
            "resource_id": str(log.resource_id) if log.resource_id else None,
            "actor_id": str(log.actor_id) if log.actor_id else None,
            "actor_email": actor.email if actor else "System",
            "reason": log.reason,
            "created_at": log.created_at.isoformat()
        })
    
    return {
        "logs": log_list,
        "total": total,
        "skip": skip,
        "limit": limit
    }


def get_csrf_token(request: Request) -> str:
    """Get CSRF token from session."""
    session_id = request.cookies.get("admin_session")
    if session_id and session_id in sessions:
        return sessions[session_id].get("csrf_token", "")
    return ""


@router.get("/admin/audit", response_class=HTMLResponse)
async def audit_log(
    request: Request,
    page: int = 1,
    action: Optional[str] = None,
    admin_email: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    db: Session = Depends(get_db),
    user: User = Depends(require_admin)
):
    """Display audit log with filters."""
    page_size = 50
    query = db.query(AuditLog)
    
    # Apply filters
    if action:
        query = query.filter(AuditLog.action == action)
    if admin_email:
        admin_users = db.query(User.id).filter(User.email.ilike(f"%{admin_email}%")).all()
        admin_ids = [u[0] for u in admin_users]
        query = query.filter(AuditLog.admin_id.in_(admin_ids))
    if date_from:
        date_from_dt = datetime.fromisoformat(date_from)
        query = query.filter(AuditLog.created_at >= date_from_dt)
    if date_to:
        date_to_dt = datetime.fromisoformat(date_to)
        query = query.filter(AuditLog.created_at <= date_to_dt)
    
    total_count = query.count()
    total_pages = ceil(total_count / page_size)
    
    logs = (
        query
        .order_by(AuditLog.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )
    
    # Add admin email to each log entry
    for log in logs:
        admin = db.query(User).filter(User.id == log.admin_id).first()
        log.admin_email = admin.email if admin else "Unknown"
    
    return templates.TemplateResponse(
        "admin/audit_log.html",
        {
            "request": request,
            "user": user,
            "csrf_token": get_csrf_token(request),
            "logs": {
                "items": logs,
                "page": page,
                "total_pages": total_pages,
                "total_count": total_count,
            },
            "filters": {
                "action": action or "",
                "admin_email": admin_email or "",
                "date_from": date_from or "",
                "date_to": date_to or "",
            },
        }
    )
