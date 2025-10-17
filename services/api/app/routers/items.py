"""Items management routes."""
from fastapi import APIRouter, Depends, HTTPException, status, Query, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, and_, func
from typing import List, Optional
from uuid import uuid4
from datetime import datetime
import logging

from ..database import get_db
from ..models import User, Report, Media, ReportType, ReportStatus, Category, Color
from ..schemas import ReportCreate, ReportSummary, ReportDetail, CategoryResponse, ColorResponse
from ..dependencies import get_current_user, get_current_admin
from ..clients import get_nlp_client, get_vision_client
from ..config import config
from ..helpers import create_audit_log

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/categories", response_model=List[CategoryResponse])
async def get_categories(
    db: AsyncSession = Depends(get_db),
    active_only: bool = True
):
    """Get all available item categories."""
    query = select(Category)
    if active_only:
        query = query.where(Category.is_active == True)
    
    query = query.order_by(Category.sort_order)
    result = await db.execute(query)
    categories = result.scalars().all()
    return categories


@router.get("/colors", response_model=List[ColorResponse])
async def get_colors(
    db: AsyncSession = Depends(get_db),
    active_only: bool = True
):
    """Get all available item colors."""
    query = select(Color)
    if active_only:
        query = query.where(Color.is_active == True)
    
    query = query.order_by(Color.sort_order)
    result = await db.execute(query)
    colors = result.scalars().all()
    return colors


