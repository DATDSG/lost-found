"""Admin users router."""

from typing import Optional
from fastapi import APIRouter, Depends, Request, Form, Query
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session
from sqlalchemy import func
from math import ceil

from app.database import get_db
from app.models import User, Report, Match, AuditLog
from .auth import require_admin, verify_csrf_token, sessions
from app.dependencies import get_current_admin

router = APIRouter()
templates = Jinja2Templates(directory="templates")


@router.get("")
async def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    role: Optional[str] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """List users with pagination and filters."""
    query = db.query(User)
    
    # Apply filters
    if role:
        query = query.filter(User.role == role)
    if status:
        is_active = status == "active"
        query = query.filter(User.is_active == is_active)
    if search:
        query = query.filter(
            (User.email.ilike(f"%{search}%")) | 
            (User.display_name.ilike(f"%{search}%"))
        )
    
    # Get total count
    total = query.count()
    
    # Get paginated results
    users = query.order_by(User.created_at.desc()).offset(skip).limit(limit).all()
    
    # Format response
    user_list = [
        {
            "id": str(user.id),
            "email": user.email,
            "display_name": user.display_name,
            "role": user.role,
            "is_active": user.is_active,
            "status": user.status,
            "created_at": user.created_at.isoformat(),
            "phone_number": user.phone_number,
            "avatar_url": user.avatar_url
        }
        for user in users
    ]
    
    return {
        "users": user_list,
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


@router.get("/admin/users", response_class=HTMLResponse)
async def users_list(
    request: Request,
    page: int = 1,
    role: Optional[str] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    user: User = Depends(require_admin)
):
    """Display users list with filters."""
    page_size = 20
    query = db.query(User)
    
    # Apply filters
    if role:
        query = query.filter(User.role == role)
    if status:
        is_active = status == "active"
        query = query.filter(User.is_active == is_active)
    if search:
        query = query.filter(
            (User.email.ilike(f"%{search}%")) | 
            (User.display_name.ilike(f"%{search}%"))
        )
    
    total_count = query.count()
    total_pages = ceil(total_count / page_size)
    
    users = (
        query
        .order_by(User.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )
    
    # Add report count to each user
    for u in users:
        u.report_count = db.query(Report).filter(Report.owner_id == u.id).count()
    
    return templates.TemplateResponse(
        "admin/users_list.html",
        {
            "request": request,
            "user": user,
            "csrf_token": get_csrf_token(request),
            "users": {
                "items": users,
                "page": page,
                "total_pages": total_pages,
                "total_count": total_count,
            },
            "filters": {
                "role": role or "",
                "status": status or "",
                "search": search or "",
            },
        }
    )


@router.get("/admin/users/{user_id}", response_class=HTMLResponse)
async def user_detail(
    request: Request,
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Display user detail page."""
    target_user = db.query(User).filter(User.id == user_id).first()
    
    if not target_user:
        return RedirectResponse(url="/admin/users", status_code=303)
    
    # Get user's reports
    reports = (
        db.query(Report)
        .filter(Report.owner_id == user_id)
        .order_by(Report.created_at.desc())
        .limit(10)
        .all()
    )
    
    # Get user's activity
    activity = (
        db.query(AuditLog)
        .filter(AuditLog.user_id == user_id)
        .order_by(AuditLog.created_at.desc())
        .limit(10)
        .all()
    )
    
    return templates.TemplateResponse(
        "admin/user_detail.html",
        {
            "request": request,
            "user": current_user,
            "csrf_token": get_csrf_token(request),
            "target_user": target_user,
            "reports": reports,
            "activity": activity,
        }
    )


@router.post("/admin/users/{user_id}/toggle-status")
async def toggle_user_status(
    request: Request,
    user_id: str,
    csrf_token: str = Form(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Toggle user active status."""
    if not verify_csrf_token(request, csrf_token):
        return RedirectResponse(url=f"/admin/users/{user_id}", status_code=303)
    
    target_user = db.query(User).filter(User.id == user_id).first()
    
    if not target_user:
        return RedirectResponse(url="/admin/users", status_code=303)
    
    # Toggle status
    target_user.is_active = not target_user.is_active
    db.commit()
    
    # Log the action
    audit_log = AuditLog(
        admin_id=current_user.id,
        user_id=target_user.id,
        action="toggle_user_status",
        resource_type="user",
        resource_id=user_id,
        details={"is_active": target_user.is_active}
    )
    db.add(audit_log)
    db.commit()
    
    return RedirectResponse(url=f"/admin/users/{user_id}", status_code=303)


@router.post("/admin/users/{user_id}/update-role")
async def update_user_role(
    request: Request,
    user_id: str,
    role: str = Form(...),
    csrf_token: str = Form(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Update user role."""
    if not verify_csrf_token(request, csrf_token):
        return RedirectResponse(url=f"/admin/users/{user_id}", status_code=303)
    
    target_user = db.query(User).filter(User.id == user_id).first()
    
    if not target_user:
        return RedirectResponse(url="/admin/users", status_code=303)
    
    old_role = target_user.role
    target_user.role = role
    db.commit()
    
    # Log the action
    audit_log = AuditLog(
        admin_id=current_user.id,
        user_id=target_user.id,
        action="update_user_role",
        resource_type="user",
        resource_id=user_id,
        details={"old_role": old_role, "new_role": role}
    )
    db.add(audit_log)
    db.commit()
    
    return RedirectResponse(url=f"/admin/users/{user_id}", status_code=303)


@router.get("/stats")
async def get_user_stats(
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Get user statistics."""
    
    # Total users
    total_users = db.query(func.count(User.id)).scalar()
    
    # Active users (not suspended)
    active_users = db.query(func.count(User.id)).filter(
        User.is_active == True
    ).scalar()
    
    # Suspended users
    suspended_users = db.query(func.count(User.id)).filter(
        User.is_active == False
    ).scalar()
    
    # Users by role
    admin_users = db.query(func.count(User.id)).filter(
        User.role == "admin"
    ).scalar()
    
    regular_users = db.query(func.count(User.id)).filter(
        User.role == "user"
    ).scalar()
    
    return {
        "total": total_users,
        "active": active_users,
        "suspended": suspended_users,
        "admins": admin_users,
        "regular": regular_users,
        "by_role": {
            "admin": admin_users,
            "user": regular_users
        },
        "by_status": {
            "active": active_users,
            "suspended": suspended_users
        }
    }
