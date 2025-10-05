"""Add performance optimization indexes and extensions

Revision ID: performance_opt_001
Revises: add_soft_delete_001
Create Date: 2024-09-29 10:51:45.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import text

# revision identifiers, used by Alembic.
revision = 'performance_opt_001'
down_revision = 'add_soft_delete_001'
branch_labels = None
depends_on = None

def upgrade():
    """Add performance optimization indexes and extensions"""
    
    # Enable required PostgreSQL extensions
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis;")
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm;")
    op.execute("CREATE EXTENSION IF NOT EXISTS btree_gin;")
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_stat_statements;")
    
    # Add search vector column for full-text search
    op.add_column('items', sa.Column('search_vector', sa.Text, nullable=True))
    
    # Create function to update search vector
    op.execute("""
        CREATE OR REPLACE FUNCTION update_items_search_vector()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.search_vector := to_tsvector('english', 
                COALESCE(NEW.title, '') || ' ' ||
                COALESCE(NEW.description, '') || ' ' ||
                COALESCE(NEW.category, '') || ' ' ||
                COALESCE(NEW.subcategory, '') || ' ' ||
                COALESCE(NEW.brand, '') || ' ' ||
                COALESCE(NEW.model, '') || ' ' ||
                COALESCE(NEW.color, '')
            );
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    """)
    
    # Create trigger to automatically update search vector
    op.execute("""
        CREATE TRIGGER items_search_vector_trigger
        BEFORE INSERT OR UPDATE ON items
        FOR EACH ROW EXECUTE FUNCTION update_items_search_vector();
    """)
    
    # Update existing records with search vector
    op.execute("""
        UPDATE items SET search_vector = to_tsvector('english', 
            COALESCE(title, '') || ' ' ||
            COALESCE(description, '') || ' ' ||
            COALESCE(category, '') || ' ' ||
            COALESCE(subcategory, '') || ' ' ||
            COALESCE(brand, '') || ' ' ||
            COALESCE(model, '') || ' ' ||
            COALESCE(color, '')
        );
    """)
    
    # Geospatial indexes
    op.execute("CREATE INDEX IF NOT EXISTS idx_items_location_gist ON items USING GIST (location_point);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_items_geohash6 ON items (geohash6) WHERE geohash6 IS NOT NULL;")
    
    # Full-text search indexes
    op.execute("CREATE INDEX IF NOT EXISTS idx_items_search_vector ON items USING GIN (search_vector);")
    
    # Trigram indexes for fuzzy search
    op.execute("CREATE INDEX IF NOT EXISTS idx_items_title_trigram ON items USING GIN (title gin_trgm_ops);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_items_description_trigram ON items USING GIN (description gin_trgm_ops) WHERE description IS NOT NULL;")
    
    # Category and filtering indexes
    op.execute("CREATE INDEX IF NOT EXISTS idx_items_category_subcategory_status ON items (category, subcategory, status);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_items_brand_model ON items (brand, model) WHERE brand IS NOT NULL;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_items_color ON items (color) WHERE color IS NOT NULL;")
    
    # Temporal indexes
    op.execute("CREATE INDEX IF NOT EXISTS idx_items_created_at_desc ON items (created_at DESC);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_items_updated_at_desc ON items (updated_at DESC);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_items_lost_found_at ON items (lost_found_at DESC) WHERE lost_found_at IS NOT NULL;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_items_time_window ON items (time_window_start, time_window_end) WHERE time_window_start IS NOT NULL;")
    
    # Composite indexes for common query patterns
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_items_active_location_time 
        ON items (status, category, created_at DESC, location_point) 
        WHERE is_deleted = FALSE AND status IN ('lost', 'found');
    """)
    
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_items_user_active 
        ON items (owner_id, status, created_at DESC) 
        WHERE is_deleted = FALSE;
    """)
    
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_items_matching_optimization 
        ON items (category, status, geohash6, created_at) 
        WHERE is_deleted = FALSE AND status IN ('lost', 'found');
    """)
    
    # User indexes
    op.execute("CREATE INDEX IF NOT EXISTS idx_users_email_active ON users (email, is_active) WHERE is_deleted = FALSE;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_users_created_at ON users (created_at DESC);")
    
    # Match indexes
    op.execute("CREATE INDEX IF NOT EXISTS idx_matches_score_final ON matches (score_final DESC) WHERE is_deleted = FALSE;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_matches_lost_item_status ON matches (lost_item_id, status) WHERE is_deleted = FALSE;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_matches_found_item_status ON matches (found_item_id, status) WHERE is_deleted = FALSE;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_matches_created_at ON matches (created_at DESC);")
    
    # Claim indexes
    op.execute("CREATE INDEX IF NOT EXISTS idx_claims_match_id ON claims (match_id) WHERE is_deleted = FALSE;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_claims_claimant_status ON claims (claimant_id, status) WHERE is_deleted = FALSE;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_claims_owner_status ON claims (owner_id, status) WHERE is_deleted = FALSE;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_claims_status_created ON claims (status, created_at DESC) WHERE is_deleted = FALSE;")
    
    # Media asset indexes
    op.execute("CREATE INDEX IF NOT EXISTS idx_media_assets_item_id ON media_assets (item_id) WHERE is_deleted = FALSE;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_media_assets_phash ON media_assets (phash) WHERE phash IS NOT NULL AND is_deleted = FALSE;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_media_assets_mime_type ON media_assets (mime_type) WHERE is_deleted = FALSE;")
    
    # Chat message indexes
    op.execute("CREATE INDEX IF NOT EXISTS idx_chat_messages_match_id ON chat_messages (match_id, created_at DESC);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages (sender_id, created_at DESC) WHERE sender_id IS NOT NULL;")
    
    # Notification indexes
    op.execute("CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications (user_id, is_read, created_at DESC);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_notifications_type_created ON notifications (type, created_at DESC);")
    
    # Flag indexes
    op.execute("CREATE INDEX IF NOT EXISTS idx_flags_item_status ON flags (item_id, status);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_flags_reporter_created ON flags (reporter_id, created_at DESC) WHERE reporter_id IS NOT NULL;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_flags_status_created ON flags (status, created_at DESC);")
    
    # Moderation log indexes
    op.execute("CREATE INDEX IF NOT EXISTS idx_moderation_logs_item_id ON moderation_logs (item_id, created_at DESC) WHERE item_id IS NOT NULL;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_moderation_logs_moderator_action ON moderation_logs (moderator_id, action, created_at DESC) WHERE moderator_id IS NOT NULL;")
    
    # Audit log indexes
    op.execute("CREATE INDEX IF NOT EXISTS idx_audit_logs_user_action_created ON audit_logs (user_id, action, created_at DESC) WHERE user_id IS NOT NULL;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_audit_logs_resource_created ON audit_logs (resource_type, resource_id, created_at DESC) WHERE resource_id IS NOT NULL;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_audit_logs_ip_address ON audit_logs (ip_address, created_at DESC) WHERE ip_address IS NOT NULL;")
    
    # Replace volatile time-window partial indexes (that used NOW()) with a stable composite index
    # NOTE: Queries like: status='lost' AND created_at > now()-interval '30 days'
    # can leverage this (status, created_at DESC) index plus a separate location_point GIST index.
    op.execute("CREATE INDEX IF NOT EXISTS idx_items_status_created_at ON items (status, created_at DESC) WHERE is_deleted = FALSE;")
    
    # Expression indexes for computed values
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_items_title_lower 
        ON items (LOWER(title)) WHERE is_deleted = FALSE;
    """)
    
    # Statistics and maintenance
    op.execute("ANALYZE items;")
    op.execute("ANALYZE users;")
    op.execute("ANALYZE matches;")
    op.execute("ANALYZE claims;")
    op.execute("ANALYZE media_assets;")

def downgrade():
    """Remove performance optimization indexes and extensions"""
    
    # Drop triggers and functions
    op.execute("DROP TRIGGER IF EXISTS items_search_vector_trigger ON items;")
    op.execute("DROP FUNCTION IF EXISTS update_items_search_vector();")
    
    # Drop search vector column
    op.drop_column('items', 'search_vector')
    
    # Drop indexes (most recent first to avoid dependency issues)
    indexes_to_drop = [
    'idx_items_title_lower',
    'idx_items_status_created_at',
        'idx_audit_logs_ip_address',
        'idx_audit_logs_resource_created',
        'idx_audit_logs_user_action_created',
        'idx_moderation_logs_moderator_action',
        'idx_moderation_logs_item_id',
        'idx_flags_status_created',
        'idx_flags_reporter_created',
        'idx_flags_item_status',
        'idx_notifications_type_created',
        'idx_notifications_user_unread',
        'idx_chat_messages_sender_id',
        'idx_chat_messages_match_id',
        'idx_media_assets_mime_type',
        'idx_media_assets_phash',
        'idx_media_assets_item_id',
        'idx_claims_status_created',
        'idx_claims_owner_status',
        'idx_claims_claimant_status',
        'idx_claims_match_id',
        'idx_matches_created_at',
        'idx_matches_found_item_status',
        'idx_matches_lost_item_status',
        'idx_matches_score_final',
        'idx_users_created_at',
        'idx_users_email_active',
        'idx_items_matching_optimization',
        'idx_items_user_active',
        'idx_items_active_location_time',
        'idx_items_time_window',
        'idx_items_lost_found_at',
        'idx_items_updated_at_desc',
        'idx_items_created_at_desc',
        'idx_items_color',
        'idx_items_brand_model',
        'idx_items_category_subcategory_status',
        'idx_items_description_trigram',
        'idx_items_title_trigram',
        'idx_items_search_vector',
        'idx_items_geohash6',
        'idx_items_location_gist'
    ]
    
    for index_name in indexes_to_drop:
        op.execute(f"DROP INDEX IF EXISTS {index_name};")
    
    # Note: We don't drop extensions as they might be used by other parts of the system
