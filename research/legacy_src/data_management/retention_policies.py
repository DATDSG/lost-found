"""
Data Retention Policies and GDPR Compliance
Implements automated data lifecycle management and privacy compliance
"""

from enum import Enum
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
import logging
import asyncio
from pathlib import Path
import json
import zipfile
import io

from ..models.user import User
from ..models.item import Item
from ..models.claim import Claim
from ..models.match import Match
from ..database import get_db
from ..core.config import settings

logger = logging.getLogger(__name__)

class RetentionPolicy(Enum):
    """Data retention policy types"""
    ACTIVE_ITEMS = "active_items"
    RESOLVED_ITEMS = "resolved_items"
    USER_DATA = "user_data"
    AUDIT_LOGS = "audit_logs"
    SESSION_DATA = "session_data"
    ANALYTICS_DATA = "analytics_data"
    ML_TRAINING_DATA = "ml_training_data"

@dataclass
class RetentionRule:
    """Data retention rule configuration"""
    policy: RetentionPolicy
    retention_days: int
    soft_delete: bool = True
    archive_before_delete: bool = True
    conditions: Optional[Dict[str, Any]] = None
    
class DataRetentionService:
    """Service for managing data retention and lifecycle"""
    
    def __init__(self, db: Session):
        self.db = db
        self.retention_rules = self._load_retention_rules()
    
    def _load_retention_rules(self) -> Dict[RetentionPolicy, RetentionRule]:
        """Load retention rules from configuration"""
        return {
            RetentionPolicy.ACTIVE_ITEMS: RetentionRule(
                policy=RetentionPolicy.ACTIVE_ITEMS,
                retention_days=settings.ACTIVE_ITEMS_RETENTION_DAYS,
                soft_delete=True,
                archive_before_delete=True
            ),
            RetentionPolicy.RESOLVED_ITEMS: RetentionRule(
                policy=RetentionPolicy.RESOLVED_ITEMS,
                retention_days=settings.RESOLVED_ITEMS_RETENTION_DAYS,
                soft_delete=True,
                archive_before_delete=True
            ),
            RetentionPolicy.USER_DATA: RetentionRule(
                policy=RetentionPolicy.USER_DATA,
                retention_days=settings.USER_DATA_RETENTION_DAYS,
                soft_delete=True,
                archive_before_delete=True,
                conditions={"inactive_days": 365}  # Users inactive for 1 year
            ),
            RetentionPolicy.AUDIT_LOGS: RetentionRule(
                policy=RetentionPolicy.AUDIT_LOGS,
                retention_days=settings.AUDIT_LOGS_RETENTION_DAYS,
                soft_delete=False,
                archive_before_delete=True
            ),
            RetentionPolicy.SESSION_DATA: RetentionRule(
                policy=RetentionPolicy.SESSION_DATA,
                retention_days=30,
                soft_delete=False,
                archive_before_delete=False
            ),
            RetentionPolicy.ANALYTICS_DATA: RetentionRule(
                policy=RetentionPolicy.ANALYTICS_DATA,
                retention_days=settings.ANALYTICS_RETENTION_DAYS,
                soft_delete=False,
                archive_before_delete=True
            )
        }
    
    async def apply_retention_policies(self) -> Dict[str, int]:
        """Apply all retention policies and return counts of affected records"""
        results = {}
        
        for policy, rule in self.retention_rules.items():
            try:
                count = await self._apply_single_policy(rule)
                results[policy.value] = count
                logger.info(f"Applied retention policy {policy.value}: {count} records processed")
            except Exception as e:
                logger.error(f"Error applying retention policy {policy.value}: {e}")
                results[policy.value] = -1
        
        return results
    
    async def _apply_single_policy(self, rule: RetentionRule) -> int:
        """Apply a single retention policy"""
        cutoff_date = datetime.utcnow() - timedelta(days=rule.retention_days)
        
        if rule.policy == RetentionPolicy.ACTIVE_ITEMS:
            return await self._cleanup_active_items(cutoff_date, rule)
        elif rule.policy == RetentionPolicy.RESOLVED_ITEMS:
            return await self._cleanup_resolved_items(cutoff_date, rule)
        elif rule.policy == RetentionPolicy.USER_DATA:
            return await self._cleanup_inactive_users(rule)
        elif rule.policy == RetentionPolicy.AUDIT_LOGS:
            return await self._cleanup_audit_logs(cutoff_date, rule)
        elif rule.policy == RetentionPolicy.SESSION_DATA:
            return await self._cleanup_session_data(cutoff_date)
        elif rule.policy == RetentionPolicy.ANALYTICS_DATA:
            return await self._cleanup_analytics_data(cutoff_date, rule)
        
        return 0
    
    async def _cleanup_active_items(self, cutoff_date: datetime, rule: RetentionRule) -> int:
        """Clean up old active items"""
        query = self.db.query(Item).filter(
            and_(
                Item.created_at < cutoff_date,
                Item.status == 'active',
                Item.deleted_at.is_(None)  # Not already soft deleted
            )
        )
        
        items = query.all()
        count = 0
        
        for item in items:
            if rule.archive_before_delete:
                await self._archive_item(item)
            
            if rule.soft_delete:
                item.deleted_at = datetime.utcnow()
                item.status = 'expired'
            else:
                self.db.delete(item)
            
            count += 1
        
        self.db.commit()
        return count
    
    async def _cleanup_resolved_items(self, cutoff_date: datetime, rule: RetentionRule) -> int:
        """Clean up old resolved items"""
        query = self.db.query(Item).filter(
            and_(
                Item.updated_at < cutoff_date,
                Item.status.in_(['resolved', 'claimed']),
                Item.deleted_at.is_(None)
            )
        )
        
        items = query.all()
        count = 0
        
        for item in items:
            if rule.archive_before_delete:
                await self._archive_item(item)
            
            if rule.soft_delete:
                item.deleted_at = datetime.utcnow()
            else:
                # Also clean up related data
                self.db.query(Match).filter(
                    or_(Match.item1_id == item.id, Match.item2_id == item.id)
                ).delete()
                self.db.query(Claim).filter(Claim.item_id == item.id).delete()
                self.db.delete(item)
            
            count += 1
        
        self.db.commit()
        return count
    
    async def _cleanup_inactive_users(self, rule: RetentionRule) -> int:
        """Clean up inactive user accounts"""
        inactive_days = rule.conditions.get('inactive_days', 365)
        cutoff_date = datetime.utcnow() - timedelta(days=inactive_days)
        
        query = self.db.query(User).filter(
            and_(
                or_(
                    User.last_login < cutoff_date,
                    User.last_login.is_(None)
                ),
                User.created_at < cutoff_date,
                User.deleted_at.is_(None),
                User.is_active == False  # Only inactive accounts
            )
        )
        
        users = query.all()
        count = 0
        
        for user in users:
            if rule.archive_before_delete:
                await self._archive_user_data(user)
            
            if rule.soft_delete:
                user.deleted_at = datetime.utcnow()
                # Anonymize sensitive data
                user.email = f"deleted_user_{user.id}@deleted.local"
                user.phone = ""
                user.full_name = "Deleted User"
            else:
                # Hard delete - cascade to related data
                self.db.query(Item).filter(Item.user_id == user.id).delete()
                self.db.query(Claim).filter(Claim.claimant_id == user.id).delete()
                self.db.delete(user)
            
            count += 1
        
        self.db.commit()
        return count
    
    async def _cleanup_audit_logs(self, cutoff_date: datetime, rule: RetentionRule) -> int:
        """Clean up old audit logs"""
        # Implementation depends on audit log storage mechanism
        # This is a placeholder for the audit log cleanup
        return 0
    
    async def _cleanup_session_data(self, cutoff_date: datetime) -> int:
        """Clean up expired session data from Redis"""
        from ..auth.session_manager import session_manager
        return session_manager.cleanup_expired_sessions()
    
    async def _cleanup_analytics_data(self, cutoff_date: datetime, rule: RetentionRule) -> int:
        """Clean up old analytics data"""
        # Implementation depends on analytics storage
        return 0
    
    async def _archive_item(self, item: Item):
        """Archive item data before deletion"""
        archive_data = {
            'id': item.id,
            'type': item.type,
            'title': item.title,
            'description': item.description,
            'category': item.category,
            'location': {
                'latitude': item.location.latitude if item.location else None,
                'longitude': item.location.longitude if item.location else None,
                'address': item.location.address if item.location else None
            },
            'created_at': item.created_at.isoformat(),
            'archived_at': datetime.utcnow().isoformat()
        }
        
        # Store in archive (could be S3, file system, etc.)
        await self._store_archive('items', item.id, archive_data)
    
    async def _archive_user_data(self, user: User):
        """Archive user data before deletion"""
        archive_data = {
            'id': user.id,
            'email': user.email,
            'full_name': user.full_name,
            'created_at': user.created_at.isoformat(),
            'last_login': user.last_login.isoformat() if user.last_login else None,
            'archived_at': datetime.utcnow().isoformat()
        }
        
        await self._store_archive('users', user.id, archive_data)
    
    async def _store_archive(self, data_type: str, record_id: int, data: Dict[str, Any]):
        """Store archived data"""
        archive_dir = Path(settings.ARCHIVE_DIRECTORY) / data_type
        archive_dir.mkdir(parents=True, exist_ok=True)
        
        filename = f"{record_id}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.json"
        filepath = archive_dir / filename
        
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)

