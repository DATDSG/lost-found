"""
Background task worker using ARQ for async job processing.
Handles embedding generation, hash generation, and background processing.
"""
import asyncio
from arq import create_pool
from arq.connections import RedisSettings
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
import logging
from typing import Optional

from app.config import config
from app.clients import get_nlp_client, get_vision_client
from app.models import User
from app.domains.reports.models.report import Report
from app.domains.matches.models.match import Match
from uuid import uuid4

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create async engine for worker
# Convert postgresql:// to postgresql+psycopg:// for async psycopg3 driver
database_url = config.DATABASE_URL
if database_url.startswith("postgresql://"):
    database_url = database_url.replace("postgresql://", "postgresql+psycopg://", 1)

engine = create_async_engine(
    database_url,
    pool_size=5,
    max_overflow=10,
    echo=config.DB_ECHO
)

AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

# Global ARQ pool
_redis_pool = None


async def get_redis_pool():
    """Get or create Redis pool for job enqueueing."""
    global _redis_pool
    if _redis_pool is None:
        _redis_pool = await create_pool(
            RedisSettings.from_dsn(config.ARQ_REDIS_URL)
        )
    return _redis_pool


async def enqueue_vision_hash_generation(media_id: str, file_path: str):
    """Enqueue vision hash generation task."""
    try:
        pool = await get_redis_pool()
        job = await pool.enqueue_job(
            "generate_hash_for_media",
            media_id,
            file_path
        )
        logger.info(f"Enqueued hash generation job {job.job_id} for media {media_id}")
        return job.job_id
    except Exception as e:
        logger.error(f"Failed to enqueue hash generation: {e}")
        return None


async def enqueue_thumbnail_generation(media_id: str, file_path: str):
    """Enqueue thumbnail generation task."""
    try:
        pool = await get_redis_pool()
        job = await pool.enqueue_job(
            "generate_thumbnail",
            media_id,
            file_path
        )
        logger.info(f"Enqueued thumbnail generation job {job.job_id} for media {media_id}")
        return job.job_id
    except Exception as e:
        logger.error(f"Failed to enqueue thumbnail generation: {e}")
        return None


async def get_db_session():
    """Get database session for worker."""
    async with AsyncSessionLocal() as session:
        yield session


async def generate_embedding_task(ctx, report_id: str):
    """Background task to generate text embedding for a report."""
    logger.info(f"Starting embedding generation for report {report_id}")
    
    async for db in get_db_session():
        try:
            # Get report
            result = await db.execute(
                select(Report).where(Report.id == report_id)
            )
            report = result.scalar_one_or_none()
            
            if not report:
                logger.error(f"Report {report_id} not found")
                return {"status": "error", "message": "Report not found"}
            
            if not report.description:
                logger.warning(f"Report {report_id} has no description")
                return {"status": "skipped", "message": "No description"}
            
            # Generate embedding
            async with get_nlp_client() as nlp:
                embedding = await nlp.get_embedding(report.description)
                
                if embedding:
                    report.embedding = embedding
                    await db.commit()
                    logger.info(f"✅ Generated embedding for report {report_id}")
                    return {"status": "success", "report_id": report_id}
                else:
                    logger.error(f"Failed to generate embedding for report {report_id}")
                    return {"status": "error", "message": "Embedding generation failed"}
                    
        except Exception as e:
            logger.error(f"Error in embedding task for report {report_id}: {e}")
            await db.rollback()
            return {"status": "error", "message": str(e)}


async def generate_hash_task(ctx, report_id: str, image_url: str):
    """Background task to generate image hash for a report."""
    logger.info(f"Starting hash generation for report {report_id}")
    
    async for db in get_db_session():
        try:
            # Get report
            result = await db.execute(
                select(Report).where(Report.id == report_id)
            )
            report = result.scalar_one_or_none()
            
            if not report:
                logger.error(f"Report {report_id} not found")
                return {"status": "error", "message": "Report not found"}
            
            # Generate image hash
            async with get_vision_client() as vision:
                image_hash = await vision.get_image_hash(image_url)
                
                if image_hash:
                    report.image_hash = image_hash
                    await db.commit()
                    logger.info(f"✅ Generated hash for report {report_id}")
                    return {"status": "success", "report_id": report_id, "hash": image_hash}
                else:
                    logger.error(f"Failed to generate hash for report {report_id}")
                    return {"status": "error", "message": "Hash generation failed"}
                    
        except Exception as e:
            logger.error(f"Error in hash task for report {report_id}: {e}")
            await db.rollback()
            return {"status": "error", "message": str(e)}




