"""Background task processing for NLP and Vision services."""
import logging
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from .models import Report, Media
from .clients import get_nlp_client, get_vision_client
from .config import config
from .database import AsyncSessionLocal

logger = logging.getLogger(__name__)


async def process_report_background_task(report_id: str):
    """
    Background task entry point for processing a report.
    Creates its own database session and runs the complete processing pipeline.
    
    Args:
        report_id: ID of the report to process
    """
    db = AsyncSessionLocal()
    
    try:
        logger.info(f"Starting background processing for report {report_id}")
        results = await process_report_complete(report_id, db)
        logger.info(f"Completed background processing for report {report_id}: {results}")
    except Exception as e:
        logger.error(f"Error in background task for report {report_id}: {e}")
    finally:
        await db.close()


async def process_report_embedding(
    report_id: str,
    db: AsyncSession
) -> bool:
    """
    Generate text embedding for a report using NLP service.
    
    Args:
        report_id: ID of the report to process
        db: Database session
    
    Returns:
        True if successful, False otherwise
    """
    try:
        # Get report
        result = await db.execute(
            select(Report).where(Report.id == report_id)
        )
        report = result.scalar_one_or_none()
        
        if not report:
            logger.error(f"Report {report_id} not found for embedding generation")
            return False
        
        if not report.description:
            logger.warning(f"Report {report_id} has no description, skipping embedding")
            return False
        
        # Generate embedding using NLP service
        async with get_nlp_client() as nlp_client:
            embedding = await nlp_client.get_embedding(report.description)
        
        if not embedding:
            logger.error(f"Failed to generate embedding for report {report_id}")
            return False
        
        # Update report with embedding
        report.embedding = embedding
        await db.commit()
        
        logger.info(f"✅ Generated embedding for report {report_id}")
        return True
        
    except Exception as e:
        logger.error(f"Error generating embedding for report {report_id}: {e}")
        return False


async def process_media_hash(
    media_id: str,
    db: AsyncSession
) -> bool:
    """
    Generate perceptual hash for media using Vision service.
    
    Args:
        media_id: ID of the media to process
        db: Database session
    
    Returns:
        True if successful, False otherwise
    """
    try:
        # Get media
        result = await db.execute(
            select(Media).where(Media.id == media_id)
        )
        media = result.scalar_one_or_none()
        
        if not media:
            logger.error(f"Media {media_id} not found for hash generation")
            return False
        
        # Get file path
        import os
        file_path = os.path.join(config.MEDIA_ROOT, media.filename)
        
        if not os.path.exists(file_path):
            logger.error(f"Media file not found: {file_path}")
            return False
        
        # Generate hash using Vision service
        async with get_vision_client() as vision_client:
            image_hash = await vision_client.get_image_hash(file_path)
        
        if not image_hash:
            logger.error(f"Failed to generate hash for media {media_id}")
            return False
        
        # Update media with hashes
        media.phash_hex = image_hash
        
        # Also update the report's image_hash if this is the first media
        if media.report_id:
            result = await db.execute(
                select(Report).where(Report.id == media.report_id)
            )
            report = result.scalar_one_or_none()
            
            if report and not report.image_hash:
                report.image_hash = image_hash
        
        await db.commit()
        
        logger.info(f"✅ Generated hash for media {media_id}")
        return True
        
    except Exception as e:
        logger.error(f"Error generating hash for media {media_id}: {e}")
        return False


async def run_matching_pipeline(
    report_id: str,
    db: AsyncSession
) -> int:
    """
    Run the matching pipeline for a report.
    
    Args:
        report_id: ID of the report to find matches for
        db: Database session
    
    Returns:
        Number of matches found
    """
    try:
        # Get report
        result = await db.execute(
            select(Report).where(Report.id == report_id)
        )
        report = result.scalar_one_or_none()
        
        if not report:
            logger.error(f"Report {report_id} not found for matching")
            return 0
        
        # Check if report has embedding (required for matching)
        if not report.embedding:
            logger.warning(f"Report {report_id} has no embedding, cannot run matching")
            return 0
        
        # Import matching pipeline
        from .matching import get_matching_pipeline
        
        # Run matching
        pipeline = await get_matching_pipeline(db)
        matches = await pipeline.find_matches(report, max_results=config.MATCH_MAX_RESULTS)
        
        if matches:
            # Store matches in database
            from .models import Match, MatchStatus
            from uuid import uuid4
            
            for match_data in matches:
                # Check if match already exists
                existing_result = await db.execute(
                    select(Match).where(
                        Match.source_report_id == report_id,
                        Match.candidate_report_id == match_data["candidate_id"]
                    )
                )
                existing_match = existing_result.scalar_one_or_none()
                
                if not existing_match:
                    # Create new match
                    match = Match(
                        id=str(uuid4()),
                        source_report_id=report_id,
                        candidate_report_id=match_data["candidate_id"],
                        status=MatchStatus.CANDIDATE,
                        score_total=match_data["score"],
                        score_text=match_data["scores"].get("text"),
                        score_image=match_data["scores"].get("image"),
                        score_geo=match_data["scores"].get("geo"),
                        score_time=match_data["scores"].get("time")
                    )
                    db.add(match)
            
            await db.commit()
            logger.info(f"✅ Found and stored {len(matches)} matches for report {report_id}")
            
            return len(matches)
        else:
            logger.info(f"No matches found for report {report_id}")
            return 0
        
    except Exception as e:
        logger.error(f"Error running matching pipeline for report {report_id}: {e}")
        return 0


async def process_report_complete(
    report_id: str,
    db: AsyncSession
) -> dict:
    """
    Complete processing pipeline for a report: embedding → matching.
    
    Args:
        report_id: ID of the report to process
        db: Database session
    
    Returns:
        Dictionary with processing results
    """
    results = {
        "report_id": report_id,
        "embedding_generated": False,
        "matches_found": 0,
        "errors": []
    }
    
    try:
        # Step 1: Generate embedding
        embedding_success = await process_report_embedding(report_id, db)
        results["embedding_generated"] = embedding_success
        
        if not embedding_success:
            results["errors"].append("Failed to generate embedding")
            return results
        
        # Step 2: Run matching pipeline
        matches_count = await run_matching_pipeline(report_id, db)
        results["matches_found"] = matches_count
        
        logger.info(f"✅ Completed processing for report {report_id}: {matches_count} matches found")
        
    except Exception as e:
        logger.error(f"Error in complete processing for report {report_id}: {e}")
        results["errors"].append(str(e))
    
    return results

