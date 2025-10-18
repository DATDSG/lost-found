-- ============================================================================
-- POSTGRESQL 18 COMMON QUERIES
-- Lost & Found Application - Ready-to-Execute Queries
-- Compatible with: PostgreSQL 18, pgAdmin 4 (Windows)
-- ============================================================================
-- Copy and paste these queries directly into pgAdmin Query Tool (F5 to run)
-- Replace placeholder values (marked with comments) with your actual data
-- ============================================================================

\c lostfound

-- ============================================================================
-- QUICK REFERENCE - MOST USED QUERIES
-- ============================================================================

-- Get all table names and row counts
SELECT 
    schemaname,
    tablename,
    (xpath('/row/cnt/text()', 
        query_to_xml(format('SELECT COUNT(*) AS cnt FROM %I.%I', schemaname, tablename), 
        false, true, '')))[1]::text::int AS row_count
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Get database size and statistics
SELECT 
    current_database() AS database_name,
    pg_size_pretty(pg_database_size(current_database())) AS size,
    (SELECT COUNT(*) FROM users) AS users,
    (SELECT COUNT(*) FROM reports) AS reports,
    (SELECT COUNT(*) FROM matches) AS matches,
    (SELECT COUNT(*) FROM messages) AS messages;

-- ============================================================================
-- SECTION 1: USER QUERIES
-- ============================================================================

-- 1.1 Get all active users
SELECT 
    id,
    email,
    display_name,
    phone_number,
    role,
    created_at,
    updated_at
FROM users
WHERE is_active = true
ORDER BY created_at DESC;

-- 1.2 Search users by email or name
SELECT 
    id,
    email,
    display_name,
    role,
    is_active,
    created_at
FROM users
WHERE 
    email ILIKE '%example%'  -- Replace 'example' with search term
    OR display_name ILIKE '%John%'  -- Replace 'John' with search term
ORDER BY created_at DESC;

-- 1.3 Get user by ID with full details
-- Replace 'USER_UUID_HERE' with actual user ID
SELECT 
    id,
    email,
    display_name,
    phone_number,
    avatar_url,
    role,
    is_active,
    created_at,
    updated_at,
    (SELECT COUNT(*) FROM reports WHERE owner_id = users.id) AS total_reports,
    (SELECT COUNT(*) FROM reports WHERE owner_id = users.id AND type = 'lost') AS lost_reports,
    (SELECT COUNT(*) FROM reports WHERE owner_id = users.id AND type = 'found') AS found_reports
FROM users
WHERE id = 'USER_UUID_HERE';

-- 1.4 Get user activity statistics
SELECT 
    u.id,
    u.display_name,
    u.email,
    COUNT(DISTINCT r.id) AS total_reports,
    COUNT(DISTINCT r.id) FILTER (WHERE r.type = 'lost') AS lost_count,
    COUNT(DISTINCT r.id) FILTER (WHERE r.type = 'found') AS found_count,
    COUNT(DISTINCT r.id) FILTER (WHERE r.is_resolved = true) AS resolved_count,
    COUNT(DISTINCT m.id) AS messages_sent,
    MAX(r.created_at) AS last_report_date,
    MAX(m.created_at) AS last_message_date
FROM users u
LEFT JOIN reports r ON u.id = r.owner_id
LEFT JOIN messages m ON u.id = m.sender_id
WHERE u.is_active = true
GROUP BY u.id, u.display_name, u.email
ORDER BY total_reports DESC;

-- 1.5 Get users by role
SELECT 
    id,
    email,
    display_name,
    role,
    created_at
FROM users
WHERE role = 'admin'  -- Change to: 'user', 'moderator', 'admin'
ORDER BY created_at DESC;

-- ============================================================================
-- SECTION 2: REPORT QUERIES
-- ============================================================================

-- 2.1 Get all approved reports (public view)
SELECT 
    r.id,
    r.type,
    r.title,
    r.description,
    r.category,
    r.colors,
    r.location_city,
    r.location_address,
    r.occurred_at,
    r.reward_offered,
    r.is_resolved,
    r.created_at,
    u.display_name AS owner_name,
    u.email AS owner_email,
    (SELECT COUNT(*) FROM media WHERE report_id = r.id) AS media_count,
    (SELECT COUNT(*) FROM matches WHERE source_report_id = r.id AND status = 'promoted') AS match_count
