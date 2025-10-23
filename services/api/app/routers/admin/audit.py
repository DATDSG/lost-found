"""Admin audit log router."""

from fastapi import APIRouter, Depends, Request, Query
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime
from typing import Optional
from math import ceil

from ...infrastructure.database.session import get_async_db
from app.models import User, AuditLog
from .auth import require_admin
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
    db: AsyncSession = Depends(get_async_db)
):
    """List audit logs with pagination and filters."""
    from sqlalchemy import select, func, and_
    
    # Build query conditions
    conditions = []
    if action:
        conditions.append(AuditLog.action == action)
    if actor_email:
        # Find users with matching email
        user_query = select(User.id).where(User.email.ilike(f"%{actor_email}%"))
        user_result = await db.execute(user_query)
        user_ids = [row[0] for row in user_result.fetchall()]
        if user_ids:
            conditions.append(AuditLog.user_id.in_(user_ids))
    if date_from:
        date_from_dt = datetime.fromisoformat(date_from)
        conditions.append(AuditLog.created_at >= date_from_dt)
    if date_to:
        date_to_dt = datetime.fromisoformat(date_to)
        conditions.append(AuditLog.created_at <= date_to_dt)
    
    # Get total count
    count_query = select(func.count()).select_from(AuditLog)
    if conditions:
        count_query = count_query.where(and_(*conditions))
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0
    
    # Get paginated results
    query = select(AuditLog)
    if conditions:
        query = query.where(and_(*conditions))
    query = query.order_by(AuditLog.created_at.desc()).offset(skip).limit(limit)
    
    result = await db.execute(query)
    logs = result.scalars().all()
    
    # Format response with actor details
    log_list = []
    for log in logs:
        actor = None
        if log.user_id:
            actor_query = select(User).where(User.id == log.user_id)
            actor_result = await db.execute(actor_query)
            actor = actor_result.scalar_one_or_none()
        
        log_list.append({
            "id": str(log.id),
            "action": log.action,
            "resource_type": log.resource_type,
            "resource_id": str(log.resource_id) if log.resource_id else None,
            "user_id": str(log.user_id) if log.user_id else None,
            "actor_email": actor.email if actor else "System",
            "details": log.details,
            "created_at": log.created_at.isoformat()
        })
    
    return {
        "items": log_list,
        "total": total,
        "skip": skip,
        "limit": limit
    }




@router.get("/admin/audit", response_class=HTMLResponse)
async def audit_log(
    request: Request,
    page: int = 1,
    action: Optional[str] = None,
    admin_email: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    db: AsyncSession = Depends(get_async_db),
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
