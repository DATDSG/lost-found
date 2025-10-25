"""
Advanced Caching System
======================
Comprehensive caching implementation with Redis, in-memory, and multi-level caching.
"""

import json
import time
import hashlib
import pickle
from typing import Any, Dict, List, Optional, Union, Callable
from functools import wraps
import asyncio
import logging
from datetime import datetime, timedelta

try:
    import redis.asyncio as redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False

logger = logging.getLogger(__name__)


class CacheConfig:
    """Cache configuration settings."""
    
    # Redis settings
    REDIS_URL = "redis://:LF_Redis_2025_Pass!@redis:6379/0"
    REDIS_MAX_CONNECTIONS = 20
    REDIS_TIMEOUT = 5
    
    # Cache TTL settings (in seconds)
    DEFAULT_TTL = 300  # 5 minutes
    SHORT_TTL = 60     # 1 minute
    MEDIUM_TTL = 600   # 10 minutes
    LONG_TTL = 3600    # 1 hour
    VERY_LONG_TTL = 86400  # 24 hours
    
    # Cache size limits
    MAX_MEMORY_CACHE_SIZE = 1000
    MAX_RESPONSE_CACHE_SIZE = 500
    
    # Cache strategies
    ENABLE_REDIS_CACHE = True
    ENABLE_MEMORY_CACHE = True
    ENABLE_RESPONSE_CACHE = True
    ENABLE_QUERY_CACHE = True
    ENABLE_FUNCTION_CACHE = True


