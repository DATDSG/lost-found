-- ============================================================================
-- LOST & FOUND APPLICATION - COMPLETE DATABASE SCHEMA
-- PostgreSQL 14+
-- Can be run directly in pgAdmin or via psql
-- ============================================================================
-- Usage:
--   1. In pgAdmin: Open Query Tool → Paste this script → Execute (F5)
--   2. In psql: psql -U postgres -d lostfound -f create_schema.sql
-- ============================================================================

\echo '============================================================================'
\echo 'Lost & Found Database Schema Setup'
\echo '============================================================================'

-- ============================================================================
-- SECTION 1: EXTENSIONS
-- ============================================================================

\echo 'Creating extensions...'

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";          -- UUID generation
CREATE EXTENSION IF NOT EXISTS "postgis";            -- Geospatial support
CREATE EXTENSION IF NOT EXISTS "vector";             -- pgvector for AI embeddings
CREATE EXTENSION IF NOT EXISTS "pg_trgm";            -- Text search (trigram matching)
CREATE EXTENSION IF NOT EXISTS "btree_gin";          -- Multi-column indexes
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements"; -- Query performance monitoring

-- ============================================================================
-- SECTION 2: CUSTOM TYPES
-- ============================================================================

\echo 'Creating custom types...'

-- Drop existing types if they exist
DROP TYPE IF EXISTS reporttype CASCADE;
DROP TYPE IF EXISTS reportstatus CASCADE;
DROP TYPE IF EXISTS matchstatus CASCADE;
DROP TYPE IF EXISTS notificationtype CASCADE;

-- Create enum types
CREATE TYPE reporttype AS ENUM ('lost', 'found');
CREATE TYPE reportstatus AS ENUM ('pending', 'approved', 'hidden', 'removed');
CREATE TYPE matchstatus AS ENUM ('candidate', 'promoted', 'suppressed', 'dismissed');
CREATE TYPE notificationtype AS ENUM ('match_found', 'message_received', 'report_approved', 'report_flagged', 'system');

-- ============================================================================
-- SECTION 3: CORE TABLES
-- ============================================================================

\echo 'Creating tables...'

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    email VARCHAR(255) NOT NULL UNIQUE,
    hashed_password VARCHAR(255) NOT NULL,
    display_name VARCHAR(120),
    phone_number VARCHAR(20),
    avatar_url VARCHAR(500),
    role VARCHAR(32) NOT NULL DEFAULT 'user',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reports table
