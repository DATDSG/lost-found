"""
Domain Router Integration
========================
Central router that integrates all domain routers into the main application.
Following Domain-Driven Design principles.
"""

from fastapi import APIRouter
from typing import List

# Import domain routers
from .domains.reports.controllers.report_controller import router as reports_router
from .domains.matches.controllers.match_controller import router as matches_router
from .domains.users.controllers.user_controller import router as users_router
from .domains.media.controllers.media_controller import router as media_router
from .domains.taxonomy.controllers.taxonomy_controller import router as taxonomy_router

# Import legacy routers for backward compatibility
from .routers import auth, health, mobile
from .routers.admin import router as admin_router

# Create main domain router
domain_router = APIRouter()

# Include domain routers
domain_router.include_router(reports_router, prefix="/v1/reports", tags=["reports"])
domain_router.include_router(matches_router, prefix="/v1/matches", tags=["matches"])
domain_router.include_router(users_router, prefix="/v1/users", tags=["users"])
domain_router.include_router(media_router, prefix="/v1/media", tags=["media"])
domain_router.include_router(taxonomy_router, prefix="/v1/taxonomy", tags=["taxonomy"])

# Include legacy routers for backward compatibility
domain_router.include_router(auth.router, prefix="/v1/auth", tags=["auth"])
domain_router.include_router(health.router, prefix="/v1/health", tags=["health"])
domain_router.include_router(mobile.router, prefix="/v1/mobile", tags=["mobile"])
domain_router.include_router(admin_router, prefix="/v1/admin", tags=["admin"])


def get_domain_routers() -> List[APIRouter]:
    """
    Get list of all domain routers for easy integration.
    
    Returns:
        List of APIRouter instances for all domains
    """
    return [
        reports_router,
        matches_router,
        users_router,
        media_router,
        taxonomy_router,
        auth.router,
        health.router,
        mobile.router,
        admin_router
    ]


def get_domain_tags() -> List[str]:
    """
    Get list of all domain tags for API documentation.
    
    Returns:
        List of tag names for all domains
    """
    return [
        "reports",
        "matches", 
        "users",
        "media",
        "taxonomy",
        "auth",
        "health",
        "mobile",
        "admin"
    ]