FROM reports r
JOIN users u ON r.owner_id = u.id
WHERE r.status = 'approved'
ORDER BY r.created_at DESC
LIMIT 50;

-- 2.2 Search reports by keyword in title or description
SELECT 
    r.id,
    r.type,
    r.title,
    r.description,
    r.category,
    r.location_city,
    r.status,
    r.created_at,
    u.display_name AS owner_name
FROM reports r
JOIN users u ON r.owner_id = u.id
WHERE 
    r.status = 'approved'
    AND (
        r.title ILIKE '%iPhone%'  -- Replace with search term
        OR r.description ILIKE '%iPhone%'  -- Replace with search term
    )
ORDER BY r.created_at DESC;

-- 2.3 Get lost reports in specific category
SELECT 
    r.id,
    r.title,
    r.description,
    r.category,
    r.colors,
    r.location_city,
    r.occurred_at,
    r.reward_offered,
    r.created_at,
    u.display_name AS owner
FROM reports r
JOIN users u ON r.owner_id = u.id
WHERE 
    r.type = 'lost'
    AND r.status = 'approved'
    AND r.category = 'electronics'  -- Replace with: electronics, bags, jewelry, etc.
    AND r.is_resolved = false
ORDER BY r.created_at DESC;

-- 2.4 Get found reports in specific category
SELECT 
    r.id,
    r.title,
    r.description,
    r.category,
    r.colors,
    r.location_city,
    r.occurred_at,
    r.created_at,
    u.display_name AS owner
FROM reports r
JOIN users u ON r.owner_id = u.id
WHERE 
    r.type = 'found'
    AND r.status = 'approved'
    AND r.category = 'bags'  -- Replace with category
    AND r.is_resolved = false
ORDER BY r.created_at DESC;

-- 2.5 Get reports by location (city)
SELECT 
    r.id,
    r.type,
    r.title,
    r.category,
    r.location_city,
    r.location_address,
    r.occurred_at,
    r.created_at,
    u.display_name AS owner
FROM reports r
JOIN users u ON r.owner_id = u.id
WHERE 
    r.status = 'approved'
    AND r.location_city = 'New York'  -- Replace with city name
ORDER BY r.created_at DESC;

-- 2.6 Get reports with specific color
SELECT 
    r.id,
    r.type,
    r.title,
    r.category,
    r.colors,
    r.location_city,
    r.created_at
FROM reports r
WHERE 
    r.status = 'approved'
    AND 'Blue' = ANY(r.colors)  -- Replace 'Blue' with color name
ORDER BY r.created_at DESC;

-- 2.7 Get reports with rewards offered
SELECT 
    r.id,
    r.type,
    r.title,
    r.category,
    r.location_city,
    r.occurred_at,
    r.reward_offered,
    r.created_at,
    u.display_name AS owner,
    u.phone_number
FROM reports r
JOIN users u ON r.owner_id = u.id
WHERE 
    r.status = 'approved'
    AND r.reward_offered = true
    AND r.is_resolved = false
ORDER BY r.created_at DESC;

-- 2.8 Get user's own reports
-- Replace 'USER_UUID_HERE' with actual user ID
SELECT 
    r.id,
    r.type,
    r.title,
    r.status,
    r.category,
    r.is_resolved,
    r.created_at,
    (SELECT COUNT(*) FROM matches WHERE source_report_id = r.id) AS total_matches,
    (SELECT COUNT(*) FROM matches WHERE source_report_id = r.id AND status = 'promoted') AS good_matches,
    (SELECT COUNT(*) FROM media WHERE report_id = r.id) AS media_count
FROM reports r
WHERE r.owner_id = 'USER_UUID_HERE'
ORDER BY r.created_at DESC;

-- 2.9 Get pending reports (for moderation)
SELECT 
    r.id,
    r.type,
    r.title,
    r.category,
    r.created_at,
    u.display_name AS owner,
    u.email AS owner_email
FROM reports r
JOIN users u ON r.owner_id = u.id
WHERE r.status = 'pending'
ORDER BY r.created_at ASC;

-- 2.10 Get recent reports (last 24 hours)
SELECT 
    r.id,
    r.type,
    r.title,
    r.category,
    r.location_city,
    r.created_at,
    u.display_name AS owner
FROM reports r
JOIN users u ON r.owner_id = u.id
WHERE 
    r.status = 'approved'
    AND r.created_at > NOW() - INTERVAL '24 hours'
ORDER BY r.created_at DESC;

