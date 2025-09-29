from typing import List
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from geoalchemy2.elements import WKTElement
from datetime import datetime
from loguru import logger

from app.core.deps import get_db, get_current_user
from app.core.config import settings
from app.db import models
from app.schemas.items import ItemCreate, ItemUpdate, ItemPublic, ItemPrivate, ItemSearch
from app.schemas.flags import FlagCreate, FlagPublic
from app.services.geospatial import encode_geohash, GeospatialUtils
from app.services.matching import MatchingService
from app.workers.matching_tasks import trigger_matching_job


router = APIRouter()


@router.post("/", response_model=ItemPublic, status_code=201)
def create_item(
    payload: ItemCreate, 
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db), 
    user: models.User = Depends(get_current_user)
):
    """Create a new lost or found item with automatic matching."""
    
    # Create PostGIS point if coordinates provided
    location_point = None
    geohash6 = None
    if payload.lat and payload.lng:
        location_point = WKTElement(
            GeospatialUtils.create_point_wkt(payload.lat, payload.lng),
            srid=4326
        )
        geohash6 = encode_geohash(payload.lat, payload.lng, settings.GEOHASH_PRECISION)
    
    # Create item with all new fields
    item = models.Item(
        # Core identification
        title=payload.title,
        description=payload.description,
        language=payload.language,
        status=payload.status,
        
        # Structured categorization
        category=payload.category,
        subcategory=payload.subcategory,
        brand=payload.brand,
        model=payload.model,
        color=payload.color,
        
        # Unique identifiers
        unique_marks=payload.unique_marks,
        evidence_hash=payload.evidence_hash,
        
        # Geospatial data
        location_point=location_point,
        location_name=payload.location_name,
        geohash6=geohash6,
        location_fuzzing=payload.location_fuzzing,
        
        # Temporal data
        lost_found_at=payload.lost_found_at or datetime.utcnow(),
        time_window_start=payload.time_window_start,
        time_window_end=payload.time_window_end,
        
        # System fields
        owner_id=user.id,
    )
    
    db.add(item)
    db.commit()
    db.refresh(item)
    
    logger.info(f"Created item {item.id} ({item.status}) for user {user.id}")
    
    # Trigger background matching job
    background_tasks.add_task(trigger_matching_job, item.id)
    
    return ItemPublic.model_validate(item)


@router.get("/", response_model=List[ItemPublic])
def list_items(
    skip: int = 0,
    limit: int = 20,
    status: str = None,
    db: Session = Depends(get_db), 
    user: models.User = Depends(get_current_user)
):
    """List user's items with pagination and filtering."""
    query = db.query(models.Item).filter(models.Item.owner_id == user.id)
    
    if status:
        query = query.filter(models.Item.status == status)
    
    items = query.order_by(models.Item.created_at.desc()).offset(skip).limit(limit).all()
    return [ItemPublic.model_validate(i) for i in items]


@router.get("/search", response_model=List[ItemPublic])
def search_items(
    search_params: ItemSearch = Depends(),
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user)
):
    """Search for items with geospatial and temporal filtering."""
    query = db.query(models.Item)
    
    # Basic filters
    if search_params.category:
        query = query.filter(models.Item.category == search_params.category)
    
    if search_params.subcategory:
        query = query.filter(models.Item.subcategory == search_params.subcategory)
    
    if search_params.status:
        query = query.filter(models.Item.status == search_params.status)
    
    # Geospatial filtering
    if search_params.lat and search_params.lng and search_params.radius_km:
        from geoalchemy2.functions import ST_DWithin
        point = WKTElement(
            GeospatialUtils.create_point_wkt(search_params.lat, search_params.lng),
            srid=4326
        )
        query = query.filter(
            ST_DWithin(
                models.Item.location_point,
                point,
                search_params.radius_km * 1000  # Convert to meters
            )
        )
    
    # Temporal filtering
    if search_params.date_from:
        query = query.filter(models.Item.lost_found_at >= search_params.date_from)
    
    if search_params.date_to:
        query = query.filter(models.Item.lost_found_at <= search_params.date_to)
    
    # Text search (basic - can be enhanced with full-text search)
    if search_params.query:
        query = query.filter(
            models.Item.title.ilike(f"%{search_params.query}%") |
            models.Item.description.ilike(f"%{search_params.query}%")
        )
    
    # Exclude own items from search results
    query = query.filter(models.Item.owner_id != user.id)
    
    items = query.order_by(models.Item.created_at.desc()).offset(search_params.skip).limit(search_params.limit).all()
    return [ItemPublic.model_validate(i) for i in items]


@router.get("/{item_id}", response_model=ItemPrivate)
def get_item(item_id: int, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    """Get item details (private view for owner)."""
    item = db.query(models.Item).filter(models.Item.id == item_id, models.Item.owner_id == user.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return ItemPrivate.model_validate(item)


@router.patch("/{item_id}", response_model=ItemPrivate)
def update_item(
    item_id: int, 
    payload: ItemUpdate, 
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db), 
    user: models.User = Depends(get_current_user)
):
    """Update item and retrigger matching if location/category changed."""
    item = db.query(models.Item).filter(models.Item.id == item_id, models.Item.owner_id == user.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    # Track if we need to retrigger matching
    retrigger_matching = False
    update_data = payload.model_dump(exclude_unset=True)
    
    # Handle location updates
    if 'lat' in update_data and 'lng' in update_data:
        if update_data['lat'] and update_data['lng']:
            item.location_point = WKTElement(
                GeospatialUtils.create_point_wkt(update_data['lat'], update_data['lng']),
                srid=4326
            )
            item.geohash6 = encode_geohash(update_data['lat'], update_data['lng'], settings.GEOHASH_PRECISION)
            retrigger_matching = True
        else:
            item.location_point = None
            item.geohash6 = None
    
    # Check if category changed
    if 'category' in update_data or 'subcategory' in update_data:
        retrigger_matching = True
    
    # Apply other updates
    for k, v in update_data.items():
        if k not in ['lat', 'lng']:  # Already handled above
            setattr(item, k, v)
    
    item.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(item)
    
    # Retrigger matching if significant changes
    if retrigger_matching:
        background_tasks.add_task(trigger_matching_job, item.id)
    
    return ItemPrivate.model_validate(item)


def delete_item(item_id: int, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    item = db.query(models.Item).filter(models.Item.id == item_id, models.Item.owner_id == user.id).first()
    if not item:
        return # idempotent
    db.delete(item)
    db.commit()


@router.post("/{item_id}/flags", response_model=FlagPublic, status_code=201)
def flag_item(item_id: int, payload: FlagCreate, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    item = db.query(models.Item).filter(models.Item.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    flag = models.Flag(
        item_id=item.id,
        reporter_id=user.id,
        source=payload.source,
        reason=payload.reason,
        metadata=payload.metadata,
    )
    db.add(flag)
    db.commit()
    db.refresh(flag)
    return FlagPublic.model_validate(flag)