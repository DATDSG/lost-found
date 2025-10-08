"""Schema improvements: add missing columns and indexes

Revision ID: 0004_schema_improvements
Revises: 0003_vector_geo
Create Date: 2025-10-07
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '0004_schema_improvements'
down_revision = '0003_vector_geo'
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Add missing columns and improve schema."""
    
    # Add missing columns to users table
    op.add_column('users', sa.Column('hashed_password', sa.String(255), nullable=True))
    op.add_column('users', sa.Column('is_active', sa.Boolean(), server_default='true', nullable=False))
    op.add_column('users', sa.Column('phone_number', sa.String(20), nullable=True))
    op.add_column('users', sa.Column('avatar_url', sa.String(500), nullable=True))
    op.add_column('users', sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('NOW()'), nullable=False))
    
    # Add missing columns to reports table
    op.add_column('reports', sa.Column('location_city', sa.String(100), nullable=True))
    op.add_column('reports', sa.Column('location_address', sa.Text(), nullable=True))
    op.add_column('reports', sa.Column('attributes', sa.Text(), nullable=True))
    op.add_column('reports', sa.Column('reward_offered', sa.Boolean(), server_default='false', nullable=False))
    op.add_column('reports', sa.Column('is_resolved', sa.Boolean(), server_default='false', nullable=False))
    
    # Add missing columns to media table
    op.add_column('media', sa.Column('url', sa.String(500), nullable=True))
    op.add_column('media', sa.Column('media_type', sa.String(20), server_default='image', nullable=False))
    
    # Add missing columns to messages table
    op.add_column('messages', sa.Column('is_read', sa.Boolean(), server_default='false', nullable=False))
    
    # Add missing columns to notifications table
    op.add_column('notifications', sa.Column('title', sa.String(200), nullable=True))
    op.add_column('notifications', sa.Column('content', sa.Text(), nullable=True))
    op.add_column('notifications', sa.Column('reference_id', postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column('notifications', sa.Column('is_read', sa.Boolean(), server_default='false', nullable=False))
    
    # Add missing columns to conversations table
    op.add_column('conversations', sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('NOW()'), nullable=False))
    
    # Create additional indexes for better performance
    op.create_index('ix_users_email', 'users', ['email'], unique=True)
    op.create_index('ix_users_status', 'users', ['status'])
    
    op.create_index('ix_reports_type', 'reports', ['type'])
    op.create_index('ix_reports_category', 'reports', ['category'])
    op.create_index('ix_reports_city', 'reports', ['location_city'])
    op.create_index('ix_reports_resolved', 'reports', ['is_resolved'])
    
    op.create_index('ix_media_report_id', 'media', ['report_id'])
    op.create_index('ix_media_phash', 'media', ['phash_hex'])
    op.create_index('ix_media_dhash', 'media', ['dhash_hex'])
    
    op.create_index('ix_matches_candidate', 'matches', ['candidate_report_id'])
    op.create_index('ix_matches_status', 'matches', ['status'])
    op.create_index('ix_matches_score', 'matches', ['score_total'])
    
    op.create_index('ix_messages_conversation', 'messages', ['conversation_id', 'created_at'])
    op.create_index('ix_messages_sender', 'messages', ['sender_id'])
    
    op.create_index('ix_notifications_user_created', 'notifications', ['user_id', 'created_at'])
    op.create_index('ix_notifications_user_unread', 'notifications', ['user_id', 'is_read'])
    
    op.create_index('ix_audit_log_actor', 'audit_log', ['actor_id'])
    op.create_index('ix_audit_log_resource', 'audit_log', ['resource', 'resource_id'])


def downgrade() -> None:
    """Remove added columns and indexes."""
    
    # Drop indexes
    op.drop_index('ix_audit_log_resource', table_name='audit_log')
    op.drop_index('ix_audit_log_actor', table_name='audit_log')
    op.drop_index('ix_notifications_user_unread', table_name='notifications')
    op.drop_index('ix_notifications_user_created', table_name='notifications')
    op.drop_index('ix_messages_sender', table_name='messages')
    op.drop_index('ix_messages_conversation', table_name='messages')
    op.drop_index('ix_matches_score', table_name='matches')
    op.drop_index('ix_matches_status', table_name='matches')
    op.drop_index('ix_matches_candidate', table_name='matches')
    op.drop_index('ix_media_dhash', table_name='media')
    op.drop_index('ix_media_phash', table_name='media')
    op.drop_index('ix_media_report_id', table_name='media')
    op.drop_index('ix_reports_resolved', table_name='reports')
    op.drop_index('ix_reports_city', table_name='reports')
    op.drop_index('ix_reports_category', table_name='reports')
    op.drop_index('ix_reports_type', table_name='reports')
    op.drop_index('ix_users_status', table_name='users')
    op.drop_index('ix_users_email', table_name='users')
    
    # Drop columns
    op.drop_column('conversations', 'updated_at')
    op.drop_column('notifications', 'is_read')
    op.drop_column('notifications', 'reference_id')
    op.drop_column('notifications', 'content')
    op.drop_column('notifications', 'title')
    op.drop_column('messages', 'is_read')
    op.drop_column('media', 'media_type')
    op.drop_column('media', 'url')
    op.drop_column('reports', 'is_resolved')
    op.drop_column('reports', 'reward_offered')
    op.drop_column('reports', 'attributes')
    op.drop_column('reports', 'location_address')
    op.drop_column('reports', 'location_city')
    op.drop_column('users', 'updated_at')
    op.drop_column('users', 'avatar_url')
    op.drop_column('users', 'phone_number')
    op.drop_column('users', 'is_active')
    op.drop_column('users', 'hashed_password')
