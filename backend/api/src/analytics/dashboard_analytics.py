"""
Analytics & Reporting Dashboard
Comprehensive analytics for admin dashboard, success metrics, user behavior, and geographic heatmaps
"""

import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from enum import Enum
import logging
import json

from sqlalchemy.orm import Session
from sqlalchemy import func, text, and_, or_, case, extract
from sqlalchemy.sql import select
import pandas as pd
import numpy as np
from geopy.distance import geodesic
import redis

from app.db.models import Item, User, Match, Claim, ChatMessage, AuditLog, Notification
from src.performance.database_optimization import QueryCacheManager, cached_query

logger = logging.getLogger(__name__)

class MetricType(Enum):
    """Types of metrics"""
    COUNT = "count"
    PERCENTAGE = "percentage"
    AVERAGE = "average"
    TREND = "trend"
    DISTRIBUTION = "distribution"
    HEATMAP = "heatmap"

class TimeRange(Enum):
    """Time range options for analytics"""
    LAST_24H = "last_24h"
    LAST_7D = "last_7d"
    LAST_30D = "last_30d"
    LAST_90D = "last_90d"
    LAST_YEAR = "last_year"
    ALL_TIME = "all_time"

@dataclass
class Metric:
    """Analytics metric structure"""
    name: str
    value: Any
    type: MetricType
    description: str
    trend: Optional[float] = None
    comparison_period: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

@dataclass
class GeographicPoint:
    """Geographic data point for heatmaps"""
    latitude: float
    longitude: float
    weight: int
    category: str
    metadata: Dict[str, Any]

@dataclass
class UserBehaviorMetric:
    """User behavior analytics"""
    user_id: int
    session_count: int
    avg_session_duration: float
    items_posted: int
    matches_viewed: int
    claims_submitted: int
    messages_sent: int
    last_activity: datetime
    engagement_score: float

