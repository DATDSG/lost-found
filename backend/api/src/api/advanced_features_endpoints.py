"""
Advanced Features API Endpoints
REST API for advanced matching, communication, and analytics features
"""

from fastapi import APIRouter, Depends, HTTPException, WebSocket, Query, BackgroundTasks
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List, Dict, Any, Optional
from pydantic import BaseModel
from datetime import datetime
import logging

from app.db.session import get_db
from app.db.models import User, Item, Match
from src.auth.rbac import require_permissions, Permission, get_current_user
from src.matching.advanced_matching import AdvancedMatchingEngine, MatchScore
from src.communication.realtime_chat import ChatService, websocket_endpoint, connection_manager
from src.communication.notification_system import (
    NotificationService, NotificationRequest, NotificationType, 
    NotificationChannel, NotificationPriority
)
from src.analytics.dashboard_analytics import (
    DashboardAnalytics, SuccessMetrics, UserBehaviorAnalytics, 
    GeographicAnalytics, TimeRange
)

logger = logging.getLogger(__name__)

# Create routers
matching_router = APIRouter(prefix="/api/v1/matching", tags=["advanced-matching"])
chat_router = APIRouter(prefix="/api/v1/chat", tags=["real-time-chat"])
notifications_router = APIRouter(prefix="/api/v1/notifications", tags=["notifications"])
analytics_router = APIRouter(prefix="/api/v1/analytics", tags=["analytics"])

# Pydantic models
class AdvancedMatchRequest(BaseModel):
    item_id: int
    user_id: Optional[int] = None
    limit: int = 20
    min_score_threshold: float = 0.2

class AdvancedMatchResponse(BaseModel):
    item_id: int
    title: str
    description: str
    category: str
    match_score: MatchScore
    distance_km: float
    created_at: datetime

class FeedbackRequest(BaseModel):
    match_id: int
    feedback_type: str  # 'positive', 'negative', 'false_positive'
    feedback_data: Dict[str, Any] = {}

class ChatHistoryResponse(BaseModel):
    messages: List[Dict[str, Any]]
    total_count: int
    has_more: bool

class NotificationSendRequest(BaseModel):
    user_ids: List[int]
    type: str
    priority: str = "medium"
    channels: List[str] = ["email", "in_app"]
    data: Dict[str, Any] = {}
    scheduled_at: Optional[datetime] = None

class AnalyticsRequest(BaseModel):
    time_range: str = "last_30d"
    category: Optional[str] = None
    include_trends: bool = True

# Advanced Matching Endpoints
@matching_router.post("/advanced-search")
async def advanced_item_matching(
    request: AdvancedMatchRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Find matches using advanced matching algorithm"""
    
    matching_engine = AdvancedMatchingEngine(db)
    
    try:
        matches = matching_engine.find_advanced_matches(
            item_id=request.item_id,
            user_id=request.user_id or current_user.id,
            limit=request.limit
        )
        
        # Convert to response format
        match_responses = []
        for item, match_score in matches:
            if match_score.total_score >= request.min_score_threshold:
                match_responses.append(AdvancedMatchResponse(
                    item_id=item.id,
                    title=item.title,
                    description=item.description or "",
                    category=item.category,
                    match_score=match_score,
                    distance_km=round(match_score.location_proximity * 10, 1),  # Approximate
                    created_at=item.created_at
                ))
        
        return {
            "matches": match_responses,
            "total_found": len(match_responses),
            "search_params": request.dict()
        }
        
    except Exception as e:
        logger.error(f"Advanced matching failed: {e}")
        raise HTTPException(status_code=500, detail="Matching service error")

@matching_router.post("/feedback")
async def submit_match_feedback(
    request: FeedbackRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Submit feedback for match quality learning"""
    
    matching_engine = AdvancedMatchingEngine(db)
    
    try:
        matching_engine.feedback_learner.learn_from_feedback(
            user_id=current_user.id,
            match_id=request.match_id,
            feedback_type=request.feedback_type,
            feedback_data=request.feedback_data
        )
        
        return {
            "success": True,
            "message": "Feedback recorded successfully",
            "match_id": request.match_id
        }
        
    except Exception as e:
        logger.error(f"Feedback submission failed: {e}")
        raise HTTPException(status_code=500, detail="Failed to record feedback")

@matching_router.get("/user-preferences/{user_id}")
async def get_user_matching_preferences(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(Permission.VIEW_USER_DETAILS))
):
    """Get user's matching preferences and learned patterns"""
    
    # This would return learned user preferences
    # For now, returning placeholder data
    
    return {
        "user_id": user_id,
        "preferences": {
            "preferred_categories": ["electronics", "clothing"],
            "location_sensitivity": 0.8,
            "time_sensitivity": 0.6,
            "image_similarity_threshold": 0.7
        },
        "learning_data": {
            "total_feedback_submissions": 15,
            "positive_feedback_rate": 0.73,
            "preferred_match_score_range": [0.6, 0.9]
        }
    }

