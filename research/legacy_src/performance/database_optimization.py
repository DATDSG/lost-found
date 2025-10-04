"""
Database Performance Optimization
Implements advanced indexing, query optimization, and caching strategies
"""

from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime, timedelta
from sqlalchemy import text, Index, func, and_, or_
from sqlalchemy.orm import Session
from sqlalchemy.sql import select
import redis
import json
import hashlib
import logging
from functools import wraps
import time

from ..core.config import settings
from ..database import get_db
from ..models.item import Item
from ..models.user import User
from ..models.match import Match
from ..models.claim import Claim

logger = logging.getLogger(__name__)

class DatabaseIndexManager:
    """Manages database indexes for optimal query performance"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def create_performance_indexes(self) -> Dict[str, bool]:
        """Create all performance-critical indexes"""
        results = {}
        
        # Geospatial indexes
        results.update(self._create_geospatial_indexes())
        
        # Search and filtering indexes
        results.update(self._create_search_indexes())
        
        # Relationship indexes
        results.update(self._create_relationship_indexes())
        
        # Temporal indexes
        results.update(self._create_temporal_indexes())
        
        # Composite indexes for common queries
        results.update(self._create_composite_indexes())
        
        return results
    
    def _create_geospatial_indexes(self) -> Dict[str, bool]:
        """Create geospatial indexes for location-based queries"""
        indexes = {
            # PostGIS spatial index on location column
            'items_location_gist': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_location_gist 
                ON items USING GIST (location);
            """,
            
            # Geohash index for spatial clustering
            'items_geohash': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_geohash 
                ON items (geohash) WHERE geohash IS NOT NULL;
            """,
            
            # Bounding box queries
            'items_lat_lng': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_lat_lng 
                ON items (ST_Y(location), ST_X(location)) 
                WHERE location IS NOT NULL;
            """
        }
        
        return self._execute_index_creation(indexes)
    
    def _create_search_indexes(self) -> Dict[str, bool]:
        """Create indexes for text search and filtering"""
        indexes = {
            # Full-text search indexes
            'items_search_vector': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_search_vector 
                ON items USING GIN (search_vector);
            """,
            
            # Trigram indexes for fuzzy search
            'items_title_trigram': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_title_trigram 
                ON items USING GIN (title gin_trgm_ops);
            """,
            
            'items_description_trigram': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_description_trigram 
                ON items USING GIN (description gin_trgm_ops);
            """,
            
            # Category and type filtering
            'items_category_type': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_category_type 
                ON items (category, type, status);
            """,
            
            # Brand and model search
            'items_brand_model': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_brand_model 
                ON items (brand, model) WHERE brand IS NOT NULL;
            """,
            
            # Color search
            'items_color': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_color 
                ON items (color) WHERE color IS NOT NULL;
            """
        }
        
        return self._execute_index_creation(indexes)
    
    def _create_relationship_indexes(self) -> Dict[str, bool]:
        """Create indexes for foreign key relationships"""
        indexes = {
            # User relationships
            'items_user_id': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_user_id 
                ON items (user_id);
            """,
            
            'claims_user_id': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_claims_user_id 
                ON claims (claimant_id);
            """,
            
            'claims_item_id': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_claims_item_id 
                ON claims (item_id);
            """,
            
            # Match relationships
            'matches_item1_id': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_item1_id 
                ON matches (item1_id);
            """,
            
            'matches_item2_id': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_item2_id 
                ON matches (item2_id);
            """,
            
            # Image relationships
            'item_images_item_id': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_item_images_item_id 
                ON item_images (item_id);
            """
        }
        
        return self._execute_index_creation(indexes)
    
    def _create_temporal_indexes(self) -> Dict[str, bool]:
        """Create indexes for time-based queries"""
        indexes = {
            # Creation time indexes
            'items_created_at': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_created_at 
                ON items (created_at DESC);
            """,
            
            'users_created_at': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_created_at 
                ON users (created_at);
            """,
            
            # Update time indexes
            'items_updated_at': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_updated_at 
                ON items (updated_at DESC);
            """,
            
            # Date lost/found indexes
            'items_date_lost_found': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_date_lost_found 
                ON items (date_lost_found DESC) WHERE date_lost_found IS NOT NULL;
            """,
            
            # Soft delete indexes
            'items_deleted_at': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_deleted_at 
                ON items (deleted_at) WHERE deleted_at IS NOT NULL;
            """,
            
            'items_is_deleted': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_is_deleted 
                ON items (is_deleted);
            """
        }
        
        return self._execute_index_creation(indexes)
    
    def _create_composite_indexes(self) -> Dict[str, bool]:
        """Create composite indexes for common query patterns"""
        indexes = {
            # Active items by location and time
            'items_active_location_time': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_active_location_time 
                ON items (status, type, created_at DESC, location) 
                WHERE is_deleted = FALSE AND status = 'active';
            """,
            
            # User's active items
            'items_user_active': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_user_active 
                ON items (user_id, status, created_at DESC) 
                WHERE is_deleted = FALSE;
            """,
            
            # Recent items by category
            'items_category_recent': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_category_recent 
                ON items (category, created_at DESC, status) 
                WHERE is_deleted = FALSE;
            """,
            
            # Matching optimization
            'items_matching_optimization': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_items_matching_optimization 
                ON items (type, category, status, created_at) 
                WHERE is_deleted = FALSE AND status = 'active';
            """,
            
            # Claims by status
            'claims_status_created': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_claims_status_created 
                ON claims (status, created_at DESC) 
                WHERE is_deleted = FALSE;
            """,
            
            # User login tracking
            'users_login_tracking': """
                CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_login_tracking 
                ON users (last_login DESC, is_active) 
                WHERE is_deleted = FALSE;
            """
        }
        
        return self._execute_index_creation(indexes)
    
    def _execute_index_creation(self, indexes: Dict[str, str]) -> Dict[str, bool]:
        """Execute index creation statements"""
        results = {}
        
        for index_name, sql in indexes.items():
            try:
                start_time = time.time()
                self.db.execute(text(sql))
                self.db.commit()
                
                execution_time = time.time() - start_time
                logger.info(f"Created index {index_name} in {execution_time:.2f}s")
                results[index_name] = True
                
            except Exception as e:
                logger.error(f"Failed to create index {index_name}: {e}")
                results[index_name] = False
                self.db.rollback()
        
        return results
    
    def analyze_query_performance(self, query: str) -> Dict[str, Any]:
        """Analyze query performance using EXPLAIN"""
        try:
            # Get query execution plan
            explain_query = f"EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) {query}"
            result = self.db.execute(text(explain_query)).fetchone()
            
            if result:
                plan = json.loads(result[0])[0]
                
                return {
                    'execution_time_ms': plan.get('Execution Time', 0),
                    'planning_time_ms': plan.get('Planning Time', 0),
                    'total_cost': plan['Plan'].get('Total Cost', 0),
                    'rows_returned': plan['Plan'].get('Actual Rows', 0),
                    'node_type': plan['Plan'].get('Node Type', ''),
                    'index_usage': self._extract_index_usage(plan['Plan'])
                }
            
        except Exception as e:
            logger.error(f"Query analysis failed: {e}")
            return {}
    
    def _extract_index_usage(self, plan_node: Dict[str, Any]) -> List[str]:
        """Extract index usage from query plan"""
        indexes = []
        
        if plan_node.get('Node Type') == 'Index Scan':
            indexes.append(plan_node.get('Index Name', ''))
        elif plan_node.get('Node Type') == 'Bitmap Index Scan':
            indexes.append(plan_node.get('Index Name', ''))
        
        # Recursively check child nodes
        for child in plan_node.get('Plans', []):
            indexes.extend(self._extract_index_usage(child))
        
        return [idx for idx in indexes if idx]
    
    def get_index_usage_stats(self) -> List[Dict[str, Any]]:
        """Get index usage statistics"""
        query = """
        SELECT 
            schemaname,
            tablename,
            indexname,
            idx_tup_read,
            idx_tup_fetch,
            idx_scan,
            CASE 
                WHEN idx_scan = 0 THEN 0 
                ELSE idx_tup_read::float / idx_scan 
            END as avg_tuples_per_scan
        FROM pg_stat_user_indexes
        ORDER BY idx_scan DESC, idx_tup_read DESC;
        """
        
        result = self.db.execute(text(query)).fetchall()
        
        return [
            {
                'schema': row[0],
                'table': row[1],
                'index': row[2],
                'tuples_read': row[3],
                'tuples_fetched': row[4],
                'scans': row[5],
                'avg_tuples_per_scan': float(row[6]) if row[6] else 0
            }
            for row in result
        ]

class QueryCacheManager:
    """Manages Redis-based query result caching"""
    
    def __init__(self):
        self.redis_client = redis.Redis(
            host=settings.REDIS_HOST,
            port=settings.REDIS_PORT,
            password=settings.REDIS_PASSWORD,
            db=settings.REDIS_CACHE_DB,
            decode_responses=True
        )
        self.default_ttl = settings.CACHE_DEFAULT_TTL
    
    def cache_key(self, query: str, params: Dict[str, Any] = None) -> str:
        """Generate cache key for query and parameters"""
        key_data = {
            'query': query,
            'params': params or {}
        }
        key_string = json.dumps(key_data, sort_keys=True)
        return f"query_cache:{hashlib.md5(key_string.encode()).hexdigest()}"
    
    def get_cached_result(self, cache_key: str) -> Optional[Any]:
        """Get cached query result"""
        try:
            cached_data = self.redis_client.get(cache_key)
            if cached_data:
                return json.loads(cached_data)
        except Exception as e:
            logger.error(f"Cache retrieval error: {e}")
        
        return None
    
    def cache_result(self, cache_key: str, result: Any, ttl: int = None) -> bool:
        """Cache query result"""
        try:
            ttl = ttl or self.default_ttl
            cached_data = json.dumps(result, default=str)
            self.redis_client.setex(cache_key, ttl, cached_data)
            return True
        except Exception as e:
            logger.error(f"Cache storage error: {e}")
            return False
    
    def invalidate_pattern(self, pattern: str) -> int:
        """Invalidate cache keys matching pattern"""
        try:
            keys = self.redis_client.keys(f"query_cache:*{pattern}*")
            if keys:
                return self.redis_client.delete(*keys)
        except Exception as e:
            logger.error(f"Cache invalidation error: {e}")
        
        return 0
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        try:
            info = self.redis_client.info()
            return {
                'used_memory_mb': info.get('used_memory', 0) / (1024 * 1024),
                'keyspace_hits': info.get('keyspace_hits', 0),
                'keyspace_misses': info.get('keyspace_misses', 0),
                'hit_rate': (
                    info.get('keyspace_hits', 0) / 
                    (info.get('keyspace_hits', 0) + info.get('keyspace_misses', 1))
                ) * 100,
                'connected_clients': info.get('connected_clients', 0)
            }
        except Exception as e:
            logger.error(f"Cache stats error: {e}")
            return {}

def cached_query(ttl: int = None, invalidate_on: List[str] = None):
    """Decorator for caching query results"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            cache_manager = QueryCacheManager()
            
            # Generate cache key
            cache_key = cache_manager.cache_key(
                query=f"{func.__module__}.{func.__name__}",
                params={'args': args, 'kwargs': kwargs}
            )
            
            # Try to get from cache
            cached_result = cache_manager.get_cached_result(cache_key)
            if cached_result is not None:
                return cached_result
            
            # Execute function and cache result
            result = func(*args, **kwargs)
            cache_manager.cache_result(cache_key, result, ttl)
            
            return result
        
        return wrapper
    return decorator

class PaginationManager:
    """Manages efficient pagination for large result sets"""
    
    @staticmethod
    def paginate_query(
        query,
        page: int = 1,
        per_page: int = 20,
        max_per_page: int = 100
    ) -> Dict[str, Any]:
        """Apply pagination to SQLAlchemy query"""
        # Validate parameters
        page = max(1, page)
        per_page = min(max(1, per_page), max_per_page)
        
        # Calculate offset
        offset = (page - 1) * per_page
        
        # Get total count (optimized for large tables)
        total = query.count()
        
        # Apply pagination
        items = query.offset(offset).limit(per_page).all()
        
        # Calculate pagination metadata
        total_pages = (total + per_page - 1) // per_page
        has_prev = page > 1
        has_next = page < total_pages
        
        return {
            'items': items,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': total,
                'total_pages': total_pages,
                'has_prev': has_prev,
                'has_next': has_next,
                'prev_page': page - 1 if has_prev else None,
                'next_page': page + 1 if has_next else None
            }
        }
    
    @staticmethod
    def cursor_paginate(
        query,
        cursor: Optional[str] = None,
        limit: int = 20,
        order_by_field: str = 'id'
    ) -> Dict[str, Any]:
        """Cursor-based pagination for better performance on large datasets"""
        limit = min(max(1, limit), 100)
        
        # Apply cursor filter if provided
        if cursor:
            try:
                cursor_value = int(cursor)
                query = query.filter(getattr(query.column_descriptions[0]['type'], order_by_field) > cursor_value)
            except (ValueError, AttributeError):
                pass
        
        # Get items with one extra to check if there are more
        items = query.order_by(order_by_field).limit(limit + 1).all()
        
        has_next = len(items) > limit
        if has_next:
            items = items[:-1]
        
        # Generate next cursor
        next_cursor = None
        if has_next and items:
            next_cursor = str(getattr(items[-1], order_by_field))
        
        return {
            'items': items,
            'pagination': {
                'cursor': cursor,
                'next_cursor': next_cursor,
                'has_next': has_next,
                'limit': limit
            }
        }

