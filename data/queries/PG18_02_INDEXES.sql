-- ============================================================================
-- POSTGRESQL 18 INDEXES SCRIPT
-- Lost & Found Application - Performance Optimization
-- Compatible with: PostgreSQL 18, pgAdmin 4 (Windows)
-- ============================================================================
-- Run this AFTER creating tables via Alembic migrations
-- Right-click on database in pgAdmin → Query Tool → Paste and Execute (F5)
-- ============================================================================

\c lostfound

-- ============================================================================
-- SECTION 1: USERS TABLE INDEXES
-- ============================================================================

-- Primary indexes for user lookup
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- Composite index for active users by role
CREATE INDEX IF NOT EXISTS idx_users_active_role ON users(is_active, role) 
WHERE is_active = true;

-- ============================================================================
-- SECTION 2: REPORTS TABLE INDEXES
-- ============================================================================

-- Basic lookup indexes
CREATE INDEX IF NOT EXISTS idx_reports_owner_id ON reports(owner_id);
CREATE INDEX IF NOT EXISTS idx_reports_type ON reports(type);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_category ON reports(category);
CREATE INDEX IF NOT EXISTS idx_reports_is_resolved ON reports(is_resolved);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_occurred_at ON reports(occurred_at DESC);

-- Location indexes
CREATE INDEX IF NOT EXISTS idx_reports_location_city ON reports(location_city);

-- Geospatial index (PostGIS) - PostgreSQL 18 optimized
CREATE INDEX IF NOT EXISTS idx_reports_geo_gist ON reports USING GIST(geo);

-- For distance queries - using geography cast
CREATE INDEX IF NOT EXISTS idx_reports_geo_geography ON reports 
USING GIST((geo::geography));

-- Vector similarity index (pgvector) - IVFFlat for PostgreSQL 18
-- Note: Build this AFTER inserting data (requires at least 1000 rows for optimal performance)
-- Adjust lists parameter based on dataset size: lists = sqrt(total_rows)
CREATE INDEX IF NOT EXISTS idx_reports_embedding_ivfflat ON reports 
USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 100);

-- Alternative: HNSW index (faster queries, slower build) - PostgreSQL 18 feature
-- Uncomment if you have pgvector 0.5.0+ with HNSW support
-- CREATE INDEX IF NOT EXISTS idx_reports_embedding_hnsw ON reports 
-- USING hnsw (embedding vector_cosine_ops) 
-- WITH (m = 16, ef_construction = 64);

-- Image hash index for perceptual similarity
CREATE INDEX IF NOT EXISTS idx_reports_image_hash ON reports(image_hash) 
WHERE image_hash IS NOT NULL;

