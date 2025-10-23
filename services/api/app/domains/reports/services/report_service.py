"""
Reports Domain Service
=====================
Business logic layer for the Reports domain.
Implements domain services and use cases following DDD principles.
"""

from typing import List, Optional, Dict, Any, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
import logging
import uuid
from datetime import datetime

from ..repositories.report_repository import ReportRepository
from ..schemas.report_schemas import (
    ReportCreate, ReportUpdate, ReportResponse, ReportSearchRequest, 
    ReportSearchResponse, ReportSummary, ReportStats
)
from ..models.report import Report, ReportType, ReportStatus
from ....infrastructure.monitoring.metrics import MetricsCollector

logger = logging.getLogger(__name__)


class ReportService:
    """
    Main service class for Report operations.
    Provides high-level business operations for the Reports domain.
    """
    
    def __init__(self, repository: ReportRepository, metrics: MetricsCollector = None):
        self.repository = repository
        self.metrics = metrics or MetricsCollector()
    
    async def create_report(self, db: AsyncSession, report_data: ReportCreate, user_id: str) -> ReportResponse:
        """Create a new report."""
        try:
            # Create report entity
            report = Report(
                id=str(uuid.uuid4()),
                owner_id=user_id,
                type=report_data.type,
                title=report_data.title,
                description=report_data.description,
                category=report_data.category,
                colors=report_data.colors or [],
                occurred_at=report_data.occurred_at,
                occurred_time=report_data.occurred_time,
                location_name=report_data.location_name,
                location_city=report_data.location_city,
                location_address=report_data.location_address,
                latitude=report_data.latitude,
                longitude=report_data.longitude,
                contact_info=report_data.contact_info,
                is_urgent=report_data.is_urgent or False,
                reward_offered=report_data.reward_offered or False,
                reward_amount=report_data.reward_amount,
                image_urls=report_data.image_urls or [],
                image_hashes=report_data.image_hashes or []
            )
            
            # Save to repository
            created_report = await self.repository.create(db, report)
            
            # Record metrics
            self.metrics.increment_request_count("create_report", "POST", 201)
            
            return ReportResponse.from_orm(created_report)
            
        except Exception as e:
            logger.error(f"Failed to create report: {e}")
            self.metrics.increment_error_count("create_report_error", "create_report")
            raise
    
    async def get_report(self, db: AsyncSession, report_id: str) -> Optional[ReportResponse]:
        """Get a report by ID."""
        try:
            report = await self.repository.get_by_id(db, report_id)
            if report:
                self.metrics.increment_request_count("get_report", "GET", 200)
                return ReportResponse.from_orm(report)
            else:
                self.metrics.increment_request_count("get_report", "GET", 404)
                return None
        except Exception as e:
            logger.error(f"Failed to get report: {e}")
            self.metrics.increment_error_count("get_report_error", "get_report")
            raise
    
    async def update_report(self, db: AsyncSession, report_id: str, update_data: ReportUpdate, user_id: str) -> Optional[ReportResponse]:
        """Update a report."""
        try:
            # Get existing report
            report = await self.repository.get_by_id(db, report_id)
            if not report:
                return None
            
            # Check ownership
            if report.owner_id != user_id:
                raise ValueError("Not authorized to update this report")
            
            # Update fields
            update_dict = update_data.dict(exclude_unset=True)
            for field, value in update_dict.items():
                setattr(report, field, value)
            
            # Save changes
            updated_report = await self.repository.update(db, report)
            
            self.metrics.increment_request_count("update_report", "PUT", 200)
            return ReportResponse.from_orm(updated_report)
            
        except Exception as e:
            logger.error(f"Failed to update report: {e}")
            self.metrics.increment_error_count("update_report_error", "update_report")
            raise
    
    async def delete_report(self, db: AsyncSession, report_id: str, user_id: str) -> bool:
        """Delete a report."""
        try:
            # Get existing report
            report = await self.repository.get_by_id(db, report_id)
            if not report:
                return False
            
            # Check ownership
            if report.owner_id != user_id:
                raise ValueError("Not authorized to delete this report")
            
            # Delete report
            await self.repository.delete(db, report_id)
            
            self.metrics.increment_request_count("delete_report", "DELETE", 200)
            return True
            
        except Exception as e:
            logger.error(f"Failed to delete report: {e}")
            self.metrics.increment_error_count("delete_report_error", "delete_report")
            raise


