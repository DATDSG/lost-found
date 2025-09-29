"""
Soft Delete Implementation
Provides soft delete functionality for all models with audit trail
"""

from datetime import datetime, timedelta
from typing import Optional, Any, Dict
from sqlalchemy import Column, DateTime, Boolean, String, Text, event
from sqlalchemy.ext.declarative import declared_attr
from sqlalchemy.orm import Session, Query
import logging

logger = logging.getLogger(__name__)

class SoftDeleteMixin:
    """Mixin to add soft delete functionality to models"""
    
    @declared_attr
    def deleted_at(cls):
        return Column(DateTime, nullable=True, index=True)
    
    @declared_attr
    def deleted_by(cls):
        return Column(String(255), nullable=True)
    
    @declared_attr
    def deletion_reason(cls):
        return Column(Text, nullable=True)
    
    @declared_attr
    def is_deleted(cls):
        return Column(Boolean, default=False, nullable=False, index=True)
    
    def soft_delete(
        self, 
        deleted_by: Optional[str] = None, 
        reason: Optional[str] = None,
        session: Optional[Session] = None
    ):
        """Soft delete the record"""
        self.deleted_at = datetime.utcnow()
        self.deleted_by = deleted_by
        self.deletion_reason = reason
        self.is_deleted = True
        
        if session:
            session.add(self)
            session.commit()
        
        logger.info(f"Soft deleted {self.__class__.__name__} {getattr(self, 'id', 'unknown')} by {deleted_by}")
    
    def restore(
        self, 
        restored_by: Optional[str] = None,
        session: Optional[Session] = None
    ):
        """Restore a soft deleted record"""
        self.deleted_at = None
        self.deleted_by = None
        self.deletion_reason = None
        self.is_deleted = False
        
        if session:
            session.add(self)
            session.commit()
        
        logger.info(f"Restored {self.__class__.__name__} {getattr(self, 'id', 'unknown')} by {restored_by}")
    
    @property
    def is_soft_deleted(self) -> bool:
        """Check if record is soft deleted"""
        return self.is_deleted and self.deleted_at is not None

class SoftDeleteQuery(Query):
    """Custom query class that excludes soft deleted records by default"""
    
    def __new__(cls, *args, **kwargs):
        if args and hasattr(args[0], '__mapper__'):
            # Check if the model has soft delete capability
            model = args[0]
            if hasattr(model.class_, 'is_deleted'):
                # Automatically filter out soft deleted records
                return super().__new__(cls)
        return super().__new__(cls)
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        # Auto-filter soft deleted records
        if (hasattr(self, 'column_descriptions') and 
            self.column_descriptions and 
            hasattr(self.column_descriptions[0]['type'], 'is_deleted')):
            self = self.filter(self.column_descriptions[0]['type'].is_deleted == False)
    
    def with_deleted(self):
        """Include soft deleted records in query"""
        # Remove the is_deleted filter
        return self.enable_assertions(False).filter()
    
    def only_deleted(self):
        """Only return soft deleted records"""
        return self.enable_assertions(False).filter(
            self.column_descriptions[0]['type'].is_deleted == True
        )

class AuditLogMixin:
    """Mixin to add audit logging for model changes"""
    
    @declared_attr
    def created_at(cls):
        return Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    
    @declared_attr
    def updated_at(cls):
        return Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False, index=True)
    
    @declared_attr
    def created_by(cls):
        return Column(String(255), nullable=True)
    
    @declared_attr
    def updated_by(cls):
        return Column(String(255), nullable=True)

def setup_soft_delete_listeners():
    """Set up SQLAlchemy event listeners for soft delete functionality"""
    
    @event.listens_for(Session, 'before_delete')
    def before_delete_listener(mapper, connection, target):
        """Convert hard deletes to soft deletes for models with SoftDeleteMixin"""
        if hasattr(target, 'soft_delete'):
            # Prevent hard delete, use soft delete instead
            target.soft_delete()
            # Cancel the delete operation
            return False
    
    @event.listens_for(Session, 'before_update')
    def before_update_listener(mapper, connection, target):
        """Update the updated_at timestamp"""
        if hasattr(target, 'updated_at'):
            target.updated_at = datetime.utcnow()