-- Full-text search index for title and description
CREATE INDEX IF NOT EXISTS idx_reports_title_trgm ON reports 
USING GIN (title gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_reports_description_trgm ON reports 
USING GIN (description gin_trgm_ops);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_reports_status_type ON reports(status, type);
CREATE INDEX IF NOT EXISTS idx_reports_status_created ON reports(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_type_occurred ON reports(type, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_category_status ON reports(category, status);

-- Partial index for active reports
CREATE INDEX IF NOT EXISTS idx_reports_active ON reports(created_at DESC) 
WHERE status = 'approved' AND is_resolved = false;

-- Partial index for pending moderation
CREATE INDEX IF NOT EXISTS idx_reports_pending ON reports(created_at DESC) 
WHERE status = 'pending';

-- ============================================================================
-- SECTION 3: MATCHES TABLE INDEXES
-- ============================================================================

-- Basic lookup indexes
CREATE INDEX IF NOT EXISTS idx_matches_source_report_id ON matches(source_report_id);
CREATE INDEX IF NOT EXISTS idx_matches_candidate_report_id ON matches(candidate_report_id);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_matches_score_total ON matches(score_total DESC);
CREATE INDEX IF NOT EXISTS idx_matches_created_at ON matches(created_at DESC);

-- Composite indexes for match queries
CREATE INDEX IF NOT EXISTS idx_matches_source_status ON matches(source_report_id, status);
CREATE INDEX IF NOT EXISTS idx_matches_source_score ON matches(source_report_id, score_total DESC);
CREATE INDEX IF NOT EXISTS idx_matches_status_score ON matches(status, score_total DESC);

-- Partial index for high-quality matches
CREATE INDEX IF NOT EXISTS idx_matches_promoted ON matches(created_at DESC) 
WHERE status = 'promoted';

-- Partial index for candidate matches
CREATE INDEX IF NOT EXISTS idx_matches_candidates ON matches(score_total DESC) 
WHERE status = 'candidate';

-- ============================================================================
-- SECTION 4: MEDIA TABLE INDEXES
-- ============================================================================

-- Basic lookup indexes
CREATE INDEX IF NOT EXISTS idx_media_report_id ON media(report_id);
CREATE INDEX IF NOT EXISTS idx_media_media_type ON media(media_type);
CREATE INDEX IF NOT EXISTS idx_media_created_at ON media(created_at DESC);

-- Perceptual hash indexes for image similarity
CREATE INDEX IF NOT EXISTS idx_media_phash_hex ON media(phash_hex) 
WHERE phash_hex IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_media_dhash_hex ON media(dhash_hex) 
WHERE dhash_hex IS NOT NULL;

-- ============================================================================
-- SECTION 5: CONVERSATIONS & MESSAGES INDEXES
-- ============================================================================

-- Conversations indexes
CREATE INDEX IF NOT EXISTS idx_conversations_match_id ON conversations(match_id);
CREATE INDEX IF NOT EXISTS idx_conversations_participant_one ON conversations(participant_one_id);
CREATE INDEX IF NOT EXISTS idx_conversations_participant_two ON conversations(participant_two_id);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC);

-- Messages indexes
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON messages(is_read);

-- Composite index for unread messages
CREATE INDEX IF NOT EXISTS idx_messages_conversation_unread ON messages(conversation_id, is_read) 
WHERE is_read = false;

-- ============================================================================
-- SECTION 6: NOTIFICATIONS TABLE INDEXES
-- ============================================================================

-- Basic lookup indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- Composite index for unread notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, created_at DESC) 
WHERE is_read = false;

-- ============================================================================
-- SECTION 7: TAXONOMY TABLES INDEXES (if they exist)
-- ============================================================================

-- Categories table
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'categories') THEN
        CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name);
        CREATE INDEX IF NOT EXISTS idx_categories_is_active ON categories(is_active) WHERE is_active = true;
    END IF;
END $$;

-- Colors table
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'colors') THEN
        CREATE INDEX IF NOT EXISTS idx_colors_name ON colors(name);
        CREATE INDEX IF NOT EXISTS idx_colors_hex_code ON colors(hex_code);
    END IF;
END $$;

-- ============================================================================
-- SECTION 8: AUDIT LOG INDEXES (if table exists)
-- ============================================================================

DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs') THEN
        CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
        CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
        CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_type ON audit_logs(entity_type);
        CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
        CREATE INDEX IF NOT EXISTS idx_audit_logs_user_action ON audit_logs(user_id, action);
    END IF;
END $$;

-- ============================================================================
-- SECTION 9: ANALYZE TABLES FOR QUERY PLANNER
-- ============================================================================

-- Update table statistics for optimal query planning
ANALYZE users;
ANALYZE reports;
ANALYZE matches;
ANALYZE media;
ANALYZE conversations;
ANALYZE messages;
ANALYZE notifications;

-- Analyze taxonomy tables if they exist
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'categories') THEN
        EXECUTE 'ANALYZE categories';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'colors') THEN
        EXECUTE 'ANALYZE colors';
    END IF;
END $$;

-- ============================================================================
-- SECTION 10: INDEX VERIFICATION
-- ============================================================================

-- List all indexes with sizes
SELECT
    schemaname AS schema,
    tablename AS table_name,
    indexname AS index_name,
    pg_size_pretty(pg_relation_size(indexrelid::regclass)) AS index_size,
    idx_scan AS times_used,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid::regclass) DESC;

-- Check for unused indexes (potential candidates for removal)
SELECT
    schemaname AS schema,
    tablename AS table_name,
    indexname AS index_name,
    pg_size_pretty(pg_relation_size(indexrelid::regclass)) AS index_size,
    idx_scan AS times_used
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
AND idx_scan = 0
AND indexrelid::regclass::text NOT LIKE '%_pkey'
ORDER BY pg_relation_size(indexrelid::regclass) DESC;

-- Show table sizes with index sizes
SELECT
    schemaname AS schema,
    tablename AS table_name,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS indexes_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- ============================================================================
-- INDEXES CREATION COMPLETE
-- ============================================================================

-- Next Steps:
-- 1. Monitor index usage with:
--    SELECT * FROM pg_stat_user_indexes WHERE schemaname = 'public';
--
-- 2. Check for missing indexes with:
--    SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;
--
-- 3. Rebuild indexes if needed:
--    REINDEX TABLE table_name;
--
-- 4. Update statistics regularly:
--    ANALYZE;

COMMIT;
