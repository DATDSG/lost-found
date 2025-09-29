"""Add soft delete columns to existing tables

Revision ID: add_soft_delete_001
Revises: 
Create Date: 2024-09-29 10:51:45.000000

"""
from alembic import op
import sqlalchemy as sa
from datetime import datetime

# revision identifiers, used by Alembic.
revision = 'add_soft_delete_001'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    """Add soft delete columns to existing tables"""
    
    # Add soft delete columns to users table
    op.add_column('users', sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('users', sa.Column('deleted_by', sa.String(255), nullable=True))
    op.add_column('users', sa.Column('deletion_reason', sa.Text(), nullable=True))
    op.add_column('users', sa.Column('is_deleted', sa.Boolean(), nullable=False, default=False))
    
    # Add indexes for users
    op.create_index('idx_users_deleted_at', 'users', ['deleted_at'])
    op.create_index('idx_users_is_deleted', 'users', ['is_deleted'])
    
    # Add soft delete columns to items table
    op.add_column('items', sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('items', sa.Column('deleted_by', sa.String(255), nullable=True))
    op.add_column('items', sa.Column('deletion_reason', sa.Text(), nullable=True))
    op.add_column('items', sa.Column('is_deleted', sa.Boolean(), nullable=False, default=False))
    
    # Add indexes for items
    op.create_index('idx_items_deleted_at', 'items', ['deleted_at'])
    op.create_index('idx_items_is_deleted', 'items', ['is_deleted'])
    
    # Add soft delete columns to media_assets table
    op.add_column('media_assets', sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('media_assets', sa.Column('deleted_by', sa.String(255), nullable=True))
    op.add_column('media_assets', sa.Column('deletion_reason', sa.Text(), nullable=True))
    op.add_column('media_assets', sa.Column('is_deleted', sa.Boolean(), nullable=False, default=False))
    
    # Add indexes for media_assets
    op.create_index('idx_media_assets_deleted_at', 'media_assets', ['deleted_at'])
    op.create_index('idx_media_assets_is_deleted', 'media_assets', ['is_deleted'])
    
    # Add soft delete columns to matches table
    op.add_column('matches', sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('matches', sa.Column('deleted_by', sa.String(255), nullable=True))
    op.add_column('matches', sa.Column('deletion_reason', sa.Text(), nullable=True))
    op.add_column('matches', sa.Column('is_deleted', sa.Boolean(), nullable=False, default=False))
    
    # Add indexes for matches
    op.create_index('idx_matches_deleted_at', 'matches', ['deleted_at'])
    op.create_index('idx_matches_is_deleted', 'matches', ['is_deleted'])
    
    # Add soft delete columns to claims table
    op.add_column('claims', sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('claims', sa.Column('deleted_by', sa.String(255), nullable=True))
    op.add_column('claims', sa.Column('deletion_reason', sa.Text(), nullable=True))
    op.add_column('claims', sa.Column('is_deleted', sa.Boolean(), nullable=False, default=False))
    
    # Add indexes for claims
    op.create_index('idx_claims_deleted_at', 'claims', ['deleted_at'])
    op.create_index('idx_claims_is_deleted', 'claims', ['is_deleted'])

def downgrade():
    """Remove soft delete columns"""
    
    # Drop indexes and columns for claims
    op.drop_index('idx_claims_is_deleted')
    op.drop_index('idx_claims_deleted_at')
    op.drop_column('claims', 'is_deleted')
    op.drop_column('claims', 'deletion_reason')
    op.drop_column('claims', 'deleted_by')
    op.drop_column('claims', 'deleted_at')
    
    # Drop indexes and columns for matches
    op.drop_index('idx_matches_is_deleted')
    op.drop_index('idx_matches_deleted_at')
    op.drop_column('matches', 'is_deleted')
    op.drop_column('matches', 'deletion_reason')
    op.drop_column('matches', 'deleted_by')
    op.drop_column('matches', 'deleted_at')
    
    # Drop indexes and columns for media_assets
    op.drop_index('idx_media_assets_is_deleted')
    op.drop_index('idx_media_assets_deleted_at')
    op.drop_column('media_assets', 'is_deleted')
    op.drop_column('media_assets', 'deletion_reason')
    op.drop_column('media_assets', 'deleted_by')
    op.drop_column('media_assets', 'deleted_at')
    
    # Drop indexes and columns for items
    op.drop_index('idx_items_is_deleted')
    op.drop_index('idx_items_deleted_at')
    op.drop_column('items', 'is_deleted')
    op.drop_column('items', 'deletion_reason')
    op.drop_column('items', 'deleted_by')
    op.drop_column('items', 'deleted_at')
    
    # Drop indexes and columns for users
    op.drop_index('idx_users_is_deleted')
    op.drop_index('idx_users_deleted_at')
    op.drop_column('users', 'is_deleted')
    op.drop_column('users', 'deletion_reason')
    op.drop_column('users', 'deleted_by')
    op.drop_column('users', 'deleted_at')
