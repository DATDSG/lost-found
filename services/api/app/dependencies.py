"""API dependencies for auth and database access."""
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .infrastructure.database.session import get_async_db
from .auth import decode_token
from .models import User

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_async_db)
) -> User:
    """Get the current authenticated user from JWT token."""
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        token = credentials.credentials
        logger.info(f"🔍 Authenticating user with token: {token[:20]}...")
        
        payload = decode_token(token)
        
        if payload is None:
            logger.warning("❌ Token decode failed - payload is None")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        user_id: str = payload.get("sub")
        if user_id is None:
            logger.warning(f"❌ Token payload missing user_id: {payload}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials"
            )
        
        logger.info(f"🔍 Looking up user: {user_id}")
        result = await db.execute(select(User).where(User.id == user_id, User.is_active == True))
        user = result.scalar_one_or_none()
        
        if user is None:
            logger.warning(f"❌ User not found or inactive: {user_id}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive"
            )
        
        logger.info(f"✅ User authenticated: {user.email}")
        return user
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Authentication error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed"
        )


async def get_current_admin(
    current_user: User = Depends(get_current_user)
) -> User:
    """Ensure the current user has admin privileges."""
    import logging
    logger = logging.getLogger(__name__)
    
    logger.info(f"🔍 Checking admin permissions for user: {current_user.email} (role: {current_user.role})")
    
    if current_user.role not in ["admin", "moderator"]:
        logger.warning(f"❌ Access denied - insufficient permissions for user: {current_user.email}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions"
        )
    
    logger.info(f"✅ Admin access granted to user: {current_user.email}")
    return current_user


async def get_current_admin_dev(
    db: AsyncSession = Depends(get_async_db)
) -> User:
    """Development-only admin user for testing."""
    import os
    if os.getenv("ENVIRONMENT") == "development":
        # Create or get a test admin user
        result = await db.execute(select(User).where(User.email == "admin@example.com"))
        user = result.scalar_one_or_none()
        if user is None:
            # Create test admin user
            from .auth import get_password_hash
            user = User(
                email="admin@example.com",
                display_name="Admin User",
                role="admin",
                is_active=True,
                password=get_password_hash("Admin123")
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)
        return user
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required"
        )
