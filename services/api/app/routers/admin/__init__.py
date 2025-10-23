"""Admin router initialization."""

from fastapi import APIRouter
from . import dashboard, users, reports, audit, bulk_operations, matches, fraud_detection

# Create main admin router
router = APIRouter()

# Include all admin sub-routers
router.include_router(dashboard.router, prefix="/dashboard", tags=["admin-dashboard"])
router.include_router(users.router, prefix="/users", tags=["admin-users"])
router.include_router(reports.router, prefix="/reports", tags=["admin-reports"])
router.include_router(matches.router, prefix="/matches", tags=["admin-matches"])
router.include_router(audit.router, prefix="/audit-logs", tags=["admin-audit"])
router.include_router(fraud_detection.router, prefix="/fraud-detection", tags=["admin-fraud-detection"])
router.include_router(bulk_operations.router, prefix="", tags=["admin-bulk-operations"])

__all__ = ["router"]
