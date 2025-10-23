"""
Infrastructure Database Session Management
=========================================
Database session management for the infrastructure layer.
"""

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import QueuePool
from sqlalchemy import text
from typing import AsyncGenerator
import logging

from .base import Base
from ...config import config

logger = logging.getLogger(__name__)

# Create async engine
async_engine = create_async_engine(
    config.DATABASE_URL,
    pool_size=config.DB_POOL_SIZE,
    max_overflow=config.DB_MAX_OVERFLOW,
    pool_timeout=config.DB_POOL_TIMEOUT,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=config.DB_ECHO,
    future=True
)

# Create session maker
async_session_local = async_sessionmaker(
    async_engine,
    class_=AsyncSession,
    expire_on_commit=False
)


async def get_async_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency for async database sessions.
    Provides database session with automatic cleanup.
    """
    async with async_session_local() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_database():
    """Initialize database tables."""
    try:
        async with async_engine.begin() as conn:
            # Create all tables
            await conn.run_sync(Base.metadata.create_all)
            logger.info("Database tables created successfully")
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        raise


async def check_database_health() -> dict:
    """Check database health and return status."""
    try:
        async with async_session_local() as session:
            # Test basic connectivity
            result = await session.execute(text("SELECT 1"))
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
            
            # Get connection pool stats (async pools have different attributes)
            pool = async_engine.pool
            try:
                pool_stats = {
                    "size": pool.size(),
                    "checked_in": pool.checkedin(),
                    "checked_out": pool.checkedout(),
                    "overflow": pool.overflow(),
                }
                # Only add invalid if the attribute exists
                if hasattr(pool, 'invalid'):
                    pool_stats["invalid"] = pool.invalid()
                else:
                    pool_stats["invalid"] = 0  # Async pools don't track invalid connections the same way
            except Exception as pool_error:
                logger.warning(f"Could not get pool stats: {pool_error}")
                pool_stats = {
                    "size": "unknown",
                    "checked_in": "unknown", 
                    "checked_out": "unknown",
                    "overflow": "unknown",
                    "invalid": "unknown"
                }
            
            return {
                "status": "healthy",
                "version": version.split(',')[0] if version else "unknown",
                "table_count": table_count,
                "pool_stats": pool_stats
            }
            
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return {
            "status": "unhealthy",
            "error": str(e)
        }
