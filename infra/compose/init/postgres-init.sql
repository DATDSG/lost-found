-- ============================================================================
-- Lost & Found Platform - PostgreSQL Initialization Script
-- Docker Compose PostgreSQL Container Setup
-- Optimized for PostgreSQL 16 with pgvector extension
-- ============================================================================
-- Connect to the database (runs automatically in docker-entrypoint-initdb.d)
-- ============================================================================
-- SECTION 1: EXTENSIONS (PostgreSQL 16 Compatible)
-- ============================================================================
-- Enable UUID generation (built-in in PostgreSQL 13+)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- Install pgvector for semantic search (AI embeddings)
-- Required for vector similarity search
-- Note: pgvector needs to be installed manually in PostGIS image
-- For now, we'll use TEXT to store embeddings as JSON
-- CREATE EXTENSION IF NOT EXISTS vector;
-- Enable PostGIS for geospatial queries
-- Required for location-based matching
CREATE EXTENSION IF NOT EXISTS postgis;
-- Enable pg_trgm for fuzzy text search
-- Improves text search performance
CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- Enable btree_gin for multi-column indexes
-- Improves query performance for complex filters
CREATE EXTENSION IF NOT EXISTS btree_gin;
-- Enable pg_stat_statements for query performance monitoring
-- Helps identify slow queries in production
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
-- ============================================================================
-- SECTION 2: CUSTOM TYPES (Enums for Data Integrity)
-- ============================================================================
-- Report type enum
DO $$ BEGIN IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'reporttype'
) THEN CREATE TYPE reporttype AS ENUM ('lost', 'found');
END IF;
END $$;
-- Report status enum
DO $$ BEGIN IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'reportstatus'
) THEN CREATE TYPE reportstatus AS ENUM ('pending', 'approved', 'hidden', 'removed');
END IF;
END $$;
-- Match status enum
DO $$ BEGIN IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'matchstatus'
) THEN CREATE TYPE matchstatus AS ENUM (
    'candidate',
    'promoted',
    'suppressed',
    'dismissed'
);
END IF;
END $$;
-- Message type enum
DO $$ BEGIN IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'messagetype'
) THEN CREATE TYPE messagetype AS ENUM ('text', 'image', 'location', 'system');
END IF;
END $$;
-- User role enum
DO $$ BEGIN IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'userrole'
) THEN CREATE TYPE userrole AS ENUM ('user', 'moderator', 'admin');
END IF;
END $$;
-- User status enum
DO $$ BEGIN IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'userstatus'
) THEN CREATE TYPE userstatus AS ENUM ('active', 'inactive', 'suspended', 'banned');
END IF;
END $$;
-- Fraud risk level enum
DO $$ BEGIN IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'fraudrisklevel'
) THEN CREATE TYPE fraudrisklevel AS ENUM ('low', 'medium', 'high', 'critical');
END IF;
END $$;
-- ============================================================================
-- SECTION 3: DATABASE CONFIGURATION
-- ============================================================================
-- Set optimal PostgreSQL configuration for the application
-- These settings improve performance for the Lost & Found workload
-- Connection settings
ALTER SYSTEM
SET max_connections = 200;
ALTER SYSTEM
SET shared_buffers = '256MB';
ALTER SYSTEM
SET effective_cache_size = '1GB';
-- Memory settings
ALTER SYSTEM
SET work_mem = '4MB';
ALTER SYSTEM
SET maintenance_work_mem = '64MB';
-- Checkpoint settings
ALTER SYSTEM
SET checkpoint_completion_target = 0.9;
ALTER SYSTEM
SET wal_buffers = '16MB';
-- Query planning
ALTER SYSTEM
SET random_page_cost = 1.1;
ALTER SYSTEM
SET effective_io_concurrency = 200;
-- Logging settings (for development)
ALTER SYSTEM
SET log_statement = 'none';
ALTER SYSTEM
SET log_min_duration_statement = 1000;
ALTER SYSTEM
SET log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h ';
-- Reload configuration
SELECT pg_reload_conf();
-- ============================================================================
-- SECTION 4: PERMISSIONS AND SECURITY
-- ============================================================================
-- Grant all privileges to the postgres user (already has superuser privileges)
-- Additional grants for completeness and future-proofing
GRANT ALL PRIVILEGES ON SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO postgres;
-- Grant usage on all custom types
GRANT USAGE ON TYPE reporttype TO postgres;
GRANT USAGE ON TYPE reportstatus TO postgres;
GRANT USAGE ON TYPE matchstatus TO postgres;
GRANT USAGE ON TYPE messagetype TO postgres;
GRANT USAGE ON TYPE userrole TO postgres;
GRANT USAGE ON TYPE userstatus TO postgres;
GRANT USAGE ON TYPE fraudrisklevel TO postgres;
-- ============================================================================
-- SECTION 5: PERFORMANCE OPTIMIZATIONS
-- ============================================================================
-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column() RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ language 'plpgsql';
-- ============================================================================
-- SECTION 6: VERIFICATION AND LOGGING
-- ============================================================================
-- Verify extensions are installed
SELECT extname AS extension_name,
    extversion AS version,
    nspname AS schema
FROM pg_extension e
    LEFT JOIN pg_namespace n ON n.oid = e.extnamespace
WHERE extname IN (
        'uuid-ossp',
        'postgis',
        'pg_trgm',
        'btree_gin',
        'pg_stat_statements'
    )
ORDER BY extname;
-- Verify custom types are created
SELECT typname AS type_name,
    CASE
        WHEN typtype = 'e' THEN 'enum'
        WHEN typtype = 'c' THEN 'composite'
        WHEN typtype = 'd' THEN 'domain'
        ELSE 'other'
    END AS type_kind
FROM pg_type
WHERE typname IN (
        'reporttype',
        'reportstatus',
        'matchstatus',
        'messagetype',
        'userrole',
        'userstatus',
        'fraudrisklevel'
    )
ORDER BY typname;
-- Log successful completion
DO $$ BEGIN RAISE NOTICE 'PostgreSQL initialization completed successfully for Lost & Found platform';
RAISE NOTICE 'Extensions installed: uuid-ossp, postgis, pg_trgm, btree_gin, pg_stat_statements';
RAISE NOTICE 'Custom types created: reporttype, reportstatus, matchstatus, messagetype, userrole, userstatus, fraudrisklevel';
RAISE NOTICE 'Database optimized for Lost & Found workload';
END $$;