-- ============================================================================
-- SECTION 3: GEOSPATIAL QUERIES (PostGIS)
-- ============================================================================

-- 3.1 Find reports near specific coordinates (within 5km)
-- Replace longitude and latitude with your coordinates
SELECT 
    r.id,
    r.type,
    r.title,
    r.category,
    r.location_city,
    ST_AsText(r.geo) AS coordinates,
    ROUND(
        ST_Distance(
            r.geo::geography,
            ST_SetSRID(ST_MakePoint(-73.9654, 40.7829), 4326)::geography
        )::numeric / 1000,
        2
    ) AS distance_km
FROM reports r
WHERE 
    r.status = 'approved'
    AND r.geo IS NOT NULL
    AND ST_DWithin(
        r.geo::geography,
        ST_SetSRID(ST_MakePoint(-73.9654, 40.7829), 4326)::geography,  -- Replace coordinates
        5000  -- 5km in meters
    )
ORDER BY distance_km;

-- 3.2 Find reports in circular area (radius search)
WITH search_point AS (
    SELECT ST_SetSRID(ST_MakePoint(-73.9654, 40.7829), 4326)::geography AS point  -- Replace coordinates
)
SELECT 
    r.id,
    r.type,
    r.title,
    r.category,
    r.location_city,
    ROUND(
        ST_Distance(r.geo::geography, sp.point)::numeric / 1000,
        2
    ) AS distance_km,
    r.created_at
FROM reports r, search_point sp
WHERE 
    r.status = 'approved'
    AND r.geo IS NOT NULL
    AND ST_DWithin(r.geo::geography, sp.point, 10000)  -- 10km radius
ORDER BY distance_km, r.created_at DESC;

-- 3.3 Get reports with coordinates (for map display)
SELECT 
    r.id,
    r.type,
    r.title,
    r.category,
    r.location_city,
    ST_X(r.geo) AS longitude,
    ST_Y(r.geo) AS latitude,
    r.created_at
FROM reports r
WHERE 
    r.status = 'approved'
    AND r.geo IS NOT NULL
ORDER BY r.created_at DESC
LIMIT 100;

-- ============================================================================
-- SECTION 4: MATCH QUERIES
-- ============================================================================

-- 4.1 Get all matches for a report
-- Replace 'REPORT_UUID_HERE' with actual report ID
SELECT 
    m.id AS match_id,
    m.status,
    m.score_total,
    m.score_text,
    m.score_image,
    m.score_geo,
    m.score_time,
    m.score_color,
    m.created_at,
    r_source.id AS source_report_id,
    r_source.title AS source_title,
    r_source.type AS source_type,
    r_candidate.id AS candidate_report_id,
    r_candidate.title AS candidate_title,
    r_candidate.type AS candidate_type,
    u.display_name AS candidate_owner
FROM matches m
JOIN reports r_source ON m.source_report_id = r_source.id
JOIN reports r_candidate ON m.candidate_report_id = r_candidate.id
JOIN users u ON r_candidate.owner_id = u.id
WHERE m.source_report_id = 'REPORT_UUID_HERE'
ORDER BY m.score_total DESC;

-- 4.2 Get high-quality matches (score > 0.7)
SELECT 
    m.id,
    m.status,
    m.score_total,
    m.created_at,
    r_source.title AS source_title,
    r_source.type AS source_type,
    r_candidate.title AS candidate_title,
    r_candidate.type AS candidate_type
FROM matches m
JOIN reports r_source ON m.source_report_id = r_source.id
JOIN reports r_candidate ON m.candidate_report_id = r_candidate.id
WHERE 
    m.status = 'candidate'
    AND m.score_total > 0.7
ORDER BY m.score_total DESC;

-- 4.3 Get promoted matches (confirmed by users)
SELECT 
    m.id,
    m.score_total,
    m.created_at,
    m.updated_at,
    r_source.title AS source_title,
    u_source.display_name AS source_owner,
    u_source.email AS source_email,
    r_candidate.title AS candidate_title,
    u_candidate.display_name AS candidate_owner,
    u_candidate.email AS candidate_email
FROM matches m
JOIN reports r_source ON m.source_report_id = r_source.id
JOIN users u_source ON r_source.owner_id = u_source.id
JOIN reports r_candidate ON m.candidate_report_id = r_candidate.id
JOIN users u_candidate ON r_candidate.owner_id = u_candidate.id
WHERE m.status = 'promoted'
ORDER BY m.updated_at DESC;

