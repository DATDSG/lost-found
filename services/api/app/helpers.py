"""Helper functions for audit logging."""
from sqlalchemy.orm import Session
from datetime import datetime
import uuid

from .models import AuditLog


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
