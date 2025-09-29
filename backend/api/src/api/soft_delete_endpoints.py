"""
API endpoints for soft delete operations
Provides REST endpoints for managing soft deleted records
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

from app.db.session import get_db
from app.db.models import Item, User, Match, Claim, MediaAsset
from src.models.soft_delete import SoftDeleteService
from src.auth.rbac import require_permissions, Permission

router = APIRouter(prefix="/api/v1/soft-delete", tags=["soft-delete"])

# Pydantic models for API
class SoftDeleteRequest(BaseModel):
    reason: Optional[str] = None

class SoftDeleteResponse(BaseModel):
    success: bool
    message: str
    deleted_count: Optional[int] = None

class RestoreRequest(BaseModel):
    pass

class RestoreResponse(BaseModel):
    success: bool
    message: str
    restored_count: Optional[int] = None

class DeletedItemResponse(BaseModel):
    id: int
    title: str
    deleted_at: datetime
    deleted_by: Optional[str]
    deletion_reason: Optional[str]

class DeletionStatsResponse(BaseModel):
    total: int
    active: int
    deleted: int
    deletion_rate: float

# Item soft delete endpoints
@router.delete("/items/{item_id}")
async def soft_delete_item(
    item_id: int,
    request: SoftDeleteRequest,
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.DELETE_ITEM))
):
    """Soft delete an item"""
    service = SoftDeleteService(db)
    
    success = service.soft_delete_item(
        Item, 
        item_id, 
        deleted_by=current_user.email,
        reason=request.reason
    )
    
    if not success:
        raise HTTPException(status_code=404, detail="Item not found or already deleted")
    
    return SoftDeleteResponse(
        success=True,
        message=f"Item {item_id} soft deleted successfully"
    )

@router.post("/items/{item_id}/restore")
async def restore_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.RESTORE_ITEM))
):
    """Restore a soft deleted item"""
    service = SoftDeleteService(db)
    
    success = service.restore_item(
        Item, 
        item_id, 
        restored_by=current_user.email
    )
    
    if not success:
        raise HTTPException(status_code=404, detail="Item not found or not deleted")
    
    return RestoreResponse(
        success=True,
        message=f"Item {item_id} restored successfully"
    )

@router.delete("/items/bulk")
async def bulk_soft_delete_items(
    item_ids: List[int],
    request: SoftDeleteRequest,
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.DELETE_ITEM))
):
    """Bulk soft delete multiple items"""
    service = SoftDeleteService(db)
    
    count = service.bulk_soft_delete(
        Item,
        item_ids,
        deleted_by=current_user.email,
        reason=request.reason
    )
    
    return SoftDeleteResponse(
        success=True,
        message=f"Successfully soft deleted {count} items",
        deleted_count=count
    )

@router.get("/items/deleted")
async def get_deleted_items(
    limit: int = Query(default=100, le=1000),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.VIEW_DELETED_ITEMS))
):
    """Get list of soft deleted items"""
    service = SoftDeleteService(db)
    
    items = service.get_deleted_items(Item, limit=limit, offset=offset)
    
    return [
        DeletedItemResponse(
            id=item.id,
            title=item.title,
            deleted_at=item.deleted_at,
            deleted_by=item.deleted_by,
            deletion_reason=item.deletion_reason
        )
        for item in items
    ]

@router.get("/items/stats")
async def get_item_deletion_stats(
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.VIEW_STATISTICS))
):
    """Get deletion statistics for items"""
    service = SoftDeleteService(db)
    stats = service.get_deletion_stats(Item)
    
    return DeletionStatsResponse(**stats)

# User soft delete endpoints
@router.delete("/users/{user_id}")
async def soft_delete_user(
    user_id: int,
    request: SoftDeleteRequest,
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.DELETE_USER))
):
    """Soft delete a user (admin only)"""
    service = SoftDeleteService(db)
    
    success = service.soft_delete_item(
        User, 
        user_id, 
        deleted_by=current_user.email,
        reason=request.reason
    )
    
    if not success:
        raise HTTPException(status_code=404, detail="User not found or already deleted")
    
    return SoftDeleteResponse(
        success=True,
        message=f"User {user_id} soft deleted successfully"
    )

@router.post("/users/{user_id}/restore")
async def restore_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.RESTORE_USER))
):
    """Restore a soft deleted user (admin only)"""
    service = SoftDeleteService(db)
    
    success = service.restore_item(
        User, 
        user_id, 
        restored_by=current_user.email
    )
    
    if not success:
        raise HTTPException(status_code=404, detail="User not found or not deleted")
    
    return RestoreResponse(
        success=True,
        message=f"User {user_id} restored successfully"
    )

# Match soft delete endpoints
@router.delete("/matches/{match_id}")
async def soft_delete_match(
    match_id: int,
    request: SoftDeleteRequest,
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.DELETE_MATCH))
):
    """Soft delete a match"""
    service = SoftDeleteService(db)
    
    success = service.soft_delete_item(
        Match, 
        match_id, 
        deleted_by=current_user.email,
        reason=request.reason
    )
    
    if not success:
        raise HTTPException(status_code=404, detail="Match not found or already deleted")
    
    return SoftDeleteResponse(
        success=True,
        message=f"Match {match_id} soft deleted successfully"
    )

# Cleanup endpoints
@router.delete("/cleanup/old-records")
async def cleanup_old_deleted_records(
    model_type: str = Query(..., regex="^(items|users|matches|claims)$"),
    days_old: int = Query(default=90, ge=1, le=365),
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.PERMANENT_DELETE))
):
    """Permanently delete old soft deleted records"""
    service = SoftDeleteService(db)
    
    model_map = {
        "items": Item,
        "users": User,
        "matches": Match,
        "claims": Claim
    }
    
    model_class = model_map[model_type]
    count = service.permanent_delete_old_records(model_class, days_old)
    
    return SoftDeleteResponse(
        success=True,
        message=f"Permanently deleted {count} old {model_type} records",
        deleted_count=count
    )

# Admin endpoints for viewing all deletion stats
@router.get("/stats/all")
async def get_all_deletion_stats(
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.VIEW_STATISTICS))
):
    """Get deletion statistics for all models"""
    service = SoftDeleteService(db)
    
    models = {
        "items": Item,
        "users": User,
        "matches": Match,
        "claims": Claim,
        "media_assets": MediaAsset
    }
    
    stats = {}
    for name, model_class in models.items():
        stats[name] = service.get_deletion_stats(model_class)
    
    return stats

# Audit endpoints
@router.get("/audit/recent-deletions")
async def get_recent_deletions(
    hours: int = Query(default=24, ge=1, le=168),  # Max 1 week
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.VIEW_AUDIT_LOGS))
):
    """Get recent deletion activity across all models"""
    from datetime import datetime, timedelta
    
    cutoff_time = datetime.utcnow() - timedelta(hours=hours)
    
    # Query recent deletions from all models
    recent_deletions = []
    
    models = [
        ("items", Item),
        ("users", User),
        ("matches", Match),
        ("claims", Claim),
        ("media_assets", MediaAsset)
    ]
    
    for model_name, model_class in models:
        if hasattr(model_class, 'deleted_at'):
            deletions = db.query(model_class).filter(
                model_class.deleted_at >= cutoff_time,
                model_class.is_deleted == True
            ).all()
            
            for deletion in deletions:
                recent_deletions.append({
                    "model_type": model_name,
                    "id": deletion.id,
                    "deleted_at": deletion.deleted_at,
                    "deleted_by": deletion.deleted_by,
                    "deletion_reason": deletion.deletion_reason
                })
    
    # Sort by deletion time (most recent first)
    recent_deletions.sort(key=lambda x: x["deleted_at"], reverse=True)
    
    return {
        "total_deletions": len(recent_deletions),
        "time_period_hours": hours,
        "deletions": recent_deletions
    }