-- 4.4 Match statistics by category
SELECT 
    r.category,
    COUNT(DISTINCT m.id) AS total_matches,
    COUNT(DISTINCT m.id) FILTER (WHERE m.status = 'promoted') AS promoted_matches,
    ROUND(AVG(m.score_total), 3) AS avg_score,
    MAX(m.score_total) AS max_score
FROM matches m
JOIN reports r ON m.source_report_id = r.id
GROUP BY r.category
ORDER BY total_matches DESC;

-- ============================================================================
-- SECTION 5: MESSAGE AND CONVERSATION QUERIES
-- ============================================================================

-- 5.1 Get user's conversations
-- Replace 'USER_UUID_HERE' with actual user ID
SELECT 
    c.id AS conversation_id,
    c.updated_at AS last_activity,
    u_other.id AS other_user_id,
    u_other.display_name AS other_user_name,
    u_other.avatar_url AS other_user_avatar,
    (
        SELECT COUNT(*) 
        FROM messages 
        WHERE conversation_id = c.id 
        AND sender_id != 'USER_UUID_HERE'  -- Replace with user ID
        AND is_read = false
    ) AS unread_count,
    (
        SELECT content 
        FROM messages 
        WHERE conversation_id = c.id 
        ORDER BY created_at DESC 
        LIMIT 1
    ) AS last_message
FROM conversations c
JOIN users u_other ON (
    CASE 
        WHEN c.participant_one_id = 'USER_UUID_HERE' THEN c.participant_two_id  -- Replace with user ID
        ELSE c.participant_one_id
    END = u_other.id
)
WHERE 
    c.participant_one_id = 'USER_UUID_HERE'  -- Replace with user ID
    OR c.participant_two_id = 'USER_UUID_HERE'  -- Replace with user ID
ORDER BY c.updated_at DESC;

-- 5.2 Get messages in a conversation
-- Replace 'CONVERSATION_UUID_HERE' with actual conversation ID
SELECT 
    m.id,
    m.content,
    m.is_read,
    m.created_at,
    u.id AS sender_id,
    u.display_name AS sender_name,
    u.avatar_url AS sender_avatar
FROM messages m
JOIN users u ON m.sender_id = u.id
WHERE m.conversation_id = 'CONVERSATION_UUID_HERE'
ORDER BY m.created_at ASC;

-- 5.3 Get unread message count for user
-- Replace 'USER_UUID_HERE' with actual user ID
SELECT 
    COUNT(*) AS unread_messages
FROM messages m
JOIN conversations c ON m.conversation_id = c.id
WHERE 
    m.is_read = false
    AND m.sender_id != 'USER_UUID_HERE'  -- Replace with user ID
    AND (
        c.participant_one_id = 'USER_UUID_HERE'  -- Replace with user ID
        OR c.participant_two_id = 'USER_UUID_HERE'  -- Replace with user ID
    );

-- ============================================================================
-- SECTION 6: NOTIFICATION QUERIES
-- ============================================================================

-- 6.1 Get user's recent notifications
-- Replace 'USER_UUID_HERE' with actual user ID
SELECT 
    id,
    type,
    title,
    message,
    is_read,
    created_at,
    data  -- JSON metadata
FROM notifications
WHERE user_id = 'USER_UUID_HERE'
ORDER BY created_at DESC
LIMIT 20;

-- 6.2 Get unread notifications
-- Replace 'USER_UUID_HERE' with actual user ID
SELECT 
    id,
    type,
    title,
    message,
    created_at,
    data
FROM notifications
WHERE 
    user_id = 'USER_UUID_HERE'
    AND is_read = false
ORDER BY created_at DESC;

-- 6.3 Get notification counts by type
-- Replace 'USER_UUID_HERE' with actual user ID
SELECT 
    type,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE is_read = false) AS unread
FROM notifications
WHERE user_id = 'USER_UUID_HERE'
GROUP BY type
ORDER BY total DESC;

-- 6.4 Mark all notifications as read
-- Replace 'USER_UUID_HERE' with actual user ID
UPDATE notifications
SET is_read = true
WHERE user_id = 'USER_UUID_HERE' AND is_read = false;

-- ============================================================================
-- SECTION 7: MEDIA QUERIES
-- ============================================================================

-- 7.1 Get media for a report
-- Replace 'REPORT_UUID_HERE' with actual report ID
SELECT 
    id,
    filename,
    url,
    media_type,
    mime_type,
    width,
    height,
    size_bytes,
    phash_hex,
    dhash_hex,
    created_at
