"""Admin users API routes."""

from __future__ import annotations

import json
from typing import Optional
from uuid import UUID, uuid4

from fastapi import APIRouter, Body, Depends, HTTPException, Query, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from ...infrastructure.database.session import get_async_db
from ...dependencies import get_current_admin
from ...helpers import create_audit_log_async
from ...models import User
from ...domains.matches.models.match import Match
from ...domains.reports.models.report import Report
from ...auth import get_password_hash

router = APIRouter()


@router.get("/me")
async def get_current_admin_user(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Get current admin user information."""
    return {
        "user": _serialize_user(current_user),
        "permissions": {
            "can_create_users": True,
            "can_modify_users": True,
            "can_delete_users": True,
            "can_view_audit_logs": True,
            "can_manage_reports": True,
            "can_manage_matches": True,
        }
    }


@router.get("")
async def get_admin_user_info(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Get current admin user information (root endpoint)."""
    return {
        "user": _serialize_user(current_user),
        "permissions": {
            "can_create_users": True,
            "can_modify_users": True,
            "can_delete_users": True,
            "can_view_audit_logs": True,
            "can_manage_reports": True,
            "can_manage_matches": True,
        }
    }


class UserCreateRequest(BaseModel):
    email: EmailStr
    password: str
    display_name: Optional[str] = None
    phone_number: Optional[str] = None
    role: str = "user"
    is_active: bool = True
    status: str = "active"


class UserUpdateRequest(BaseModel):
    display_name: Optional[str] = None
    phone_number: Optional[str] = None
    avatar_url: Optional[str] = None
    status: Optional[str] = None
    is_active: Optional[bool] = None


class RoleUpdateRequest(BaseModel):
    role: str


class StatusActionRequest(BaseModel):
    reason: Optional[str] = None


class UserStatusUpdateRequest(BaseModel):
    status: str
    reason: Optional[str] = None


async def _get_user_or_404(db: AsyncSession, user_id: str) -> User:
    try:
        uuid = UUID(user_id)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user id format",
        ) from exc

    result = await db.execute(select(User).where(User.id == uuid))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    return user


def _serialize_user(user: User) -> dict:
    return {
        "id": str(user.id),
        "email": user.email,
        "display_name": user.display_name,
        "phone_number": user.phone_number,
        "avatar_url": user.avatar_url,
        "role": user.role,
        "status": user.status,
        "is_active": user.is_active,
        "created_at": user.created_at.isoformat() if user.created_at else None,
        "updated_at": user.updated_at.isoformat() if user.updated_at else None,
    }


