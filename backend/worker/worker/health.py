"""Worker health check endpoints (if needed for monitoring).
For Celery workers, health is typically checked via celery inspect commands.
This module provides optional HTTP endpoints if worker runs alongside a FastAPI server.
"""
from typing import Dict, Any

try:
    from backend.common.health import readiness
except ImportError:  # pragma: no cover
    readiness = None


def worker_health() -> Dict[str, Any]:
    """Basic worker health status."""
    return {"status": "ok", "worker": "celery"}


def worker_readyz() -> Dict[str, Any]:
    """Worker readiness check."""
    # Could check Celery broker connection, Redis availability, etc.
    return {"ready": True, "worker": "celery"}


__all__ = ["worker_health", "worker_readyz"]
