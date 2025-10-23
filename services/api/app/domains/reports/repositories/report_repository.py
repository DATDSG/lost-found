"""
Reports Domain Repository
========================
Repository pattern implementation for the Reports domain.
Handles all data access operations for reports.
"""

from typing import List, Optional, Dict, Any, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func, desc, asc
from sqlalchemy.orm import selectinload
import logging

from ..models.report import Report, ReportType, ReportStatus
from ..schemas.report_schemas import ReportSearchRequest, ReportStats

logger = logging.getLogger(__name__)


class ReportRepository:
    """
    Repository for Report entities.
    Implements the Repository pattern for clean separation of data access logic.
    """
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create(self, report_data: Dict[str, Any]) -> Report:
        """Create a new report."""
        try:
            report = Report(**report_data)
            self.db.add(report)
            await self.db.commit()
            await self.db.refresh(report)
            logger.info(f"Created report: {report.id}")
            return report
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Failed to create report: {e}")
            raise
    
    async def get_by_id(self, report_id: str) -> Optional[Report]:
        """Get a report by ID."""
        try:
            result = await self.db.execute(
                select(Report)
                .options(selectinload(Report.owner))
                .where(Report.id == report_id)
            )
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Failed to get report {report_id}: {e}")
            raise
    
    async def get_by_owner(self, owner_id: str, limit: int = 50, offset: int = 0) -> List[Report]:
        """Get reports by owner ID."""
        try:
            result = await self.db.execute(
                select(Report)
                .where(Report.owner_id == owner_id)
                .order_by(desc(Report.created_at))
                .limit(limit)
                .offset(offset)
            )
            return result.scalars().all()
        except Exception as e:
            logger.error(f"Failed to get reports for owner {owner_id}: {e}")
            raise
    
    async def get_reports(
        self, 
        limit: int = 20, 
        offset: int = 0, 
        search: Optional[str] = None,
        type: Optional[str] = None,
        category: Optional[str] = None,
        status: Optional[str] = "approved"
    ) -> List[Report]:
        """Get reports with optional filtering."""
        try:
            query = select(Report).options(selectinload(Report.owner))
            
            # Apply filters
            conditions = []
            
            if status:
                conditions.append(Report.status == status)
            
            if type:
                conditions.append(Report.type == type)
            
            if category:
                conditions.append(Report.category == category)
            
            if search:
                search_condition = or_(
                    Report.title.ilike(f"%{search}%"),
                    Report.description.ilike(f"%{search}%"),
                    Report.location_city.ilike(f"%{search}%"),
                    Report.location_address.ilike(f"%{search}%")
                )
                conditions.append(search_condition)
            
            if conditions:
                query = query.where(and_(*conditions))
            
            query = query.order_by(desc(Report.created_at)).limit(limit).offset(offset)
            
            result = await self.db.execute(query)
            return result.scalars().all()
            
        except Exception as e:
            logger.error(f"Failed to get reports: {e}")
            raise
    
    async def update(self, report_id: str, update_data: Dict[str, Any]) -> Optional[Report]:
        """Update a report."""
        try:
            result = await self.db.execute(
                select(Report).where(Report.id == report_id)
            )
            report = result.scalar_one_or_none()
            
            if not report:
                return None
            
            for key, value in update_data.items():
                if hasattr(report, key) and value is not None:
                    setattr(report, key, value)
            
            await self.db.commit()
            await self.db.refresh(report)
            logger.info(f"Updated report: {report_id}")
            return report
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Failed to update report {report_id}: {e}")
            raise
    
    async def delete(self, report_id: str) -> bool:
        """Soft delete a report by setting status to 'removed'."""
        try:
            result = await self.db.execute(
                select(Report).where(Report.id == report_id)
            )
            report = result.scalar_one_or_none()
            
            if not report:
                return False
            
            report.status = ReportStatus.REMOVED.value
            await self.db.commit()
            logger.info(f"Soft deleted report: {report_id}")
            return True
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Failed to delete report {report_id}: {e}")
            raise
    
    async def search(self, search_request: ReportSearchRequest) -> Tuple[List[Report], int]:
        """Search reports with filters and pagination."""
        try:
            query = select(Report)
            
            # Apply filters
            conditions = []
            
            if search_request.query:
                conditions.append(
                    or_(
                        Report.title.ilike(f"%{search_request.query}%"),
                        Report.description.ilike(f"%{search_request.query}%")
                    )
                )
            
            if search_request.type:
                conditions.append(Report.type == search_request.type.value)
            
            if search_request.category:
                conditions.append(Report.category == search_request.category)
            
            if search_request.location_city:
                conditions.append(Report.location_city.ilike(f"%{search_request.location_city}%"))
            
            if search_request.is_urgent is not None:
                conditions.append(Report.is_urgent == search_request.is_urgent)
            
            if search_request.reward_offered is not None:
                conditions.append(Report.reward_offered == search_request.reward_offered)
            
            if search_request.date_from:
                conditions.append(Report.occurred_at >= search_request.date_from)
            
            if search_request.date_to:
                conditions.append(Report.occurred_at <= search_request.date_to)
            
            # Location-based search
            if search_request.latitude and search_request.longitude and search_request.radius_km:
                # Simple bounding box search (not precise but fast)
                lat_offset = search_request.radius_km / 111.0
                lng_offset = search_request.radius_km / (111.0 * abs(search_request.latitude) / 90.0)
                
                conditions.extend([
                    Report.latitude.between(
                        search_request.latitude - lat_offset,
                        search_request.latitude + lat_offset
                    ),
                    Report.longitude.between(
                        search_request.longitude - lng_offset,
                        search_request.longitude + lng_offset
                    )
                ])
            
            if conditions:
                query = query.where(and_(*conditions))
            
            # Only show active reports
            query = query.where(Report.status == ReportStatus.APPROVED.value)
            
            # Get total count
            count_query = select(func.count(Report.id))
            if conditions:
                count_query = count_query.where(and_(*conditions))
            count_query = count_query.where(Report.status == ReportStatus.APPROVED.value)
            
            total_result = await self.db.execute(count_query)
            total = total_result.scalar()
            
            # Apply pagination and ordering
            query = query.order_by(desc(Report.created_at))
            query = query.limit(search_request.page_size).offset(
                (search_request.page - 1) * search_request.page_size
            )
            
            result = await self.db.execute(query)
            reports = result.scalars().all()
            
            return reports, total
            
        except Exception as e:
            logger.error(f"Failed to search reports: {e}")
            raise
    
    async def get_nearby_reports(
        self, 
        latitude: float, 
        longitude: float, 
        radius_km: float = 5.0,
        report_type: Optional[ReportType] = None,
        limit: int = 20
    ) -> List[Report]:
        """Get reports near a specific location."""
        try:
            # Calculate bounding box
            lat_offset = radius_km / 111.0
            lng_offset = radius_km / (111.0 * abs(latitude) / 90.0)
            
            query = select(Report).where(
                and_(
                    Report.status == ReportStatus.APPROVED.value,
                    Report.latitude.between(latitude - lat_offset, latitude + lat_offset),
                    Report.longitude.between(longitude - lng_offset, longitude + lng_offset)
                )
            )
            
            if report_type:
                query = query.where(Report.type == report_type.value)
            
            query = query.order_by(desc(Report.created_at)).limit(limit)
            
            result = await self.db.execute(query)
            return result.scalars().all()
            
        except Exception as e:
            logger.error(f"Failed to get nearby reports: {e}")
            raise
    
    async def get_stats(self) -> ReportStats:
        """Get report statistics."""
        try:
            # Total counts
            total_result = await self.db.execute(select(func.count(Report.id)))
            total_reports = total_result.scalar()
            
            lost_result = await self.db.execute(
                select(func.count(Report.id)).where(Report.type == ReportType.LOST.value)
            )
            lost_reports = lost_result.scalar()
            
            found_result = await self.db.execute(
                select(func.count(Report.id)).where(Report.type == ReportType.FOUND.value)
            )
            found_reports = found_result.scalar()
            
            pending_result = await self.db.execute(
                select(func.count(Report.id)).where(Report.status == ReportStatus.PENDING.value)
            )
            pending_reports = pending_result.scalar()
            
            approved_result = await self.db.execute(
                select(func.count(Report.id)).where(Report.status == ReportStatus.APPROVED.value)
            )
            approved_reports = approved_result.scalar()
            
            urgent_result = await self.db.execute(
                select(func.count(Report.id)).where(Report.is_urgent == True)
            )
            urgent_reports = urgent_result.scalar()
            
            reward_result = await self.db.execute(
                select(func.count(Report.id)).where(Report.reward_offered == True)
            )
            reports_with_rewards = reward_result.scalar()
            
            # Reports with images
            image_result = await self.db.execute(
                select(func.count(Report.id)).where(Report.images.isnot(None))
            )
            reports_with_images = image_result.scalar()
            
            # Average images per report
            avg_images_result = await self.db.execute(
                select(func.avg(func.array_length(Report.images, 1))))
            avg_images = avg_images_result.scalar() or 0
            
            # Most common categories
            categories_result = await self.db.execute(
                select(Report.category, func.count(Report.id))
                .group_by(Report.category)
                .order_by(desc(func.count(Report.id)))
                .limit(10)
            )
            most_common_categories = [
                {"category": cat, "count": count} 
                for cat, count in categories_result.fetchall()
            ]
            
            # Reports by city
            cities_result = await self.db.execute(
                select(Report.location_city, func.count(Report.id))
                .where(Report.location_city.isnot(None))
                .group_by(Report.location_city)
                .order_by(desc(func.count(Report.id)))
                .limit(10)
            )
            reports_by_city = [
                {"city": city, "count": count} 
                for city, count in cities_result.fetchall()
            ]
            
            return ReportStats(
                total_reports=total_reports,
                lost_reports=lost_reports,
                found_reports=found_reports,
                pending_reports=pending_reports,
                approved_reports=approved_reports,
                urgent_reports=urgent_reports,
                reports_with_rewards=reports_with_rewards,
                reports_with_images=reports_with_images,
                average_images_per_report=round(avg_images, 2),
                most_common_categories=most_common_categories,
                reports_by_city=reports_by_city
            )
            
        except Exception as e:
            logger.error(f"Failed to get report stats: {e}")
            raise
    
    async def get_active_reports_count(self) -> int:
        """Get count of active reports."""
        try:
            result = await self.db.execute(
                select(func.count(Report.id)).where(Report.status == ReportStatus.APPROVED.value)
            )
            return result.scalar()
        except Exception as e:
            logger.error(f"Failed to get active reports count: {e}")
            raise
