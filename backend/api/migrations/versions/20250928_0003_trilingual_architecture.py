"""Tri-lingual Lost & Found architecture with geospatial support

Revision ID: 20250928_0003
Revises: 20250928_0002_admin_enhancements
Create Date: 2025-09-28 20:50:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
import geoalchemy2

# revision identifiers, used by Alembic.
revision = '20250928_0003'
down_revision = '20250928_0002_admin_enhancements'
branch_labels = None
depends_on = None


def upgrade():
    # Enable PostGIS extension
    op.execute('CREATE EXTENSION IF NOT EXISTS postgis')
    
    # Add new columns to users table (skip columns that already exist from init migration)
    op.add_column('users', sa.Column('phone', sa.String(length=20), nullable=True))
    op.add_column('users', sa.Column('preferred_language', sa.String(length=5), nullable=False, server_default='en'))
    # is_active already exists from init migration
    op.add_column('users', sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')))
    
    # Drop old columns from items table
    op.drop_column('items', 'lat')
    op.drop_column('items', 'lng')
    
    # Add new columns to items table
    op.add_column('items', sa.Column('language', sa.String(length=5), nullable=False, server_default='en'))
    op.add_column('items', sa.Column('subcategory', sa.String(length=100), nullable=True))
    op.add_column('items', sa.Column('brand', sa.String(length=100), nullable=True))
    op.add_column('items', sa.Column('model', sa.String(length=100), nullable=True))
    op.add_column('items', sa.Column('color', sa.String(length=50), nullable=True))
    op.add_column('items', sa.Column('unique_marks', sa.Text(), nullable=True))
    op.add_column('items', sa.Column('evidence_hash', sa.String(length=64), nullable=True))
    
    # Geospatial columns
    op.add_column('items', sa.Column('location_point', geoalchemy2.Geography('POINT', srid=4326), nullable=True))
    op.add_column('items', sa.Column('location_name', sa.String(length=255), nullable=True))
    op.add_column('items', sa.Column('geohash6', sa.String(length=6), nullable=True))
    op.add_column('items', sa.Column('location_fuzzing', sa.Integer(), nullable=False, server_default='100'))
    
    # Temporal columns
    op.add_column('items', sa.Column('lost_found_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('items', sa.Column('time_window_start', sa.DateTime(timezone=True), nullable=True))
    op.add_column('items', sa.Column('time_window_end', sa.DateTime(timezone=True), nullable=True))
    
    # System columns
    op.add_column('items', sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')))
    
    # NLP columns (optional)
    op.add_column('items', sa.Column('text_embedding', postgresql.JSON(astext_type=sa.Text()), nullable=True))
    op.add_column('items', sa.Column('extracted_entities', postgresql.JSON(astext_type=sa.Text()), nullable=True))
    
    # Update items.status to support new values
    op.execute("ALTER TABLE items DROP CONSTRAINT IF EXISTS items_status_check")
    op.execute("ALTER TABLE items ADD CONSTRAINT items_status_check CHECK (status IN ('lost', 'found', 'claimed', 'closed'))")
    
    # Make category required
    op.alter_column('items', 'category', nullable=False)
    
    # Update matches table structure
    op.drop_column('matches', 'score')
    op.add_column('matches', sa.Column('score_final', sa.Float(), nullable=False, server_default='0'))
    op.add_column('matches', sa.Column('score_breakdown', postgresql.JSON(astext_type=sa.Text()), nullable=True))
    op.add_column('matches', sa.Column('distance_km', sa.Float(), nullable=True))
    op.add_column('matches', sa.Column('time_diff_hours', sa.Float(), nullable=True))
    op.add_column('matches', sa.Column('status', sa.String(length=20), nullable=False, server_default='pending'))
    op.add_column('matches', sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')))
    
    # Create claims table
    op.create_table('claims',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('match_id', sa.Integer(), nullable=False),
        sa.Column('claimant_id', sa.Integer(), nullable=False),
        sa.Column('owner_id', sa.Integer(), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='pending'),
        sa.Column('evidence_provided', sa.Text(), nullable=True),
        sa.Column('evidence_hash', sa.String(length=64), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['claimant_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['match_id'], ['matches.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['owner_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Update chat_messages table
    op.drop_column('chat_messages', 'room')
    op.add_column('chat_messages', sa.Column('match_id', sa.Integer(), nullable=False))
    op.add_column('chat_messages', sa.Column('is_masked', sa.Boolean(), nullable=False, server_default='true'))
    op.create_foreign_key('fk_chat_messages_match', 'chat_messages', 'matches', ['match_id'], ['id'], ondelete='CASCADE')
    
    # Create audit_logs table
    op.create_table('audit_logs',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('action', sa.String(length=100), nullable=False),
        sa.Column('resource_type', sa.String(length=50), nullable=False),
        sa.Column('resource_id', sa.Integer(), nullable=True),
        sa.Column('ip_address', sa.String(length=45), nullable=True),
        sa.Column('user_agent', sa.Text(), nullable=True),
        sa.Column('metadata', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create indexes for performance
    
    # Items indexes
    op.create_index('idx_items_category_subcategory', 'items', ['category', 'subcategory'])
    op.create_index('idx_items_geohash_time', 'items', ['geohash6', 'lost_found_at'])
    op.create_index('idx_items_status_category', 'items', ['status', 'category'])
    op.create_index('idx_items_time_window', 'items', ['time_window_start', 'time_window_end'])
    op.create_index('idx_items_brand', 'items', ['brand'])
    op.create_index('idx_items_color', 'items', ['color'])
    op.create_index('idx_items_geohash6', 'items', ['geohash6'])
    
    # Geospatial index
    op.execute('CREATE INDEX IF NOT EXISTS idx_items_location_point ON items USING GIST (location_point)')
    
    # Matches indexes
    op.create_index('idx_matches_score', 'matches', ['score_final'])
    op.create_index('idx_matches_lost_item', 'matches', ['lost_item_id', 'status'])
    op.create_index('idx_matches_found_item', 'matches', ['found_item_id', 'status'])
    
    # Audit logs indexes
    op.create_index('idx_audit_logs_user_action', 'audit_logs', ['user_id', 'action'])
    op.create_index('idx_audit_logs_resource', 'audit_logs', ['resource_type', 'resource_id'])
    op.create_index('idx_audit_logs_created', 'audit_logs', ['created_at'])


def downgrade():
    # Drop new indexes
    op.drop_index('idx_audit_logs_created', table_name='audit_logs')
    op.drop_index('idx_audit_logs_resource', table_name='audit_logs')
    op.drop_index('idx_audit_logs_user_action', table_name='audit_logs')
    op.drop_index('idx_matches_found_item', table_name='matches')
    op.drop_index('idx_matches_lost_item', table_name='matches')
    op.drop_index('idx_matches_score', table_name='matches')
    op.execute('DROP INDEX IF EXISTS idx_items_location_point')
    op.drop_index('idx_items_geohash6', table_name='items')
    op.drop_index('idx_items_color', table_name='items')
    op.drop_index('idx_items_brand', table_name='items')
    op.drop_index('idx_items_time_window', table_name='items')
    op.drop_index('idx_items_status_category', table_name='items')
    op.drop_index('idx_items_geohash_time', table_name='items')
    op.drop_index('idx_items_category_subcategory', table_name='items')
    
    # Drop new tables
    op.drop_table('audit_logs')
    op.drop_table('claims')
    
    # Revert chat_messages changes
    op.drop_constraint('fk_chat_messages_match', 'chat_messages', type_='foreignkey')
    op.drop_column('chat_messages', 'is_masked')
    op.drop_column('chat_messages', 'match_id')
    op.add_column('chat_messages', sa.Column('room', sa.String(length=100), nullable=False))
    
    # Revert matches table changes
    op.drop_column('matches', 'updated_at')
    op.drop_column('matches', 'status')
    op.drop_column('matches', 'time_diff_hours')
    op.drop_column('matches', 'distance_km')
    op.drop_column('matches', 'score_breakdown')
    op.drop_column('matches', 'score_final')
    op.add_column('matches', sa.Column('score', sa.Float(), nullable=False, server_default='0'))
    
    # Revert items table changes
    op.drop_column('items', 'extracted_entities')
    op.drop_column('items', 'text_embedding')
    op.drop_column('items', 'updated_at')
    op.drop_column('items', 'time_window_end')
    op.drop_column('items', 'time_window_start')
    op.drop_column('items', 'lost_found_at')
    op.drop_column('items', 'location_fuzzing')
    op.drop_column('items', 'geohash6')
    op.drop_column('items', 'location_name')
    op.drop_column('items', 'location_point')
    op.drop_column('items', 'evidence_hash')
    op.drop_column('items', 'unique_marks')
    op.drop_column('items', 'color')
    op.drop_column('items', 'model')
    op.drop_column('items', 'brand')
    op.drop_column('items', 'subcategory')
    op.drop_column('items', 'language')
    
    # Restore old columns
    op.add_column('items', sa.Column('lng', sa.Float(), nullable=True))
    op.add_column('items', sa.Column('lat', sa.Float(), nullable=True))
    
    # Revert category constraint
    op.alter_column('items', 'category', nullable=True)
    
    # Revert status constraint
    op.execute("ALTER TABLE items DROP CONSTRAINT IF EXISTS items_status_check")
    op.execute("ALTER TABLE items ADD CONSTRAINT items_status_check CHECK (status IN ('lost', 'found', 'resolved'))")
    
    # Revert users table changes
    op.drop_column('users', 'updated_at')
    op.drop_column('users', 'is_active')
    op.drop_column('users', 'preferred_language')
    op.drop_column('users', 'phone')
