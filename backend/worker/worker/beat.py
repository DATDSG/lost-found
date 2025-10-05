"""Celery beat schedule and periodic maintenance tasks.

Adds a periodic refresh for mv_recent_items materialized view if it exists.
"""
from __future__ import annotations
import os
from celery import Celery
from celery.schedules import crontab
import logging
import psycopg2

logger = logging.getLogger(__name__)

REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")
celery = Celery('worker_beat', broker=REDIS_URL, backend=REDIS_URL)

celery.conf.timezone = 'UTC'

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://lostfound:lostfound@postgres:5432/lostfound")
MV_NAME = os.getenv("RECENT_ITEMS_MV", "mv_recent_items")
MV_REFRESH_MINUTES = int(os.getenv("RECENT_ITEMS_MV_REFRESH_MINUTES", "10"))
ENABLE_MV_REFRESH = os.getenv("ENABLE_MV_REFRESH", "true").lower() in {"1","true","yes"}

@celery.task(name="maintenance.refresh_recent_items_mv")
def refresh_recent_items_mv():
    if not ENABLE_MV_REFRESH:
        logger.info("MV refresh disabled via ENABLE_MV_REFRESH")
        return "disabled"
    try:
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = True
        cur = conn.cursor()
        cur.execute("SELECT to_regclass(%s)", (MV_NAME,))
        exists = cur.fetchone()[0] is not None
        if not exists:
            logger.warning("Materialized view %s not found; skipping", MV_NAME)
            return "missing"
        logger.info("Refreshing materialized view %s CONCURRENTLY", MV_NAME)
        cur.execute(f"REFRESH MATERIALIZED VIEW CONCURRENTLY {MV_NAME};")
        return "refreshed"
    except Exception as e:
        logger.exception("Failed to refresh MV: %s", e)
        return f"error:{e}"
    finally:
        try:
            cur.close(); conn.close()
        except Exception:
            pass

# Dynamic schedule registration
if ENABLE_MV_REFRESH:
    celery.conf.beat_schedule = {
        'refresh-mv-recent-items': {
            'task': 'maintenance.refresh_recent_items_mv',
            'schedule': MV_REFRESH_MINUTES * 60,
        }
    }
