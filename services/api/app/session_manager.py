"""Redis-based session management for admin authentication."""

import json
import secrets
from typing import Dict, Optional
from datetime import datetime, timedelta, timezone
import redis.asyncio as redis
import logging

from .config import config

logger = logging.getLogger(__name__)


class RedisSessionManager:
    """Redis-based session manager for admin authentication."""
    
    def __init__(self):
        self.redis_client: Optional[redis.Redis] = None
        self.session_prefix = "admin_session:"
        self.session_ttl = timedelta(hours=24)  # 24 hour session expiry
    
    async def initialize(self):
        """Initialize Redis connection."""
        try:
            self.redis_client = await redis.from_url(
                config.REDIS_URL,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5,
                retry_on_timeout=True
            )
            # Test connection
            await self.redis_client.ping()
            logger.info("Redis session manager initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize Redis session manager: {e}")
            raise
    
    async def close(self):
        """Close Redis connection."""
        if self.redis_client:
            await self.redis_client.close()
    
    async def create_session(self, user_id: str) -> tuple[str, str]:
        """
        Create a new session for a user.
        Returns tuple of (session_id, csrf_token).
        """
        if not self.redis_client:
            raise RuntimeError("Redis session manager not initialized")
        
        session_id = secrets.token_urlsafe(32)
        csrf_token = secrets.token_urlsafe(32)
        
        session_data = {
            "user_id": user_id,
            "csrf_token": csrf_token,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "last_accessed": datetime.now(timezone.utc).isoformat()
        }
        
        # Store session in Redis with TTL
        await self.redis_client.setex(
            f"{self.session_prefix}{session_id}",
            int(self.session_ttl.total_seconds()),
            json.dumps(session_data)
        )
        
        logger.info(f"Created session for user {user_id}")
        return session_id, csrf_token
    
    async def get_session(self, session_id: str) -> Optional[Dict]:
        """
        Get session data by session ID.
        Returns session data dict or None if not found/expired.
        """
        if not self.redis_client:
            return None
        
        try:
            session_data_str = await self.redis_client.get(f"{self.session_prefix}{session_id}")
            if not session_data_str:
                return None
            
            session_data = json.loads(session_data_str)
            
            # Update last accessed time
            session_data["last_accessed"] = datetime.now(timezone.utc).isoformat()
            await self.redis_client.setex(
                f"{self.session_prefix}{session_id}",
                int(self.session_ttl.total_seconds()),
                json.dumps(session_data)
            )
            
            return session_data
        except Exception as e:
            logger.error(f"Error getting session {session_id}: {e}")
            return None
    
    async def delete_session(self, session_id: str) -> bool:
        """
        Delete a session.
        Returns True if session was deleted, False if not found.
        """
        if not self.redis_client:
            return False
        
        try:
            result = await self.redis_client.delete(f"{self.session_prefix}{session_id}")
            logger.info(f"Deleted session {session_id}")
            return result > 0
        except Exception as e:
            logger.error(f"Error deleting session {session_id}: {e}")
            return False
    
    async def verify_csrf_token(self, session_id: str, token: str) -> bool:
        """
        Verify CSRF token for a session.
        Returns True if valid, False otherwise.
        """
        session_data = await self.get_session(session_id)
        if not session_data:
            return False
        
        stored_token = session_data.get("csrf_token", "")
        return secrets.compare_digest(token, stored_token)
    
    async def cleanup_expired_sessions(self) -> int:
        """
        Clean up expired sessions (Redis TTL handles this automatically).
        Returns number of sessions cleaned up.
        """
        if not self.redis_client:
            return 0
        
        try:
            # Get all session keys
            session_keys = await self.redis_client.keys(f"{self.session_prefix}*")
            
            # Check which ones are expired (TTL <= 0)
            expired_count = 0
            for key in session_keys:
                ttl = await self.redis_client.ttl(key)
                if ttl <= 0:
                    await self.redis_client.delete(key)
                    expired_count += 1
            
            logger.info(f"Cleaned up {expired_count} expired sessions")
            return expired_count
        except Exception as e:
            logger.error(f"Error cleaning up sessions: {e}")
            return 0
    
    async def get_session_stats(self) -> Dict:
        """Get session statistics."""
        if not self.redis_client:
            return {"error": "Redis not initialized"}
        
        try:
            session_keys = await self.redis_client.keys(f"{self.session_prefix}*")
            total_sessions = len(session_keys)
            
            # Get active sessions (TTL > 0)
            active_sessions = 0
            for key in session_keys:
                ttl = await self.redis_client.ttl(key)
                if ttl > 0:
                    active_sessions += 1
            
            return {
                "total_sessions": total_sessions,
                "active_sessions": active_sessions,
                "expired_sessions": total_sessions - active_sessions,
                "session_ttl_hours": self.session_ttl.total_seconds() / 3600
            }
        except Exception as e:
            logger.error(f"Error getting session stats: {e}")
            return {"error": str(e)}


# Global session manager instance
session_manager = RedisSessionManager()
