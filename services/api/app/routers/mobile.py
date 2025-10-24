"""
Mobile API Endpoints
===================
Specialized endpoints optimized for mobile applications with offline support
and mobile-specific features.
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query, Request, BackgroundTasks
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func, desc
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
import logging
import uuid

from ..infrastructure.database.session import get_async_db
from ..models import User
from ..domains.reports.models.report import Report, ReportType, ReportStatus
from ..domains.matches.models.match import Match, MatchStatus
from ..schemas import UserResponse
from ..domains.reports.schemas.report_schemas import ReportCreate, ReportUpdate, ReportResponse
from ..domains.matches.schemas.match_schemas import MatchResponse
from ..dependencies import get_current_user
from ..cache import cache_get, cache_set, cache_delete
from ..storage import get_minio_client, generate_object_name, validate_file_type
from ..clients import get_nlp_client, get_vision_client
from ..config import config

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/sync", response_model=Dict[str, Any])
async def mobile_sync(
    last_sync: Optional[datetime] = Query(None, description="Last sync timestamp"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    Mobile sync endpoint for offline support.
    Returns all data changed since last sync.
    """
    try:
        sync_data = {
            "timestamp": datetime.utcnow(),
            "reports": [],
            "matches": []
        }
        
        # Get reports updated since last sync
        if last_sync:
            reports_query = select(Report).where(
                and_(
                    Report.owner_id == user.id,
                    Report.updated_at > last_sync
                )
            ).order_by(desc(Report.updated_at))
        else:
            # First sync - get all user reports
            reports_query = select(Report).where(
                Report.owner_id == user.id
            ).order_by(desc(Report.created_at))
        
        reports_result = await db.execute(reports_query)
        reports = reports_result.scalars().all()
        
        for report in reports:
            sync_data["reports"].append({
                "id": report.id,
                "type": report.type,
                "status": report.status,
                "title": report.title,
                "description": report.description,
                "category": report.category,
                "location": report.location,
                "latitude": report.latitude,
                "longitude": report.longitude,
                "created_at": report.created_at,
                "updated_at": report.updated_at,
                "images": report.images or [],
                "is_urgent": report.is_urgent,
                "reward_offered": report.reward_offered,
                "reward_amount": report.reward_amount
            })
        
        # Get matches updated since last sync
        if last_sync:
            matches_query = select(Match).where(
                and_(
                    or_(
                        Match.source_report.has(Report.owner_id == user.id),
                        Match.candidate_report.has(Report.owner_id == user.id)
                    ),
                    Match.updated_at > last_sync
                )
            ).order_by(desc(Match.updated_at))
        else:
            matches_query = select(Match).where(
                or_(
                    Match.source_report.has(Report.owner_id == user.id),
                    Match.candidate_report.has(Report.owner_id == user.id)
                )
            ).order_by(desc(Match.created_at))
        
        matches_result = await db.execute(matches_query)
        matches = matches_result.scalars().all()
        
        for match in matches:
            sync_data["matches"].append({
                "id": match.id,
                "source_report_id": match.source_report_id,
                "candidate_report_id": match.candidate_report_id,
                "status": match.status,
                "score": match.score_total,
                "created_at": match.created_at,
                "updated_at": match.updated_at,
                "is_notified": match.is_notified
            })
        
        # Cache sync data for offline access
        cache_key = f"mobile_sync:{user.id}:{sync_data['timestamp'].timestamp()}"
        await cache_set(cache_key, sync_data, ttl=3600)  # 1 hour
        
        return {
            "success": True,
            "sync_timestamp": sync_data["timestamp"],
            "data": sync_data,
            "counts": {
                "reports": len(sync_data["reports"]),
                "matches": len(sync_data["matches"])
            }
        }
        
    except Exception as e:
        logger.error(f"Mobile sync failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Sync failed"
        )


