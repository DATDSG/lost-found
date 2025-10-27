# Routers package
from . import auth, health, mobile
from .admin import router as admin_router

__all__ = ["auth", "health", "mobile", "admin_router"]
