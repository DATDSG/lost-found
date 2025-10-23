"""
Redis Client for Infrastructure Layer
====================================
Redis client implementation for caching and session management.
"""

import redis.asyncio as redis
from typing import Optional, Any, Dict
import json
import logging
from ...config import config

logger = logging.getLogger(__name__)

class RedisClient:
    """Redis client wrapper with connection management."""
    
    def __init__(self, url: str = None):
        self.url = url or config.REDIS_URL
        self.client: Optional[redis.Redis] = None
    
    async def connect(self):
        """Connect to Redis."""
        try:
            self.client = redis.from_url(
                self.url,
                max_connections=config.REDIS_MAX_CONNECTIONS,
                decode_responses=True
            )
            await self.client.ping()
            logger.info("Redis connection established")
        except Exception as e:
            logger.error(f"Redis connection failed: {e}")
            raise
    
    async def disconnect(self):
        """Disconnect from Redis."""
        if self.client:
            await self.client.close()
            logger.info("Redis connection closed")
    
    async def ping(self) -> bool:
        """Ping Redis server."""
        if not self.client:
            await self.connect()
        return await self.client.ping()
    
    async def set(self, key: str, value: Any, ex: int = None) -> bool:
        """Set a key-value pair."""
        if not self.client:
            await self.connect()
        
        if isinstance(value, (dict, list)):
            value = json.dumps(value)
        
        return await self.client.set(key, value, ex=ex)
    
    async def get(self, key: str) -> Optional[Any]:
        """Get a value by key."""
        if not self.client:
            await self.connect()
        
        value = await self.client.get(key)
        if value is None:
            return None
        
        try:
            return json.loads(value)
        except (json.JSONDecodeError, TypeError):
            return value
    
    async def delete(self, *keys: str) -> int:
        """Delete keys."""
        if not self.client:
            await self.connect()
        
        return await self.client.delete(*keys)
    
    async def exists(self, key: str) -> bool:
        """Check if key exists."""
        if not self.client:
            await self.connect()
        
        return await self.client.exists(key)
    
    async def expire(self, key: str, time: int) -> bool:
        """Set expiration time for key."""
        if not self.client:
            await self.connect()
        
        return await self.client.expire(key, time)
    
    async def health_check(self) -> Dict[str, Any]:
        """Check Redis health."""
        try:
            if not self.client:
                await self.connect()
            
            info = await self.client.info()
            return {
                "status": "healthy",
                "version": info.get("redis_version", "unknown"),
                "connected_clients": info.get("connected_clients", 0),
                "used_memory": info.get("used_memory_human", "unknown")
            }
        except Exception as e:
            logger.error(f"Redis health check failed: {e}")
            return {
                "status": "unhealthy",
                "error": str(e)
            }

# Global Redis client instance
_redis_client: Optional[RedisClient] = None

def get_redis_client() -> Optional[RedisClient]:
    """Get the global Redis client instance."""
    global _redis_client
    if _redis_client is None:
        try:
            _redis_client = RedisClient()
        except Exception as e:
            logger.warning(f"Failed to create Redis client: {e}")
            return None
    return _redis_client
