"""CSRF token management endpoints for admin panel."""

from fastapi import APIRouter, Request, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from ...database import get_db
from ...dependencies import get_current_admin
from ...models import User
from ...csrf import get_csrf_token, verify_csrf_token, csrf_protection
from ...exceptions import AuthenticationError

router = APIRouter()


@router.get("/csrf-token")
async def get_csrf_token_endpoint(
    request: Request,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Get CSRF token for admin operations."""
    try:
        # Generate session ID if not exists
        session_id = request.cookies.get("admin_session")
        if not session_id:
            import secrets
            session_id = secrets.token_hex(32)
        
        # Generate CSRF token
        csrf_token = csrf_protection.generate_csrf_token(session_id, str(current_user.id))
        
        response = JSONResponse(
            content={
                "csrf_token": csrf_token,
                "session_id": session_id,
                "expires_in": csrf_protection.token_expiry_minutes * 60  # seconds
            }
        )
        
        # Set session cookie
        response.set_cookie(
            key="admin_session",
            value=session_id,
            httponly=True,
            secure=True,
            samesite="strict",
            max_age=csrf_protection.token_expiry_minutes * 60
        )
        
        return response
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate CSRF token"
        )


@router.post("/csrf-token/verify")
async def verify_csrf_token_endpoint(
    request: Request,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Verify CSRF token validity."""
    try:
        csrf_token = request.headers.get("X-CSRF-Token")
        if not csrf_token:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="CSRF token not provided"
            )
        
        is_valid = verify_csrf_token(request, csrf_token)
        
        return {
            "valid": is_valid,
            "message": "CSRF token is valid" if is_valid else "CSRF token is invalid"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to verify CSRF token"
        )


@router.post("/csrf-token/refresh")
async def refresh_csrf_token_endpoint(
    request: Request,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Refresh CSRF token."""
    try:
        # Verify current token before refreshing
        csrf_token = request.headers.get("X-CSRF-Token")
        if not csrf_token or not verify_csrf_token(request, csrf_token):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Invalid CSRF token"
            )
        
        # Get session ID
        session_id = request.cookies.get("admin_session")
        if not session_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No active session found"
            )
        
        # Refresh token
        new_csrf_token = csrf_protection.refresh_token(session_id, str(current_user.id))
        
        return {
            "csrf_token": new_csrf_token,
            "expires_in": csrf_protection.token_expiry_minutes * 60,
            "message": "CSRF token refreshed successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to refresh CSRF token"
        )


@router.post("/csrf-token/revoke")
async def revoke_csrf_token_endpoint(
    request: Request,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Revoke CSRF token."""
    try:
        # Verify current token before revoking
        csrf_token = request.headers.get("X-CSRF-Token")
        if not csrf_token or not verify_csrf_token(request, csrf_token):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Invalid CSRF token"
            )
        
        # Get session ID
        session_id = request.cookies.get("admin_session")
        if not session_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No active session found"
            )
        
        # Revoke token
        revoked = csrf_protection.revoke_token(session_id)
        
        response = JSONResponse(
            content={
                "revoked": revoked,
                "message": "CSRF token revoked successfully" if revoked else "No token to revoke"
            }
        )
        
        # Clear session cookie
        response.delete_cookie(key="admin_session")
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to revoke CSRF token"
        )
