"""
Reports Domain Controller
========================
FastAPI controller for the Reports domain.
Handles HTTP requests and responses for report operations.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, Path
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import logging

from ..services.report_service import ReportDomainService
from ..schemas.report_schemas import (
    ReportCreate, ReportUpdate, ReportResponse, ReportSearchRequest,
    ReportSearchResponse, ReportSummary, ReportStats, ReportTypeEnum
)
from ....infrastructure.database.session import get_async_db
from ....infrastructure.monitoring.metrics import get_metrics_collector
from ....dependencies import get_current_user
from ....models import User

logger = logging.getLogger(__name__)

router = APIRouter(tags=["reports"])


@router.post("/", response_model=ReportResponse, status_code=status.HTTP_201_CREATED)
async def create_report(
    report_data: ReportCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db),
    metrics = Depends(get_metrics_collector)
):
    """
    Create a new report.
    
    This endpoint allows authenticated users to create a new lost or found item report.
    The report will be created with PENDING status and requires admin approval.
    """
    try:
        service = ReportDomainService(db, metrics)
        report = await service.create_report(report_data, str(current_user.id))
        
        logger.info(f"Report created successfully: {report.id}")
        return report
        
    except ValueError as e:
        logger.warning(f"Validation error creating report: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error creating report: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create report"
        )


@router.get("/", response_model=List[ReportResponse])
async def get_reports(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Number of reports per page"),
    search: Optional[str] = Query(None, description="Search term"),
    report_type: Optional[ReportTypeEnum] = Query(None, description="Report type filter"),
    category: Optional[str] = Query(None, description="Category filter"),
    report_status: Optional[str] = Query("approved", description="Report status filter"),
    db: AsyncSession = Depends(get_async_db),
    metrics = Depends(get_metrics_collector)
):
    """
    Get a list of reports with optional filtering.
    
    Returns paginated list of reports. By default, only returns approved reports.
    Users can filter by type, category, status, and search terms.
    """
    try:
        service = ReportDomainService(db, metrics)
        reports = await service.get_reports(
            page=page,
            page_size=page_size,
            search=search,
            type=report_type,
            category=category,
            status=report_status
        )
        
        return reports
        
    except Exception as e:
        logger.error(f"Error getting reports: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get reports"
        )


@router.get("/{report_id}", response_model=ReportResponse)
async def get_report(
    report_id: str = Path(..., description="Report ID"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db),
    metrics = Depends(get_metrics_collector)
):
    """
    Get a specific report by ID.
    
    Users can view their own reports regardless of status, and approved reports from others.
    """
    try:
        service = ReportDomainService(db, metrics)
        report = await service.get_report(report_id, str(current_user.id))
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        return report
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting report {report_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get report"
        )


@router.put("/{report_id}", response_model=ReportResponse)
async def update_report(
    report_id: str = Path(..., description="Report ID"),
    update_data: ReportUpdate = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db),
    metrics = Depends(get_metrics_collector)
):
    """
    Update an existing report.
    
    Users can only update their own reports. Some fields may have restrictions
    based on the current report status.
    """
    try:
        service = ReportDomainService(db, metrics)
        report = await service.update_report(report_id, update_data, str(current_user.id))
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        logger.info(f"Report updated successfully: {report_id}")
        return report
        
    except PermissionError as e:
        logger.warning(f"Permission denied updating report {report_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )
    except ValueError as e:
        logger.warning(f"Validation error updating report {report_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error updating report {report_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update report"
        )


@router.delete("/{report_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_report(
    report_id: str = Path(..., description="Report ID"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db),
    metrics = Depends(get_metrics_collector)
):
    """
    Delete a report (soft delete).
    
    Users can only delete their own reports. This performs a soft delete
    by setting the status to 'removed'.
    """
    try:
        service = ReportDomainService(db, metrics)
        success = await service.delete_report(report_id, str(current_user.id))
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        logger.info(f"Report deleted successfully: {report_id}")
        
    except PermissionError as e:
        logger.warning(f"Permission denied deleting report {report_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error deleting report {report_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete report"
        )


@router.get("/user/my-reports", response_model=List[ReportResponse])
async def get_my_reports(
    limit: int = Query(50, ge=1, le=100, description="Maximum number of reports"),
    offset: int = Query(0, ge=0, description="Number of reports to skip"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db),
    metrics = Depends(get_metrics_collector)
):
    """
    Get current user's reports.
    
    Returns all reports created by the authenticated user, regardless of status.
    """
    try:
        service = ReportDomainService(db, metrics)
        reports = await service.get_user_reports(str(current_user.id), limit, offset)
        
        return reports
        
    except Exception as e:
        logger.error(f"Error getting user reports: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user reports"
        )


@router.get("/nearby", response_model=List[ReportResponse])
async def get_nearby_reports(
    latitude: float = Query(..., description="Latitude coordinate"),
    longitude: float = Query(..., description="Longitude coordinate"),
    radius_km: float = Query(5.0, ge=0.1, le=100, description="Search radius in kilometers"),
    type: Optional[ReportTypeEnum] = Query(None, description="Report type filter"),
    limit: int = Query(20, ge=1, le=100, description="Maximum number of reports"),
    db: AsyncSession = Depends(get_async_db),
    metrics = Depends(get_metrics_collector)
):
    """
    Get reports near a specific location.
    
    Returns approved reports within the specified radius of the given coordinates.
    Useful for map-based interfaces and location-aware searches.
    """
    try:
        service = ReportDomainService(db, metrics)
        reports = await service.get_nearby_reports(
            latitude, longitude, radius_km, type, limit
        )
        
        return reports
        
    except Exception as e:
        logger.error(f"Error getting nearby reports: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get nearby reports"
        )


@router.get("/stats/overview", response_model=ReportStats)
async def get_report_stats(
    db: AsyncSession = Depends(get_async_db),
    metrics = Depends(get_metrics_collector)
):
    """
    Get comprehensive report statistics.
    
    Returns aggregated statistics about reports including counts by type,
    status, location, and other metrics. Useful for dashboards and analytics.
    """
    try:
        service = ReportDomainService(db, metrics)
        stats = await service.get_report_stats()
        
        return stats
        
    except Exception as e:
        logger.error(f"Error getting report stats: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get report statistics"
        )


# Admin endpoints
@router.post("/{report_id}/approve", response_model=ReportResponse)
async def approve_report(
    report_id: str = Path(..., description="Report ID"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db),
    metrics = Depends(get_metrics_collector)
):
    """
    Approve a pending report (Admin only).
    
    This endpoint is restricted to admin users and changes the report
    status from PENDING to APPROVED.
    """
    try:
        # Check if user is admin (this would be implemented in auth middleware)
        if current_user.role not in ["admin", "moderator"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin access required"
            )
        
        service = ReportDomainService(db, metrics)
        report = await service.approve_report(report_id, str(current_user.id))
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        logger.info(f"Report approved by admin: {report_id}")
        return report
        
    except HTTPException:
        raise
    except ValueError as e:
        logger.warning(f"Validation error approving report {report_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error approving report {report_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to approve report"
        )
