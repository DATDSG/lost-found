"""Helper functions for notifications and audit logging."""
from sqlalchemy.ext.asyncio import AsyncSession
import uuid

from .models import Notification, AuditLog


async def create_notification(
    db: AsyncSession,
    user_id: str,
    notification_type: str,
    title: str,
    content: str = None,
    reference_id: str = None
) -> Notification:
    """Create a notification for a user."""
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
    await db.commit()
    await db.refresh(notification)
    
    return notification


async def create_audit_log(
    db: AsyncSession,
    user_id: str,  # Keep as user_id for backward compatibility
    action: str,
    resource_type: str = None,  # Keep old parameter name
    resource_id: str = None,
    details: str = None  # Keep old parameter name
) -> AuditLog:
    """Create an audit log entry."""
    audit_log = AuditLog(
        id=str(uuid.uuid4()),
        actor_id=uuid.UUID(user_id),  # Convert string to UUID
        action=action,
        resource=resource_type,  # Map to resource in model
        resource_id=resource_id,
        reason=details  # Map to reason in model
    )
    
    db.add(audit_log)
    await db.commit()
    await db.refresh(audit_log)
    
    return audit_log

