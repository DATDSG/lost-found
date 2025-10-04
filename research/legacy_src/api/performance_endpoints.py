"""
API endpoints for database performance optimization
Provides REST endpoints for managing indexes, caching, and performance monitoring
"""

from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Dict, Any, Optional
from pydantic import BaseModel
from datetime import datetime

from app.db.session import get_db
from src.performance.database_optimization import (
    DatabaseIndexManager, 
    QueryCacheManager, 
    PaginationManager, 
    QueryOptimizer,
    PerformanceMonitor
)
from src.auth.rbac import require_permissions, Permission

router = APIRouter(prefix="/api/v1/performance", tags=["performance"])

# Pydantic models
class IndexCreationResponse(BaseModel):
    success: bool
    created_indexes: Dict[str, bool]
    total_created: int
    total_failed: int

class QueryAnalysisRequest(BaseModel):
    query: str

class QueryAnalysisResponse(BaseModel):
    execution_time_ms: float
    planning_time_ms: float
    total_cost: float
    rows_returned: int
    node_type: str
    index_usage: List[str]

class CacheStatsResponse(BaseModel):
    used_memory_mb: float
    keyspace_hits: int
    keyspace_misses: int
    hit_rate: float
    connected_clients: int

class NearbyItemsRequest(BaseModel):
    latitude: float
    longitude: float
    radius_km: float = 5.0
    item_type: Optional[str] = None
    category: Optional[str] = None
    limit: int = 50

class MatchingCandidatesRequest(BaseModel):
    item_id: int
    max_distance_km: float = 10.0
    max_time_diff_hours: int = 168
    limit: int = 20

# Index management endpoints
@router.post("/indexes/create-all")
async def create_all_indexes(
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.MANAGE_SYSTEM))
):
    """Create all performance indexes (runs in background)"""
    
    def create_indexes_task():
        index_manager = DatabaseIndexManager(db)
        results = index_manager.create_performance_indexes()
        
        # Log results
        created = sum(1 for success in results.values() if success)
        failed = len(results) - created
        
        # You could send notification to admin here
        print(f"Index creation completed: {created} created, {failed} failed")
    
    background_tasks.add_task(create_indexes_task)
    
    return {
        "message": "Index creation started in background",
        "status": "running"
    }

@router.get("/indexes/usage-stats")
async def get_index_usage_stats(
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.VIEW_STATISTICS))
):
    """Get index usage statistics"""
    index_manager = DatabaseIndexManager(db)
    stats = index_manager.get_index_usage_stats()
    
    return {
        "total_indexes": len(stats),
        "indexes": stats
    }

@router.post("/queries/analyze")
async def analyze_query_performance(
    request: QueryAnalysisRequest,
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.ANALYZE_QUERIES))
):
    """Analyze query performance using EXPLAIN"""
    index_manager = DatabaseIndexManager(db)
    
    try:
        analysis = index_manager.analyze_query_performance(request.query)
        
        if not analysis:
            raise HTTPException(status_code=400, detail="Query analysis failed")
        
        return QueryAnalysisResponse(**analysis)
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Query analysis error: {str(e)}")

# Cache management endpoints
@router.get("/cache/stats")
async def get_cache_stats(
    current_user = Depends(require_permissions(Permission.VIEW_STATISTICS))
):
    """Get Redis cache statistics"""
    cache_manager = QueryCacheManager()
    stats = cache_manager.get_cache_stats()
    
    if not stats:
        raise HTTPException(status_code=503, detail="Cache unavailable")
    
    return CacheStatsResponse(**stats)

