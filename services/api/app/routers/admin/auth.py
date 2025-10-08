"""Admin authentication and authorization helpers."""

from fastapi import Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from typing import Dict
import secrets

from app.database import get_db
from app.models import User

# In-memory session storage (should be replaced with Redis in production)
sessions: Dict[str, dict] = {}


async def require_admin(
    request: Request,
    db: Session = Depends(get_db)
) -> User:
    """
    Dependency that requires admin authentication.
    Raises HTTPException if user is not authenticated or not an admin.
    """
    session_id = request.cookies.get("admin_session")
    
    if not session_id or session_id not in sessions:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    
    session_data = sessions[session_id]
    user_id = session_data.get("user_id")
    
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid session"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    
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


def verify_csrf_token(request: Request, token: str) -> bool:
    """
    Verify CSRF token from request.
    Returns True if valid, False otherwise.
    """
    session_id = request.cookies.get("admin_session")
    
    if not session_id or session_id not in sessions:
        return False
    
    session_token = sessions[session_id].get("csrf_token", "")
    return secrets.compare_digest(token, session_token)


def create_session(user_id: str) -> tuple[str, str]:
    """
    Create a new session for a user.
    Returns tuple of (session_id, csrf_token).
    """
    session_id = secrets.token_urlsafe(32)
    csrf_token = secrets.token_urlsafe(32)
    
    sessions[session_id] = {
        "user_id": user_id,
        "csrf_token": csrf_token
    }
    
    return session_id, csrf_token


def delete_session(session_id: str) -> None:
    """Delete a session."""
    if session_id in sessions:
        del sessions[session_id]