class GDPRComplianceService:
    """Service for GDPR compliance operations"""
    
    def __init__(self, db: Session):
        self.db = db
    
    async def export_user_data(self, user_id: int) -> bytes:
        """Export all user data for GDPR compliance"""
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise ValueError("User not found")
        
        # Collect all user data
        export_data = {
            'user_profile': self._export_user_profile(user),
            'items': self._export_user_items(user_id),
            'claims': self._export_user_claims(user_id),
            'matches': self._export_user_matches(user_id),
            'export_metadata': {
                'exported_at': datetime.utcnow().isoformat(),
                'export_version': '1.0',
                'user_id': user_id
            }
        }
        
        # Create ZIP file
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
            # Add main data file
            zip_file.writestr(
                'user_data.json',
                json.dumps(export_data, indent=2, default=str)
            )
            
            # Add user images if any
            await self._add_user_images_to_zip(zip_file, user_id)
        
        zip_buffer.seek(0)
        return zip_buffer.getvalue()
    
    def _export_user_profile(self, user: User) -> Dict[str, Any]:
        """Export user profile data"""
        return {
            'id': user.id,
            'email': user.email,
            'full_name': user.full_name,
            'phone': user.phone,
            'created_at': user.created_at,
            'last_login': user.last_login,
            'email_verified': user.email_verified,
            'role': user.role.value,
            'language_preference': getattr(user, 'language_preference', 'en')
        }
    
    def _export_user_items(self, user_id: int) -> List[Dict[str, Any]]:
        """Export user's items"""
        items = self.db.query(Item).filter(
            Item.user_id == user_id,
            Item.deleted_at.is_(None)
        ).all()
        
        return [
            {
                'id': item.id,
                'type': item.type,
                'title': item.title,
                'description': item.description,
                'category': item.category,
                'subcategory': item.subcategory,
                'brand': item.brand,
                'color': item.color,
                'model': item.model,
                'status': item.status,
                'location': {
                    'latitude': item.location.latitude if item.location else None,
                    'longitude': item.location.longitude if item.location else None,
                    'address': item.location.address if item.location else None
                },
                'date_lost_found': item.date_lost_found,
                'reward_offered': item.reward_offered,
                'created_at': item.created_at,
                'updated_at': item.updated_at
            }
            for item in items
        ]
    
    def _export_user_claims(self, user_id: int) -> List[Dict[str, Any]]:
        """Export user's claims"""
        claims = self.db.query(Claim).filter(
            Claim.claimant_id == user_id,
            Claim.deleted_at.is_(None)
        ).all()
        
        return [
            {
                'id': claim.id,
                'item_id': claim.item_id,
                'status': claim.status,
                'description': claim.description,
                'contact_info': claim.contact_info,
                'created_at': claim.created_at,
                'updated_at': claim.updated_at
            }
            for claim in claims
        ]
    
    def _export_user_matches(self, user_id: int) -> List[Dict[str, Any]]:
        """Export matches involving user's items"""
        # Get user's items
        user_items = self.db.query(Item.id).filter(Item.user_id == user_id).all()
        item_ids = [item.id for item in user_items]
        
        if not item_ids:
            return []
        
        matches = self.db.query(Match).filter(
            or_(
                Match.item1_id.in_(item_ids),
                Match.item2_id.in_(item_ids)
            )
        ).all()
        
        return [
            {
                'id': match.id,
                'item1_id': match.item1_id,
                'item2_id': match.item2_id,
                'score': match.score,
                'status': match.status,
                'created_at': match.created_at
            }
            for match in matches
        ]
    
    async def _add_user_images_to_zip(self, zip_file: zipfile.ZipFile, user_id: int):
        """Add user's item images to export ZIP"""
        # This would fetch and add actual image files
        # Implementation depends on image storage system
        pass
    
    async def delete_user_data(self, user_id: int, verification_code: str) -> bool:
        """Permanently delete all user data (GDPR right to be forgotten)"""
        # Verify deletion request (in real implementation, this would check a verification code)
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            return False
        
        try:
            # Delete user's items and related data
            user_items = self.db.query(Item).filter(Item.user_id == user_id).all()
            for item in user_items:
                # Delete matches involving this item
                self.db.query(Match).filter(
                    or_(Match.item1_id == item.id, Match.item2_id == item.id)
                ).delete()
                
                # Delete claims for this item
                self.db.query(Claim).filter(Claim.item_id == item.id).delete()
                
                # Delete the item itself
                self.db.delete(item)
            
            # Delete user's claims on other items
            self.db.query(Claim).filter(Claim.claimant_id == user_id).delete()
            
            # Delete the user account
            self.db.delete(user)
            
            self.db.commit()
            
            logger.info(f"Permanently deleted all data for user {user_id}")
            return True
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error deleting user data for user {user_id}: {e}")
            return False
    
    def anonymize_user_data(self, user_id: int) -> bool:
        """Anonymize user data while preserving statistical value"""
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            return False
        
        try:
            # Anonymize user profile
            user.email = f"anonymous_{user.id}@anonymized.local"
            user.full_name = "Anonymous User"
            user.phone = ""
            user.oauth_provider_id = None
            
            # Anonymize items (keep statistical data but remove identifying info)
            user_items = self.db.query(Item).filter(Item.user_id == user_id).all()
            for item in user_items:
                item.title = f"Anonymous Item {item.id}"
                item.description = "Description removed for privacy"
                # Keep category, type, location (fuzzy) for statistical purposes
            
            # Anonymize claims
            user_claims = self.db.query(Claim).filter(Claim.claimant_id == user_id).all()
            for claim in user_claims:
                claim.description = "Claim description removed for privacy"
                claim.contact_info = {}
            
            self.db.commit()
            
            logger.info(f"Anonymized data for user {user_id}")
            return True
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error anonymizing user data for user {user_id}: {e}")
            return False

# Background task for automated retention policy enforcement
async def run_retention_policies():
    """Background task to run retention policies"""
    while True:
        try:
            db = next(get_db())
            retention_service = DataRetentionService(db)
            results = await retention_service.apply_retention_policies()
            
            total_processed = sum(count for count in results.values() if count > 0)
            if total_processed > 0:
                logger.info(f"Retention policies processed {total_processed} records")
            
        except Exception as e:
            logger.error(f"Error running retention policies: {e}")
        
        # Run daily
        await asyncio.sleep(24 * 60 * 60)