@router.get("/search", response_model=List[ReportSummary])
async def search_items(
    q: str = Query(..., description="Search query"),
    category: Optional[str] = None,
    color: Optional[str] = None,
    item_type: Optional[ReportType] = None,
    location: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Search for items with advanced filters."""
    query = select(Report).where(Report.status == ReportStatus.APPROVED)
    
    # Text search
    if q:
        search_pattern = f"%{q}%"
        query = query.where(
            or_(
                Report.title.ilike(search_pattern),
                Report.description.ilike(search_pattern),
                Report.category.ilike(search_pattern)
            )
        )
    
    # Category filter
    if category:
        query = query.where(Report.category == category)
    
    # Color filter
    if color:
        query = query.where(Report.colors.contains([color]))
    
    # Type filter
    if item_type:
        query = query.where(Report.type == item_type)
    
    # Location filter
    if location:
        query = query.where(Report.location_city.ilike(f"%{location}%"))
    
    # Order by most recent
    query = query.order_by(Report.created_at.desc())
    
    # Pagination
    offset = (page - 1) * page_size
    query = query.offset(offset).limit(page_size)
    
    result = await db.execute(query)
    items = result.scalars().all()
    
    return items


@router.get("/nearby", response_model=List[ReportSummary])
async def get_nearby_items(
    latitude: float = Query(..., description="User's latitude"),
    longitude: float = Query(..., description="User's longitude"),
    radius_km: float = Query(10.0, ge=0.1, le=100.0, description="Search radius in kilometers"),
    item_type: Optional[ReportType] = None,
    category: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get items near a specific location."""
    # For now, we'll use a simple bounding box approach
    # In production, you'd want to use PostGIS for proper geographic queries
    
    # Convert radius to approximate degrees (rough approximation)
    lat_degree = radius_km / 111.0  # 1 degree latitude ≈ 111 km
    lng_degree = radius_km / (111.0 * abs(latitude) * 0.0174532925)  # Adjust for longitude
    
    query = select(Report).where(Report.status == ReportStatus.APPROVED)
    
    # Basic bounding box filter (this is simplified - use PostGIS for production)
    query = query.where(
        and_(
            Report.latitude >= latitude - lat_degree,
            Report.latitude <= latitude + lat_degree,
            Report.longitude >= longitude - lng_degree,
            Report.longitude <= longitude + lng_degree
        )
    )
    
    # Additional filters
    if item_type:
        query = query.where(Report.type == item_type)
    
    if category:
        query = query.where(Report.category == category)
    
    # Order by most recent
    query = query.order_by(Report.created_at.desc())
    
    # Pagination
    offset = (page - 1) * page_size
    query = query.offset(offset).limit(page_size)
    
    result = await db.execute(query)
    items = result.scalars().all()
    
    return items


@router.get("/stats")
async def get_item_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get item statistics for the current user."""
    
    # User's items
    user_items_query = select(func.count(Report.id)).where(Report.owner_id == current_user.id)
    user_items_result = await db.execute(user_items_query)
    user_items_count = user_items_result.scalar()
    
    # User's lost items
    user_lost_query = select(func.count(Report.id)).where(
        and_(Report.owner_id == current_user.id, Report.type == ReportType.LOST)
    )
    user_lost_result = await db.execute(user_lost_query)
    user_lost_count = user_lost_result.scalar()
    
    # User's found items
    user_found_query = select(func.count(Report.id)).where(
        and_(Report.owner_id == current_user.id, Report.type == ReportType.FOUND)
    )
    user_found_result = await db.execute(user_found_query)
    user_found_count = user_found_result.scalar()
    
    # Total items in system
    total_items_query = select(func.count(Report.id)).where(Report.status == ReportStatus.APPROVED)
    total_items_result = await db.execute(total_items_query)
    total_items_count = total_items_result.scalar()
    
    return {
        "user_items": {
            "total": user_items_count,
            "lost": user_lost_count,
            "found": user_found_count
        },
        "system_total": total_items_count
    }


@router.get("/trending", response_model=List[ReportSummary])
async def get_trending_items(
    limit: int = Query(10, ge=1, le=50),
    db: AsyncSession = Depends(get_db)
):
    """Get trending items (most viewed/recent)."""
    
    # For now, return most recent items
    # In production, you'd implement proper trending algorithm based on views, matches, etc.
    query = select(Report).where(Report.status == ReportStatus.APPROVED)
    query = query.order_by(Report.created_at.desc()).limit(limit)
    
    result = await db.execute(query)
    items = result.scalars().all()
    
    return items


@router.get("/featured", response_model=List[ReportSummary])
async def get_featured_items(
    limit: int = Query(5, ge=1, le=20),
    db: AsyncSession = Depends(get_db)
):
    """Get featured items (admin curated)."""
    
    # For now, return most recent approved items
    # In production, you'd have a featured flag or admin curation
    query = select(Report).where(Report.status == ReportStatus.APPROVED)
    query = query.order_by(Report.created_at.desc()).limit(limit)
    
    result = await db.execute(query)
    items = result.scalars().all()
    
    return items


@router.post("/{item_id}/flag")
async def flag_item(
    item_id: str,
    reason: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Flag an item for review."""
    
    # Check if item exists
    result = await db.execute(select(Report).where(Report.id == item_id))
    item = result.scalar_one_or_none()
    
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found"
        )
    
    # Create audit log for flagging
    await create_audit_log(
        db=db,
        user_id=str(current_user.id),
        action="item_flagged",
        resource_type="report",
        resource_id=item_id,
        details=f"Flagged by user {current_user.email}: {reason}"
    )
    
    return {"message": "Item flagged successfully", "item_id": item_id}


@router.get("/{item_id}/similar", response_model=List[ReportSummary])
async def get_similar_items(
    item_id: str,
    limit: int = Query(5, ge=1, le=20),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get items similar to the specified item."""
    
    # Get the source item
    result = await db.execute(select(Report).where(Report.id == item_id))
    source_item = result.scalar_one_or_none()
    
    if not source_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found"
        )
    
    # Find similar items based on category and type
    query = select(Report).where(
        and_(
            Report.id != item_id,
            Report.status == ReportStatus.APPROVED,
            Report.category == source_item.category,
            Report.type != source_item.type  # Opposite type (lost vs found)
        )
    )
    
    query = query.order_by(Report.created_at.desc()).limit(limit)
    
    result = await db.execute(query)
    similar_items = result.scalars().all()
    
    return similar_items