@router.delete("/cache/invalidate")
async def invalidate_cache_pattern(
    pattern: str = Query(..., description="Pattern to match for cache invalidation"),
    current_user = Depends(require_permissions(Permission.MANAGE_CACHE))
):
    """Invalidate cache keys matching pattern"""
    cache_manager = QueryCacheManager()
    
    try:
        invalidated_count = cache_manager.invalidate_pattern(pattern)
        
        return {
            "success": True,
            "invalidated_keys": invalidated_count,
            "pattern": pattern
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Cache invalidation failed: {str(e)}")

@router.delete("/cache/clear-all")
async def clear_all_cache(
    current_user = Depends(require_permissions(Permission.MANAGE_CACHE))
):
    """Clear all cache (use with caution)"""
    cache_manager = QueryCacheManager()
    
    try:
        # Clear all query cache keys
        invalidated_count = cache_manager.invalidate_pattern("")
        
        return {
            "success": True,
            "message": "All cache cleared",
            "invalidated_keys": invalidated_count
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Cache clear failed: {str(e)}")

# Optimized query endpoints
@router.post("/queries/nearby-items")
async def get_nearby_items_optimized(
    request: NearbyItemsRequest,
    db: Session = Depends(get_db)
):
    """Get nearby items using optimized geospatial query"""
    optimizer = QueryOptimizer(db)
    
    try:
        items = optimizer.get_nearby_items(
            latitude=request.latitude,
            longitude=request.longitude,
            radius_km=request.radius_km,
            item_type=request.item_type,
            category=request.category,
            limit=request.limit
        )
        
        return {
            "items": items,
            "count": len(items),
            "query_params": request.dict()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Nearby items query failed: {str(e)}")

@router.post("/queries/matching-candidates")
async def get_matching_candidates_optimized(
    request: MatchingCandidatesRequest,
    db: Session = Depends(get_db)
):
    """Get matching candidates using optimized query"""
    optimizer = QueryOptimizer(db)
    
    try:
        candidates = optimizer.get_matching_candidates(
            item_id=request.item_id,
            max_distance_km=request.max_distance_km,
            max_time_diff_hours=request.max_time_diff_hours,
            limit=request.limit
        )
        
        return {
            "candidates": candidates,
            "count": len(candidates),
            "query_params": request.dict()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Matching candidates query failed: {str(e)}")

# Pagination endpoints
@router.get("/pagination/items")
async def paginate_items(
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=20, ge=1, le=100),
    category: Optional[str] = Query(default=None),
    status: Optional[str] = Query(default=None),
    db: Session = Depends(get_db)
):
    """Get paginated items with optional filtering"""
    from app.db.models import Item
    
    # Build base query
    query = db.query(Item).filter(Item.is_deleted == False)
    
    # Apply filters
    if category:
        query = query.filter(Item.category == category)
    if status:
        query = query.filter(Item.status == status)
    
    # Apply pagination
    result = PaginationManager.paginate_query(
        query=query,
        page=page,
        per_page=per_page
    )
    
    # Convert items to dict for JSON serialization
    items_data = []
    for item in result['items']:
        items_data.append({
            'id': item.id,
            'title': item.title,
            'category': item.category,
            'status': item.status,
            'created_at': item.created_at.isoformat()
        })
    
    result['items'] = items_data
    return result

@router.get("/pagination/items/cursor")
async def cursor_paginate_items(
    cursor: Optional[str] = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    category: Optional[str] = Query(default=None),
    db: Session = Depends(get_db)
):
    """Get items using cursor-based pagination"""
    from app.db.models import Item
    
    # Build base query
    query = db.query(Item).filter(Item.is_deleted == False)
    
    # Apply filters
    if category:
        query = query.filter(Item.category == category)
    
    # Apply cursor pagination
    result = PaginationManager.cursor_paginate(
        query=query,
        cursor=cursor,
        limit=limit,
        order_by_field='id'
    )
    
    # Convert items to dict for JSON serialization
    items_data = []
    for item in result['items']:
        items_data.append({
            'id': item.id,
            'title': item.title,
            'category': item.category,
            'status': item.status,
            'created_at': item.created_at.isoformat()
        })
    
    result['items'] = items_data
    return result

# Performance monitoring endpoints
@router.get("/monitoring/metrics")
async def get_performance_metrics(
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.VIEW_STATISTICS))
):
    """Get comprehensive performance metrics"""
    monitor = PerformanceMonitor(db)
    
    try:
        metrics = monitor.get_performance_metrics()
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "metrics": metrics
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Performance metrics failed: {str(e)}")

@router.get("/monitoring/health")
async def get_system_health(
    db: Session = Depends(get_db)
):
    """Get basic system health indicators"""
    try:
        # Test database connection
        db.execute("SELECT 1")
        db_healthy = True
    except:
        db_healthy = False
    
    # Test cache connection
    try:
        cache_manager = QueryCacheManager()
        cache_manager.redis_client.ping()
        cache_healthy = True
    except:
        cache_healthy = False
    
    # Overall health
    overall_healthy = db_healthy and cache_healthy
    
    return {
        "healthy": overall_healthy,
        "timestamp": datetime.utcnow().isoformat(),
        "components": {
            "database": {
                "healthy": db_healthy,
                "status": "connected" if db_healthy else "disconnected"
            },
            "cache": {
                "healthy": cache_healthy,
                "status": "connected" if cache_healthy else "disconnected"
            }
        }
    }

# Bulk operations with pagination
@router.get("/bulk/export-items")
async def bulk_export_items(
    format: str = Query(default="json", regex="^(json|csv)$"),
    category: Optional[str] = Query(default=None),
    status: Optional[str] = Query(default=None),
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=1000, ge=1, le=5000),
    db: Session = Depends(get_db),
    current_user = Depends(require_permissions(Permission.EXPORT_DATA))
):
    """Export items in bulk with pagination"""
    from app.db.models import Item
    
    # Build query
    query = db.query(Item).filter(Item.is_deleted == False)
    
    if category:
        query = query.filter(Item.category == category)
    if status:
        query = query.filter(Item.status == status)
    
    # Apply pagination
    result = PaginationManager.paginate_query(
        query=query,
        page=page,
        per_page=per_page
    )
    
    # Format data
    if format == "json":
        items_data = []
        for item in result['items']:
            items_data.append({
                'id': item.id,
                'title': item.title,
                'description': item.description,
                'category': item.category,
                'status': item.status,
                'created_at': item.created_at.isoformat(),
                'updated_at': item.updated_at.isoformat()
            })
        
        return {
            "format": "json",
            "data": items_data,
            "pagination": result['pagination']
        }
    
    elif format == "csv":
        import csv
        import io
        
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Write header
        writer.writerow(['id', 'title', 'description', 'category', 'status', 'created_at', 'updated_at'])
        
        # Write data
        for item in result['items']:
            writer.writerow([
                item.id,
                item.title,
                item.description or '',
                item.category,
                item.status,
                item.created_at.isoformat(),
                item.updated_at.isoformat()
            ])
        
        csv_data = output.getvalue()
        output.close()
        
        return {
            "format": "csv",
            "data": csv_data,
            "pagination": result['pagination']
        }
