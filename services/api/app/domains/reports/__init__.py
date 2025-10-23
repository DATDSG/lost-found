"""
Reports Domain Package
=====================
Domain-driven design implementation for the Reports bounded context.

This package contains:
- Models: Domain entities and value objects
- Schemas: Data transfer objects and validation schemas
- Repositories: Data access layer
- Services: Business logic and domain services
- Controllers: HTTP API endpoints

Following DDD principles:
- Bounded Context: Reports domain is isolated from other domains
- Entities: Report entity with business logic
- Value Objects: ReportType, ReportStatus enums
- Domain Services: Business logic that doesn't fit in entities
- Repository Pattern: Clean data access abstraction
"""

from .models.report import Report, ReportType, ReportStatus
from .schemas.report_schemas import (
    ReportCreate, ReportUpdate, ReportResponse, ReportSearchRequest,
    ReportSearchResponse, ReportSummary, ReportStats, ReportTypeEnum, ReportStatusEnum
)
from .repositories.report_repository import ReportRepository
from .services.report_service import ReportDomainService
from .controllers.report_controller import router as reports_router

__all__ = [
    # Models
    "Report",
    "ReportType", 
    "ReportStatus",
    
    # Schemas
    "ReportCreate",
    "ReportUpdate", 
    "ReportResponse",
    "ReportSearchRequest",
    "ReportSearchResponse",
    "ReportSummary",
    "ReportStats",
    "ReportTypeEnum",
    "ReportStatusEnum",
    
    # Repository
    "ReportRepository",
    
    # Services
    "ReportDomainService",
    
    # Controllers
    "reports_router",
]