class QueryOptimizer:
    """Optimizes common queries for better performance"""
    
    def __init__(self, db: Session):
        self.db = db
    
    @cached_query(ttl=300)  # Cache for 5 minutes
    def get_nearby_items(
        self,
        latitude: float,
        longitude: float,
        radius_km: float = 5.0,
        item_type: Optional[str] = None,
        category: Optional[str] = None,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Optimized geospatial query for nearby items"""
        
        # Use PostGIS for efficient spatial queries
        query = self.db.query(Item).filter(
            Item.is_deleted == False,
            Item.status == 'active',
            func.ST_DWithin(
                Item.location,
                func.ST_GeogFromText(f'POINT({longitude} {latitude})'),
                radius_km * 1000  # Convert km to meters
            )
        )
        
        # Add optional filters
        if item_type:
            query = query.filter(Item.type == item_type)
        
        if category:
            query = query.filter(Item.category == category)
        
        # Order by distance and limit results
        query = query.order_by(
            func.ST_Distance(
                Item.location,
                func.ST_GeogFromText(f'POINT({longitude} {latitude})')
            )
        ).limit(limit)
        
        items = query.all()
        
        # Convert to serializable format
        return [
            {
                'id': item.id,
                'title': item.title,
                'type': item.type,
                'category': item.category,
                'distance_km': self._calculate_distance(
                    latitude, longitude,
                    item.location.latitude, item.location.longitude
                ),
                'created_at': item.created_at.isoformat()
            }
            for item in items
        ]
    
    @cached_query(ttl=600)  # Cache for 10 minutes
    def get_matching_candidates(
        self,
        item_id: int,
        max_distance_km: float = 10.0,
        max_time_diff_hours: int = 168,  # 1 week
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Optimized query for finding matching candidates"""
        
        # Get the source item
        source_item = self.db.query(Item).filter(Item.id == item_id).first()
        if not source_item:
            return []
        
        # Determine opposite type
        opposite_type = 'found' if source_item.type == 'lost' else 'lost'
        
        # Time range filter
        time_cutoff = datetime.utcnow() - timedelta(hours=max_time_diff_hours)
        
        # Build optimized query
        query = self.db.query(Item).filter(
            Item.is_deleted == False,
            Item.status == 'active',
            Item.type == opposite_type,
            Item.category == source_item.category,
            Item.created_at >= time_cutoff,
            Item.id != item_id,
            func.ST_DWithin(
                Item.location,
                source_item.location,
                max_distance_km * 1000
            )
        ).order_by(
            func.ST_Distance(Item.location, source_item.location),
            Item.created_at.desc()
        ).limit(limit)
        
        candidates = query.all()
        
        return [
            {
                'id': candidate.id,
                'title': candidate.title,
                'description': candidate.description,
                'distance_km': self._calculate_distance(
                    source_item.location.latitude,
                    source_item.location.longitude,
                    candidate.location.latitude,
                    candidate.location.longitude
                ),
                'time_diff_hours': (
                    datetime.utcnow() - candidate.created_at
                ).total_seconds() / 3600,
                'created_at': candidate.created_at.isoformat()
            }
            for candidate in candidates
        ]
    
    def _calculate_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two points using Haversine formula"""
        from math import radians, cos, sin, asin, sqrt
        
        # Convert to radians
        lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
        
        # Haversine formula
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * asin(sqrt(a))
        
        # Radius of earth in kilometers
        r = 6371
        
        return c * r

# Performance monitoring
class PerformanceMonitor:
    """Monitors database and cache performance"""
    
    def __init__(self, db: Session):
        self.db = db
        self.cache_manager = QueryCacheManager()
    
    def get_performance_metrics(self) -> Dict[str, Any]:
        """Get comprehensive performance metrics"""
        return {
            'database': self._get_database_metrics(),
            'cache': self.cache_manager.get_cache_stats(),
            'queries': self._get_slow_queries(),
            'indexes': self._get_index_efficiency()
        }
    
    def _get_database_metrics(self) -> Dict[str, Any]:
        """Get database performance metrics"""
        try:
            # Connection stats
            conn_query = """
            SELECT count(*) as active_connections,
                   max(now() - query_start) as longest_query
            FROM pg_stat_activity 
            WHERE state = 'active';
            """
            
            conn_result = self.db.execute(text(conn_query)).fetchone()
            
            # Table stats
            table_query = """
            SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del, n_live_tup
            FROM pg_stat_user_tables
            ORDER BY n_live_tup DESC;
            """
            
            table_results = self.db.execute(text(table_query)).fetchall()
            
            return {
                'active_connections': conn_result[0] if conn_result else 0,
                'longest_query_duration': str(conn_result[1]) if conn_result and conn_result[1] else '0',
                'table_stats': [
                    {
                        'schema': row[0],
                        'table': row[1],
                        'inserts': row[2],
                        'updates': row[3],
                        'deletes': row[4],
                        'live_tuples': row[5]
                    }
                    for row in table_results[:10]  # Top 10 tables
                ]
            }
        except Exception as e:
            logger.error(f"Database metrics error: {e}")
            return {}
    
    def _get_slow_queries(self) -> List[Dict[str, Any]]:
        """Get slow query statistics"""
        try:
            query = """
            SELECT query, calls, total_time, mean_time, rows
            FROM pg_stat_statements
            WHERE calls > 10
            ORDER BY mean_time DESC
            LIMIT 10;
            """
            
            results = self.db.execute(text(query)).fetchall()
            
            return [
                {
                    'query': row[0][:200] + '...' if len(row[0]) > 200 else row[0],
                    'calls': row[1],
                    'total_time_ms': float(row[2]),
                    'mean_time_ms': float(row[3]),
                    'avg_rows': row[4]
                }
                for row in results
            ]
        except Exception as e:
            logger.error(f"Slow queries error: {e}")
            return []
    
    def _get_index_efficiency(self) -> Dict[str, Any]:
        """Get index efficiency metrics"""
        try:
            query = """
            SELECT 
                t.tablename,
                indexrelname,
                idx_scan,
                idx_tup_read,
                idx_tup_fetch,
                pg_size_pretty(pg_relation_size(indexrelid)) as size
            FROM pg_stat_user_indexes i
            JOIN pg_stat_user_tables t ON i.relid = t.relid
            WHERE idx_scan < 50  -- Potentially unused indexes
            ORDER BY pg_relation_size(indexrelid) DESC;
            """
            
            results = self.db.execute(text(query)).fetchall()
            
            return {
                'potentially_unused_indexes': [
                    {
                        'table': row[0],
                        'index': row[1],
                        'scans': row[2],
                        'tuples_read': row[3],
                        'tuples_fetched': row[4],
                        'size': row[5]
                    }
                    for row in results[:10]
                ]
            }
        except Exception as e:
            logger.error(f"Index efficiency error: {e}")
            return {}
