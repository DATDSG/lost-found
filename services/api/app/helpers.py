"""Helper functions for notifications, conversations, and audit logging."""
from sqlalchemy.orm import Session
from datetime import datetime
import uuid

from .models import Notification, Conversation, Message, AuditLog, User, Match


def create_notification(
    db: Session,
    user_id: str,
    notification_type: str,
    title: str,
    content: str = None,
    reference_id: str = None
) -> Notification:
    """
    Create a notification for a user.
    
    Args:
        db: Database session
        user_id: User to notify
        notification_type: Type of notification (e.g., "match_confirmed", "message_received")
        title: Notification title
        content: Optional notification content
        reference_id: Optional reference to related resource (match_id, message_id, etc.)
    
    Returns:
        Created notification
    """
    notification = Notification(
        id=str(uuid.uuid4()),
        user_id=user_id,
        type=notification_type,
        title=title,
        content=content,
        reference_id=reference_id,
        is_read=False
    )
    
    db.add(notification)
    db.commit()
    db.refresh(notification)
    
    return notification


def get_or_create_conversation(
    db: Session,
    report1_id: str,
    report2_id: str
) -> Conversation:
    """
    Get existing conversation between two reports or create a new one.
    
    Args:
        db: Database session
        report1_id: First report ID
        report2_id: Second report ID
    
    Returns:
        Conversation (existing or newly created)
    """
    # Try to find existing conversation
    conversation = db.query(Conversation).filter(
        ((Conversation.report1_id == report1_id) & (Conversation.report2_id == report2_id)) |
        ((Conversation.report1_id == report2_id) & (Conversation.report2_id == report1_id))
    ).first()
    
    if conversation:
        return conversation
    
    # Create new conversation
    conversation = Conversation(
        id=str(uuid.uuid4()),
        report1_id=report1_id,
        report2_id=report2_id
    )
    
    db.add(conversation)
    db.commit()
    db.refresh(conversation)
    
    return conversation


def create_audit_log(
    db: Session,
    user_id: str,
    action: str,
    resource_type: str = None,
    resource_id: str = None,
    details: str = None
) -> AuditLog:
    """
    Create an audit log entry.
    
    Args:
        db: Database session
        user_id: User who performed the action
        action: Action performed (e.g., "report_updated", "match_confirmed")
        resource_type: Type of resource affected (e.g., "report", "match")
        resource_id: ID of affected resource
        details: Optional JSON string with additional details
    
    Returns:
        Created audit log entry
    """
    audit_log = AuditLog(
        id=str(uuid.uuid4()),
        user_id=user_id,
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        details=details
    )
    
    db.add(audit_log)
    db.commit()
    db.refresh(audit_log)
    
    return audit_log


def notify_match_confirmation(
    db: Session,
    match: Match,
    confirming_user_id: str
) -> Notification:
    """
    Create notification when a match is confirmed.
    
    Args:
        db: Database session
        match: The confirmed match
        confirming_user_id: User who confirmed the match
    
    Returns:
        Created notification
    """
    # Determine the other user in the match
    other_user_id = (
        match.target_report.owner_id 
        if match.source_report.owner_id == confirming_user_id 
        else match.source_report.owner_id
    )
    
    # Get confirming user's name
    confirming_user = db.query(User).filter(User.id == confirming_user_id).first()
    user_name = confirming_user.display_name or confirming_user.email if confirming_user else "Someone"
    
    # Create notification
    return create_notification(
        db=db,
        user_id=other_user_id,
        notification_type="match_confirmed",
        title="Match Confirmed!",
        content=f"{user_name} confirmed a match with your item. You can now message them.",
        reference_id=match.id
    )