class DashboardAnalytics:
    """Main dashboard analytics service"""
    
    def __init__(self, db: Session):
        self.db = db
        self.cache_manager = QueryCacheManager()
    
    @cached_query(ttl=300)  # Cache for 5 minutes
    async def get_key_metrics(self, time_range: TimeRange = TimeRange.LAST_30D) -> Dict[str, Metric]:
        """Get key dashboard metrics"""
        
        # Calculate time boundaries
        end_date = datetime.utcnow()
        start_date = self._get_start_date(end_date, time_range)
        
        # Previous period for comparison
        period_length = end_date - start_date
        prev_start = start_date - period_length
        prev_end = start_date
        
        metrics = {}
        
        # 1. Total Items
        current_items = self.db.query(func.count(Item.id)).filter(
            Item.created_at >= start_date,
            Item.created_at <= end_date,
            Item.is_deleted == False
        ).scalar()
        
        prev_items = self.db.query(func.count(Item.id)).filter(
            Item.created_at >= prev_start,
            Item.created_at < prev_end,
            Item.is_deleted == False
        ).scalar()
        
        trend = ((current_items - prev_items) / max(prev_items, 1)) * 100 if prev_items else 0
        
        metrics["total_items"] = Metric(
            name="Total Items",
            value=current_items,
            type=MetricType.COUNT,
            description="Total items posted in the selected period",
            trend=trend,
            comparison_period=f"vs previous {time_range.value}"
        )
        
        # 2. Successful Matches
        successful_matches = self.db.query(func.count(Match.id)).filter(
            Match.created_at >= start_date,
            Match.created_at <= end_date,
            Match.status == 'claimed'
        ).scalar()
        
        prev_matches = self.db.query(func.count(Match.id)).filter(
            Match.created_at >= prev_start,
            Match.created_at < prev_end,
            Match.status == 'claimed'
        ).scalar()
        
        match_trend = ((successful_matches - prev_matches) / max(prev_matches, 1)) * 100 if prev_matches else 0
        
        metrics["successful_matches"] = Metric(
            name="Successful Matches",
            value=successful_matches,
            type=MetricType.COUNT,
            description="Items successfully reunited with owners",
            trend=match_trend,
            comparison_period=f"vs previous {time_range.value}"
        )
        
        # 3. Success Rate
        total_matches = self.db.query(func.count(Match.id)).filter(
            Match.created_at >= start_date,
            Match.created_at <= end_date
        ).scalar()
        
        success_rate = (successful_matches / max(total_matches, 1)) * 100
        
        metrics["success_rate"] = Metric(
            name="Success Rate",
            value=round(success_rate, 1),
            type=MetricType.PERCENTAGE,
            description="Percentage of matches that resulted in successful claims",
            metadata={"total_matches": total_matches}
        )
        
        # 4. Active Users
        active_users = self.db.query(func.count(func.distinct(AuditLog.user_id))).filter(
            AuditLog.created_at >= start_date,
            AuditLog.created_at <= end_date,
            AuditLog.user_id.isnot(None)
        ).scalar()
        
        metrics["active_users"] = Metric(
            name="Active Users",
            value=active_users,
            type=MetricType.COUNT,
            description="Users who performed actions in the selected period"
        )
        
        # 5. Average Response Time
        avg_response_time = self.db.query(
            func.avg(
                extract('epoch', ChatMessage.created_at) - 
                extract('epoch', Match.created_at)
            ) / 3600  # Convert to hours
        ).join(Match, ChatMessage.match_id == Match.id).filter(
            ChatMessage.created_at >= start_date,
            ChatMessage.created_at <= end_date
        ).scalar()
        
        metrics["avg_response_time"] = Metric(
            name="Avg Response Time",
            value=round(avg_response_time or 0, 1),
            type=MetricType.AVERAGE,
            description="Average time (hours) from match to first message",
            metadata={"unit": "hours"}
        )
        
        return metrics
    
    @cached_query(ttl=600)  # Cache for 10 minutes
    async def get_category_distribution(self, time_range: TimeRange = TimeRange.LAST_30D) -> Dict[str, Any]:
        """Get item category distribution"""
        
        start_date = self._get_start_date(datetime.utcnow(), time_range)
        
        # Category distribution
        category_data = self.db.query(
            Item.category,
            func.count(Item.id).label('count'),
            func.count(case([(Item.status == 'lost', 1)])).label('lost_count'),
            func.count(case([(Item.status == 'found', 1)])).label('found_count')
        ).filter(
            Item.created_at >= start_date,
            Item.is_deleted == False
        ).group_by(Item.category).all()
        
        categories = []
        for row in category_data:
            categories.append({
                "category": row.category,
                "total": row.count,
                "lost": row.lost_count,
                "found": row.found_count,
                "balance": row.found_count - row.lost_count
            })
        
        return {
            "categories": categories,
            "total_items": sum(cat["total"] for cat in categories)
        }
    
    @cached_query(ttl=300)
    async def get_temporal_trends(self, time_range: TimeRange = TimeRange.LAST_30D) -> Dict[str, Any]:
        """Get temporal trends for items and matches"""
        
        start_date = self._get_start_date(datetime.utcnow(), time_range)
        
        # Daily item posting trends
        if time_range in [TimeRange.LAST_24H, TimeRange.LAST_7D]:
            date_trunc = 'hour'
            date_format = '%Y-%m-%d %H:00'
        else:
            date_trunc = 'day'
            date_format = '%Y-%m-%d'
        
        item_trends = self.db.query(
            func.date_trunc(date_trunc, Item.created_at).label('period'),
            func.count(case([(Item.status == 'lost', 1)])).label('lost_items'),
            func.count(case([(Item.status == 'found', 1)])).label('found_items')
        ).filter(
            Item.created_at >= start_date,
            Item.is_deleted == False
        ).group_by(func.date_trunc(date_trunc, Item.created_at)).order_by('period').all()
        
        # Match trends
        match_trends = self.db.query(
            func.date_trunc(date_trunc, Match.created_at).label('period'),
            func.count(Match.id).label('matches'),
            func.count(case([(Match.status == 'claimed', 1)])).label('successful_matches')
        ).filter(
            Match.created_at >= start_date
        ).group_by(func.date_trunc(date_trunc, Match.created_at)).order_by('period').all()
        
        # Format data
        trends = {
            "items": [
                {
                    "date": row.period.strftime(date_format),
                    "lost": row.lost_items,
                    "found": row.found_items,
                    "total": row.lost_items + row.found_items
                }
                for row in item_trends
            ],
            "matches": [
                {
                    "date": row.period.strftime(date_format),
                    "total_matches": row.matches,
                    "successful_matches": row.successful_matches,
                    "success_rate": (row.successful_matches / max(row.matches, 1)) * 100
                }
                for row in match_trends
            ]
        }
        
        return trends
    
    def _get_start_date(self, end_date: datetime, time_range: TimeRange) -> datetime:
        """Calculate start date based on time range"""
        if time_range == TimeRange.LAST_24H:
            return end_date - timedelta(hours=24)
        elif time_range == TimeRange.LAST_7D:
            return end_date - timedelta(days=7)
        elif time_range == TimeRange.LAST_30D:
            return end_date - timedelta(days=30)
        elif time_range == TimeRange.LAST_90D:
            return end_date - timedelta(days=90)
        elif time_range == TimeRange.LAST_YEAR:
            return end_date - timedelta(days=365)
        else:  # ALL_TIME
            return datetime(2020, 1, 1)  # System start date

