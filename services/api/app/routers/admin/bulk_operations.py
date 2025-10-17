"""Admin bulk operations router."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
import json

from ...database import get_db
from ...models import User, Report, ReportStatus, Match, MatchStatus
from ...schemas import BulkOperationRequest, BulkOperationResult, BulkOperationError
from ...dependencies import get_current_admin
from ...helpers import create_audit_log

router = APIRouter()


# ============================================================================
# REPORTS BULK OPERATIONS
# ============================================================================

@router.post("/reports/bulk/approve", response_model=BulkOperationResult)
def bulk_approve_reports(
    bulk_request: BulkOperationRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Approve multiple reports at once."""
    success_count = 0
    errors = []
    
    for report_id in bulk_request.ids:
        try:
            report = db.query(Report).filter(Report.id == report_id).first()
            
            if not report:
                errors.append(BulkOperationError(
                    id=report_id,
                    error="Report not found"
                ))
                continue
            
            # Update status
            old_status = report.status
            report.status = ReportStatus.APPROVED
            
            # Create audit log
            create_audit_log(
                db=db,
                user_id=current_user.id,
                action="report_bulk_approved",
                resource_type="report",
                resource_id=report_id,
                details=json.dumps({
                    "admin": current_user.email,
                    "old_status": str(old_status),
                    "new_status": "approved",
                    "bulk_operation": True
                })
            )
            
            success_count += 1
            
        except Exception as e:
            errors.append(BulkOperationError(
                id=report_id,
                error=str(e)
            ))
    
    # Commit all changes
    db.commit()
    
    return BulkOperationResult(
        success=success_count,
        failed=len(errors),
        errors=errors
    )