@router.post("/reports/quick", response_model=ReportResponse)
async def create_quick_report(
    request: Request,
    background_tasks: BackgroundTasks,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    Quick report creation optimized for mobile.
    Handles both JSON and multipart form data.
    """
    try:
        logger.info(f"Creating quick report for user {user.id}")
        
        # Check content type
        content_type = request.headers.get("content-type", "")
        
        if "multipart/form-data" in content_type:
            # Handle multipart form data
            form_data = await request.form()
            
            # Extract form fields
            report_data = {
                "type": form_data.get("type"),
                "title": form_data.get("title"),
                "description": form_data.get("description"),
                "category": form_data.get("category"),
                "location_city": form_data.get("location_city"),
                "occurred_at": form_data.get("occurred_at"),
                "colors": form_data.get("colors", "[]"),
                "is_urgent": form_data.get("is_urgent", "false").lower() == "true",
                "reward_offered": form_data.get("reward_offered", "false").lower() == "true",
                "reward_amount": form_data.get("reward_amount"),
                "latitude": form_data.get("latitude"),
                "longitude": form_data.get("longitude"),
                "images": []
            }
            
            # Parse colors if it's a JSON string
            if isinstance(report_data["colors"], str):
                try:
                    import json
                    report_data["colors"] = json.loads(report_data["colors"])
                except:
                    report_data["colors"] = []
            
            # Handle latitude/longitude
            if report_data["latitude"]:
                try:
                    report_data["latitude"] = float(report_data["latitude"])
                except:
                    report_data["latitude"] = None
            
            if report_data["longitude"]:
                try:
                    report_data["longitude"] = float(report_data["longitude"])
                except:
                    report_data["longitude"] = None
            
            # Parse occurred_at
            if report_data["occurred_at"]:
                try:
                    from datetime import datetime
                    report_data["occurred_at"] = datetime.fromisoformat(report_data["occurred_at"].replace('Z', '+00:00'))
                except:
                    report_data["occurred_at"] = datetime.utcnow()
            else:
                report_data["occurred_at"] = datetime.utcnow()
            
            # Validate required fields
            if not report_data["type"] or not report_data["title"] or not report_data["category"]:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Missing required fields: type, title, category"
                )
            
            logger.info(f"Multipart report data: {report_data}")
            
        else:
            # Handle JSON data
            json_data = await request.json()
            report_data = json_data
            logger.info(f"JSON report data: {report_data}")
        
        # Create report
        report = Report(
            id=str(uuid.uuid4()),
            owner_id=user.id,
            type=report_data["type"],
            status="pending",
            title=report_data["title"],
            description=report_data.get("description"),
            category=report_data["category"],
            location_city=report_data.get("location_city"),
            latitude=report_data.get("latitude"),
            longitude=report_data.get("longitude"),
            contact_info=report_data.get("contact_info"),
            is_urgent=report_data.get("is_urgent", False),
            reward_offered=report_data.get("reward_offered", False),
            reward_amount=report_data.get("reward_amount"),
            occurred_at=report_data.get("occurred_at", datetime.utcnow()),
            colors=report_data.get("colors", []),
            images=report_data.get("images", []),
            image_hashes=[],
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        
        db.add(report)
        await db.commit()
        await db.refresh(report)
        
        # Background processing for images and matching
        if report_data.get("images"):
            background_tasks.add_task(process_report_images, report.id, report_data["images"])
        
        background_tasks.add_task(generate_report_embeddings, report.id)
        background_tasks.add_task(find_initial_matches, report.id)
        
        logger.info(f"Quick report created: {report.id}")
        
        return ReportResponse.from_orm(report)
        
    except ValueError as e:
        logger.error(f"Validation error in quick report creation: {e}")
        logger.error(f"Report data: {report_data}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid report data: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Quick report creation failed: {e}")
        logger.error(f"Report data: {report_data}")
        logger.error(f"User ID: {user.id}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Report creation failed: {str(e)}"
        )


@router.get("/reports/nearby", response_model=List[ReportResponse])
async def get_nearby_reports(
    latitude: float = Query(..., description="User latitude"),
    longitude: float = Query(..., description="User longitude"),
    radius_km: float = Query(5.0, description="Search radius in kilometers"),
    report_type: Optional[ReportType] = Query(None, description="Filter by report type"),
    limit: int = Query(20, description="Maximum number of reports"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    Get reports near user location for mobile map view.
    """
    try:
        # Calculate bounding box for location search
        # Approximate: 1 degree ≈ 111 km
        lat_offset = radius_km / 111.0
        lng_offset = radius_km / (111.0 * abs(latitude) / 90.0)
        
        query = select(Report).where(
            and_(
                Report.status == ReportStatus.APPROVED,
                Report.latitude.between(latitude - lat_offset, latitude + lat_offset),
                Report.longitude.between(longitude - lng_offset, longitude + lng_offset),
                Report.owner_id != user.id  # Exclude user's own reports
            )
        )
        
        if report_type:
            query = query.where(Report.type == report_type)
        
        query = query.order_by(desc(Report.created_at)).limit(limit)
        
        result = await db.execute(query)
        reports = result.scalars().all()
        
        # Add distance calculation
        nearby_reports = []
        for report in reports:
            # Simple distance calculation (not precise but fast)
            lat_diff = abs(report.latitude - latitude)
            lng_diff = abs(report.longitude - longitude)
            distance_km = ((lat_diff ** 2 + lng_diff ** 2) ** 0.5) * 111.0
            
            report_dict = ReportResponse.from_orm(report).model_dump()
            report_dict["distance_km"] = round(distance_km, 2)
            nearby_reports.append(report_dict)
        
        # Sort by distance
        nearby_reports.sort(key=lambda x: x["distance_km"])
        
        return nearby_reports
        
    except Exception as e:
        logger.error(f"Nearby reports query failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get nearby reports"
        )


@router.get("/matches/pending", response_model=List[MatchResponse])
async def get_pending_matches(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    Get pending matches for mobile app.
    """
    try:
        query = select(Match).where(
            and_(
                or_(
                    Match.source_report.has(Report.owner_id == user.id),
                    Match.candidate_report.has(Report.owner_id == user.id)
                ),
                Match.status == MatchStatus.CANDIDATE,
                Match.is_notified == False
            )
        ).order_by(desc(Match.score_total))
        
        result = await db.execute(query)
        matches = result.scalars().all()
        
        return [MatchResponse.from_orm(match) for match in matches]
        
    except Exception as e:
        logger.error(f"Pending matches query failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get pending matches"
        )


@router.post("/matches/{match_id}/respond")
async def respond_to_match(
    match_id: str,
    response: str = Query(..., description="Response: 'accept' or 'decline'"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    Respond to a match (accept or decline).
    """
    try:
        if response not in ["accept", "decline"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Response must be 'accept' or 'decline'"
            )
        
        # Get match
        query = select(Match).where(
            and_(
                Match.id == match_id,
                or_(
                    Match.source_report.has(Report.owner_id == user.id),
                    Match.candidate_report.has(Report.owner_id == user.id)
                )
            )
        )
        
        result = await db.execute(query)
        match = result.scalar_one_or_none()
        
        if not match:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )
        
        # Update match status
        if response == "accept":
            match.status = MatchStatus.APPROVED
        else:
            match.status = MatchStatus.REJECTED
        
        match.updated_at = datetime.utcnow()
        await db.commit()
        
        logger.info(f"Match {match_id} responded with: {response}")
        
        return {
            "success": True,
            "match_id": match_id,
            "response": response,
            "status": match.status
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Match response failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to respond to match"
        )


@router.get("/reports/my/reports", response_model=List[ReportResponse])
async def get_user_reports(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    Get all reports created by the current user.
    """
    try:
        query = select(Report).where(
            Report.owner_id == user.id
        ).order_by(desc(Report.created_at))
        
        result = await db.execute(query)
        reports = result.scalars().all()
        
        return [ReportResponse.from_orm(report) for report in reports]
        
    except Exception as e:
        logger.error(f"User reports query failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user reports"
        )


@router.get("/users/stats", response_model=Dict[str, Any])
async def get_user_stats(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    Get comprehensive user statistics for profile page.
    """
    try:
        # Get basic user statistics directly
        total_reports_query = select(func.count(Report.id)).where(Report.owner_id == user.id)
        total_reports = await db.scalar(total_reports_query) or 0
        
        active_reports_query = select(func.count(Report.id)).where(
            and_(
                Report.owner_id == user.id,
                Report.status == ReportStatus.APPROVED
            )
        )
        active_reports = await db.scalar(active_reports_query) or 0
        
        draft_reports_query = select(func.count(Report.id)).where(
            and_(
                Report.owner_id == user.id,
                Report.status == ReportStatus.PENDING
            )
        )
        draft_reports = await db.scalar(draft_reports_query) or 0
        
        resolved_reports_query = select(func.count(Report.id)).where(
            and_(
                Report.owner_id == user.id,
                Report.is_resolved == True
            )
        )
        resolved_reports = await db.scalar(resolved_reports_query) or 0
        
        # Match statistics
        total_matches_query = select(func.count(Match.id)).where(
            or_(
                Match.source_report.has(Report.owner_id == user.id),
                Match.candidate_report.has(Report.owner_id == user.id)
            )
        )
        total_matches = await db.scalar(total_matches_query) or 0
        
        successful_matches_query = select(func.count(Match.id)).where(
            and_(
                or_(
                    Match.source_report.has(Report.owner_id == user.id),
                    Match.candidate_report.has(Report.owner_id == user.id)
                ),
                Match.status == MatchStatus.PROMOTED
            )
        )
        successful_matches = await db.scalar(successful_matches_query) or 0
        
        # Calculate account age
        account_age_days = (datetime.utcnow().replace(tzinfo=None) - user.created_at.replace(tzinfo=None)).days
        
        stats = {
            "total_reports": total_reports,
            "active_reports": active_reports,
            "resolved_reports": resolved_reports,
            "draft_reports": draft_reports,
            "matches_found": total_matches,
            "successful_matches": successful_matches,
            "activity": {
                "account_age_days": account_age_days,
                "last_login": None,
                "total_logins": 0
            }
        }
        
        return {
            "success": True,
            "message": "Statistics retrieved successfully",
            "data": stats
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"User stats query failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user statistics"
        )


@router.get("/stats", response_model=Dict[str, Any])
async def get_mobile_stats(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    Get user statistics for mobile dashboard.
    """
    try:
        # Get report counts
        reports_query = select(func.count(Report.id)).where(Report.owner_id == user.id)
        total_reports = await db.scalar(reports_query)
        
        active_reports_query = select(func.count(Report.id)).where(
            and_(
                Report.owner_id == user.id,
                Report.status == ReportStatus.APPROVED
            )
        )
        active_reports = await db.scalar(active_reports_query)
        
        # Get match counts
        matches_query = select(func.count(Match.id)).where(
            or_(
                Match.source_report.has(Report.owner_id == user.id),
                Match.candidate_report.has(Report.owner_id == user.id)
            )
        )
        total_matches = await db.scalar(matches_query)
        
        pending_matches_query = select(func.count(Match.id)).where(
            and_(
                or_(
                    Match.source_report.has(Report.owner_id == user.id),
                    Match.candidate_report.has(Report.owner_id == user.id)
                ),
                Match.status == MatchStatus.CANDIDATE
            )
        )
        pending_matches = await db.scalar(pending_matches_query)
        
        return {
            "reports": {
                "total": total_reports,
                "active": active_reports,
                "pending": total_reports - active_reports
            },
            "matches": {
                "total": total_matches,
                "pending": pending_matches,
                "resolved": total_matches - pending_matches
            },
            "success_rate": round((total_matches - pending_matches) / max(total_matches, 1) * 100, 1)
        }
        
    except Exception as e:
        logger.error(f"Mobile stats query failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get statistics"
        )




# Background task functions
async def process_report_images(report_id: str, image_urls: List[str]):
    """Process report images in background."""
    try:
        vision_client = get_minio_client()
        
        for image_url in image_urls:
            # Generate image hash
            async with get_vision_client() as vision:
                image_hash = await vision.get_image_hash(image_url)
            
            if image_hash:
                # Update report with image hash
                # This would require a separate database session
                logger.info(f"Generated hash for image: {image_url}")
        
    except Exception as e:
        logger.error(f"Image processing failed for report {report_id}: {e}")


async def generate_report_embeddings(report_id: str):
    """Generate text embeddings for report."""
    try:
        # This would require getting the report from database
        # and calling NLP service
        logger.info(f"Generating embeddings for report: {report_id}")
        
    except Exception as e:
        logger.error(f"Embedding generation failed for report {report_id}: {e}")


async def find_initial_matches(report_id: str):
    """Find initial matches for new report."""
    try:
        # This would use the matching service
        logger.info(f"Finding matches for report: {report_id}")
        
    except Exception as e:
        logger.error(f"Match finding failed for report {report_id}: {e}")