class SuccessMetrics:
    """Track and analyze match success rates"""
    
    def __init__(self, db: Session):
        self.db = db
    
    @cached_query(ttl=600)
    async def get_match_success_analysis(self) -> Dict[str, Any]:
        """Comprehensive match success analysis"""
        
        # Overall success metrics
        total_matches = self.db.query(func.count(Match.id)).scalar()
        successful_matches = self.db.query(func.count(Match.id)).filter(
            Match.status == 'claimed'
        ).scalar()
        
        overall_success_rate = (successful_matches / max(total_matches, 1)) * 100
        
        # Success rate by category
        category_success = self.db.query(
            Item.category,
            func.count(Match.id).label('total_matches'),
            func.count(case([(Match.status == 'claimed', 1)])).label('successful_matches')
        ).join(Item, Match.lost_item_id == Item.id).group_by(Item.category).all()
        
        category_analysis = []
        for row in category_success:
            success_rate = (row.successful_matches / max(row.total_matches, 1)) * 100
            category_analysis.append({
                "category": row.category,
                "total_matches": row.total_matches,
                "successful_matches": row.successful_matches,
                "success_rate": round(success_rate, 1)
            })
        
        # Success rate by match score ranges
        score_ranges = [
            (0.0, 0.3, "Low (0-30%)"),
            (0.3, 0.5, "Medium (30-50%)"),
            (0.5, 0.7, "High (50-70%)"),
            (0.7, 0.9, "Very High (70-90%)"),
            (0.9, 1.0, "Excellent (90-100%)")
        ]
        
        score_analysis = []
        for min_score, max_score, label in score_ranges:
            matches_in_range = self.db.query(func.count(Match.id)).filter(
                Match.score_final >= min_score,
                Match.score_final < max_score
            ).scalar()
            
            successful_in_range = self.db.query(func.count(Match.id)).filter(
                Match.score_final >= min_score,
                Match.score_final < max_score,
                Match.status == 'claimed'
            ).scalar()
            
            success_rate = (successful_in_range / max(matches_in_range, 1)) * 100
            
            score_analysis.append({
                "score_range": label,
                "total_matches": matches_in_range,
                "successful_matches": successful_in_range,
                "success_rate": round(success_rate, 1)
            })
        
        # Time to success analysis
        time_to_success = self.db.query(
            func.avg(
                extract('epoch', Claim.created_at) - 
                extract('epoch', Match.created_at)
            ) / 3600  # Convert to hours
        ).join(Match, Claim.match_id == Match.id).filter(
            Claim.status == 'approved'
        ).scalar()
        
        return {
            "overall": {
                "total_matches": total_matches,
                "successful_matches": successful_matches,
                "success_rate": round(overall_success_rate, 1),
                "avg_time_to_success_hours": round(time_to_success or 0, 1)
            },
            "by_category": category_analysis,
            "by_score_range": score_analysis
        }
    
    async def get_conversion_funnel(self) -> Dict[str, Any]:
        """Analyze the conversion funnel from item posting to successful match"""
        
        # Funnel stages
        total_items = self.db.query(func.count(Item.id)).filter(
            Item.is_deleted == False
        ).scalar()
        
        items_with_matches = self.db.query(func.count(func.distinct(Match.lost_item_id))).scalar()
        
        matches_with_claims = self.db.query(func.count(func.distinct(Claim.match_id))).scalar()
        
        successful_claims = self.db.query(func.count(Claim.id)).filter(
            Claim.status == 'approved'
        ).scalar()
        
        # Calculate conversion rates
        match_rate = (items_with_matches / max(total_items, 1)) * 100
        claim_rate = (matches_with_claims / max(items_with_matches, 1)) * 100
        success_rate = (successful_claims / max(matches_with_claims, 1)) * 100
        
        return {
            "funnel_stages": [
                {
                    "stage": "Items Posted",
                    "count": total_items,
                    "conversion_rate": 100.0,
                    "description": "Total items posted by users"
                },
                {
                    "stage": "Items with Matches",
                    "count": items_with_matches,
                    "conversion_rate": round(match_rate, 1),
                    "description": "Items that received at least one match"
                },
                {
                    "stage": "Matches with Claims",
                    "count": matches_with_claims,
                    "conversion_rate": round(claim_rate, 1),
                    "description": "Matches that received claim submissions"
                },
                {
                    "stage": "Successful Claims",
                    "count": successful_claims,
                    "conversion_rate": round(success_rate, 1),
                    "description": "Claims that were approved and items reunited"
                }
            ],
            "overall_conversion_rate": round((successful_claims / max(total_items, 1)) * 100, 2)
        }

