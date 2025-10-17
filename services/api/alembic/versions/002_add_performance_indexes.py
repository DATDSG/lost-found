"""Add performance indexes

Revision ID: 002
Revises: 001
Create Date: 2024-01-15 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade():
    """Add performance indexes for frequently queried columns."""
    
    # Reports indexes
    op.create_index('idx_reports_status_type', 'reports', ['status', 'type'], unique=False)
    op.create_index('idx_reports_category_status', 'reports', ['category', 'status'], unique=False)
    op.create_index('idx_reports_owner_status', 'reports', ['owner_id', 'status'], unique=False)
    op.create_index('idx_reports_created_desc', 'reports', [sa.text('created_at DESC')], unique=False)
    
    # Matches indexes
    op.create_index('idx_matches_source_status', 'matches', ['source_report_id', 'status'], unique=False)
    op.create_index('idx_matches_candidate_status', 'matches', ['candidate_report_id', 'status'], unique=False)
    op.create_index('idx_matches_score_desc', 'matches', [sa.text('score_total DESC')], unique=False)
    
    # Messages indexes
    op.create_index('idx_messages_conversation_created', 'messages', ['conversation_id', 'created_at'], unique=False)
    op.create_index('idx_messages_sender_created', 'messages', ['sender_id', 'created_at'], unique=False)
    
    # Notifications indexes
    op.create_index('idx_notifications_user_read', 'notifications', ['user_id', 'is_read'], unique=False)
    op.create_index('idx_notifications_user_created', 'notifications', ['user_id', 'created_at'], unique=False)
    
    # Audit logs indexes
    op.create_index('idx_audit_actor_created', 'audit_log', ['actor_id', 'created_at'], unique=False)
    op.create_index('idx_audit_resource', 'audit_log', ['resource', 'resource_id'], unique=False)


def downgrade():
    """Remove performance indexes."""
    
    # Reports indexes
    op.drop_index('idx_reports_status_type', table_name='reports')
    op.drop_index('idx_reports_category_status', table_name='reports')
    op.drop_index('idx_reports_owner_status', table_name='reports')
    op.drop_index('idx_reports_created_desc', table_name='reports')
    
    # Matches indexes
    op.drop_index('idx_matches_source_status', table_name='matches')
    op.drop_index('idx_matches_candidate_status', table_name='matches')
    op.drop_index('idx_matches_score_desc', table_name='matches')
    
    # Messages indexes
    op.drop_index('idx_messages_conversation_created', table_name='messages')
    op.drop_index('idx_messages_sender_created', table_name='messages')
    
    # Notifications indexes
    op.drop_index('idx_notifications_user_read', table_name='notifications')
    op.drop_index('idx_notifications_user_created', table_name='notifications')
    
    # Audit logs indexes
    op.drop_index('idx_audit_actor_created', table_name='audit_log')
    op.drop_index('idx_audit_resource', table_name='audit_log')

