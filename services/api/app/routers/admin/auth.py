"""Admin authentication and authorization helpers."""

from fastapi import Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Dict
import secrets

from ...database import get_db
from ...models import User
from ...session_manager import session_manager


async def require_admin(
    request: Request,
    db: AsyncSession = Depends(get_db)
) -> User:
    """
    Dependency that requires admin authentication.
    Raises HTTPException if user is not authenticated or not an admin.
    """
    session_id = request.cookies.get("admin_session")
    
    if not session_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    
    session_data = await session_manager.get_session(session_id)
    if not session_data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired session"
        )
    
    user_id = session_data.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid session"
        )
    
    # Get user from database
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    if user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    return user


async def verify_csrf_token(request: Request, token: str) -> bool:
    """
    Verify CSRF token from request.
    Returns True if valid, False otherwise.
    """
    session_id = request.cookies.get("admin_session")
    
    if not session_id:
        return False
    
    return await session_manager.verify_csrf_token(session_id, token)


async def create_session(user_id: str) -> tuple[str, str]:
    """
    Create a new session for a user.
    Returns tuple of (session_id, csrf_token).
    """
    return await session_manager.create_session(user_id)


async def delete_session(session_id: str) -> bool:
    """
    Delete a session.
    Returns True if session was deleted, False if not found.
    """
    return await session_manager.delete_session(session_id)


# Legacy compatibility - keep for backward compatibility
sessions: Dict[str, dict] = {}