class UserBehaviorAnalytics:
    """Analyze user behavior patterns"""
    
    def __init__(self, db: Session):
        self.db = db
    
    @cached_query(ttl=900)  # Cache for 15 minutes
    async def get_user_engagement_metrics(self) -> Dict[str, Any]:
        """Get comprehensive user engagement metrics"""
        
        # Active user counts by period
        now = datetime.utcnow()
        
        daily_active = self.db.query(func.count(func.distinct(AuditLog.user_id))).filter(
            AuditLog.created_at >= now - timedelta(days=1),
            AuditLog.user_id.isnot(None)
        ).scalar()
        
        weekly_active = self.db.query(func.count(func.distinct(AuditLog.user_id))).filter(
            AuditLog.created_at >= now - timedelta(days=7),
            AuditLog.user_id.isnot(None)
        ).scalar()
        
        monthly_active = self.db.query(func.count(func.distinct(AuditLog.user_id))).filter(
            AuditLog.created_at >= now - timedelta(days=30),
            AuditLog.user_id.isnot(None)
        ).scalar()
        
        # User retention analysis
        new_users_last_month = self.db.query(func.count(User.id)).filter(
            User.created_at >= now - timedelta(days=30)
        ).scalar()
        
        returning_users = self.db.query(func.count(func.distinct(AuditLog.user_id))).filter(
            AuditLog.created_at >= now - timedelta(days=30),
            AuditLog.user_id.in_(
                self.db.query(User.id).filter(
                    User.created_at < now - timedelta(days=30)
                )
            )
        ).scalar()
        
        # User activity distribution
        user_activity = self.db.query(
            AuditLog.user_id,
            func.count(AuditLog.id).label('activity_count'),
            func.count(func.distinct(func.date(AuditLog.created_at))).label('active_days')
        ).filter(
            AuditLog.created_at >= now - timedelta(days=30),
            AuditLog.user_id.isnot(None)
        ).group_by(AuditLog.user_id).all()
        
        # Categorize users by engagement level
        low_engagement = sum(1 for row in user_activity if row.activity_count < 5)
        medium_engagement = sum(1 for row in user_activity if 5 <= row.activity_count < 20)
        high_engagement = sum(1 for row in user_activity if row.activity_count >= 20)
        
        return {
            "active_users": {
                "daily": daily_active,
                "weekly": weekly_active,
                "monthly": monthly_active
            },
            "user_retention": {
                "new_users_last_month": new_users_last_month,
                "returning_users": returning_users,
                "retention_rate": round((returning_users / max(monthly_active, 1)) * 100, 1)
            },
            "engagement_distribution": {
                "low_engagement": low_engagement,
                "medium_engagement": medium_engagement,
                "high_engagement": high_engagement,
                "total_active_users": len(user_activity)
            }
        }
    
    async def get_user_journey_analysis(self) -> Dict[str, Any]:
        """Analyze typical user journeys and behavior patterns"""
        
        # Most common user actions
        action_frequency = self.db.query(
            AuditLog.action,
            func.count(AuditLog.id).label('frequency')
        ).filter(
            AuditLog.created_at >= datetime.utcnow() - timedelta(days=30)
        ).group_by(AuditLog.action).order_by(func.count(AuditLog.id).desc()).all()
        
        # User posting patterns
        posting_patterns = self.db.query(
            extract('hour', Item.created_at).label('hour'),
            func.count(Item.id).label('count')
        ).filter(
            Item.created_at >= datetime.utcnow() - timedelta(days=30),
            Item.is_deleted == False
        ).group_by(extract('hour', Item.created_at)).order_by('hour').all()
        
        # Response time patterns
        response_times = self.db.query(
            func.avg(
                extract('epoch', ChatMessage.created_at) - 
                extract('epoch', Match.created_at)
            ) / 3600  # Convert to hours
        ).join(Match, ChatMessage.match_id == Match.id).filter(
            ChatMessage.created_at >= datetime.utcnow() - timedelta(days=30)
        ).scalar()
        
        return {
            "common_actions": [
                {"action": row.action, "frequency": row.frequency}
                for row in action_frequency[:10]
            ],
            "posting_patterns": [
                {"hour": int(row.hour), "count": row.count}
                for row in posting_patterns
            ],
            "avg_response_time_hours": round(response_times or 0, 1)
        }