@router.post("/reports/bulk/reject", response_model=BulkOperationResult)
def bulk_reject_reports(
    bulk_request: BulkOperationRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Reject (hide) multiple reports at once."""
    success_count = 0
    errors = []
    
    for report_id in bulk_request.ids:
        try:
            report = db.query(Report).filter(Report.id == report_id).first()
            
            if not report:
                errors.append(BulkOperationError(
                    id=report_id,
                    error="Report not found"
                ))
                continue
            
            # Update status
            old_status = report.status
            report.status = ReportStatus.HIDDEN
            
            # Create audit log
            create_audit_log(
                db=db,
                user_id=current_user.id,
                action="report_bulk_rejected",
                resource_type="report",
                resource_id=report_id,
                details=json.dumps({
                    "admin": current_user.email,
                    "old_status": str(old_status),
                    "new_status": "hidden",
                    "bulk_operation": True
                })
            )
            
            success_count += 1
            
        except Exception as e:
            errors.append(BulkOperationError(
                id=report_id,
                error=str(e)
            ))
    
    # Commit all changes
    db.commit()
    
    return BulkOperationResult(
        success=success_count,
        failed=len(errors),
        errors=errors
    )


@router.post("/reports/bulk/delete", response_model=BulkOperationResult)
def bulk_delete_reports(
    bulk_request: BulkOperationRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete multiple reports at once (soft delete by setting status to REMOVED)."""
    success_count = 0
    errors = []
    
    for report_id in bulk_request.ids:
        try:
            report = db.query(Report).filter(Report.id == report_id).first()
            
            if not report:
                errors.append(BulkOperationError(
                    id=report_id,
                    error="Report not found"
                ))
                continue
            
            # Soft delete by setting status to REMOVED
            old_status = report.status
            report.status = ReportStatus.REMOVED
            
            # Create audit log
            create_audit_log(
                db=db,
                user_id=current_user.id,
                action="report_bulk_deleted",
                resource_type="report",
                resource_id=report_id,
                details=json.dumps({
                    "admin": current_user.email,
                    "old_status": str(old_status),
                    "new_status": "removed",
                    "bulk_operation": True,
                    "report_title": report.title
                })
            )
            
            success_count += 1
            
        except Exception as e:
            errors.append(BulkOperationError(
                id=report_id,
                error=str(e)
            ))
    
    # Commit all changes
    db.commit()
    
    return BulkOperationResult(
        success=success_count,
        failed=len(errors),
        errors=errors
    )


# ============================================================================
# USERS BULK OPERATIONS
# ============================================================================

@router.post("/users/bulk/activate", response_model=BulkOperationResult)
def bulk_activate_users(
    bulk_request: BulkOperationRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Activate multiple users at once."""
    success_count = 0
    errors = []
    
    for user_id in bulk_request.ids:
        try:
            user = db.query(User).filter(User.id == user_id).first()
            
            if not user:
                errors.append(BulkOperationError(
                    id=user_id,
                    error="User not found"
                ))
                continue
            
            # Don't allow deactivating yourself
            if user.id == current_user.id:
                errors.append(BulkOperationError(
                    id=user_id,
                    error="Cannot modify your own account status"
                ))
                continue
            
            # Update status
            old_status = user.is_active
            user.is_active = True
            
            # Create audit log
            create_audit_log(
                db=db,
                user_id=current_user.id,
                action="user_bulk_activated",
                resource_type="user",
                resource_id=user_id,
                details=json.dumps({
                    "admin": current_user.email,
                    "old_status": "inactive" if not old_status else "active",
                    "new_status": "active",
                    "bulk_operation": True,
                    "user_email": user.email
                })
            )
            
            success_count += 1
            
        except Exception as e:
            errors.append(BulkOperationError(
                id=user_id,
                error=str(e)
            ))
    
    # Commit all changes
    db.commit()
    
    return BulkOperationResult(
        success=success_count,
        failed=len(errors),
        errors=errors
    )


@router.post("/users/bulk/deactivate", response_model=BulkOperationResult)
def bulk_deactivate_users(
    bulk_request: BulkOperationRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Deactivate multiple users at once."""
    success_count = 0
    errors = []
    
    for user_id in bulk_request.ids:
        try:
            user = db.query(User).filter(User.id == user_id).first()
            
            if not user:
                errors.append(BulkOperationError(
                    id=user_id,
                    error="User not found"
                ))
                continue
            
            # Don't allow deactivating yourself
            if user.id == current_user.id:
                errors.append(BulkOperationError(
                    id=user_id,
                    error="Cannot modify your own account status"
                ))
                continue
            
            # Update status
            old_status = user.is_active
            user.is_active = False
            
            # Create audit log
            create_audit_log(
                db=db,
                user_id=current_user.id,
                action="user_bulk_deactivated",
                resource_type="user",
                resource_id=user_id,
                details=json.dumps({
                    "admin": current_user.email,
                    "old_status": "active" if old_status else "inactive",
                    "new_status": "inactive",
                    "bulk_operation": True,
                    "user_email": user.email
                })
            )
            
            success_count += 1
            
        except Exception as e:
            errors.append(BulkOperationError(
                id=user_id,
                error=str(e)
            ))
    
    # Commit all changes
    db.commit()
    
    return BulkOperationResult(
        success=success_count,
        failed=len(errors),
        errors=errors
    )


@router.post("/users/bulk/delete", response_model=BulkOperationResult)
def bulk_delete_users(
    bulk_request: BulkOperationRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete multiple users at once (soft delete by deactivating)."""
    success_count = 0
    errors = []
    
    for user_id in bulk_request.ids:
        try:
            user = db.query(User).filter(User.id == user_id).first()
            
            if not user:
                errors.append(BulkOperationError(
                    id=user_id,
                    error="User not found"
                ))
                continue
            
            # Don't allow deleting yourself
            if user.id == current_user.id:
                errors.append(BulkOperationError(
                    id=user_id,
                    error="Cannot delete your own account"
                ))
                continue
            
            # Soft delete by deactivating
            user.is_active = False
            
            # Create audit log
            create_audit_log(
                db=db,
                user_id=current_user.id,
                action="user_bulk_deleted",
                resource_type="user",
                resource_id=user_id,
                details=json.dumps({
                    "admin": current_user.email,
                    "bulk_operation": True,
                    "user_email": user.email,
                    "user_display_name": user.display_name
                })
            )
            
            success_count += 1
            
        except Exception as e:
            errors.append(BulkOperationError(
                id=user_id,
                error=str(e)
            ))
    
    # Commit all changes
    db.commit()
    
    return BulkOperationResult(
        success=success_count,
        failed=len(errors),
        errors=errors
    )


# ============================================================================
# MATCHES BULK OPERATIONS
# ============================================================================

@router.post("/matches/bulk/approve", response_model=BulkOperationResult)
def bulk_approve_matches(
    bulk_request: BulkOperationRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Approve multiple matches at once (promote them)."""
    success_count = 0
    errors = []
    
    for match_id in bulk_request.ids:
        try:
            match = db.query(Match).filter(Match.id == match_id).first()
            
            if not match:
                errors.append(BulkOperationError(
                    id=match_id,
                    error="Match not found"
                ))
                continue
            
            # Update status
            old_status = match.status
            match.status = MatchStatus.PROMOTED
            
            # Create audit log
            create_audit_log(
                db=db,
                user_id=current_user.id,
                action="match_bulk_approved",
                resource_type="match",
                resource_id=match_id,
                details=json.dumps({
                    "admin": current_user.email,
                    "old_status": str(old_status),
                    "new_status": "promoted",
                    "bulk_operation": True,
                    "score": match.score_total
                })
            )
            
            success_count += 1
            
        except Exception as e:
            errors.append(BulkOperationError(
                id=match_id,
                error=str(e)
            ))
    
    # Commit all changes
    db.commit()
    
    return BulkOperationResult(
        success=success_count,
        failed=len(errors),
        errors=errors
    )


@router.post("/matches/bulk/reject", response_model=BulkOperationResult)
def bulk_reject_matches(
    bulk_request: BulkOperationRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Reject multiple matches at once (suppress them)."""
    success_count = 0
    errors = []
    
    for match_id in bulk_request.ids:
        try:
            match = db.query(Match).filter(Match.id == match_id).first()
            
            if not match:
                errors.append(BulkOperationError(
                    id=match_id,
                    error="Match not found"
                ))
                continue
            
            # Update status
            old_status = match.status
            match.status = MatchStatus.SUPPRESSED
            
            # Create audit log
            create_audit_log(
                db=db,
                user_id=current_user.id,
                action="match_bulk_rejected",
                resource_type="match",
                resource_id=match_id,
                details=json.dumps({
                    "admin": current_user.email,
                    "old_status": str(old_status),
                    "new_status": "suppressed",
                    "bulk_operation": True
                })
            )
            
            success_count += 1
            
        except Exception as e:
            errors.append(BulkOperationError(
                id=match_id,
                error=str(e)
            ))
    
    # Commit all changes
    db.commit()
    
    return BulkOperationResult(
        success=success_count,
        failed=len(errors),
        errors=errors
    )


@router.post("/matches/bulk/notify", response_model=BulkOperationResult)
def bulk_notify_matches(
    bulk_request: BulkOperationRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Send notifications to users for multiple matches."""
    from app.models import Notification
    from uuid import uuid4
    from datetime import datetime, timezone
    
    success_count = 0
    errors = []
    
    for match_id in bulk_request.ids:
        try:
            match = db.query(Match).filter(Match.id == match_id).first()
            
            if not match:
                errors.append(BulkOperationError(
                    id=match_id,
                    error="Match not found"
                ))
                continue
            
            # Get both report owners
            source_report = match.source_report
            target_report = match.target_report
            
            if not source_report or not target_report:
                errors.append(BulkOperationError(
                    id=match_id,
                    error="Associated reports not found"
                ))
                continue
            
            # Create notifications for both users
            notifications_created = 0
            
            # Notification for source report owner
            if source_report.owner_id:
                notification = Notification(
                    id=str(uuid4()),
                    user_id=source_report.owner_id,
                    type="match_notification",
                    title="Potential Match Found",
                    message=f"We found a potential match for your {source_report.type} report: {source_report.title}",
                    data=json.dumps({
                        "match_id": match_id,
                        "report_id": target_report.id,
                        "admin_notified": True
                    }),
                    is_read=False,
                    created_at=datetime.now(timezone.utc)
                )
                db.add(notification)
                notifications_created += 1
            
            # Notification for target report owner
            if target_report.owner_id and target_report.owner_id != source_report.owner_id:
                notification = Notification(
                    id=str(uuid4()),
                    user_id=target_report.owner_id,
                    type="match_notification",
                    title="Potential Match Found",
                    message=f"We found a potential match for your {target_report.type} report: {target_report.title}",
                    data=json.dumps({
                        "match_id": match_id,
                        "report_id": source_report.id,
                        "admin_notified": True
                    }),
                    is_read=False,
                    created_at=datetime.now(timezone.utc)
                )
                db.add(notification)
                notifications_created += 1
            
            # Create audit log
            create_audit_log(
                db=db,
                user_id=current_user.id,
                action="match_bulk_notified",
                resource_type="match",
                resource_id=match_id,
                details=json.dumps({
                    "admin": current_user.email,
                    "bulk_operation": True,
                    "notifications_sent": notifications_created
                })
            )
            
            success_count += 1
            
        except Exception as e:
            errors.append(BulkOperationError(
                id=match_id,
                error=str(e)
            ))
    
    # Commit all changes
    db.commit()
    
    return BulkOperationResult(
        success=success_count,
        failed=len(errors),
        errors=errors
    )