class ReportDomainService:
    """
    Domain service for Report entities.
    Contains business logic that doesn't naturally fit in the entity.
    """
    
    def __init__(self, db: AsyncSession, metrics: Optional[MetricsCollector] = None):
        self.db = db
        self.repository = ReportRepository(db)
        self.metrics = metrics or MetricsCollector()
    
    async def create_report(self, report_data: ReportCreate, owner_id: str) -> ReportResponse:
        """
        Create a new report with business logic validation.
        
        Args:
            report_data: Report creation data
            owner_id: ID of the report owner
            
        Returns:
            Created report response
            
        Raises:
            ValueError: If business rules are violated
        """
        try:
            # Business logic validation
            await self._validate_report_creation(report_data, owner_id)
            
            # Convert to dict and add metadata
            report_dict = report_data.model_dump()
            report_dict.update({
                "id": str(uuid.uuid4()),
                "owner_id": owner_id,
                "status": ReportStatus.PENDING.value,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            })
            
            # Create report
            report = await self.repository.create(report_dict)
            
            # Record metrics
            self.metrics.increment_counter("reports_created_total", {
                "type": report.type,
                "category": report.category
            })
            
            logger.info(f"Created report {report.id} for user {owner_id}")
            
            return ReportResponse.model_validate(report)
            
        except Exception as e:
            logger.error(f"Failed to create report for user {owner_id}: {e}")
            raise
    
    async def update_report(self, report_id: str, update_data: ReportUpdate, user_id: str) -> Optional[ReportResponse]:
        """
        Update an existing report with authorization check.
        
        Args:
            report_id: ID of the report to update
            update_data: Update data
            user_id: ID of the user making the update
            
        Returns:
            Updated report response or None if not found
            
        Raises:
            PermissionError: If user doesn't own the report
        """
        try:
            # Get existing report
            report = await self.repository.get_by_id(report_id)
            if not report:
                return None
            
            # Authorization check
            if str(report.owner_id) != user_id:
                raise PermissionError("You can only update your own reports")
            
            # Business logic validation
            await self._validate_report_update(report, update_data)
            
            # Convert to dict and add metadata
            update_dict = update_data.model_dump(exclude_unset=True)
            update_dict["updated_at"] = datetime.utcnow()
            
            # Update report
            updated_report = await self.repository.update(report_id, update_dict)
            
            # Record metrics
            self.metrics.increment_counter("reports_updated_total", {
                "report_id": report_id
            })
            
            logger.info(f"Updated report {report_id} by user {user_id}")
            
            return ReportResponse.model_validate(updated_report)
            
        except Exception as e:
            logger.error(f"Failed to update report {report_id}: {e}")
            raise
    
    async def delete_report(self, report_id: str, user_id: str) -> bool:
        """
        Soft delete a report with authorization check.
        
        Args:
            report_id: ID of the report to delete
            user_id: ID of the user making the deletion
            
        Returns:
            True if deleted, False if not found
            
        Raises:
            PermissionError: If user doesn't own the report
        """
        try:
            # Get existing report
            report = await self.repository.get_by_id(report_id)
            if not report:
                return False
            
            # Authorization check
            if str(report.owner_id) != user_id:
                raise PermissionError("You can only delete your own reports")
            
            # Soft delete
            success = await self.repository.delete(report_id)
            
            if success:
                # Record metrics
                self.metrics.increment_counter("reports_deleted_total", {
                    "report_id": report_id
                })
                
                logger.info(f"Deleted report {report_id} by user {user_id}")
            
            return success
            
        except Exception as e:
            logger.error(f"Failed to delete report {report_id}: {e}")
            raise
    
    async def get_report(self, report_id: str, user_id: Optional[str] = None) -> Optional[ReportResponse]:
        """
        Get a report by ID with optional authorization check.
        
        Args:
            report_id: ID of the report
            user_id: Optional user ID for authorization
            
        Returns:
            Report response or None if not found
        """
        try:
            report = await self.repository.get_by_id(report_id)
            if not report:
                return None
            
            # If user_id provided, check if they can view this report
            if user_id and not await self._can_user_view_report(report, user_id):
                return None
            
            return ReportResponse.model_validate(report)
            
        except Exception as e:
            logger.error(f"Failed to get report {report_id}: {e}")
            raise
    
    async def search_reports(self, search_request: ReportSearchRequest) -> ReportSearchResponse:
        """
        Search reports with filters and pagination.
        
        Args:
            search_request: Search criteria and pagination
            
        Returns:
            Search response with reports and metadata
        """
        try:
            reports, total = await self.repository.search(search_request)
            
            # Convert to summary format
            report_summaries = [
                ReportSummary(
                    id=report.id,
                    type=report.type,
                    title=report.title,
                    category=report.category,
                    location_city=report.location_city,
                    occurred_at=report.occurred_at,
                    is_urgent=report.is_urgent,
                    reward_offered=report.reward_offered,
                    image_count=report.get_image_count(),
                    created_at=report.created_at
                )
                for report in reports
            ]
            
            # Calculate pagination metadata
            has_next = (search_request.page * search_request.page_size) < total
            has_previous = search_request.page > 1
            
            # Record metrics
            self.metrics.increment_counter("reports_searched_total", {
                "query_length": len(search_request.query or ""),
                "filters_applied": len([f for f in [
                    search_request.type, search_request.category, 
                    search_request.location_city, search_request.is_urgent,
                    search_request.reward_offered
                ] if f is not None])
            })
            
            return ReportSearchResponse(
                reports=report_summaries,
                total=total,
                page=search_request.page,
                page_size=search_request.page_size,
                has_next=has_next,
                has_previous=has_previous
            )
            
        except Exception as e:
            logger.error(f"Failed to search reports: {e}")
            raise
    
    async def get_reports(
        self, 
        page: int = 1, 
        page_size: int = 20, 
        search: Optional[str] = None,
        type: Optional[str] = None,
        category: Optional[str] = None,
        status: Optional[str] = "approved"
    ) -> List[ReportResponse]:
        """
        Get a paginated list of reports with optional filtering.
        
        Args:
            page: Page number (1-based)
            page_size: Number of reports per page
            search: Optional search term
            type: Optional report type filter (lost/found)
            category: Optional category filter
            status: Report status filter (default: approved)
            
        Returns:
            List of report responses
        """
        try:
            offset = (page - 1) * page_size
            
            reports = await self.repository.get_reports(
                limit=page_size,
                offset=offset,
                search=search,
                type=type,
                category=category,
                status=status
            )
            
            return [ReportResponse.model_validate(report) for report in reports]
            
        except Exception as e:
            logger.error(f"Failed to get reports: {e}")
            raise
    
    async def get_user_reports(self, user_id: str, limit: int = 50, offset: int = 0) -> List[ReportResponse]:
        """
        Get reports for a specific user.
        
        Args:
            user_id: ID of the user
            limit: Maximum number of reports
            offset: Number of reports to skip
            
        Returns:
            List of user's reports
        """
        try:
            reports = await self.repository.get_by_owner(user_id, limit, offset)
            
            return [ReportResponse.model_validate(report) for report in reports]
            
        except Exception as e:
            logger.error(f"Failed to get reports for user {user_id}: {e}")
            raise
    
    async def get_nearby_reports(
        self, 
        latitude: float, 
        longitude: float, 
        radius_km: float = 5.0,
        report_type: Optional[ReportType] = None,
        limit: int = 20
    ) -> List[ReportResponse]:
        """
        Get reports near a specific location.
        
        Args:
            latitude: Latitude coordinate
            longitude: Longitude coordinate
            radius_km: Search radius in kilometers
            report_type: Optional report type filter
            limit: Maximum number of reports
            
        Returns:
            List of nearby reports
        """
        try:
            reports = await self.repository.get_nearby_reports(
                latitude, longitude, radius_km, report_type, limit
            )
            
            # Record metrics
            self.metrics.increment_counter("nearby_reports_searched_total", {
                "radius_km": radius_km,
                "report_type": report_type.value if report_type else "all"
            })
            
            return [ReportResponse.model_validate(report) for report in reports]
            
        except Exception as e:
            logger.error(f"Failed to get nearby reports: {e}")
            raise
    
    async def get_report_stats(self) -> ReportStats:
        """
        Get comprehensive report statistics.
        
        Returns:
            Report statistics
        """
        try:
            stats = await self.repository.get_stats()
            
            # Record metrics
            self.metrics.increment_counter("report_stats_requested_total")
            
            return stats
            
        except Exception as e:
            logger.error(f"Failed to get report stats: {e}")
            raise
    
    async def approve_report(self, report_id: str, admin_user_id: str) -> Optional[ReportResponse]:
        """
        Approve a pending report (admin operation).
        
        Args:
            report_id: ID of the report to approve
            admin_user_id: ID of the admin user
            
        Returns:
            Approved report response or None if not found
        """
        try:
            report = await self.repository.get_by_id(report_id)
            if not report:
                return None
            
            if report.status != ReportStatus.PENDING.value:
                raise ValueError("Only pending reports can be approved")
            
            # Update status
            updated_report = await self.repository.update(report_id, {
                "status": ReportStatus.APPROVED.value,
                "updated_at": datetime.utcnow()
            })
            
            # Record metrics
            self.metrics.increment_counter("reports_approved_total", {
                "admin_user_id": admin_user_id,
                "report_type": report.type
            })
            
            logger.info(f"Approved report {report_id} by admin {admin_user_id}")
            
            return ReportResponse.model_validate(updated_report)
            
        except Exception as e:
            logger.error(f"Failed to approve report {report_id}: {e}")
            raise
    
    # Private helper methods
    
    async def _validate_report_creation(self, report_data: ReportCreate, owner_id: str) -> None:
        """Validate business rules for report creation."""
        # Check if user has too many pending reports
        user_reports = await self.repository.get_by_owner(owner_id, limit=100)
        pending_count = sum(1 for r in user_reports if r.status == ReportStatus.PENDING.value)
        
        if pending_count >= 10:  # Business rule: max 10 pending reports per user
            raise ValueError("You have too many pending reports. Please wait for approval.")
        
        # Validate reward amount
        if report_data.reward_offered and not report_data.reward_amount:
            raise ValueError("Reward amount must be specified when offering a reward")
        
        if report_data.reward_amount and report_data.reward_amount > 10000:  # Business rule: max reward
            raise ValueError("Reward amount cannot exceed $10,000")
    
    async def _validate_report_update(self, report: Report, update_data: ReportUpdate) -> None:
        """Validate business rules for report updates."""
        # Can't update approved reports to pending
        if (report.status == ReportStatus.APPROVED.value and 
            update_data.status == ReportStatus.PENDING.value):
            raise ValueError("Cannot change approved reports back to pending")
        
        # Validate reward amount
        if update_data.reward_offered and not update_data.reward_amount:
            raise ValueError("Reward amount must be specified when offering a reward")
        
        if update_data.reward_amount and update_data.reward_amount > 10000:
            raise ValueError("Reward amount cannot exceed $10,000")
    
    async def _can_user_view_report(self, report: Report, user_id: str) -> bool:
        """Check if a user can view a specific report."""
        # Users can always view their own reports
        if str(report.owner_id) == user_id:
            return True
        
        # Users can view approved reports
        if report.status == ReportStatus.APPROVED.value:
            return True
        
        # Users cannot view pending, hidden, or removed reports from others
        return False
    
    async def get_reports(
        self, 
        page: int = 1, 
        page_size: int = 20, 
        search: Optional[str] = None,
        type: Optional[str] = None,
        category: Optional[str] = None,
        status: Optional[str] = "approved"
    ) -> List[ReportResponse]:
        """
        Get a paginated list of reports with optional filtering.
        
        Args:
            page: Page number (1-based)
            page_size: Number of reports per page
            search: Optional search term
            type: Optional report type filter (lost/found)
            category: Optional category filter
            status: Report status filter (default: approved)
            
        Returns:
            List of report responses
        """
        try:
            offset = (page - 1) * page_size
            
            reports = await self.repository.get_reports(
                limit=page_size,
                offset=offset,
                search=search,
                type=type,
                category=category,
                status=status
            )
            
            return [ReportResponse.model_validate(report) for report in reports]
            
        except Exception as e:
            logger.error(f"Failed to get reports: {e}")
            raise