FROM media
WHERE report_id = 'REPORT_UUID_HERE'
ORDER BY created_at ASC;

-- 7.2 Get reports with media
SELECT 
    r.id AS report_id,
    r.title,
    r.type,
    r.category,
    COUNT(m.id) AS media_count,
    array_agg(m.url ORDER BY m.created_at) AS media_urls
FROM reports r
JOIN media m ON r.report_id = m.id
WHERE r.status = 'approved'
GROUP BY r.id, r.title, r.type, r.category
HAVING COUNT(m.id) > 0
ORDER BY r.created_at DESC;

-- 7.3 Get total storage usage by media type
SELECT 
    media_type,
    COUNT(*) AS file_count,
    pg_size_pretty(SUM(size_bytes)) AS total_size,
    AVG(size_bytes) AS avg_file_size
FROM media
GROUP BY media_type
ORDER BY SUM(size_bytes) DESC;

-- ============================================================================
-- SECTION 8: ANALYTICS AND STATISTICS
-- ============================================================================

-- 8.1 Dashboard overview statistics
SELECT 
    (SELECT COUNT(*) FROM users WHERE is_active = true) AS active_users,
    (SELECT COUNT(*) FROM reports WHERE status = 'approved') AS approved_reports,
    (SELECT COUNT(*) FROM reports WHERE type = 'lost' AND status = 'approved' AND is_resolved = false) AS active_lost,
    (SELECT COUNT(*) FROM reports WHERE type = 'found' AND status = 'approved' AND is_resolved = false) AS active_found,
    (SELECT COUNT(*) FROM matches WHERE status = 'promoted') AS successful_matches,
    (SELECT COUNT(*) FROM messages WHERE created_at > NOW() - INTERVAL '24 hours') AS messages_today,
    (SELECT COUNT(*) FROM reports WHERE created_at > NOW() - INTERVAL '7 days') AS reports_this_week;

-- 8.2 Reports by category (with percentages)
WITH totals AS (
    SELECT COUNT(*) AS total_count FROM reports WHERE status = 'approved'
)
SELECT 
    category,
    COUNT(*) AS count,
    ROUND((COUNT(*) * 100.0) / totals.total_count, 2) AS percentage
FROM reports, totals
WHERE status = 'approved'
GROUP BY category, totals.total_count
ORDER BY count DESC;

-- 8.3 Reports by city (top 10)
SELECT 
    location_city,
    COUNT(*) AS report_count,
    COUNT(*) FILTER (WHERE type = 'lost') AS lost_count,
    COUNT(*) FILTER (WHERE type = 'found') AS found_count
FROM reports
WHERE 
    status = 'approved'
    AND location_city IS NOT NULL
GROUP BY location_city
ORDER BY report_count DESC
LIMIT 10;

-- 8.4 Daily report trends (last 30 days)
SELECT 
    DATE(created_at) AS date,
    COUNT(*) AS total_reports,
    COUNT(*) FILTER (WHERE type = 'lost') AS lost,
    COUNT(*) FILTER (WHERE type = 'found') AS found
FROM reports
WHERE 
    status = 'approved'
    AND created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- 8.5 Match success rate by category
SELECT 
    r.category,
    COUNT(DISTINCT r.id) AS total_reports,
    COUNT(DISTINCT m.id) FILTER (WHERE m.status = 'promoted') AS successful_matches,
    ROUND(
        (COUNT(DISTINCT m.id) FILTER (WHERE m.status = 'promoted') * 100.0) / 
        NULLIF(COUNT(DISTINCT r.id), 0),
        2
    ) AS success_rate_percent
FROM reports r
LEFT JOIN matches m ON r.id = m.source_report_id
WHERE r.status = 'approved'
GROUP BY r.category
ORDER BY success_rate_percent DESC;

-- 8.6 Most active users (by reports created)
SELECT 
    u.id,
    u.display_name,
    u.email,
    COUNT(r.id) AS total_reports,
    COUNT(r.id) FILTER (WHERE r.type = 'lost') AS lost,
    COUNT(r.id) FILTER (WHERE r.type = 'found') AS found,
    MAX(r.created_at) AS last_report_date
FROM users u
LEFT JOIN reports r ON u.id = r.owner_id AND r.status = 'approved'
WHERE u.is_active = true
GROUP BY u.id, u.display_name, u.email
HAVING COUNT(r.id) > 0
ORDER BY total_reports DESC
LIMIT 20;