async def process_new_report_task(ctx, report_id: str, has_image: bool = False, image_url: str = None):
    """
    Comprehensive task to process a new report:
    1. Generate text embedding
    2. Generate image hash (if applicable)
    3. Find matches
    """
    logger.info(f"Processing new report {report_id}")
    
    # Step 1: Generate embedding
    embedding_result = await generate_embedding_task(ctx, report_id)
    if embedding_result.get("status") != "success":
        logger.warning(f"Embedding generation failed: {embedding_result}")
    
    # Step 2: Generate hash if image exists
    if has_image and image_url:
        hash_result = await generate_hash_task(ctx, report_id, image_url)
        if hash_result.get("status") != "success":
            logger.warning(f"Hash generation failed: {hash_result}")
    
    # Step 3: Find matches would go here
    # This would require importing the matching pipeline
    logger.info(f"✅ Completed processing for report {report_id}")
    
    return {
        "status": "success",
        "report_id": report_id,
        "embedding": embedding_result.get("status"),
        "hash": hash_result.get("status") if has_image else "skipped"
    }


async def generate_hash_for_media(ctx, media_id: str, file_path: str):
    """Generate perceptual hash for uploaded media."""
    logger.info(f"Generating hash for media {media_id}")
    
    try:
        async with get_vision_client() as vision:
            image_hash = await vision.get_image_hash(file_path)
            
            if image_hash:
                logger.info(f"✅ Generated hash for media {media_id}: {image_hash}")
                return {"status": "success", "media_id": media_id, "hash": image_hash}
            else:
                logger.error(f"Failed to generate hash for media {media_id}")
                return {"status": "error", "message": "Hash generation failed"}
    except Exception as e:
        logger.error(f"Error generating hash for media {media_id}: {e}")
        return {"status": "error", "message": str(e)}


async def generate_thumbnail(ctx, media_id: str, file_path: str):
    """Generate thumbnail for uploaded media."""
    logger.info(f"Generating thumbnail for media {media_id}")
    
    try:
        from PIL import Image
        import os
        
        # Open image
        with Image.open(file_path) as img:
            # Create thumbnail (max 300x300)
            img.thumbnail((300, 300), Image.Resampling.LANCZOS)
            
            # Save thumbnail
            thumbnail_dir = os.path.dirname(file_path).replace("originals", "thumbnails")
            os.makedirs(thumbnail_dir, exist_ok=True)
            
            thumbnail_path = os.path.join(thumbnail_dir, os.path.basename(file_path))
            img.save(thumbnail_path, optimize=True, quality=85)
            
            logger.info(f"✅ Generated thumbnail for media {media_id}")
            return {"status": "success", "media_id": media_id, "thumbnail_path": thumbnail_path}
    except Exception as e:
        logger.error(f"Error generating thumbnail for media {media_id}: {e}")
        return {"status": "error", "message": str(e)}


async def startup(ctx):
    """Worker startup hook."""
    logger.info("🚀 ARQ Worker starting up")
    logger.info(f"Redis URL: {config.ARQ_REDIS_URL}")


async def shutdown(ctx):
    """Worker shutdown hook."""
    logger.info("👋 ARQ Worker shutting down")
    await engine.dispose()


class WorkerSettings:
    """ARQ worker settings."""
    
    functions = [
        generate_embedding_task,
        generate_hash_task,
        process_new_report_task,
        generate_hash_for_media,
        generate_thumbnail,
    ]
    
    redis_settings = RedisSettings.from_dsn(config.ARQ_REDIS_URL)
    
    on_startup = startup
    on_shutdown = shutdown
    
    # Worker configuration
    max_jobs = 10
    job_timeout = config.BACKGROUND_TASK_TIMEOUT
    keep_result = 3600  # Keep results for 1 hour
    
    # Retry configuration
    max_tries = 3
    retry_delay = 60  # 1 minute between retries
