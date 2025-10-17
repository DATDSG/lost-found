"""Admin audit log router."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, or_
from typing import Optional

from ...database import get_db
from ...models import User, AuditLog
from ...dependencies import get_current_admin

router = APIRouter()

@router.get("")
async def list_audit_logs(
    skip: int = Query(0, ge=0),
    limit: int = Query(25, ge=1, le=100),
    action: Optional[str] = None,
    actor_email: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """List audit logs with pagination and filters."""
    # Build query
    query = select(AuditLog)
    
    # Apply filters
    if action:
        query = query.where(AuditLog.action == action)
    
    if actor_email:
        # Join with users table to filter by email
        query = query.join(User, AuditLog.actor_id == User.id).where(User.email == actor_email)
    
    # Get total count
    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0
    
    # Apply pagination and ordering
    query = query.order_by(AuditLog.created_at.desc()).offset(skip).limit(limit)
    
    # Execute query
    result = await db.execute(query)
    audit_logs = result.scalars().all()
    
    # Convert to response format
    logs_data = []
    for log in audit_logs:
        logs_data.append({
            "id": log.id,
            "action": log.action,
            "resource": log.resource,
            "resource_id": log.resource_id,
            "actor_id": log.actor_id,
            "reason": log.reason,
            "created_at": log.created_at.isoformat()
        })
    
    return {
        "items": logs_data,
        "total": total,
        "skip": skip,
        "limit": limit,
        "page": (skip // limit) + 1 if limit > 0 else 1,
        "pages": (total + limit - 1) // limit if limit > 0 else 1,
        "has_next": (skip + limit) < total,
        "has_prev": skip > 0
    }