-- ============================================================================
-- SECTION 9: ADMIN QUERIES
-- ============================================================================

-- 9.1 Get all pending reports for moderation
SELECT 
    r.id,
    r.type,
    r.title,
    r.category,
    r.created_at,
    u.display_name AS owner,
    u.email AS owner_email,
    (SELECT COUNT(*) FROM media WHERE report_id = r.id) AS media_count
FROM reports r
JOIN users u ON r.owner_id = u.id
WHERE r.status = 'pending'
ORDER BY r.created_at ASC;

-- 9.2 Approve a report
-- Replace 'REPORT_UUID_HERE' with actual report ID
UPDATE reports
SET status = 'approved', updated_at = NOW()
WHERE id = 'REPORT_UUID_HERE';

-- 9.3 Reject a report
-- Replace 'REPORT_UUID_HERE' with actual report ID
UPDATE reports
SET status = 'removed', updated_at = NOW()
WHERE id = 'REPORT_UUID_HERE';

-- 9.4 Get flagged or suspicious content
SELECT 
    r.id,
    r.title,
    r.type,
    r.category,
    r.created_at,
    u.email AS owner_email,
    (SELECT COUNT(*) FROM reports WHERE owner_id = u.id) AS user_report_count
FROM reports r
JOIN users u ON r.owner_id = u.id
WHERE 
    r.title ILIKE '%test%'
    OR r.description ILIKE '%spam%'
    OR EXISTS (
        SELECT 1 FROM reports r2 
        WHERE r2.owner_id = u.id 
        GROUP BY r2.owner_id 
        HAVING COUNT(*) > 10
    )
ORDER BY r.created_at DESC;

-- 9.5 Deactivate a user
-- Replace 'USER_UUID_HERE' with actual user ID
UPDATE users
SET is_active = false, updated_at = NOW()
WHERE id = 'USER_UUID_HERE';

-- 9.6 Get system health metrics
SELECT 
    'Active Users' AS metric,
    COUNT(*)::text AS value
FROM users WHERE is_active = true
UNION ALL
SELECT 'Total Reports', COUNT(*)::text FROM reports
UNION ALL
SELECT 'Pending Reports', COUNT(*)::text FROM reports WHERE status = 'pending'
UNION ALL
SELECT 'Active Matches', COUNT(*)::text FROM matches WHERE status IN ('candidate', 'promoted')
UNION ALL
SELECT 'Database Size', pg_size_pretty(pg_database_size(current_database()))
UNION ALL
SELECT 'Tables', COUNT(*)::text FROM information_schema.tables WHERE table_schema = 'public';

-- ============================================================================
-- SECTION 10: MAINTENANCE QUERIES
-- ============================================================================

-- 10.1 Vacuum and analyze all tables
VACUUM ANALYZE users;
VACUUM ANALYZE reports;
VACUUM ANALYZE matches;
VACUUM ANALYZE media;
VACUUM ANALYZE conversations;
VACUUM ANALYZE messages;
VACUUM ANALYZE notifications;

-- 10.2 Check table sizes
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 10.3 Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    pg_size_pretty(pg_relation_size(indexrelid::regclass)) AS size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- 10.4 Find slow queries (requires pg_stat_statements)
SELECT 
    query,
    calls,
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND((100 * total_exec_time / SUM(total_exec_time) OVER())::numeric, 2) AS percentage
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
ORDER BY total_exec_time DESC
LIMIT 10;

-- 10.5 Get active connections
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    query_start,
    LEFT(query, 100) AS query_preview
FROM pg_stat_activity
WHERE datname = current_database()
AND state != 'idle'
ORDER BY query_start DESC;

-- ============================================================================
-- QUERIES FILE COMPLETE
-- ============================================================================

-- Tips for using these queries in pgAdmin:
-- 1. Copy the query you need
-- 2. Paste into Query Tool (Tools → Query Tool or F5)
-- 3. Replace placeholder values (marked with comments)
-- 4. Execute with F5 or click Execute button
-- 5. Results appear in Data Output panel below
-- 6. Export results: Right-click results → Export → CSV/Excel

-- For bulk operations:
-- - Select multiple queries and execute together
-- - Use transactions with BEGIN; ... COMMIT; for safety
-- - Use EXPLAIN ANALYZE to check query performance

COMMIT;
