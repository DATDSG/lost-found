"""
Redis Cache and Session Management
==================================
Enhanced Redis integration for caching, sessions, and background tasks.
"""
import json
import logging
from typing import Optional, Any, Dict, Union
from datetime import datetime, timedelta
import asyncio
from contextlib import asynccontextmanager

try:
    import redis.asyncio as redis
    from redis.asyncio import ConnectionPool
    REDIS_AVAILABLE = True
except ImportError:
    redis = None
    ConnectionPool = None
    REDIS_AVAILABLE = False

from .config import config

logger = logging.getLogger(__name__)


class RedisClient:
    """Enhanced Redis client with connection pooling and error handling."""
    
    def __init__(self):
        if not REDIS_AVAILABLE:
            raise RuntimeError("redis package is required for Redis support")
        
        self.url = config.REDIS_URL
        self.max_connections = config.REDIS_MAX_CONNECTIONS
        self.cache_ttl = config.REDIS_CACHE_TTL
        
        # Create connection pool
        self.pool = ConnectionPool.from_url(
            self.url,
            max_connections=self.max_connections,
            decode_responses=True,
            retry_on_timeout=True,
            socket_keepalive=True,
            socket_keepalive_options={},
            health_check_interval=30
        )
        
        # Create Redis client
        self.client = redis.Redis(connection_pool=self.pool)
    
    async def ping(self) -> bool:
        """Test Redis connection."""
        try:
            await self.client.ping()
            return True
        except Exception as e:
            logger.error(f"Redis ping failed: {e}")
            return False
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from Redis."""
        try:
            value = await self.client.get(key)
            if value:
                return json.loads(value)
            return None
        except Exception as e:
            logger.error(f"Redis get failed for key {key}: {e}")
            return None
    
    async def set(
        self, 
        key: str, 
        value: Any, 
        ttl: Optional[int] = None,
        nx: bool = False
    ) -> bool:
        """Set value in Redis."""
        try:
            ttl = ttl or self.cache_ttl
            serialized_value = json.dumps(value, default=str)
            
            if nx:
                result = await self.client.set(key, serialized_value, ex=ttl, nx=True)
            else:
                result = await self.client.set(key, serialized_value, ex=ttl)
            
            return bool(result)
        except Exception as e:
            logger.error(f"Redis set failed for key {key}: {e}")
            return False
    
    async def delete(self, key: str) -> bool:
        """Delete key from Redis."""
        try:
            result = await self.client.delete(key)
            return bool(result)
        except Exception as e:
            logger.error(f"Redis delete failed for key {key}: {e}")
            return False
    
    async def exists(self, key: str) -> bool:
        """Check if key exists in Redis."""
        try:
            result = await self.client.exists(key)
            return bool(result)
        except Exception as e:
            logger.error(f"Redis exists failed for key {key}: {e}")
            return False
    
    async def expire(self, key: str, ttl: int) -> bool:
        """Set expiration for key."""
        try:
            result = await self.client.expire(key, ttl)
            return bool(result)
        except Exception as e:
            logger.error(f"Redis expire failed for key {key}: {e}")
            return False
    
    async def ttl(self, key: str) -> int:
        """Get TTL for key."""
        try:
            return await self.client.ttl(key)
        except Exception as e:
            logger.error(f"Redis ttl failed for key {key}: {e}")
            return -1
    
    async def incr(self, key: str, amount: int = 1) -> Optional[int]:
        """Increment key value."""
        try:
            return await self.client.incrby(key, amount)
        except Exception as e:
            logger.error(f"Redis incr failed for key {key}: {e}")
            return None
    
    async def decr(self, key: str, amount: int = 1) -> Optional[int]:
        """Decrement key value."""
        try:
            return await self.client.decrby(key, amount)
        except Exception as e:
            logger.error(f"Redis decr failed for key {key}: {e}")
            return None
    
    async def hget(self, name: str, key: str) -> Optional[Any]:
        """Get hash field value."""
        try:
            value = await self.client.hget(name, key)
            if value:
                return json.loads(value)
            return None
        except Exception as e:
            logger.error(f"Redis hget failed for {name}:{key}: {e}")
            return None
    
    async def hset(self, name: str, key: str, value: Any) -> bool:
        """Set hash field value."""
        try:
            serialized_value = json.dumps(value, default=str)
            result = await self.client.hset(name, key, serialized_value)
            return bool(result)
        except Exception as e:
            logger.error(f"Redis hset failed for {name}:{key}: {e}")
            return False
    
    async def hgetall(self, name: str) -> Dict[str, Any]:
        """Get all hash fields."""
        try:
            data = await self.client.hgetall(name)
            result = {}
            for key, value in data.items():
                try:
                    result[key] = json.loads(value)
                except json.JSONDecodeError:
                    result[key] = value
            return result
        except Exception as e:
            logger.error(f"Redis hgetall failed for {name}: {e}")
            return {}
    
    async def hdel(self, name: str, *keys: str) -> int:
        """Delete hash fields."""
        try:
            return await self.client.hdel(name, *keys)
        except Exception as e:
            logger.error(f"Redis hdel failed for {name}: {e}")
            return 0
    
    async def sadd(self, name: str, *values: Any) -> int:
        """Add values to set."""
        try:
            serialized_values = [json.dumps(v, default=str) for v in values]
            return await self.client.sadd(name, *serialized_values)
        except Exception as e:
            logger.error(f"Redis sadd failed for {name}: {e}")
            return 0
    
    async def smembers(self, name: str) -> set:
        """Get all set members."""
        try:
            members = await self.client.smembers(name)
            result = set()
            for member in members:
                try:
                    result.add(json.loads(member))
                except json.JSONDecodeError:
                    result.add(member)
            return result
        except Exception as e:
            logger.error(f"Redis smembers failed for {name}: {e}")
            return set()
    
    async def srem(self, name: str, *values: Any) -> int:
        """Remove values from set."""
        try:
            serialized_values = [json.dumps(v, default=str) for v in values]
            return await self.client.srem(name, *serialized_values)
        except Exception as e:
            logger.error(f"Redis srem failed for {name}: {e}")
            return 0
    
    async def lpush(self, name: str, *values: Any) -> int:
        """Push values to list."""
        try:
            serialized_values = [json.dumps(v, default=str) for v in values]
            return await self.client.lpush(name, *serialized_values)
        except Exception as e:
            logger.error(f"Redis lpush failed for {name}: {e}")
            return 0
    
    async def rpop(self, name: str) -> Optional[Any]:
        """Pop value from list."""
        try:
            value = await self.client.rpop(name)
            if value:
                return json.loads(value)
            return None
        except Exception as e:
            logger.error(f"Redis rpop failed for {name}: {e}")
            return None
    
    async def llen(self, name: str) -> int:
        """Get list length."""
        try:
            return await self.client.llen(name)
        except Exception as e:
            logger.error(f"Redis llen failed for {name}: {e}")
            return 0
    
    async def flushdb(self) -> bool:
        """Flush current database."""
        try:
            await self.client.flushdb()
            return True
        except Exception as e:
            logger.error(f"Redis flushdb failed: {e}")
            return False
    
    async def info(self) -> Dict[str, Any]:
        """Get Redis server info."""
        try:
            info = await self.client.info()
            return info
        except Exception as e:
            logger.error(f"Redis info failed: {e}")
            return {}
    
    async def health_check(self) -> Dict[str, Any]:
        """Check Redis health."""
        try:
            # Test basic connectivity
            ping_result = await self.ping()
            if not ping_result:
                return {
                    "status": "unhealthy",
                    "error": "Ping failed"
                }
            
            # Get server info
            info = await self.info()
            
            # Test basic operations
            test_key = "health_check_test"
            test_value = {"timestamp": datetime.utcnow().isoformat()}
            
            await self.set(test_key, test_value, ttl=10)
            retrieved_value = await self.get(test_key)
            await self.delete(test_key)
            
            if retrieved_value != test_value:
                return {
                    "status": "unhealthy",
                    "error": "Read/write test failed"
                }
            
            return {
                "status": "healthy",
                "version": info.get("redis_version", "unknown"),
                "memory_used": info.get("used_memory_human", "unknown"),
                "connected_clients": info.get("connected_clients", 0),
                "uptime": info.get("uptime_in_seconds", 0)
            }
            
        except Exception as e:
            logger.error(f"Redis health check failed: {e}")
            return {
                "status": "unhealthy",
                "error": str(e)
            }
    
    async def close(self):
        """Close Redis connection."""
        try:
            await self.client.close()
        except Exception as e:
            logger.error(f"Failed to close Redis connection: {e}")


# Global Redis client instance
_redis_client: Optional[RedisClient] = None


def get_redis_client() -> RedisClient:
    """Get Redis client instance."""
    global _redis_client
    if _redis_client is None:
        _redis_client = RedisClient()
    return _redis_client


@asynccontextmanager
async def get_redis_session():
    """Context manager for Redis operations."""
    client = get_redis_client()
    try:
        yield client
    finally:
        # Don't close the global client
        pass


# Cache helper functions
async def cache_get(key: str, default: Any = None) -> Any:
    """Get value from cache."""
    if not config.ENABLE_REDIS_CACHE:
        return default
    
    client = get_redis_client()
    value = await client.get(key)
    return value if value is not None else default


async def cache_set(key: str, value: Any, ttl: Optional[int] = None) -> bool:
    """Set value in cache."""
    if not config.ENABLE_REDIS_CACHE:
        return False
    
    client = get_redis_client()
    return await client.set(key, value, ttl)


async def cache_delete(key: str) -> bool:
    """Delete value from cache."""
    if not config.ENABLE_REDIS_CACHE:
        return False
    
    client = get_redis_client()
    return await client.delete(key)


async def cache_exists(key: str) -> bool:
    """Check if key exists in cache."""
    if not config.ENABLE_REDIS_CACHE:
        return False
    
    client = get_redis_client()
    return await client.exists(key)


# Session management
async def create_session(user_id: str, session_data: Dict[str, Any], ttl: int = 3600) -> str:
    """Create user session."""
    session_id = f"session:{user_id}:{datetime.utcnow().timestamp()}"
    session_data["created_at"] = datetime.utcnow().isoformat()
    session_data["user_id"] = user_id
    
    client = get_redis_client()
    await client.set(session_id, session_data, ttl)
    return session_id


async def get_session(session_id: str) -> Optional[Dict[str, Any]]:
    """Get user session."""
    client = get_redis_client()
    return await client.get(session_id)


async def update_session(session_id: str, session_data: Dict[str, Any], ttl: Optional[int] = None) -> bool:
    """Update user session."""
    client = get_redis_client()
    return await client.set(session_id, session_data, ttl)


async def delete_session(session_id: str) -> bool:
    """Delete user session."""
    client = get_redis_client()
    return await client.delete(session_id)


# Rate limiting
async def check_rate_limit(identifier: str, limit: int, window: int = 60) -> Dict[str, Any]:
    """Check rate limit for identifier."""
    key = f"rate_limit:{identifier}"
    client = get_redis_client()
    
    # Get current count
    current_count = await client.get(key) or 0
    current_count = int(current_count)
    
    if current_count >= limit:
        return {
            "allowed": False,
            "current_count": current_count,
            "limit": limit,
            "reset_time": window
        }
    
    # Increment counter
    await client.incr(key)
    if current_count == 0:
        await client.expire(key, window)
    
    return {
        "allowed": True,
        "current_count": current_count + 1,
        "limit": limit,
        "reset_time": window
    }