CREATE TABLE IF NOT EXISTS reports (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    owner_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type reporttype NOT NULL,
    status reportstatus NOT NULL DEFAULT 'pending',
    
    title VARCHAR(300) NOT NULL,
    description TEXT,
    category VARCHAR(64) NOT NULL,
    colors VARCHAR(32)[],
    
    occurred_at TIMESTAMPTZ NOT NULL,
    geo GEOMETRY(Point, 4326),
    location_city VARCHAR(100),
    location_address TEXT,
    
    embedding vector(384),
    image_hash VARCHAR(32),
    
    attributes TEXT,
    reward_offered BOOLEAN DEFAULT false,
    is_resolved BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Media table
CREATE TABLE IF NOT EXISTS media (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    report_id VARCHAR(36) NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    
    filename VARCHAR(400) NOT NULL,
    url VARCHAR(500) NOT NULL,
    media_type VARCHAR(20) DEFAULT 'image',
    mime_type VARCHAR(64),
    size_bytes BIGINT,
    width INTEGER,
    height INTEGER,
    
    phash_hex VARCHAR(32),
    dhash_hex VARCHAR(32),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Matches table
CREATE TABLE IF NOT EXISTS matches (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    source_report_id VARCHAR(36) NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    candidate_report_id VARCHAR(36) NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    
    status matchstatus NOT NULL DEFAULT 'candidate',
    
    score_total FLOAT NOT NULL,
    score_text FLOAT,
    score_image FLOAT,
    score_geo FLOAT,
    score_time FLOAT,
    score_color FLOAT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_match UNIQUE (source_report_id, candidate_report_id),
    CONSTRAINT different_reports CHECK (source_report_id != candidate_report_id)
);

-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    match_id VARCHAR(36) REFERENCES matches(id) ON DELETE SET NULL,
    participant_one_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    participant_two_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT different_participants CHECK (participant_one_id != participant_two_id)
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    conversation_id VARCHAR(36) NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    reference_id VARCHAR(36),
    
    is_read BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Audit logs table
CREATE TABLE IF NOT EXISTS audit_logs (
    id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE SET NULL,
    
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id VARCHAR(36),
    details TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- SECTION 4: TAXONOMY TABLES
-- ============================================================================

\echo 'Creating taxonomy tables...'

CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(50),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS colors (
    id VARCHAR(32) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    hex_code VARCHAR(7),
    rgb_value VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- SECTION 5: INDEXES
-- ============================================================================

\echo 'Creating indexes...'

-- Users
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- Reports
CREATE INDEX IF NOT EXISTS idx_reports_owner_id ON reports(owner_id);
CREATE INDEX IF NOT EXISTS idx_reports_type ON reports(type);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_category ON reports(category);
CREATE INDEX IF NOT EXISTS idx_reports_city ON reports(location_city);
CREATE INDEX IF NOT EXISTS idx_reports_is_resolved ON reports(is_resolved);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_occurred_at ON reports(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_image_hash ON reports(image_hash) WHERE image_hash IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_reports_geo ON reports USING GIST(geo) WHERE geo IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_reports_embedding ON reports USING hnsw (embedding vector_cosine_ops) WHERE embedding IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_reports_text_search ON reports USING gin(to_tsvector('english', title || ' ' || COALESCE(description, '')));

-- Media
CREATE INDEX IF NOT EXISTS idx_media_report_id ON media(report_id);
CREATE INDEX IF NOT EXISTS idx_media_phash ON media(phash_hex) WHERE phash_hex IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_media_dhash ON media(dhash_hex) WHERE dhash_hex IS NOT NULL;

-- Matches
CREATE INDEX IF NOT EXISTS idx_matches_source ON matches(source_report_id);
CREATE INDEX IF NOT EXISTS idx_matches_candidate ON matches(candidate_report_id);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_matches_score ON matches(score_total DESC);
CREATE INDEX IF NOT EXISTS idx_matches_created_at ON matches(created_at DESC);

-- Conversations
CREATE INDEX IF NOT EXISTS idx_conversations_match_id ON conversations(match_id);
CREATE INDEX IF NOT EXISTS idx_conversations_p1 ON conversations(participant_one_id);
CREATE INDEX IF NOT EXISTS idx_conversations_p2 ON conversations(participant_two_id);

-- Messages
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- Notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- Audit logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- ============================================================================
-- SECTION 6: SEED DATA
-- ============================================================================

\echo 'Inserting seed data...'

INSERT INTO categories (id, name, icon, description, sort_order) VALUES
    ('electronics', 'Electronics', '📱', 'Phones, tablets, laptops, cameras, etc.', 1),
    ('accessories', 'Accessories', '👜', 'Bags, wallets, jewelry, watches, etc.', 2),
    ('documents', 'Documents', '📄', 'IDs, passports, cards, papers, etc.', 3),
    ('clothing', 'Clothing', '👕', 'Shirts, pants, jackets, shoes, etc.', 4),
    ('keys', 'Keys', '🔑', 'House keys, car keys, keychains, etc.', 5),
    ('pets', 'Pets', '🐕', 'Dogs, cats, birds, etc.', 6),
    ('vehicles', 'Vehicles', '🚗', 'Cars, bikes, scooters, etc.', 7),
    ('sports', 'Sports Equipment', '⚽', 'Balls, rackets, gear, etc.', 8),
    ('books', 'Books & Media', '📚', 'Books, DVDs, games, etc.', 9),
    ('other', 'Other', '📦', 'Miscellaneous items', 10)
ON CONFLICT (id) DO NOTHING;

INSERT INTO colors (id, name, hex_code, rgb_value, sort_order) VALUES
    ('black', 'Black', '#000000', '0,0,0', 1),
    ('white', 'White', '#FFFFFF', '255,255,255', 2),
    ('gray', 'Gray', '#808080', '128,128,128', 3),
    ('red', 'Red', '#FF0000', '255,0,0', 4),
    ('blue', 'Blue', '#0000FF', '0,0,255', 5),
    ('green', 'Green', '#00FF00', '0,255,0', 6),
    ('yellow', 'Yellow', '#FFFF00', '255,255,0', 7),
    ('orange', 'Orange', '#FFA500', '255,165,0', 8),
    ('purple', 'Purple', '#800080', '128,0,128', 9),
    ('pink', 'Pink', '#FFC0CB', '255,192,203', 10),
    ('brown', 'Brown', '#A52A2A', '165,42,42', 11),
    ('silver', 'Silver', '#C0C0C0', '192,192,192', 12),
    ('gold', 'Gold', '#FFD700', '255,215,0', 13)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- SECTION 7: TRIGGERS
-- ============================================================================

\echo 'Creating triggers...'

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_reports_updated_at ON reports;
CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_matches_updated_at ON matches;
CREATE TRIGGER update_matches_updated_at BEFORE UPDATE ON matches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_conversations_updated_at ON conversations;
CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VERIFICATION
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'Schema Setup Complete!'
\echo '============================================================================'
\echo ''

-- Display summary
SELECT 
    'Tables Created' AS summary_type,
    COUNT(*)::text AS count
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'

UNION ALL

SELECT 
    'Indexes Created' AS summary_type,
    COUNT(*)::text AS count
FROM pg_indexes 
WHERE schemaname = 'public'

UNION ALL

SELECT 
    'Extensions Enabled' AS summary_type,
    COUNT(*)::text AS count
FROM pg_extension 
WHERE extname IN ('uuid-ossp', 'postgis', 'vector', 'pg_trgm', 'btree_gin', 'pg_stat_statements');

\echo ''
\echo 'All tables:'
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

\echo ''
\echo '✅ Database schema is ready!'
\echo ''