# Real-time Chat Endpoints
@chat_router.websocket("/ws/{match_id}")
async def chat_websocket(
    websocket: WebSocket,
    match_id: int,
    db: Session = Depends(get_db)
):
    """WebSocket endpoint for real-time chat"""
    # This uses the websocket_endpoint function from realtime_chat.py
    # Authentication would be handled via query parameters or headers
    await websocket_endpoint(websocket, match_id, db)

@chat_router.get("/history/{match_id}")
async def get_chat_history(
    match_id: int,
    limit: int = Query(default=50, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get chat history for a match"""
    
    chat_service = ChatService(db)
    
    try:
        messages = await chat_service.get_chat_history(
            match_id=match_id,
            user_id=current_user.id,
            limit=limit,
            offset=offset
        )
        
        # Convert to dict format
        message_dicts = [
            {
                "id": msg.id,
                "sender_id": msg.sender_id,
                "sender_name": msg.sender_name,
                "content": msg.content,
                "timestamp": msg.timestamp.isoformat(),
                "is_masked": msg.is_masked
            }
            for msg in messages
        ]
        
        return ChatHistoryResponse(
            messages=message_dicts,
            total_count=len(message_dicts),
            has_more=len(message_dicts) == limit
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Chat history retrieval failed: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve chat history")

@chat_router.get("/active-users/{match_id}")
async def get_active_chat_users(
    match_id: int,
    current_user: User = Depends(get_current_user)
):
    """Get list of users currently active in chat"""
    
    active_users = connection_manager.get_active_users(match_id)
    typing_users = connection_manager.get_typing_users(match_id)
    
    return {
        "match_id": match_id,
        "active_users": active_users,
        "typing_users": [
            {
                "user_id": indicator.user_id,
                "user_name": indicator.user_name,
                "timestamp": indicator.timestamp.isoformat()
            }
            for indicator in typing_users
        ],
        "total_active": len(active_users)
    }

@chat_router.post("/mark-read/{match_id}")
async def mark_messages_as_read(
    match_id: int,
    message_ids: List[int],
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Mark messages as read"""
    
    chat_service = ChatService(db)
    
    try:
        await chat_service.mark_messages_as_read(
            match_id=match_id,
            user_id=current_user.id,
            message_ids=message_ids
        )
        
        return {
            "success": True,
            "marked_count": len(message_ids),
            "match_id": match_id
        }
        
    except Exception as e:
        logger.error(f"Mark as read failed: {e}")
        raise HTTPException(status_code=500, detail="Failed to mark messages as read")

# Notification Endpoints
@notifications_router.post("/send")
async def send_notification(
    request: NotificationSendRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(Permission.SEND_NOTIFICATIONS))
):
    """Send notification to multiple users"""
    
    notification_service = NotificationService(db)
    
    # Convert string enums
    try:
        notification_type = NotificationType(request.type)
        priority = NotificationPriority(request.priority)
        channels = [NotificationChannel(ch) for ch in request.channels]
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid enum value: {e}")
    
    # Create notification requests
    notification_requests = []
    for user_id in request.user_ids:
        notification_requests.append(NotificationRequest(
            user_id=user_id,
            type=notification_type,
            priority=priority,
            channels=channels,
            data=request.data,
            scheduled_at=request.scheduled_at
        ))
    
    # Send notifications in background
    async def send_notifications_task():
        results = await notification_service.send_bulk_notifications(notification_requests)
        logger.info(f"Sent {len(results)} notifications")
    
    background_tasks.add_task(send_notifications_task)
    
    return {
        "success": True,
        "message": "Notifications queued for sending",
        "recipient_count": len(request.user_ids),
        "channels": request.channels
    }

@notifications_router.get("/templates")
async def get_notification_templates(
    language: str = Query(default="en"),
    channel: str = Query(default="email"),
    current_user: User = Depends(require_permissions(Permission.VIEW_TEMPLATES))
):
    """Get available notification templates"""
    
    notification_service = NotificationService(Session())
    
    try:
        channel_enum = NotificationChannel(channel)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid channel")
    
    # Get available templates (this would be implemented in TemplateManager)
    templates = []
    for notification_type in NotificationType:
        template = notification_service.template_manager.get_template(
            notification_type, language, channel_enum
        )
        if template:
            templates.append({
                "id": template.id,
                "type": template.type.value,
                "language": template.language,
                "channel": template.channel.value,
                "subject_template": template.subject_template,
                "metadata": template.metadata
            })
    
    return {
        "templates": templates,
        "language": language,
        "channel": channel,
        "total_count": len(templates)
    }

@notifications_router.get("/user/{user_id}")
async def get_user_notifications(
    user_id: int,
    limit: int = Query(default=20, le=100),
    offset: int = Query(default=0, ge=0),
    unread_only: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get user's notifications"""
    
    # Check permission (users can only see their own notifications)
    if user_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Access denied")
    
    query = db.query(Notification).filter(Notification.user_id == user_id)
    
    if unread_only:
        query = query.filter(Notification.is_read == False)
    
    notifications = query.order_by(Notification.created_at.desc()).offset(offset).limit(limit).all()
    
    notification_data = []
    for notif in notifications:
        notification_data.append({
            "id": notif.id,
            "type": notif.type,
            "payload": notif.payload,
            "is_read": notif.is_read,
            "created_at": notif.created_at.isoformat()
        })
    
    return {
        "notifications": notification_data,
        "total_count": len(notification_data),
        "unread_count": sum(1 for n in notification_data if not n["is_read"])
    }

# Analytics Endpoints
@analytics_router.get("/dashboard/overview")
async def get_dashboard_overview(
    time_range: str = Query(default="last_30d"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(Permission.VIEW_ANALYTICS))
):
    """Get dashboard overview metrics"""
    
    try:
        time_range_enum = TimeRange(time_range)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid time range")
    
    analytics = DashboardAnalytics(db)
    
    try:
        # Get key metrics
        metrics = await analytics.get_key_metrics(time_range_enum)
        
        # Get category distribution
        category_data = await analytics.get_category_distribution(time_range_enum)
        
        # Get temporal trends
        trends = await analytics.get_temporal_trends(time_range_enum)
        
        return {
            "metrics": {name: {
                "value": metric.value,
                "type": metric.type.value,
                "description": metric.description,
                "trend": metric.trend,
                "comparison_period": metric.comparison_period
            } for name, metric in metrics.items()},
            "category_distribution": category_data,
            "trends": trends,
            "time_range": time_range,
            "generated_at": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Dashboard analytics failed: {e}")
        raise HTTPException(status_code=500, detail="Analytics service error")

@analytics_router.get("/success-metrics")
async def get_success_metrics(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(Permission.VIEW_ANALYTICS))
):
    """Get match success rate analysis"""
    
    success_metrics = SuccessMetrics(db)
    
    try:
        analysis = await success_metrics.get_match_success_analysis()
        funnel = await success_metrics.get_conversion_funnel()
        
        return {
            "success_analysis": analysis,
            "conversion_funnel": funnel,
            "generated_at": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Success metrics failed: {e}")
        raise HTTPException(status_code=500, detail="Success metrics service error")

@analytics_router.get("/user-behavior")
async def get_user_behavior_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(Permission.VIEW_ANALYTICS))
):
    """Get user behavior and engagement analytics"""
    
    behavior_analytics = UserBehaviorAnalytics(db)
    
    try:
        engagement = await behavior_analytics.get_user_engagement_metrics()
        journey = await behavior_analytics.get_user_journey_analysis()
        
        return {
            "engagement_metrics": engagement,
            "user_journey": journey,
            "generated_at": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"User behavior analytics failed: {e}")
        raise HTTPException(status_code=500, detail="User behavior analytics service error")

@analytics_router.get("/geographic/heatmap")
async def get_geographic_heatmap(
    category: Optional[str] = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(Permission.VIEW_ANALYTICS))
):
    """Get geographic heatmap data"""
    
    geo_analytics = GeographicAnalytics(db)
    
    try:
        heatmap_data = await geo_analytics.get_geographic_heatmap_data(category)
        location_success = await geo_analytics.get_location_success_rates()
        
        return {
            "heatmap_data": heatmap_data,
            "location_success_rates": location_success,
            "category_filter": category,
            "generated_at": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Geographic analytics failed: {e}")
        raise HTTPException(status_code=500, detail="Geographic analytics service error")

@analytics_router.get("/export")
async def export_analytics_data(
    format: str = Query(default="json", regex="^(json|csv|excel)$"),
    time_range: str = Query(default="last_30d"),
    include_raw_data: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permissions(Permission.EXPORT_ANALYTICS))
):
    """Export analytics data in various formats"""
    
    try:
        time_range_enum = TimeRange(time_range)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid time range")
    
    analytics = DashboardAnalytics(db)
    
    try:
        # Gather all analytics data
        metrics = await analytics.get_key_metrics(time_range_enum)
        category_data = await analytics.get_category_distribution(time_range_enum)
        trends = await analytics.get_temporal_trends(time_range_enum)
        
        export_data = {
            "export_info": {
                "generated_at": datetime.utcnow().isoformat(),
                "time_range": time_range,
                "format": format,
                "user_id": current_user.id
            },
            "metrics": {name: {
                "value": metric.value,
                "type": metric.type.value,
                "description": metric.description
            } for name, metric in metrics.items()},
            "category_distribution": category_data,
            "trends": trends
        }
        
        if format == "json":
            return JSONResponse(content=export_data)
        
        elif format == "csv":
            # Convert to CSV format (simplified)
            import pandas as pd
            import io
            
            # Create CSV from metrics
            metrics_df = pd.DataFrame([
                {
                    "metric_name": name,
                    "value": data["value"],
                    "type": data["type"],
                    "description": data["description"]
                }
                for name, data in export_data["metrics"].items()
            ])
            
            csv_buffer = io.StringIO()
            metrics_df.to_csv(csv_buffer, index=False)
            
            return JSONResponse(
                content={"csv_data": csv_buffer.getvalue()},
                headers={"Content-Type": "application/json"}
            )
        
        else:  # Excel format would require additional processing
            return JSONResponse(content=export_data)
        
    except Exception as e:
        logger.error(f"Analytics export failed: {e}")
        raise HTTPException(status_code=500, detail="Export service error")

# Include all routers
def get_advanced_features_routers():
    """Get all advanced features routers"""
    return [
        matching_router,
        chat_router,
        notifications_router,
        analytics_router
    ]
