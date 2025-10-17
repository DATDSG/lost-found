"""Complete Lost & Found Platform Schema v2.0

Revision ID: 001_complete_schema_v2
Revises: 
Create Date: 2025-10-15

This migration creates the complete database schema for the Lost & Found platform
with MinIO integration, improved performance, and production-ready features.
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
import geoalchemy2
from pgvector.sqlalchemy import Vector

# revision identifiers, used by Alembic.
revision = '001_complete_schema_v2'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create complete database schema for Lost & Found platform v2.0."""
    
    # ========================================
    # STEP 1: Enable PostgreSQL Extensions
    # ========================================
    print("🔧 Enabling PostgreSQL extensions...")
    
    # Enable pgvector for vector similarity search (required for AI embeddings)
    conn = op.get_bind()
    try:
        conn.execute(sa.text("SAVEPOINT before_vector"))
        conn.execute(sa.text("CREATE EXTENSION IF NOT EXISTS vector"))
        conn.execute(sa.text("RELEASE SAVEPOINT before_vector"))
        print("✅ pgvector enabled")
    except Exception as e:
        conn.execute(sa.text("ROLLBACK TO SAVEPOINT before_vector"))
        print(f"⚠️  pgvector already exists or not available: {e}")
    
    # Enable PostGIS for geographic queries (optional)
    try:
        conn.execute(sa.text("SAVEPOINT before_postgis"))
        conn.execute(sa.text("CREATE EXTENSION IF NOT EXISTS postgis"))
        conn.execute(sa.text("RELEASE SAVEPOINT before_postgis"))
        print("✅ PostGIS enabled")
    except Exception as e:
        conn.execute(sa.text("ROLLBACK TO SAVEPOINT before_postgis"))
        print(f"⚠️  PostGIS not available: {e}")
        print("📍 Geographic features will use TEXT columns instead")
    
    # Enable additional useful extensions
    try:
        conn.execute(sa.text("CREATE EXTENSION IF NOT EXISTS pg_trgm"))
        print("✅ pg_trgm enabled (fuzzy text search)")
    except Exception as e:
        print(f"⚠️  pg_trgm not available: {e}")
    
    try:
        conn.execute(sa.text("CREATE EXTENSION IF NOT EXISTS btree_gin"))
        print("✅ btree_gin enabled (multi-column indexes)")
    except Exception as e:
        print(f"⚠️  btree_gin not available: {e}")
    
    # ========================================
    # STEP 2: Create Core Tables
    # ========================================
    
    # --- Users Table ---
    print("👥 Creating users table...")
    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('email', sa.String(255), nullable=False, unique=True),
        sa.Column('password', sa.String(255), nullable=False),
        sa.Column('display_name', sa.String(120)),
        sa.Column('phone_number', sa.String(20)),
        sa.Column('avatar_url', sa.String(500)),
        sa.Column('role', sa.String(32), nullable=False, server_default='user'),
        sa.Column('status', sa.String(32), nullable=False, server_default='active'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('email_verified', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('last_login_at', sa.DateTime(timezone=True)),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
    )
    op.create_index('ix_users_email', 'users', ['email'])
    op.create_index('ix_users_role', 'users', ['role'])
    op.create_index('ix_users_status', 'users', ['status'])
    op.create_index('ix_users_created_at', 'users', ['created_at'])
    
    # --- Reports Table ---
    print("📋 Creating reports table...")
    op.create_table(
        'reports',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('owner_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('type', sa.String(16), nullable=False),  # 'lost' or 'found'
        sa.Column('status', sa.String(16), nullable=False, server_default='pending'),  # 'pending', 'approved', 'hidden', 'removed'
        sa.Column('title', sa.String(300), nullable=False),
        sa.Column('description', sa.Text()),
        sa.Column('category', sa.String(64), nullable=False),
        sa.Column('colors', postgresql.ARRAY(sa.String()), server_default='{}'),
        sa.Column('occurred_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('geo', sa.Text()),  # TEXT for compatibility (or Geometry(Point, 4326) if PostGIS available)
        sa.Column('location_city', sa.String(100)),
        sa.Column('location_address', sa.Text()),
        sa.Column('location_lat', sa.Float()),
        sa.Column('location_lng', sa.Float()),
        sa.Column('embedding', Vector(384)),  # pgvector for semantic search (E5-small model)
        sa.Column('image_hash', sa.String(32)),  # Perceptual hash from Vision service
        sa.Column('attributes', sa.Text()),  # JSON string for category-specific attributes
        sa.Column('reward_offered', sa.Boolean(), default=False),
        sa.Column('reward_amount', sa.Numeric(10, 2)),
        sa.Column('is_resolved', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('resolved_at', sa.DateTime(timezone=True)),
        sa.Column('minio_object_key', sa.String(500)),  # MinIO object key for media storage
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('NOW()')),
    )
    op.create_index('ix_reports_owner_id', 'reports', ['owner_id'])
    op.create_index('ix_reports_type', 'reports', ['type'])
    op.create_index('ix_reports_status', 'reports', ['status'])
    op.create_index('ix_reports_category', 'reports', ['category'])
    op.create_index('ix_reports_location_city', 'reports', ['location_city'])
    op.create_index('ix_reports_image_hash', 'reports', ['image_hash'])
    op.create_index('ix_reports_is_resolved', 'reports', ['is_resolved'])
    op.create_index('ix_reports_created_at', 'reports', ['created_at'])
    op.create_index('ix_reports_occurred_at', 'reports', ['occurred_at'])
    
    # --- Media Table (Enhanced for MinIO) ---
    print("📸 Creating media table...")
    op.create_table(
        'media',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('report_id', sa.String(), sa.ForeignKey('reports.id', ondelete='CASCADE'), nullable=False),
        sa.Column('filename', sa.String(400), nullable=False),
        sa.Column('url', sa.String(500), nullable=False),
        sa.Column('minio_object_key', sa.String(500)),  # MinIO object key
        sa.Column('minio_bucket', sa.String(100), server_default='lost-found-media'),  # MinIO bucket name
        sa.Column('media_type', sa.String(32), server_default='image'),
        sa.Column('mime_type', sa.String(64)),
        sa.Column('size_bytes', sa.Integer()),
        sa.Column('width', sa.Integer()),
        sa.Column('height', sa.Integer()),
        sa.Column('phash_hex', sa.String(64)),  # Perceptual hash
        sa.Column('dhash_hex', sa.String(64)),  # Difference hash
        sa.Column('avg_hash_hex', sa.String(64)),  # Average hash
        sa.Column('whash_hex', sa.String(64)),  # Wavelet hash
        sa.Column('colorhash_hex', sa.String(64)),  # Color hash
        sa.Column('is_primary', sa.Boolean(), server_default='false'),  # Primary image for report
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
    )
    op.create_index('ix_media_report_id', 'media', ['report_id'])
    op.create_index('ix_media_minio_object_key', 'media', ['minio_object_key'])
    op.create_index('ix_media_is_primary', 'media', ['is_primary'])
    op.create_index('ix_media_phash', 'media', ['phash_hex'])
    
    # --- Matches Table (Enhanced) ---
    print("🔗 Creating matches table...")
    op.create_table(
        'matches',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('source_report_id', sa.String(), sa.ForeignKey('reports.id', ondelete='CASCADE'), nullable=False),
        sa.Column('candidate_report_id', sa.String(), sa.ForeignKey('reports.id', ondelete='CASCADE'), nullable=False),
        sa.Column('status', sa.String(24), nullable=False, server_default='candidate'),  # 'candidate', 'promoted', 'suppressed', 'dismissed'
        sa.Column('score_total', sa.Float(), nullable=False),
        sa.Column('score_text', sa.Float()),
        sa.Column('score_image', sa.Float()),
        sa.Column('score_geo', sa.Float()),
        sa.Column('score_time', sa.Float()),
        sa.Column('score_color', sa.Float()),
        sa.Column('confidence', sa.Float()),  # AI confidence score
        sa.Column('reviewed_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL')),
        sa.Column('reviewed_at', sa.DateTime(timezone=True)),
        sa.Column('review_notes', sa.Text()),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
    )
    op.create_index('ix_matches_source_report_id', 'matches', ['source_report_id'])
    op.create_index('ix_matches_candidate_report_id', 'matches', ['candidate_report_id'])
    op.create_index('ix_matches_status', 'matches', ['status'])
    op.create_index('ix_matches_score_total', 'matches', ['score_total'])
    op.create_index('ix_matches_confidence', 'matches', ['confidence'])
    
    # --- Conversations Table ---
    print("💬 Creating conversations table...")
    op.create_table(
        'conversations',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('match_id', sa.String(), sa.ForeignKey('matches.id', ondelete='CASCADE')),
        sa.Column('participant_one_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('participant_two_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('status', sa.String(32), server_default='active'),  # 'active', 'archived', 'blocked'
        sa.Column('last_message_at', sa.DateTime(timezone=True)),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('NOW()')),
    )
    op.create_index('ix_conversations_match_id', 'conversations', ['match_id'])
    op.create_index('ix_conversations_participants', 'conversations', ['participant_one_id', 'participant_two_id'])
    op.create_index('ix_conversations_status', 'conversations', ['status'])
    op.create_index('ix_conversations_last_message_at', 'conversations', ['last_message_at'])
    
    # --- Messages Table (Enhanced) ---
    print("📨 Creating messages table...")
    op.create_table(
        'messages',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('conversation_id', sa.String(), sa.ForeignKey('conversations.id', ondelete='CASCADE'), nullable=False),
        sa.Column('sender_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('message_type', sa.String(32), server_default='text'),  # 'text', 'image', 'location', 'system'
        sa.Column('media_id', sa.String(), sa.ForeignKey('media.id', ondelete='SET NULL')),
        sa.Column('is_read', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('read_at', sa.DateTime(timezone=True)),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
    )
    op.create_index('ix_messages_conversation_id', 'messages', ['conversation_id'])
    op.create_index('ix_messages_sender_id', 'messages', ['sender_id'])
    op.create_index('ix_messages_is_read', 'messages', ['is_read'])
    op.create_index('ix_messages_created_at', 'messages', ['created_at'])
    
    # --- Notifications Table (Enhanced) ---
    print("🔔 Creating notifications table...")
    op.create_table(
        'notifications',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('type', sa.String(64), nullable=False),  # 'match', 'message', 'system', 'admin'
        sa.Column('title', sa.String(200), nullable=False),
        sa.Column('content', sa.Text()),
        sa.Column('reference_id', sa.String()),  # ID of related object (report, match, etc.)
        sa.Column('reference_type', sa.String(64)),  # Type of reference ('report', 'match', 'message')
        sa.Column('is_read', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('read_at', sa.DateTime(timezone=True)),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
    )
    op.create_index('ix_notifications_user_id', 'notifications', ['user_id'])
    op.create_index('ix_notifications_type', 'notifications', ['type'])
    op.create_index('ix_notifications_is_read', 'notifications', ['is_read'])
    op.create_index('ix_notifications_created_at', 'notifications', ['created_at'])
    
    # --- WebSocket Sessions Table ---
    print("🌐 Creating websocket_sessions table...")
    op.create_table(
        'websocket_sessions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('connection_id', sa.String(), nullable=False),
        sa.Column('endpoint', sa.String(), nullable=False),  # 'chat' or 'notifications'
        sa.Column('connected_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('last_ping_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('user_agent', sa.Text(), nullable=True),
        sa.Column('ip_address', sa.String(), nullable=True),
        sa.Column('is_active', sa.Boolean(), server_default='true', nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    )
    op.create_index('idx_websocket_sessions_user_id', 'websocket_sessions', ['user_id'])
    op.create_index('idx_websocket_sessions_is_active', 'websocket_sessions', ['is_active'])
    op.create_index('idx_websocket_sessions_endpoint', 'websocket_sessions', ['endpoint'])
    op.create_index('idx_websocket_sessions_connected_at', 'websocket_sessions', ['connected_at'])
    op.create_index('idx_websocket_sessions_stale', 'websocket_sessions', ['is_active', 'last_ping_at'])
    
    # --- Audit Log Table (Enhanced) ---
    print("📊 Creating audit_log table...")
    op.create_table(
        'audit_log',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('actor_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL')),
        sa.Column('action', sa.String(64), nullable=False),
        sa.Column('resource', sa.String(64)),  # Resource type (e.g., 'report', 'user')
        sa.Column('resource_id', sa.String()),
        sa.Column('reason', sa.Text()),  # Details or reason for action
        sa.Column('ip_address', sa.String(45)),  # IPv6 compatible
        sa.Column('user_agent', sa.Text()),
        sa.Column('metadata', sa.Text()),  # JSON metadata
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
    )
    op.create_index('ix_audit_log_actor_id', 'audit_log', ['actor_id'])
    op.create_index('ix_audit_log_action', 'audit_log', ['action'])
    op.create_index('ix_audit_log_resource', 'audit_log', ['resource'])
    op.create_index('ix_audit_log_created_at', 'audit_log', ['created_at'])
    
    # ========================================
    # STEP 3: Create Taxonomy Tables
    # ========================================
    
    # --- Categories Table ---
    print("📂 Creating categories table...")
    op.create_table(
        'categories',
        sa.Column('id', sa.String(64), primary_key=True),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('description', sa.Text()),
        sa.Column('icon', sa.String(50)),
        sa.Column('sort_order', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
    )
    op.create_index('ix_categories_sort_order', 'categories', ['sort_order'])
    op.create_index('ix_categories_is_active', 'categories', ['is_active'])
    
    # --- Colors Table ---
    print("🎨 Creating colors table...")
    op.create_table(
        'colors',
        sa.Column('id', sa.String(32), primary_key=True),
        sa.Column('name', sa.String(50), nullable=False),
        sa.Column('hex_code', sa.String(7)),
        sa.Column('sort_order', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
    )
    op.create_index('ix_colors_sort_order', 'colors', ['sort_order'])
    op.create_index('ix_colors_is_active', 'colors', ['is_active'])
    
    # ========================================
    # STEP 4: Create Performance Indexes
    # ========================================
    print("⚡ Creating performance indexes...")
    
    # Vector similarity search index (for embedding column)
    try:
        op.execute("""
            CREATE INDEX IF NOT EXISTS ix_reports_embedding_vector 
            ON reports USING ivfflat (embedding vector_cosine_ops)
            WITH (lists = 100)
        """)
        print("✅ Vector similarity index created")
    except Exception as e:
        print(f"⚠️  Vector index creation failed: {e}")
    
    # Composite indexes for common query patterns
    op.create_index('ix_reports_type_status', 'reports', ['type', 'status'])
    op.create_index('ix_reports_type_created_at', 'reports', ['type', 'created_at'])
    op.create_index('ix_reports_category_status', 'reports', ['category', 'status'])
    op.create_index('ix_reports_location_city_type', 'reports', ['location_city', 'type'])
    op.create_index('ix_matches_source_status_score', 'matches', ['source_report_id', 'status', 'score_total'])
    op.create_index('ix_matches_candidate_status_score', 'matches', ['candidate_report_id', 'status', 'score_total'])
    
    # Full-text search indexes
    try:
        op.execute("CREATE INDEX IF NOT EXISTS ix_reports_title_gin ON reports USING gin(to_tsvector('english', title))")
        op.execute("CREATE INDEX IF NOT EXISTS ix_reports_description_gin ON reports USING gin(to_tsvector('english', description))")
        print("✅ Full-text search indexes created")
    except Exception as e:
        print(f"⚠️  Full-text search indexes failed: {e}")
    
    # ========================================
    # STEP 5: Create Triggers for Auto-Update
    # ========================================
    print("🔄 Creating update triggers...")
    
    # Function to update updated_at timestamp
    op.execute("""
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = CURRENT_TIMESTAMP;
            RETURN NEW;
        END;
        $$ language 'plpgsql';
    """)
    
    # Apply triggers to tables with updated_at columns
    op.execute("""
        CREATE TRIGGER update_users_updated_at 
        BEFORE UPDATE ON users 
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    """)
    
    op.execute("""
        CREATE TRIGGER update_reports_updated_at 
        BEFORE UPDATE ON reports 
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    """)
    
    op.execute("""
        CREATE TRIGGER update_conversations_updated_at 
        BEFORE UPDATE ON conversations 
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    """)
    
    print("✅ Update triggers created")
    
    # ========================================
    # STEP 6: Seed Initial Data
    # ========================================
    print("🌱 Seeding initial taxonomy data...")
    
    # Seed categories
    op.execute("""
        INSERT INTO categories (id, name, description, icon, sort_order, is_active) VALUES
        ('electronics', 'Electronics', 'Electronic devices and gadgets', 'smartphone', 1, true),
        ('documents', 'Documents', 'Important papers and documents', 'description', 2, true),
        ('accessories', 'Accessories', 'Personal accessories and items', 'watch', 3, true),
        ('bags', 'Bags & Luggage', 'Bags, backpacks, and luggage', 'work', 4, true),
        ('keys', 'Keys', 'Keys and keychains', 'vpn_key', 5, true),
        ('pets', 'Pets', 'Lost or found pets', 'pets', 6, true),
        ('clothing', 'Clothing', 'Clothes and apparel', 'checkroom', 7, true),
        ('jewelry', 'Jewelry', 'Jewelry and watches', 'diamond', 8, true),
        ('sports', 'Sports Equipment', 'Sports and fitness equipment', 'sports_soccer', 9, true),
        ('vehicles', 'Vehicles', 'Cars, bikes, and other vehicles', 'directions_car', 10, true),
        ('other', 'Other', 'Items that don''t fit other categories', 'category', 99, true)
    """)
    
    # Seed colors
    op.execute("""
        INSERT INTO colors (id, name, hex_code, sort_order, is_active) VALUES
        ('black', 'Black', '#000000', 1, true),
        ('white', 'White', '#FFFFFF', 2, true),
        ('gray', 'Gray', '#808080', 3, true),
        ('silver', 'Silver', '#C0C0C0', 4, true),
        ('red', 'Red', '#FF0000', 5, true),
        ('blue', 'Blue', '#0000FF', 6, true),
        ('green', 'Green', '#008000', 7, true),
        ('yellow', 'Yellow', '#FFFF00', 8, true),
        ('orange', 'Orange', '#FFA500', 9, true),
        ('purple', 'Purple', '#800080', 10, true),
        ('pink', 'Pink', '#FFC0CB', 11, true),
        ('brown', 'Brown', '#A52A2A', 12, true),
        ('gold', 'Gold', '#FFD700', 13, true),
        ('beige', 'Beige', '#F5F5DC', 14, true),
        ('multicolor', 'Multicolor', NULL, 15, true)
    """)
    
    print("✅ Initial data seeded")
    
    # ========================================
    # STEP 7: Create Views for Common Queries
    # ========================================
    print("👁️  Creating useful views...")
    
    # Active reports view
    op.execute("""
        CREATE VIEW active_reports AS
        SELECT r.*, u.display_name as owner_name, u.email as owner_email
        FROM reports r
        JOIN users u ON r.owner_id = u.id
        WHERE r.status = 'approved' AND r.is_resolved = false
        ORDER BY r.created_at DESC;
    """)
    
    # Recent matches view
    op.execute("""
        CREATE VIEW recent_matches AS
        SELECT m.*, 
               sr.title as source_title, sr.type as source_type,
               cr.title as candidate_title, cr.type as candidate_type
        FROM matches m
        JOIN reports sr ON m.source_report_id = sr.id
        JOIN reports cr ON m.candidate_report_id = cr.id
        WHERE m.status = 'candidate'
        ORDER BY m.created_at DESC;
    """)
    
    print("✅ Views created")
    
    print("🎉 Complete schema creation finished!")
    print("📊 Database ready for Lost & Found platform v2.0 with MinIO integration")


def downgrade() -> None:
    """Drop all tables, views, functions, and extensions (use with caution!)."""
    
    print("🗑️  Starting schema downgrade...")
    
    # Drop views first
    op.execute("DROP VIEW IF EXISTS recent_matches")
    op.execute("DROP VIEW IF EXISTS active_reports")
    print("✅ Views dropped")
    
    # Drop triggers
    op.execute("DROP TRIGGER IF EXISTS update_conversations_updated_at ON conversations")
    op.execute("DROP TRIGGER IF EXISTS update_reports_updated_at ON reports")
    op.execute("DROP TRIGGER IF EXISTS update_users_updated_at ON users")
    print("✅ Triggers dropped")
    
    # Drop function
    op.execute("DROP FUNCTION IF EXISTS update_updated_at_column()")
    print("✅ Functions dropped")
    
    # Drop tables in reverse order (respecting foreign key constraints)
    op.drop_table('audit_log')
    op.drop_table('websocket_sessions')
    op.drop_table('notifications')
    op.drop_table('messages')
    op.drop_table('conversations')
    op.drop_table('matches')
    op.drop_table('media')
    op.drop_table('reports')
    op.drop_table('colors')
    op.drop_table('categories')
    op.drop_table('users')
    print("✅ Tables dropped")
    
    # Drop extensions (commented out to preserve for other databases)
    # op.execute("DROP EXTENSION IF EXISTS vector")
    # op.execute("DROP EXTENSION IF EXISTS postgis")
    # op.execute("DROP EXTENSION IF EXISTS pg_trgm")
    # op.execute("DROP EXTENSION IF EXISTS btree_gin")
    
    print("✅ Schema downgrade complete!")
