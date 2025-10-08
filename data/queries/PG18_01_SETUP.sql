-- ============================================================================
-- POSTGRESQL 18 SETUP SCRIPT
-- Lost & Found Application - Database Initialization
-- Compatible with: PostgreSQL 18, pgAdmin 4 (Windows)
-- ============================================================================
-- Run this script as postgres superuser or database owner
-- Right-click on database in pgAdmin → Query Tool → Paste and Execute (F5)
-- ============================================================================

-- ============================================================================
-- SECTION 1: DATABASE CREATION (Run as postgres superuser)
-- ============================================================================

-- Create database (if not exists)
-- Note: Uncomment if you need to create the database
-- CREATE DATABASE lostfound
--     WITH 
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'en_US.UTF-8'
--     LC_CTYPE = 'en_US.UTF-8'
--     TABLESPACE = pg_default
--     CONNECTION LIMIT = -1
--     IS_TEMPLATE = False;

-- Create application user (if needed)
-- Note: Uncomment and set a secure password
-- CREATE USER lostfound WITH PASSWORD 'your_secure_password_here';
-- GRANT ALL PRIVILEGES ON DATABASE lostfound TO lostfound;

-- Connect to the database
\c lostfound

-- ============================================================================
-- SECTION 2: EXTENSIONS (PostgreSQL 18 Compatible)
-- ============================================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgvector for semantic search (AI embeddings)
-- Requires: pgvector extension installed
-- Download from: https://github.com/pgvector/pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable PostGIS for geospatial queries
-- Requires: PostGIS extension installed
-- Download from: https://postgis.net/install/
CREATE EXTENSION IF NOT EXISTS postgis;

-- Enable pg_trgm for fuzzy text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Enable btree_gin for multi-column indexes
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- Enable pg_stat_statements for query performance monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Verify extensions are installed
SELECT 
    extname AS extension_name,
    extversion AS version,
    nspname AS schema
FROM pg_extension e
LEFT JOIN pg_namespace n ON n.oid = e.extnamespace
WHERE extname IN ('uuid-ossp', 'vector', 'postgis', 'pg_trgm', 'btree_gin', 'pg_stat_statements')
ORDER BY extname;

-- ============================================================================
-- SECTION 3: CUSTOM TYPES (Enums)
-- ============================================================================

-- Report type enum
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'reporttype') THEN
        CREATE TYPE reporttype AS ENUM ('lost', 'found');
    END IF;
END $$;

-- Report status enum
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'reportstatus') THEN
        CREATE TYPE reportstatus AS ENUM ('pending', 'approved', 'hidden', 'removed');
    END IF;
END $$;

-- Match status enum
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'matchstatus') THEN
        CREATE TYPE matchstatus AS ENUM ('candidate', 'promoted', 'suppressed', 'dismissed');
    END IF;
END $$;

-- Notification type enum
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notificationtype') THEN
        CREATE TYPE notificationtype AS ENUM (
            'match_found', 
            'message_received', 
            'report_approved', 
            'report_rejected',
            'system_announcement'
        );
    END IF;
END $$;

-- Verify custom types
SELECT 
    typname AS type_name,
    enumlabel AS enum_value
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
WHERE typname IN ('reporttype', 'reportstatus', 'matchstatus', 'notificationtype')
ORDER BY typname, enumlabel;

-- ============================================================================
-- SECTION 4: PERFORMANCE CONFIGURATION
-- ============================================================================

-- Set work_mem for complex queries (session level)
SET work_mem = '256MB';

-- Set maintenance_work_mem for index creation
SET maintenance_work_mem = '512MB';

-- Enable parallel query execution
SET max_parallel_workers_per_gather = 4;

-- Set effective_cache_size (adjust based on your RAM)
-- This is 4GB - adjust for your system
SET effective_cache_size = '4GB';

-- Set random_page_cost for SSD
SET random_page_cost = 1.1;

-- Show current settings
SELECT 
    name,
    setting,
    unit,
    context
FROM pg_settings
WHERE name IN (
    'work_mem',
    'maintenance_work_mem',
    'max_parallel_workers_per_gather',
    'effective_cache_size',
    'random_page_cost',
    'shared_buffers'
)
ORDER BY name;

-- ============================================================================
-- SECTION 5: GRANT PERMISSIONS
-- ============================================================================

-- Grant schema permissions
GRANT USAGE ON SCHEMA public TO lostfound;
GRANT CREATE ON SCHEMA public TO lostfound;

-- Grant permissions on all tables (run after tables are created)
-- Note: Uncomment after running migrations
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO lostfound;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO lostfound;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO lostfound;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO lostfound;

-- ============================================================================
-- SECTION 6: VERIFICATION QUERIES
-- ============================================================================

-- Check PostgreSQL version
SELECT version();

-- Check if we're on PostgreSQL 18
SELECT 
    current_setting('server_version') AS version,
    current_setting('server_version_num')::int >= 180000 AS is_pg18_or_higher;

-- List all databases
SELECT 
    datname AS database_name,
    pg_size_pretty(pg_database_size(datname)) AS size,
    datcollate AS collation
FROM pg_database
WHERE datistemplate = false
ORDER BY pg_database_size(datname) DESC;

-- List all schemas
SELECT 
    schema_name,
    schema_owner
FROM information_schema.schemata
WHERE schema_name NOT IN ('pg_catalog', 'information_schema')
ORDER BY schema_name;

-- Check extension versions and availability
SELECT 
    e.extname,
    e.extversion,
    n.nspname AS schema,
    d.description
FROM pg_extension e
LEFT JOIN pg_namespace n ON e.extnamespace = n.oid
LEFT JOIN pg_description d ON d.objoid = e.oid
ORDER BY e.extname;

-- Verify vector extension capabilities
SELECT 
    proname AS function_name,
    prokind AS kind
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
AND proname LIKE '%vector%'
LIMIT 10;

-- Verify PostGIS capabilities
SELECT postgis_full_version();

-- ============================================================================
-- SECTION 7: MONITORING SETUP
-- ============================================================================

-- Enable query logging (optional - for development)
-- Note: Uncomment for debugging slow queries
-- ALTER SYSTEM SET log_statement = 'all';
-- ALTER SYSTEM SET log_duration = on;
-- ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries > 1 second

-- Create statistics monitoring view
CREATE OR REPLACE VIEW v_database_stats AS
SELECT 
    current_database() AS database_name,
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT COUNT(*) FROM pg_stat_activity WHERE datname = current_database()) AS active_connections,
    (SELECT COUNT(*) FROM pg_stat_activity WHERE datname = current_database() AND state = 'active') AS active_queries,
    now() AS stats_timestamp;

-- View database statistics
SELECT * FROM v_database_stats;

-- ============================================================================
-- SETUP COMPLETE
-- ============================================================================

-- Next Steps:
-- 1. Run Alembic migrations to create tables:
--    Open Command Prompt in services/api directory and run:
--    alembic upgrade head
--
-- 2. Verify tables were created:
--    SELECT table_name FROM information_schema.tables 
--    WHERE table_schema = 'public' ORDER BY table_name;
--
-- 3. Run PG18_02_INDEXES.sql to create optimized indexes
--
-- 4. Run PG18_03_SEED_DATA.sql to populate initial data
--
-- 5. Use PG18_04_QUERIES.sql for common operations

COMMIT;
