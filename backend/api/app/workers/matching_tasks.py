"""
Background tasks for matching items.

Handles asynchronous matching job processing using RQ (Redis Queue).
"""

from typing import Optional
from loguru import logger
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.db.session import SessionLocal
from app.db.models import Item, AuditLog
from app.services.matching import MatchingService
from app.core.config import settings


def trigger_matching_job(item_id: int) -> None:
    """
    Trigger background matching job for an item.
    
    This function is called as a background task when items are created/updated.
    """
    if not settings.ENV == "test":  # Skip in tests
        from rq import Queue
        import redis
        
        redis_conn = redis.from_url(settings.REDIS_URL)
        queue = Queue(settings.RQ_DEFAULT_QUEUE, connection=redis_conn)
        
        # Enqueue the matching job
        job = queue.enqueue(
            process_item_matching,
            item_id,
            job_timeout='5m',
            description=f"Match item {item_id}"
        )
        
        logger.info(f"Enqueued matching job {job.id} for item {item_id}")


def process_item_matching(item_id: int) -> dict:
    """
    Process matching for a specific item.
    
    This is the actual worker function that runs in the background.
    """
    db = SessionLocal()
    try:
        # Get the item
        item = db.query(Item).filter(Item.id == item_id).first()
        if not item:
            logger.warning(f"Item {item_id} not found for matching")
            return {"status": "error", "message": "Item not found"}
        
        logger.info(f"Processing matching for item {item_id} ({item.status})")
        
        # Initialize matching service
        matching_service = MatchingService(db)
        
        # Find matches
        matches = matching_service.find_matches(item, limit=settings.TOP_K_MATCHES)
        
        if not matches:
            logger.info(f"No matches found for item {item_id}")
            return {"status": "success", "matches_found": 0}
        
        # Save matches to database
        saved_matches = matching_service.save_matches(item, matches)
        
        logger.info(f"Found and saved {len(saved_matches)} matches for item {item_id}")
        
        # Create audit log
        audit_log = AuditLog(
            user_id=item.owner_id,
            action="matching.completed",
            resource_type="item",
            resource_id=item.id,
            metadata={
                "matches_found": len(saved_matches),
                "top_score": max([m.score_final for m in saved_matches]) if saved_matches else 0,
                "nlp_enabled": settings.NLP_ON,
                "cv_enabled": settings.CV_ON
            }
        )
        db.add(audit_log)
        db.commit()
        
        # TODO: Send notifications to users about new matches
        # This would be another background task
        
        return {
            "status": "success",
            "matches_found": len(saved_matches),
            "item_id": item_id
        }
        
    except Exception as e:
        logger.error(f"Error processing matching for item {item_id}: {e}")
        db.rollback()
        return {"status": "error", "message": str(e)}
    
    finally:
        db.close()


def reprocess_all_matches() -> dict:
    """
    Reprocess matches for all active items.
    
    Useful when matching algorithm is updated or feature flags change.
    """
    db = SessionLocal()
    try:
        # Get all active items
        active_items = db.query(Item).filter(
            Item.status.in_(["lost", "found"])
        ).all()
        
        logger.info(f"Reprocessing matches for {len(active_items)} active items")
        
        processed = 0
        errors = 0
        
        for item in active_items:
            try:
                result = process_item_matching(item.id)
                if result["status"] == "success":
                    processed += 1
                else:
                    errors += 1
            except Exception as e:
                logger.error(f"Error reprocessing item {item.id}: {e}")
                errors += 1
        
        return {
            "status": "success",
            "total_items": len(active_items),
            "processed": processed,
            "errors": errors
        }
        
    except Exception as e:
        logger.error(f"Error in reprocess_all_matches: {e}")
        return {"status": "error", "message": str(e)}
    
    finally:
        db.close()


def cleanup_old_matches(days_old: int = 30) -> dict:
    """
    Clean up old dismissed matches to keep database lean.
    
    Args:
        days_old: Remove matches older than this many days
    """
    from datetime import datetime, timedelta
    from app.db.models import Match
    
    db = SessionLocal()
    try:
        cutoff_date = datetime.utcnow() - timedelta(days=days_old)
        
        # Delete old dismissed matches
        deleted_count = db.query(Match).filter(
            Match.status == "dismissed",
            Match.updated_at < cutoff_date
        ).delete()
        
        db.commit()
        
        logger.info(f"Cleaned up {deleted_count} old dismissed matches")
        
        return {
            "status": "success",
            "deleted_count": deleted_count
        }
        
    except Exception as e:
        logger.error(f"Error in cleanup_old_matches: {e}")
        db.rollback()
        return {"status": "error", "message": str(e)}
    
    finally:
        db.close()


# Utility functions for manual testing/debugging

def test_matching_for_item(item_id: int) -> dict:
    """Test matching for a specific item (for debugging)."""
    return process_item_matching(item_id)


def get_matching_stats() -> dict:
    """Get statistics about matching performance."""
    db = SessionLocal()
    try:
        from app.db.models import Match
        
        total_matches = db.query(Match).count()
        pending_matches = db.query(Match).filter(Match.status == "pending").count()
        claimed_matches = db.query(Match).filter(Match.status == "claimed").count()
        
        # Average score
        avg_score = db.query(func.avg(Match.score_final)).scalar() or 0
        
        return {
            "total_matches": total_matches,
            "pending_matches": pending_matches,
            "claimed_matches": claimed_matches,
            "average_score": float(avg_score),
            "nlp_enabled": settings.NLP_ON,
            "cv_enabled": settings.CV_ON
        }
        
    finally:
        db.close()