@router.get("")
async def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    role: Optional[str] = None,
    status_filter: Optional[str] = None,
    search: Optional[str] = None,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Return paginated list of users with optional filters."""
    conditions = []
    if role:
        conditions.append(User.role == role)
    if status_filter:
        if status_filter == "active":
            conditions.append(User.is_active.is_(True))
        elif status_filter == "inactive":
            conditions.append(User.is_active.is_(False))
        else:
            conditions.append(User.status == status_filter)
    if search:
        pattern = f"%{search}%"
        conditions.append(
            or_(
                User.email.ilike(pattern),
                User.display_name.ilike(pattern),
                User.phone_number.ilike(pattern),
            )
        )

    count_query = select(func.count()).select_from(User)
    if conditions:
        count_query = count_query.where(*conditions)
    total = (await db.execute(count_query)).scalar() or 0

    query = select(User).order_by(User.created_at.desc())
    if conditions:
        query = query.where(*conditions)
    query = query.offset(skip).limit(limit)

    result = await db.execute(query)
    users = result.scalars().all()

    return {
        "items": [_serialize_user(user) for user in users],
        "total": total,
        "skip": skip,
        "limit": limit,
    }


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_user(
    payload: UserCreateRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Create a new user account."""
    existing = await db.execute(select(User).where(User.email == payload.email))
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists",
        )

    user = User(
        id=uuid4(),
        email=payload.email,
        password=get_password_hash(payload.password),
        display_name=payload.display_name or payload.email.split("@")[0],
        phone_number=payload.phone_number,
        role=payload.role,
        is_active=payload.is_active,
        status=payload.status,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    await create_audit_log_async(
        db=db,
        user_id=str(current_user.id),
        action="create_user",
        resource_type="user",
        resource_id=str(user.id),
        details=json.dumps(
            {
                "email": user.email,
                "role": user.role,
                "created_by": current_user.email,
            }
        ),
    )

    return {"user": _serialize_user(user)}


@router.get("/stats")
async def get_user_stats(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Return aggregate statistics for users."""
    total = (await db.execute(select(func.count()).select_from(User))).scalar() or 0
    active = (
        await db.execute(
            select(func.count()).select_from(User).where(User.is_active.is_(True))
        )
    ).scalar() or 0
    inactive = total - active
    admins = (
        await db.execute(
            select(func.count()).select_from(User).where(User.role == "admin")
        )
    ).scalar() or 0

    moderators = (
        await db.execute(
            select(func.count()).select_from(User).where(User.role == "moderator")
        )
    ).scalar() or 0

    return {
        "total": total,
        "active": active,
        "inactive": inactive,
        "roles": {
            "admin": admins,
            "moderator": moderators,
            "user": total - admins - moderators,
        },
    }


@router.get("/{user_id}")
async def get_user_detail(
    user_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Return user details with aggregate stats."""
    user = await _get_user_or_404(db, user_id)

    reports_count = (
        await db.execute(
            select(func.count()).select_from(Report).where(Report.owner_id == user.id)
        )
    ).scalar() or 0

    user_reports_subquery = (
        select(Report.id).where(Report.owner_id == user.id).subquery()
    )
    matches_count = (
        await db.execute(
            select(func.count())
            .select_from(Match)
            .where(
                or_(
                    Match.source_report_id.in_(
                        select(user_reports_subquery.c.id)
                    ),
                    Match.candidate_report_id.in_(
                        select(user_reports_subquery.c.id)
                    ),
                )
            )
        )
    ).scalar() or 0

    return {
        "user": _serialize_user(user),
        "statistics": {
            "reports": reports_count,
            "matches": matches_count,
        },
    }


@router.patch("/{user_id}")
async def update_user(
    user_id: str,
    payload: UserUpdateRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Update mutable fields for a user."""
    user = await _get_user_or_404(db, user_id)
    changes = {}

    if payload.display_name is not None and payload.display_name != user.display_name:
        changes["display_name"] = {
            "old": user.display_name,
            "new": payload.display_name,
        }
        user.display_name = payload.display_name
    if payload.phone_number is not None and payload.phone_number != user.phone_number:
        changes["phone_number"] = {
            "old": user.phone_number,
            "new": payload.phone_number,
        }
        user.phone_number = payload.phone_number
    if payload.avatar_url is not None and payload.avatar_url != user.avatar_url:
        changes["avatar_url"] = {
            "old": user.avatar_url,
            "new": payload.avatar_url,
        }
        user.avatar_url = payload.avatar_url
    if payload.status is not None and payload.status != user.status:
        changes["status"] = {"old": user.status, "new": payload.status}
        user.status = payload.status
    if payload.is_active is not None and payload.is_active != user.is_active:
        changes["is_active"] = {"old": user.is_active, "new": payload.is_active}
        user.is_active = payload.is_active

    if not changes:
        return {"user": _serialize_user(user), "message": "No changes applied"}

    await db.commit()
    await db.refresh(user)

    await create_audit_log_async(
        db=db,
        user_id=str(current_user.id),
        action="update_user",
        resource_type="user",
        resource_id=str(user.id),
        details=json.dumps(changes),
    )

    return {"user": _serialize_user(user)}


@router.patch("/{user_id}/role")
async def update_user_role(
    user_id: str,
    payload: RoleUpdateRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Update the user's role."""
    user = await _get_user_or_404(db, user_id)
    old_role = user.role
    if old_role == payload.role:
        return {"user": _serialize_user(user), "message": "Role unchanged"}

    user.role = payload.role
    await db.commit()
    await db.refresh(user)

    await create_audit_log_async(
        db=db,
        user_id=str(current_user.id),
        action="update_user_role",
        resource_type="user",
        resource_id=str(user.id),
        details=json.dumps({"old_role": old_role, "new_role": payload.role}),
    )

    return {"user": _serialize_user(user)}


@router.patch("/{user_id}/status")
async def update_user_status(
    user_id: str,
    payload: UserStatusUpdateRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Update the user's status."""
    user = await _get_user_or_404(db, user_id)
    old_status = user.status
    old_is_active = user.is_active
    
    # Prevent admin users from deactivating themselves
    if str(user.id) == str(current_user.id) and payload.status in ["inactive", "banned", "suspended"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Admin users cannot deactivate themselves"
        )
    
    # Map status to is_active and status fields
    if payload.status == "active":
        user.is_active = True
        user.status = "active"
    elif payload.status == "inactive":
        user.is_active = False
        user.status = "inactive"
    elif payload.status == "banned":
        user.is_active = False
        user.status = "banned"
    elif payload.status == "suspended":
        user.is_active = False
        user.status = "suspended"
    else:
        # For other statuses, just update the status field
        user.status = payload.status
    
    await db.commit()
    await db.refresh(user)

    await create_audit_log_async(
        db=db,
        user_id=str(current_user.id),
        action="update_user_status",
        resource_type="user",
        resource_id=str(user.id),
        details=json.dumps({
            "old_status": old_status,
            "old_is_active": old_is_active,
            "new_status": user.status,
            "new_is_active": user.is_active,
            "reason": payload.reason,
        }),
    )

    return {"user": _serialize_user(user)}


@router.post("/{user_id}/ban")
async def ban_user(
    user_id: str,
    payload: StatusActionRequest = Body(default_factory=StatusActionRequest),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Ban a user (disables account)."""
    user = await _get_user_or_404(db, user_id)

    user.is_active = False
    user.status = "banned"
    await db.commit()
    await db.refresh(user)

    await create_audit_log_async(
        db=db,
        user_id=str(current_user.id),
        action="ban_user",
        resource_type="user",
        resource_id=str(user.id),
        details=json.dumps(
            {"reason": payload.reason, "email": user.email, "status": "banned"}
        ),
    )

    return {"user": _serialize_user(user)}


@router.post("/{user_id}/unban")
async def unban_user(
    user_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Re-activate a previously banned user."""
    user = await _get_user_or_404(db, user_id)

    user.is_active = True
    user.status = "active"
    await db.commit()
    await db.refresh(user)

    await create_audit_log_async(
        db=db,
        user_id=str(current_user.id),
        action="unban_user",
        resource_type="user",
        resource_id=str(user.id),
        details=json.dumps({"email": user.email}),
    )

    return {"user": _serialize_user(user)}


@router.post("/{user_id}/suspend")
async def suspend_user(
    user_id: str,
    payload: StatusActionRequest = Body(default_factory=StatusActionRequest),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Temporarily suspend a user (keeps account inactive)."""
    user = await _get_user_or_404(db, user_id)

    user.is_active = False
    user.status = "suspended"
    await db.commit()
    await db.refresh(user)

    await create_audit_log_async(
        db=db,
        user_id=str(current_user.id),
        action="suspend_user",
        resource_type="user",
        resource_id=str(user.id),
        details=json.dumps({"reason": payload.reason}),
    )

    return {"user": _serialize_user(user)}


@router.post("/{user_id}/activate")
async def activate_user(
    user_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Activate a suspended or inactive user."""
    user = await _get_user_or_404(db, user_id)

    user.is_active = True
    user.status = "active"
    await db.commit()
    await db.refresh(user)

    await create_audit_log_async(
        db=db,
        user_id=str(current_user.id),
        action="activate_user",
        resource_type="user",
        resource_id=str(user.id),
        details=json.dumps({"email": user.email}),
    )

    return {"user": _serialize_user(user)}


@router.delete("/{user_id}")
async def delete_user(
    user_id: str,
    payload: StatusActionRequest = Body(default_factory=StatusActionRequest),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_async_db),
):
    """Soft delete a user by disabling the account."""
    user = await _get_user_or_404(db, user_id)

    user.is_active = False
    user.status = "deleted"
    await db.commit()
    await db.refresh(user)

    await create_audit_log_async(
        db=db,
        user_id=str(current_user.id),
        action="delete_user",
        resource_type="user",
        resource_id=str(user.id),
        details=json.dumps({"reason": payload.reason}),
    )

    return {"message": "User marked as deleted"}
