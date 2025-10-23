"""Simple admin authentication and authorization helpers."""

from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ...infrastructure.database.session import get_async_db
from app.models import User
from app.dependencies import get_current_user


async def require_admin(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Dependency that requires admin authentication.
    Raises HTTPException if user is not an admin.
    """
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    return current_user
