"""CSRF protection implementation for the Lost & Found API."""

import secrets
import hashlib
import hmac
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse

from .config import config
from .exceptions import ValidationError, AuthenticationError


class CSRFProtection:
    """CSRF protection implementation."""
    
    def __init__(self, secret_key: str = None, token_expiry_minutes: int = 30):
        self.secret_key = secret_key or config.JWT_SECRET_KEY or "default-csrf-secret"
        self.token_expiry_minutes = token_expiry_minutes
        self.session_tokens: Dict[str, Dict[str, Any]] = {}
    
    def generate_csrf_token(self, session_id: str, user_id: str = None) -> str:
        """Generate a CSRF token for a session."""
        # Create token data
        timestamp = datetime.utcnow().timestamp()
        random_data = secrets.token_hex(16)
        
        # Create token payload
        payload = f"{session_id}:{user_id or 'anonymous'}:{timestamp}:{random_data}"
        
        # Generate HMAC signature
        signature = hmac.new(
            self.secret_key.encode(),
            payload.encode(),
            hashlib.sha256
        ).hexdigest()
        
        # Combine payload and signature
        token = f"{payload}:{signature}"
        
        # Store token in session
        self.session_tokens[session_id] = {
            "token": token,
            "user_id": user_id,
            "created_at": datetime.utcnow(),
            "expires_at": datetime.utcnow() + timedelta(minutes=self.token_expiry_minutes)
        }
        
        return token
    
    def validate_csrf_token(self, session_id: str, token: str, user_id: str = None) -> bool:
        """Validate a CSRF token."""
        if not session_id or not token:
            return False
        
        # Check if session exists
        if session_id not in self.session_tokens:
            return False
        
        session_data = self.session_tokens[session_id]
        
        # Check if token matches
        if session_data["token"] != token:
            return False
        
        # Check if token is expired
        if datetime.utcnow() > session_data["expires_at"]:
            # Remove expired token
            del self.session_tokens[session_id]
            return False
        
        # Check user ID if provided
        if user_id and session_data["user_id"] != user_id:
            return False
        
        return True
    
    def verify_token_signature(self, token: str) -> bool:
        """Verify the HMAC signature of a token."""
        try:
            parts = token.split(":")
            if len(parts) != 5:  # session_id:user_id:timestamp:random:signature
                return False
            
            payload = ":".join(parts[:4])
            provided_signature = parts[4]
            
            # Generate expected signature
            expected_signature = hmac.new(
                self.secret_key.encode(),
                payload.encode(),
                hashlib.sha256
            ).hexdigest()
            
            # Compare signatures securely
            return hmac.compare_digest(provided_signature, expected_signature)
        
        except Exception:
            return False
    
    def refresh_token(self, session_id: str, user_id: str = None) -> str:
        """Refresh a CSRF token for a session."""
        if session_id in self.session_tokens:
            del self.session_tokens[session_id]
        
        return self.generate_csrf_token(session_id, user_id)
    
    def revoke_token(self, session_id: str) -> bool:
        """Revoke a CSRF token."""
        if session_id in self.session_tokens:
            del self.session_tokens[session_id]
            return True
        return False
    
    def cleanup_expired_tokens(self):
        """Remove expired tokens from memory."""
        current_time = datetime.utcnow()
        expired_sessions = [
            session_id for session_id, data in self.session_tokens.items()
            if current_time > data["expires_at"]
        ]
        
        for session_id in expired_sessions:
            del self.session_tokens[session_id]
    
    def get_session_info(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get session information."""
        return self.session_tokens.get(session_id)


# Global CSRF protection instance
csrf_protection = CSRFProtection()


def get_csrf_token(request: Request) -> str:
    """Get CSRF token from request headers or generate new one."""
    session_id = request.cookies.get("session_id")
    if not session_id:
        # Generate new session ID
        session_id = secrets.token_hex(32)
    
    # Get user ID from JWT token if available
    user_id = None
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        try:
            from .auth import decode_token
            token = auth_header.split(" ")[1]
            payload = decode_token(token)
            user_id = payload.get("sub")
        except Exception:
            pass  # Ignore JWT errors for CSRF token generation
    
    return csrf_protection.generate_csrf_token(session_id, user_id)


def verify_csrf_token(request: Request, token: str = None) -> bool:
    """Verify CSRF token from request."""
    session_id = request.cookies.get("session_id")
    if not session_id:
        return False
    
    # Get token from parameter or header
    if not token:
        token = request.headers.get("X-CSRF-Token")
    
    if not token:
        return False
    
    # Get user ID from JWT token if available
    user_id = None
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        try:
            from .auth import decode_token
            jwt_token = auth_header.split(" ")[1]
            payload = decode_token(jwt_token)
            user_id = payload.get("sub")
        except Exception:
            pass  # Ignore JWT errors for CSRF verification
    
    return csrf_protection.validate_csrf_token(session_id, token, user_id)


def require_csrf_token(request: Request, token: str = None):
    """Dependency to require valid CSRF token."""
    if not verify_csrf_token(request, token):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid or missing CSRF token"
        )


def csrf_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """Handle CSRF-related exceptions."""
    if exc.status_code == status.HTTP_403_FORBIDDEN and "CSRF" in str(exc.detail):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": {
                    "code": "csrf_token_invalid",
                    "message": "CSRF token validation failed",
                    "details": {
                        "path": request.url.path,
                        "method": request.method,
                        "suggestion": "Include valid X-CSRF-Token header"
                    }
                }
            }
        )
    
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"message": str(exc.detail)}}
    )


# CSRF middleware
async def csrf_middleware(request: Request, call_next):
    """CSRF protection middleware."""
    # Skip CSRF check for safe methods and certain endpoints
    if request.method in ["GET", "HEAD", "OPTIONS"]:
        response = await call_next(request)
        return response
    
    # Skip CSRF check for authentication endpoints
    if request.url.path.startswith("/auth/"):
        response = await call_next(request)
        return response
    
    # Skip CSRF check for public endpoints
    public_endpoints = ["/health", "/metrics", "/docs", "/openapi.json"]
    if any(request.url.path.startswith(endpoint) for endpoint in public_endpoints):
        response = await call_next(request)
        return response
    
    # Verify CSRF token for other endpoints
    csrf_token = request.headers.get("X-CSRF-Token")
    if not verify_csrf_token(request, csrf_token):
        return JSONResponse(
            status_code=status.HTTP_403_FORBIDDEN,
            content={
                "error": {
                    "code": "csrf_token_required",
                    "message": "CSRF token is required for this operation",
                    "details": {
                        "path": request.url.path,
                        "method": request.method,
                        "suggestion": "Include valid X-CSRF-Token header"
                    }
                }
            }
        )
    
    response = await call_next(request)
    return response
