"""Admin users router."""

from typing import Optional
from fastapi import APIRouter, Depends, Request, Form, Query, HTTPException, status, Body
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select
from math import ceil
from pydantic import BaseModel, EmailStr

from ...database import get_db
from ...models import User, Report, Match, AuditLog
from .auth import require_admin, verify_csrf_token, sessions
from ...dependencies import get_current_admin

router = APIRouter()
templates = Jinja2Templates(directory="templates")


class CreateUserRequest(BaseModel):
    email: EmailStr
    password: str
    display_name: Optional[str] = None
    role: str = "user"
    is_active: bool = True


@router.get("")
async def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    role: Optional[str] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """List users with pagination and filters."""
    query = select(User)
    
    # Apply filters
    if role:
        query = query.where(User.role == role)
    if status:
        is_active = status == "active"
        query = query.where(User.is_active == is_active)
    if search:
        query = query.where(
            (User.email.ilike(f"%{search}%")) | 
            (User.display_name.ilike(f"%{search}%"))
        )
    
    # Get total count
    count_query = select(func.count(User.id))
    if role:
        count_query = count_query.where(User.role == role)
    if status:
        is_active = status == "active"
        count_query = count_query.where(User.is_active == is_active)
    if search:
        count_query = count_query.where(
            (User.email.ilike(f"%{search}%")) | 
            (User.display_name.ilike(f"%{search}%"))
        )
    
    total_result = await db.execute(count_query)
    total = total_result.scalar()
    
    # Get paginated results
    users_result = await db.execute(
        query.order_by(User.created_at.desc()).offset(skip).limit(limit)
    )
    users = users_result.scalars().all()
    
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
        "items": user_list,
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.post("")
async def create_user(
    request_data: CreateUserRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Create a new user."""
    from ...auth import get_password_hash
    import uuid as uuid_pkg
    
    # Check if user already exists
    existing_user_result = await db.execute(
        select(User).where(User.email == request_data.email)
    )
    existing_user = existing_user_result.scalar_one_or_none()
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists"
        )
    
    # Create new user
    new_user = User(
        id=uuid_pkg.uuid4(),
        email=request_data.email,
        password=get_password_hash(request_data.password),
        display_name=request_data.display_name,
        role=request_data.role,
        is_active=request_data.is_active,
        status="active" if request_data.is_active else "inactive"
    )
    
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    
    return {
        "id": str(new_user.id),
        "email": new_user.email,
        "display_name": new_user.display_name,
        "role": new_user.role,
        "is_active": new_user.is_active,
        "status": new_user.status,
        "created_at": new_user.created_at.isoformat(),
        "updated_at": new_user.updated_at.isoformat() if new_user.updated_at else None
    }


async def get_csrf_token(request: Request) -> str:
    """Get CSRF token from session."""
    session_id = request.cookies.get("admin_session")
    if session_id:
        from ..session_manager import session_manager
        session_data = await session_manager.get_session(session_id)
        if session_data:
            return session_data.get("csrf_token", "")
    return ""


@router.get("/admin/users", response_class=HTMLResponse)
async def users_list(
    request: Request,
    page: int = 1,
    role: Optional[str] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_admin)
):
    """Display users list with filters."""
    page_size = 20
    query = select(User)
    
    # Apply filters
    if role:
        query = query.where(User.role == role)
    if status:
        is_active = status == "active"
        query = query.where(User.is_active == is_active)
    if search:
        query = query.where(
            (User.email.ilike(f"%{search}%")) | 
            (User.display_name.ilike(f"%{search}%"))
        )
    
    # Get total count
    count_query = select(func.count(User.id))
    if role:
        count_query = count_query.where(User.role == role)
    if status:
        is_active = status == "active"
        count_query = count_query.where(User.is_active == is_active)
    if search:
        count_query = count_query.where(
            (User.email.ilike(f"%{search}%")) | 
            (User.display_name.ilike(f"%{search}%"))
        )
    
    total_count_result = await db.execute(count_query)
    total_count = total_count_result.scalar()
    total_pages = ceil(total_count / page_size)
    
    # Get paginated users
    users_result = await db.execute(
        query
        .order_by(User.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    users = users_result.scalars().all()
    
    # Add report count to each user
    for u in users:
        report_count_query = select(func.count(Report.id)).where(Report.owner_id == u.id)
        report_count_result = await db.execute(report_count_query)
        u.report_count = report_count_result.scalar()
    
    return templates.TemplateResponse(
        "admin/users_list.html",
        {
            "request": request,
            "user": user,
            "csrf_token": await get_csrf_token(request),
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
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Display user detail page."""
    result = await db.execute(select(User).where(User.id == user_id))
    target_user = result.scalar_one_or_none()
    
    if not target_user:
        return RedirectResponse(url="/admin/users", status_code=303)
    
    # Get user's reports
    reports_result = await db.execute(
        select(Report)
        .where(Report.owner_id == user_id)
        .order_by(Report.created_at.desc())
        .limit(10)
    )
    reports = reports_result.scalars().all()
    
    # Get user's activity
    activity_result = await db.execute(
        select(AuditLog)
        .where(AuditLog.user_id == user_id)
        .order_by(AuditLog.created_at.desc())
        .limit(10)
    )
    activity = activity_result.scalars().all()
    
    return templates.TemplateResponse(
        "admin/user_detail.html",
        {
            "request": request,
            "user": current_user,
            "csrf_token": await get_csrf_token(request),
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
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Toggle user active status."""
    if not await verify_csrf_token(request, csrf_token):
        return RedirectResponse(url=f"/admin/users/{user_id}", status_code=303)
    
    result = await db.execute(select(User).where(User.id == user_id))
    target_user = result.scalar_one_or_none()
    
    if not target_user:
        return RedirectResponse(url="/admin/users", status_code=303)
    
    # Toggle status
    target_user.is_active = not target_user.is_active
    await db.commit()
    
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
    await db.commit()
    
    return RedirectResponse(url=f"/admin/users/{user_id}", status_code=303)


@router.post("/admin/users/{user_id}/update-role")
async def update_user_role(
    request: Request,
    user_id: str,
    role: str = Form(...),
    csrf_token: str = Form(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Update user role."""
    if not await verify_csrf_token(request, csrf_token):
        return RedirectResponse(url=f"/admin/users/{user_id}", status_code=303)
    
    result = await db.execute(select(User).where(User.id == user_id))
    target_user = result.scalar_one_or_none()
    
    if not target_user:
        return RedirectResponse(url="/admin/users", status_code=303)
    
    old_role = target_user.role
    target_user.role = role
    await db.commit()
    
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
    await db.commit()
    
    return RedirectResponse(url=f"/admin/users/{user_id}", status_code=303)


@router.post("/{user_id}/ban")
async def ban_user(
    user_id: str,
    reason: str = Body(..., embed=True),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Ban a user (set is_active to False)."""
    # Only admins can ban users
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can ban users"
        )
    
    # Get user
    result = await db.execute(select(User).where(User.id == user_id))
    target_user = result.scalar_one_or_none()
    
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Cannot ban yourself
    if target_user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot ban yourself"
        )
    
    # Ban user
    target_user.is_active = False
    target_user.status = "banned"
    
    # Create audit log
    audit_log = AuditLog(
        actor_id=current_user.id,
        action="user_banned",
        resource="user",
        resource_id=user_id,
        reason=reason,
        metadata={"target_email": target_user.email}
    )
    db.add(audit_log)
    
    await db.commit()
    
    return {
        "message": "User banned successfully",
        "user_id": user_id,
        "status": "banned"
    }


@router.post("/{user_id}/unban")
async def unban_user(
    user_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Unban a user (set is_active to True)."""
    # Only admins can unban users
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can unban users"
        )
    
    # Get user
    result = await db.execute(select(User).where(User.id == user_id))
    target_user = result.scalar_one_or_none()
    
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Unban user
    target_user.is_active = True
    target_user.status = "active"
    
    # Create audit log
    audit_log = AuditLog(
        actor_id=current_user.id,
        action="user_unbanned",
        resource="user",
        resource_id=user_id,
        metadata={"target_email": target_user.email}
    )
    db.add(audit_log)
    
    await db.commit()
    
    return {
        "message": "User unbanned successfully",
        "user_id": user_id,
        "status": "active"
    }


class UpdateRoleRequest(BaseModel):
    role: str


@router.patch("/{user_id}/role")
async def update_user_role_api(
    user_id: str,
    request_data: UpdateRoleRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Update user role."""
    # Only admins can update roles
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can update user roles"
        )
    
    # Validate role
    valid_roles = ["user", "moderator", "admin"]
    if request_data.role not in valid_roles:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid role. Must be one of: {', '.join(valid_roles)}"
        )
    
    # Get user
    result = await db.execute(select(User).where(User.id == user_id))
    target_user = result.scalar_one_or_none()
    
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Cannot change your own role
    if target_user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot change your own role"
        )
    
    old_role = target_user.role
    target_user.role = request_data.role
    
    # Create audit log
    audit_log = AuditLog(
        actor_id=current_user.id,
        action="user_role_updated",
        resource="user",
        resource_id=user_id,
        metadata={
            "target_email": target_user.email,
            "old_role": old_role,
            "new_role": request_data.role
        }
    )
    db.add(audit_log)
    
    await db.commit()
    
    return {
        "message": "User role updated successfully",
        "user_id": user_id,
        "old_role": old_role,
        "new_role": request_data.role
    }


@router.get("/stats")
async def get_user_stats(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get user statistics."""
    
    # Total users
    total_users_result = await db.execute(select(func.count(User.id)))
    total_users = total_users_result.scalar()
    
    # Active users (not suspended)
    active_users_result = await db.execute(
        select(func.count(User.id)).where(User.is_active == True)
    )
    active_users = active_users_result.scalar()
    
    # Suspended users
    suspended_users_result = await db.execute(
        select(func.count(User.id)).where(User.is_active == False)
    )
    suspended_users = suspended_users_result.scalar()
    
    # Users by role
    admin_users_result = await db.execute(
        select(func.count(User.id)).where(User.role == "admin")
    )
    admin_users = admin_users_result.scalar()
    
    regular_users_result = await db.execute(
        select(func.count(User.id)).where(User.role == "user")
    )
    regular_users = regular_users_result.scalar()
    
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


@router.get("/{user_id}")
async def get_user_details(
    user_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get detailed information about a specific user."""
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Get user's reports count
    reports_count_result = await db.execute(
        select(func.count(Report.id)).where(Report.owner_id == user_id)
    )
    reports_count = reports_count_result.scalar()
    
    # Get user's matches count
    matches_count_result = await db.execute(
        select(func.count(Match.id)).where(
            (Match.source_report.has(Report.owner_id == user_id)) |
            (Match.candidate_report.has(Report.owner_id == user_id))
        )
    )
    matches_count = matches_count_result.scalar()
    
    return {
        "id": str(user.id),
        "email": user.email,
        "display_name": user.display_name or "",
        "phone_number": user.phone_number or "",
        "role": user.role,
        "status": user.status,
        "is_active": user.is_active,
        "created_at": user.created_at.isoformat(),
        "updated_at": user.updated_at.isoformat() if user.updated_at else None,
        "last_login": None,  # Field doesn't exist in User model
        "email_verified": False,  # Field doesn't exist in User model
        "phone_verified": False,  # Field doesn't exist in User model
        "preferences": {},  # Field doesn't exist in User model
        "statistics": {
            "reports_count": reports_count,
            "matches_count": matches_count
        }
    }

@router.delete("/{user_id}")
async def delete_user(
    user_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete a user (admin only)."""
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.role == "admin" and user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete your own admin account"
        )
    
    # Create audit log
    from ...helpers import create_audit_log
    await create_audit_log(
        db=db,
        actor_id=current_user.id,
        action="delete",
        resource="user",
        resource_id=user.id,
        changes={"deleted": True, "email": user.email}
    )
    
    await db.delete(user)
    await db.commit()
    
    return {"message": "User deleted successfully"}

@router.post("/{user_id}/suspend")
async def suspend_user(
    user_id: str,
    reason: str = Body(..., embed=True),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Suspend a user."""
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.role == "admin":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot suspend admin users"
        )
    
    user.is_active = False
    user.status = "suspended"
    
    # Create audit log
    from ...helpers import create_audit_log
    await create_audit_log(
        db=db,
        actor_id=current_user.id,
        action="suspend",
        resource="user",
        resource_id=user.id,
        changes={
            "reason": reason,
            "status": "suspended"
        }
    )
    
    await db.commit()
    
    return {"message": "User suspended successfully", "reason": reason}

@router.post("/{user_id}/activate")
async def activate_user(
    user_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Activate a suspended user."""
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.is_active = True
    user.status = "active"
    
    # Create audit log
    from ...helpers import create_audit_log
    await create_audit_log(
        db=db,
        actor_id=current_user.id,
        action="activate",
        resource="user",
        resource_id=user.id,
        changes={"status": "active"}
    )
    
    await db.commit()
    
    return {"message": "User activated successfully"}


@router.get("")
async def get_users_api(
    skip: int = 0,
    limit: int = 10,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get users list (JSON API)."""
    # Get total count
    total_count_result = await db.execute(select(func.count(User.id)))
    total = total_count_result.scalar()
    
    # Get paginated users
    users_result = await db.execute(
        select(User)
        .order_by(User.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    users = users_result.scalars().all()
    
    # Format users data
    users_data = []
    for user in users:
        # Get user's reports count
        reports_count_result = await db.execute(
            select(func.count(Report.id)).where(Report.owner_id == user.id)
        )
        reports_count = reports_count_result.scalar()
        
        # Get user's matches count
        matches_count_result = await db.execute(
            select(func.count(Match.id)).where(
                (Match.source_report.has(Report.owner_id == user.id)) |
                (Match.candidate_report.has(Report.owner_id == user.id))
            )
        )
        matches_count = matches_count_result.scalar()
        
        users_data.append({
            "id": str(user.id),
            "email": user.email,
            "display_name": user.display_name or "",
            "phone_number": user.phone_number or "",
            "role": user.role,
            "status": user.status,
            "is_active": user.is_active,
            "created_at": user.created_at.isoformat(),
            "updated_at": user.updated_at.isoformat() if user.updated_at else None,
            "last_login": None,  # Field doesn't exist in User model
            "email_verified": False,  # Field doesn't exist in User model
            "phone_verified": False,  # Field doesn't exist in User model
            "preferences": {},  # Field doesn't exist in User model
            "statistics": {
                "reports_count": reports_count,
                "matches_count": matches_count
            }
        })
    
    return {
        "items": users_data,
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.patch("/{user_id}")
async def update_user(
    user_id: str,
    request: dict,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Update user information."""
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Track changes for audit log
    changes = {}
    
    # Update fields if provided
    if "display_name" in request and request["display_name"] is not None:
        old_value = user.display_name
        user.display_name = request["display_name"]
        changes["display_name"] = {"old": old_value, "new": request["display_name"]}
    
    if "phone_number" in request and request["phone_number"] is not None:
        old_value = user.phone_number
        user.phone_number = request["phone_number"]
        changes["phone_number"] = {"old": old_value, "new": request["phone_number"]}
    
    if "role" in request and request["role"] is not None:
        old_value = user.role
        user.role = request["role"]
        changes["role"] = {"old": old_value, "new": request["role"]}
    
    if "is_active" in request and request["is_active"] is not None:
        old_value = user.is_active
        user.is_active = request["is_active"]
        changes["is_active"] = {"old": old_value, "new": request["is_active"]}
    
    if "status" in request and request["status"] is not None:
        old_value = user.status
        user.status = request["status"]
        changes["status"] = {"old": old_value, "new": request["status"]}
    
    # Create audit log if there were changes
    if changes:
        await create_audit_log(
            db=db,
            actor_id=current_user.id,
            action="update",
            resource="user",
            resource_id=user.id,
            changes=changes
        )
    
    await db.commit()
    
    return {
        "message": "User updated successfully",
        "user": {
            "id": str(user.id),
            "email": user.email,
            "display_name": user.display_name,
            "phone_number": user.phone_number,
            "role": user.role,
            "status": user.status,
            "is_active": user.is_active
        }
    }
