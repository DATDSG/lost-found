"""
Rate limiting middleware using slowapi.

Protects API endpoints from abuse and DDoS attacks.
"""
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import Request, Response
from app.core.config import settings

# Initialize rate limiter
limiter = Limiter(
    key_func=get_remote_address,
    enabled=settings.RATE_LIMIT_ENABLED,
    storage_uri=settings.REDIS_URL if settings.RATE_LIMIT_ENABLED else None,
    strategy="fixed-window"
)

def setup_rate_limiting(app):
    """Setup rate limiting for FastAPI app."""
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    
    return limiter