class GeographicAnalytics:
    """Geographic heatmap and location analytics"""
    
    def __init__(self, db: Session):
        self.db = db
    
    @cached_query(ttl=1800)  # Cache for 30 minutes
    async def get_geographic_heatmap_data(self, category: Optional[str] = None) -> Dict[str, Any]:
        """Generate geographic heatmap data for item distributions"""
        
        # Base query for items with location data
        query = self.db.query(
            Item.category,
            Item.status,
            func.ST_Y(Item.location_point).label('latitude'),
            func.ST_X(Item.location_point).label('longitude'),
            Item.created_at
        ).filter(
            Item.location_point.isnot(None),
            Item.is_deleted == False,
            Item.created_at >= datetime.utcnow() - timedelta(days=90)  # Last 3 months
        )
        
        if category:
            query = query.filter(Item.category == category)
        
        items = query.all()
        
        # Process data for heatmap
        heatmap_points = []
        category_distribution = {}
        
        for item in items:
            point = GeographicPoint(
                latitude=float(item.latitude),
                longitude=float(item.longitude),
                weight=1,
                category=item.category,
                metadata={
                    "status": item.status,
                    "created_at": item.created_at.isoformat()
                }
            )
            heatmap_points.append(point)
            
            # Count by category
            if item.category not in category_distribution:
                category_distribution[item.category] = {"lost": 0, "found": 0}
            category_distribution[item.category][item.status] += 1
        
        # Calculate hotspots (areas with high item density)
        hotspots = self._calculate_hotspots(heatmap_points)
        
        return {
            "heatmap_points": [
                {
                    "lat": point.latitude,
                    "lng": point.longitude,
                    "weight": point.weight,
                    "category": point.category,
                    "metadata": point.metadata
                }
                for point in heatmap_points
            ],
            "category_distribution": category_distribution,
            "hotspots": hotspots,
            "total_points": len(heatmap_points)
        }
    
    def _calculate_hotspots(self, points: List[GeographicPoint], radius_km: float = 1.0) -> List[Dict[str, Any]]:
        """Calculate geographic hotspots based on point density"""
        if len(points) < 10:  # Need minimum points for meaningful hotspots
            return []
        
        # Simple clustering algorithm to find hotspots
        hotspots = []
        processed_points = set()
        
        for i, point in enumerate(points):
            if i in processed_points:
                continue
            
            # Find nearby points
            cluster_points = [point]
            cluster_indices = {i}
            
            for j, other_point in enumerate(points):
                if j != i and j not in processed_points:
                    distance = geodesic(
                        (point.latitude, point.longitude),
                        (other_point.latitude, other_point.longitude)
                    ).kilometers
                    
                    if distance <= radius_km:
                        cluster_points.append(other_point)
                        cluster_indices.add(j)
            
            # Create hotspot if cluster is significant
            if len(cluster_points) >= 5:  # Minimum 5 points for a hotspot
                center_lat = np.mean([p.latitude for p in cluster_points])
                center_lng = np.mean([p.longitude for p in cluster_points])
                
                category_counts = {}
                for p in cluster_points:
                    category_counts[p.category] = category_counts.get(p.category, 0) + 1
                
                hotspots.append({
                    "center": {"lat": center_lat, "lng": center_lng},
                    "point_count": len(cluster_points),
                    "radius_km": radius_km,
                    "categories": category_counts,
                    "dominant_category": max(category_counts.keys(), key=category_counts.get)
                })
                
                processed_points.update(cluster_indices)
        
        # Sort hotspots by point count (descending)
        hotspots.sort(key=lambda x: x["point_count"], reverse=True)
        
        return hotspots[:10]  # Return top 10 hotspots
    
    async def get_location_success_rates(self) -> Dict[str, Any]:
        """Analyze success rates by geographic areas"""
        
        # This would require more sophisticated geographic analysis
        # For now, providing a basic implementation
        
        location_data = self.db.query(
            Item.location_name,
            func.count(Match.id).label('total_matches'),
            func.count(case([(Match.status == 'claimed', 1)])).label('successful_matches')
        ).join(Match, Match.lost_item_id == Item.id).filter(
            Item.location_name.isnot(None)
        ).group_by(Item.location_name).having(
            func.count(Match.id) >= 5  # Minimum 5 matches for meaningful data
        ).all()
        
        location_analysis = []
        for row in location_data:
            success_rate = (row.successful_matches / max(row.total_matches, 1)) * 100
            location_analysis.append({
                "location": row.location_name,
                "total_matches": row.total_matches,
                "successful_matches": row.successful_matches,
                "success_rate": round(success_rate, 1)
            })
        
        # Sort by success rate
        location_analysis.sort(key=lambda x: x["success_rate"], reverse=True)
        
        return {
            "location_success_rates": location_analysis[:20],  # Top 20 locations
            "analysis_note": "Based on locations with at least 5 matches"
        }