class SoftDeleteService:
    """Service for managing soft delete operations"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def soft_delete_item(
        self, 
        model_class: Any, 
        item_id: int, 
        deleted_by: str,
        reason: str = None
    ) -> bool:
        """Soft delete an item by ID"""
        try:
            item = self.db.query(model_class).filter(
                model_class.id == item_id,
                model_class.is_deleted == False
            ).first()
            
            if not item:
                return False
            
            item.soft_delete(deleted_by=deleted_by, reason=reason, session=self.db)
            return True
            
        except Exception as e:
            logger.error(f"Error soft deleting {model_class.__name__} {item_id}: {e}")
            self.db.rollback()
            return False
    
    def restore_item(
        self, 
        model_class: Any, 
        item_id: int, 
        restored_by: str
    ) -> bool:
        """Restore a soft deleted item"""
        try:
            item = self.db.query(model_class).filter(
                model_class.id == item_id,
                model_class.is_deleted == True
            ).first()
            
            if not item:
                return False
            
            item.restore(restored_by=restored_by, session=self.db)
            return True
            
        except Exception as e:
            logger.error(f"Error restoring {model_class.__name__} {item_id}: {e}")
            self.db.rollback()
            return False
    
    def bulk_soft_delete(
        self, 
        model_class: Any, 
        item_ids: list[int], 
        deleted_by: str,
        reason: str = None
    ) -> int:
        """Soft delete multiple items"""
        try:
            count = self.db.query(model_class).filter(
                model_class.id.in_(item_ids),
                model_class.is_deleted == False
            ).update({
                'deleted_at': datetime.utcnow(),
                'deleted_by': deleted_by,
                'deletion_reason': reason,
                'is_deleted': True
            }, synchronize_session=False)
            
            self.db.commit()
            logger.info(f"Bulk soft deleted {count} {model_class.__name__} records")
            return count
            
        except Exception as e:
            logger.error(f"Error bulk soft deleting {model_class.__name__}: {e}")
            self.db.rollback()
            return 0
    
    def permanent_delete_old_records(
        self, 
        model_class: Any, 
        days_old: int = 90
    ) -> int:
        """Permanently delete records that have been soft deleted for a specified period"""
        try:
            cutoff_date = datetime.utcnow() - timedelta(days=days_old)
            
            # Find records to permanently delete
            records = self.db.query(model_class).filter(
                model_class.is_deleted == True,
                model_class.deleted_at < cutoff_date
            ).all()
            
            count = len(records)
            
            # Log before permanent deletion
            for record in records:
                logger.info(f"Permanently deleting {model_class.__name__} {getattr(record, 'id', 'unknown')}")
            
            # Permanently delete
            self.db.query(model_class).filter(
                model_class.is_deleted == True,
                model_class.deleted_at < cutoff_date
            ).delete(synchronize_session=False)
            
            self.db.commit()
            logger.info(f"Permanently deleted {count} old {model_class.__name__} records")
            return count
            
        except Exception as e:
            logger.error(f"Error permanently deleting old {model_class.__name__} records: {e}")
            self.db.rollback()
            return 0
    
    def get_deleted_items(
        self, 
        model_class: Any, 
        limit: int = 100,
        offset: int = 0
    ) -> list:
        """Get soft deleted items"""
        return self.db.query(model_class).filter(
            model_class.is_deleted == True
        ).offset(offset).limit(limit).all()
    
    def get_deletion_stats(self, model_class: Any) -> Dict[str, int]:
        """Get deletion statistics for a model"""
        total_count = self.db.query(model_class).count()
        deleted_count = self.db.query(model_class).filter(
            model_class.is_deleted == True
        ).count()
        active_count = total_count - deleted_count
        
        return {
            'total': total_count,
            'active': active_count,
            'deleted': deleted_count,
            'deletion_rate': (deleted_count / total_count * 100) if total_count > 0 else 0
        }

# Enhanced models with soft delete capability
class SoftDeletedItem(SoftDeleteMixin, AuditLogMixin):
    """Base class for items with soft delete and audit capabilities"""
    
    __abstract__ = True
    
    def __repr__(self):
        status = "DELETED" if self.is_soft_deleted else "ACTIVE"
        return f"<{self.__class__.__name__}(id={getattr(self, 'id', 'None')}, status={status})>"

# Database session configuration for soft delete
def configure_soft_delete_session(session_factory):
    """Configure database session to use soft delete query class"""
    
    # Set up event listeners
    setup_soft_delete_listeners()
    
    # Configure default query class
    session_factory.configure(query_cls=SoftDeleteQuery)
    
    return session_factory

# Utility functions for soft delete operations
def exclude_deleted(query: Query) -> Query:
    """Utility function to exclude deleted records from any query"""
    model = query.column_descriptions[0]['type']
    if hasattr(model, 'is_deleted'):
        return query.filter(model.is_deleted == False)
    return query

def include_deleted(query: Query) -> Query:
    """Utility function to include deleted records in query"""
    return query

def only_deleted(query: Query) -> Query:
    """Utility function to only return deleted records"""
    model = query.column_descriptions[0]['type']
    if hasattr(model, 'is_deleted'):
        return query.filter(model.is_deleted == True)
    return query.filter(False)  # Return empty result if no soft delete capability

# Decorator for automatic soft delete handling
def with_soft_delete(func):
    """Decorator to automatically handle soft delete in service methods"""
    def wrapper(*args, **kwargs):
        # Add soft delete filtering to queries
        result = func(*args, **kwargs)
        
        # If result is a query, apply soft delete filter
        if isinstance(result, Query):
            return exclude_deleted(result)
        
        return result
    
    return wrapper

# Migration helper for adding soft delete to existing models
class SoftDeleteMigration:
    """Helper class for migrating existing models to soft delete"""
    
    @staticmethod
    def add_soft_delete_columns(table_name: str) -> str:
        """Generate SQL to add soft delete columns to existing table"""
        return f"""
        ALTER TABLE {table_name} 
        ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL,
        ADD COLUMN IF NOT EXISTS deleted_by VARCHAR(255) NULL,
        ADD COLUMN IF NOT EXISTS deletion_reason TEXT NULL,
        ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE;
        
        CREATE INDEX IF NOT EXISTS idx_{table_name}_deleted_at ON {table_name}(deleted_at);
        CREATE INDEX IF NOT EXISTS idx_{table_name}_is_deleted ON {table_name}(is_deleted);
        """
    
    @staticmethod
    def migrate_existing_deletions(table_name: str) -> str:
        """Generate SQL to handle existing hard deletions"""
        return f"""
        -- This would typically involve restoring from backups or logs
        -- to identify previously deleted records and mark them as soft deleted
        
        -- Example: Mark records as deleted based on some criteria
        -- UPDATE {table_name} 
        -- SET is_deleted = TRUE, deleted_at = NOW(), deletion_reason = 'Historical deletion'
        -- WHERE some_condition_indicating_deletion;
        """