class MemoryCache:
    """In-memory cache implementation."""
    
    def __init__(self, max_size: int = CacheConfig.MAX_MEMORY_CACHE_SIZE):
        self.max_size = max_size
        self.cache: Dict[str, Dict[str, Any]] = {}
        self.access_times: Dict[str, float] = {}
    
    def _generate_key(self, prefix: str, *args, **kwargs) -> str:
        """Generate cache key from arguments."""
        key_data = {
            'args': args,
            'kwargs': sorted(kwargs.items())
        }
        key_string = json.dumps(key_data, sort_keys=True)
        return f"{prefix}:{hashlib.md5(key_string.encode()).hexdigest()}"
    
    def get(self, key: str) -> Optional[Any]:
        """Get value from cache."""
        if key not in self.cache:
            return None
        
        cache_entry = self.cache[key]
        
        # Check TTL
        if cache_entry.get('expires_at') and time.time() > cache_entry['expires_at']:
            self.delete(key)
            return None
        
        # Update access time
        self.access_times[key] = time.time()
        
        return cache_entry['value']
    
    def set(self, key: str, value: Any, ttl: int = CacheConfig.DEFAULT_TTL) -> None:
        """Set value in cache."""
        # Remove oldest entries if cache is full
        if len(self.cache) >= self.max_size:
            self._evict_oldest()
        
        expires_at = time.time() + ttl if ttl > 0 else None
        
        self.cache[key] = {
            'value': value,
            'expires_at': expires_at,
            'created_at': time.time()
        }
        self.access_times[key] = time.time()
    
    def delete(self, key: str) -> bool:
        """Delete key from cache."""
        if key in self.cache:
            del self.cache[key]
            if key in self.access_times:
                del self.access_times[key]
            return True
        return False
    
    def clear(self) -> None:
        """Clear all cache entries."""
        self.cache.clear()
        self.access_times.clear()
    
    def _evict_oldest(self) -> None:
        """Evict oldest accessed entries."""
        if not self.access_times:
            return
        
        # Remove 10% of oldest entries
        entries_to_remove = max(1, len(self.access_times) // 10)
        oldest_keys = sorted(self.access_times.items(), key=lambda x: x[1])[:entries_to_remove]
        
        for key, _ in oldest_keys:
            self.delete(key)
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        return {
            'size': len(self.cache),
            'max_size': self.max_size,
            'hit_rate': 'calculated_externally',
            'keys': list(self.cache.keys())
        }


class RedisCache:
    """Redis cache implementation."""
    
    def __init__(self, redis_url: str = CacheConfig.REDIS_URL):
        self.redis_url = redis_url
        self.redis_client: Optional[redis.Redis] = None
        self.connected = False
    
    async def connect(self) -> bool:
        """Connect to Redis."""
        if not REDIS_AVAILABLE:
            logger.warning("Redis not available, using memory cache only")
            return False
        
        try:
            self.redis_client = redis.from_url(
                self.redis_url,
                max_connections=CacheConfig.REDIS_MAX_CONNECTIONS,
                socket_timeout=CacheConfig.REDIS_TIMEOUT,
                socket_connect_timeout=CacheConfig.REDIS_TIMEOUT,
                retry_on_timeout=True,
                decode_responses=True
            )
            
            # Test connection
            await self.redis_client.ping()
            self.connected = True
            logger.info("Connected to Redis cache")
            return True
            
        except Exception as e:
            logger.error(f"Failed to connect to Redis: {e}")
            self.connected = False
            return False
    
    async def disconnect(self) -> None:
        """Disconnect from Redis."""
        if self.redis_client:
            await self.redis_client.close()
            self.connected = False
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from Redis cache."""
        if not self.connected or not self.redis_client:
            return None
        
        try:
            value = await self.redis_client.get(key)
            if value is None:
                return None
            
            # Try to deserialize JSON first, then pickle
            try:
                return json.loads(value)
            except (json.JSONDecodeError, TypeError):
                try:
                    return pickle.loads(value.encode('latin1'))
                except:
                    return value
                    
        except Exception as e:
            logger.error(f"Redis get error: {e}")
            return None
    
    async def set(self, key: str, value: Any, ttl: int = CacheConfig.DEFAULT_TTL) -> bool:
        """Set value in Redis cache."""
        if not self.connected or not self.redis_client:
            return False
        
        try:
            # Try to serialize as JSON first, then pickle
            try:
                serialized_value = json.dumps(value)
            except (TypeError, ValueError):
                serialized_value = pickle.dumps(value).decode('latin1')
            
            await self.redis_client.setex(key, ttl, serialized_value)
            return True
            
        except Exception as e:
            logger.error(f"Redis set error: {e}")
            return False
    
    async def delete(self, key: str) -> bool:
        """Delete key from Redis cache."""
        if not self.connected or not self.redis_client:
            return False
        
        try:
            result = await self.redis_client.delete(key)
            return result > 0
        except Exception as e:
            logger.error(f"Redis delete error: {e}")
            return False
    
    async def clear(self) -> bool:
        """Clear all Redis cache entries."""
        if not self.connected or not self.redis_client:
            return False
        
        try:
            await self.redis_client.flushdb()
            return True
        except Exception as e:
            logger.error(f"Redis clear error: {e}")
            return False
    
    async def get_stats(self) -> Dict[str, Any]:
        """Get Redis cache statistics."""
        if not self.connected or not self.redis_client:
            return {'connected': False}
        
        try:
            info = await self.redis_client.info()
            return {
                'connected': True,
                'used_memory': info.get('used_memory_human', 'unknown'),
                'connected_clients': info.get('connected_clients', 0),
                'keyspace_hits': info.get('keyspace_hits', 0),
                'keyspace_misses': info.get('keyspace_misses', 0),
                'total_commands_processed': info.get('total_commands_processed', 0)
            }
        except Exception as e:
            logger.error(f"Redis stats error: {e}")
            return {'connected': False, 'error': str(e)}


class MultiLevelCache:
    """Multi-level cache implementation (Memory + Redis)."""
    
    def __init__(self):
        self.memory_cache = MemoryCache()
        self.redis_cache = RedisCache()
        self.cache_hits = {'memory': 0, 'redis': 0, 'miss': 0}
        self.cache_operations = {'get': 0, 'set': 0, 'delete': 0}
    
    async def initialize(self) -> None:
        """Initialize cache system."""
        await self.redis_cache.connect()
    
    async def shutdown(self) -> None:
        """Shutdown cache system."""
        await self.redis_cache.disconnect()
    
    def _generate_key(self, prefix: str, *args, **kwargs) -> str:
        """Generate cache key from arguments."""
        key_data = {
            'args': args,
            'kwargs': sorted(kwargs.items())
        }
        key_string = json.dumps(key_data, sort_keys=True)
        return f"{prefix}:{hashlib.md5(key_string.encode()).hexdigest()}"
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from multi-level cache."""
        self.cache_operations['get'] += 1
        
        # Try memory cache first
        value = self.memory_cache.get(key)
        if value is not None:
            self.cache_hits['memory'] += 1
            return value
        
        # Try Redis cache
        value = await self.redis_cache.get(key)
        if value is not None:
            self.cache_hits['redis'] += 1
            # Store in memory cache for faster access
            self.memory_cache.set(key, value, CacheConfig.SHORT_TTL)
            return value
        
        self.cache_hits['miss'] += 1
        return None
    
    async def set(self, key: str, value: Any, ttl: int = CacheConfig.DEFAULT_TTL) -> bool:
        """Set value in multi-level cache."""
        self.cache_operations['set'] += 1
        
        # Set in memory cache
        self.memory_cache.set(key, value, min(ttl, CacheConfig.SHORT_TTL))
        
        # Set in Redis cache
        return await self.redis_cache.set(key, value, ttl)
    
    async def delete(self, key: str) -> bool:
        """Delete key from multi-level cache."""
        self.cache_operations['delete'] += 1
        
        # Delete from memory cache
        memory_deleted = self.memory_cache.delete(key)
        
        # Delete from Redis cache
        redis_deleted = await self.redis_cache.delete(key)
        
        return memory_deleted or redis_deleted
    
    async def clear(self) -> bool:
        """Clear all cache levels."""
        self.memory_cache.clear()
        return await self.redis_cache.clear()
    
    def get_hit_rate(self) -> float:
        """Calculate cache hit rate."""
        total_hits = sum(self.cache_hits.values())
        if total_hits == 0:
            return 0.0
        
        hits = self.cache_hits['memory'] + self.cache_hits['redis']
        return (hits / total_hits) * 100
    
    async def get_stats(self) -> Dict[str, Any]:
        """Get comprehensive cache statistics."""
        memory_stats = self.memory_cache.get_stats()
        redis_stats = await self.redis_cache.get_stats()
        
        return {
            'memory_cache': memory_stats,
            'redis_cache': redis_stats,
            'hit_rate': self.get_hit_rate(),
            'cache_hits': self.cache_hits,
            'cache_operations': self.cache_operations
        }


# Global cache instance
cache = MultiLevelCache()


def cached(prefix: str, ttl: int = CacheConfig.DEFAULT_TTL, cache_key_func: Optional[Callable] = None):
    """Decorator for caching function results."""
    def decorator(func):
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            # Generate cache key
            if cache_key_func:
                key = cache_key_func(*args, **kwargs)
            else:
                key = cache._generate_key(prefix, *args, **kwargs)
            
            # Try to get from cache
            cached_result = await cache.get(key)
            if cached_result is not None:
                return cached_result
            
            # Execute function and cache result
            result = await func(*args, **kwargs)
            await cache.set(key, result, ttl)
            return result
        
        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            # Generate cache key
            if cache_key_func:
                key = cache_key_func(*args, **kwargs)
            else:
                key = cache._generate_key(prefix, *args, **kwargs)
            
            # Try to get from cache
            cached_result = cache.memory_cache.get(key)
            if cached_result is not None:
                return cached_result
            
            # Execute function and cache result
            result = func(*args, **kwargs)
            cache.memory_cache.set(key, result, ttl)
            return result
        
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator


class CacheManager:
    """Centralized cache management."""
    
    def __init__(self):
        self.cache = cache
        self.enabled = True
    
    async def initialize(self) -> None:
        """Initialize cache manager."""
        await self.cache.initialize()
    
    async def shutdown(self) -> None:
        """Shutdown cache manager."""
        await self.cache.shutdown()
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from cache."""
        if not self.enabled:
            return None
        return await self.cache.get(key)
    
    async def set(self, key: str, value: Any, ttl: int = CacheConfig.DEFAULT_TTL) -> bool:
        """Set value in cache."""
        if not self.enabled:
            return False
        return await self.cache.set(key, value, ttl)
    
    async def delete(self, key: str) -> bool:
        """Delete key from cache."""
        if not self.enabled:
            return False
        return await self.cache.delete(key)
    
    async def clear(self) -> bool:
        """Clear all cache."""
        if not self.enabled:
            return False
        return await self.cache.clear()
    
    async def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        return await self.cache.get_stats()
    
    def enable(self) -> None:
        """Enable caching."""
        self.enabled = True
    
    def disable(self) -> None:
        """Disable caching."""
        self.enabled = False


# Global cache manager
cache_manager = CacheManager()


# Cache decorators for different use cases
def cache_response(ttl: int = CacheConfig.MEDIUM_TTL):
    """Cache API response data."""
    return cached("response", ttl)

def cache_query(ttl: int = CacheConfig.MEDIUM_TTL):
    """Cache database query results."""
    return cached("query", ttl)

def cache_function(ttl: int = CacheConfig.DEFAULT_TTL):
    """Cache function results."""
    return cached("function", ttl)

def cache_nlp_result(ttl: int = CacheConfig.LONG_TTL):
    """Cache NLP processing results."""
    return cached("nlp", ttl)

def cache_vision_result(ttl: int = CacheConfig.LONG_TTL):
    """Cache vision processing results."""
    return cached("vision", ttl)

def cache_match_result(ttl: int = CacheConfig.MEDIUM_TTL):
    """Cache matching algorithm results."""
    return cached("match", ttl)


# Cache utilities
class CacheUtils:
    """Cache utility functions."""
    
    @staticmethod
    def generate_key(prefix: str, *args, **kwargs) -> str:
        """Generate cache key."""
        key_data = {
            'args': args,
            'kwargs': sorted(kwargs.items())
        }
        key_string = json.dumps(key_data, sort_keys=True)
        return f"{prefix}:{hashlib.md5(key_string.encode()).hexdigest()}"
    
    @staticmethod
    def get_ttl_for_data_type(data_type: str) -> int:
        """Get appropriate TTL for data type."""
        ttl_map = {
            'user': CacheConfig.MEDIUM_TTL,
            'report': CacheConfig.MEDIUM_TTL,
            'match': CacheConfig.SHORT_TTL,
            'nlp': CacheConfig.LONG_TTL,
            'vision': CacheConfig.LONG_TTL,
            'query': CacheConfig.MEDIUM_TTL,
            'response': CacheConfig.SHORT_TTL,
            'static': CacheConfig.VERY_LONG_TTL
        }
        return ttl_map.get(data_type, CacheConfig.DEFAULT_TTL)
    
    @staticmethod
    async def warm_cache(keys_and_values: List[tuple], ttl: int = CacheConfig.DEFAULT_TTL) -> None:
        """Warm cache with multiple key-value pairs."""
        for key, value in keys_and_values:
            await cache_manager.set(key, value, ttl)
    
    @staticmethod
    async def invalidate_pattern(pattern: str) -> int:
        """Invalidate cache entries matching pattern."""
        # This would require Redis SCAN command implementation
        # For now, return 0
        return 0


# Initialize cache system
async def initialize_cache_system():
    """Initialize the cache system."""
    await cache_manager.initialize()
    logger.info("Cache system initialized successfully")

async def shutdown_cache_system():
    """Shutdown the cache system."""
    await cache_manager.shutdown()
    logger.info("Cache system shutdown complete")
