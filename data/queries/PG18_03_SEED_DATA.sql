-- ============================================================================
-- POSTGRESQL 18 SEED DATA SCRIPT
-- Lost & Found Application - Initial Data Population
-- Compatible with: PostgreSQL 18, pgAdmin 4 (Windows)
-- ============================================================================
-- Run this AFTER creating tables and indexes
-- Right-click on database in pgAdmin → Query Tool → Paste and Execute (F5)
-- ============================================================================

\c lostfound

-- ============================================================================
-- SECTION 1: SEED CATEGORIES
-- ============================================================================

-- Note: Adjust table name if your schema uses 'item_categories' instead
INSERT INTO categories (id, name, description, icon, is_active, display_order, created_at)
VALUES
    (uuid_generate_v4(), 'electronics', 'Electronic devices and accessories', '📱', true, 1, NOW()),
    (uuid_generate_v4(), 'clothing', 'Clothing items and accessories', '👕', true, 2, NOW()),
    (uuid_generate_v4(), 'bags', 'Bags, backpacks, and luggage', '🎒', true, 3, NOW()),
    (uuid_generate_v4(), 'jewelry', 'Jewelry and valuable accessories', '💍', true, 4, NOW()),
    (uuid_generate_v4(), 'documents', 'ID cards, passports, papers', '📄', true, 5, NOW()),
    (uuid_generate_v4(), 'keys', 'Keys and keychains', '🔑', true, 6, NOW()),
    (uuid_generate_v4(), 'wallets', 'Wallets and purses', '👛', true, 7, NOW()),
    (uuid_generate_v4(), 'glasses', 'Eyeglasses and sunglasses', '👓', true, 8, NOW()),
    (uuid_generate_v4(), 'pets', 'Lost or found pets', '🐾', true, 9, NOW()),
    (uuid_generate_v4(), 'sports', 'Sports equipment', '⚽', true, 10, NOW()),
    (uuid_generate_v4(), 'books', 'Books and notebooks', '📚', true, 11, NOW()),
    (uuid_generate_v4(), 'toys', 'Toys and games', '🧸', true, 12, NOW()),
    (uuid_generate_v4(), 'vehicles', 'Bicycles, scooters, etc.', '🚲', true, 13, NOW()),
    (uuid_generate_v4(), 'other', 'Other items', '📦', true, 99, NOW())
ON CONFLICT (id) DO NOTHING;

-- Verify categories
SELECT 
    name,
    description,
    icon,
    is_active,
    display_order
FROM categories
ORDER BY display_order;

-- ============================================================================
-- SECTION 2: SEED COLORS
-- ============================================================================

INSERT INTO colors (id, name, hex_code, rgb_value, created_at)
VALUES
    (uuid_generate_v4(), 'Red', '#FF0000', 'rgb(255, 0, 0)', NOW()),
    (uuid_generate_v4(), 'Blue', '#0000FF', 'rgb(0, 0, 255)', NOW()),
    (uuid_generate_v4(), 'Green', '#00FF00', 'rgb(0, 255, 0)', NOW()),
    (uuid_generate_v4(), 'Yellow', '#FFFF00', 'rgb(255, 255, 0)', NOW()),
    (uuid_generate_v4(), 'Orange', '#FFA500', 'rgb(255, 165, 0)', NOW()),
    (uuid_generate_v4(), 'Purple', '#800080', 'rgb(128, 0, 128)', NOW()),
    (uuid_generate_v4(), 'Pink', '#FFC0CB', 'rgb(255, 192, 203)', NOW()),
    (uuid_generate_v4(), 'Brown', '#A52A2A', 'rgb(165, 42, 42)', NOW()),
    (uuid_generate_v4(), 'Black', '#000000', 'rgb(0, 0, 0)', NOW()),
    (uuid_generate_v4(), 'White', '#FFFFFF', 'rgb(255, 255, 255)', NOW()),
    (uuid_generate_v4(), 'Gray', '#808080', 'rgb(128, 128, 128)', NOW()),
    (uuid_generate_v4(), 'Silver', '#C0C0C0', 'rgb(192, 192, 192)', NOW()),
    (uuid_generate_v4(), 'Gold', '#FFD700', 'rgb(255, 215, 0)', NOW()),
    (uuid_generate_v4(), 'Beige', '#F5F5DC', 'rgb(245, 245, 220)', NOW()),
    (uuid_generate_v4(), 'Navy', '#000080', 'rgb(0, 0, 128)', NOW()),
    (uuid_generate_v4(), 'Teal', '#008080', 'rgb(0, 128, 128)', NOW()),
    (uuid_generate_v4(), 'Maroon', '#800000', 'rgb(128, 0, 0)', NOW()),
    (uuid_generate_v4(), 'Multicolor', '#RAINBOW', 'rgb(255, 255, 255)', NOW())
ON CONFLICT (id) DO NOTHING;

-- Verify colors
SELECT 
    name,
    hex_code,
    rgb_value
FROM colors
ORDER BY name;

-- ============================================================================
-- SECTION 3: CREATE TEST USERS
-- ============================================================================

-- Create test users with hashed passwords
-- Note: These are bcrypt hashed passwords for "password123"
-- In production, use proper password hashing via your application

INSERT INTO users (id, email, hashed_password, display_name, phone_number, role, is_active, created_at)
VALUES
    (
        uuid_generate_v4(),
        'admin@lostfound.com',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqVr/VPBKa',
        'System Admin',
        '+1234567890',
        'admin',
        true,
        NOW()
    ),
    (
        uuid_generate_v4(),
        'john.doe@example.com',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqVr/VPBKa',
        'John Doe',
        '+1234567891',
        'user',
        true,
        NOW()
    ),
    (
        uuid_generate_v4(),
        'jane.smith@example.com',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqVr/VPBKa',
        'Jane Smith',
        '+1234567892',
        'user',
        true,
        NOW()
    ),
    (
        uuid_generate_v4(),
        'moderator@lostfound.com',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqVr/VPBKa',
        'Content Moderator',
        '+1234567893',
        'moderator',
        true,
        NOW()
    )
ON CONFLICT (email) DO NOTHING;

-- Verify users
SELECT 
    email,
    display_name,
    role,
    is_active,
    created_at
FROM users
ORDER BY created_at;

-- ============================================================================
-- SECTION 4: CREATE SAMPLE REPORTS
-- ============================================================================

-- Get user IDs for sample reports
DO $$
DECLARE
    v_user1_id UUID;
    v_user2_id UUID;
    v_category_electronics VARCHAR;
    v_category_bags VARCHAR;
    v_report1_id UUID;
    v_report2_id UUID;
BEGIN
    -- Get test users
    SELECT id INTO v_user1_id FROM users WHERE email = 'john.doe@example.com' LIMIT 1;
    SELECT id INTO v_user2_id FROM users WHERE email = 'jane.smith@example.com' LIMIT 1;
    
    -- Get categories
    SELECT name INTO v_category_electronics FROM categories WHERE name = 'electronics' LIMIT 1;
    SELECT name INTO v_category_bags FROM categories WHERE name = 'bags' LIMIT 1;
    
    -- Create lost iPhone report
    v_report1_id := uuid_generate_v4();
    INSERT INTO reports (
        id, owner_id, type, status, title, description, category, colors,
        occurred_at, geo, location_city, location_address,
        reward_offered, is_resolved, created_at
    )
    VALUES (
        v_report1_id,
        v_user1_id,
        'lost',
        'approved',
        'Lost iPhone 14 Pro',
        'Lost my iPhone 14 Pro in Space Black. Has a small crack on the bottom right corner. Last seen near Central Park.',
        v_category_electronics,
        ARRAY['Black'],
        NOW() - INTERVAL '2 days',
        ST_SetSRID(ST_MakePoint(-73.9654, 40.7829), 4326), -- Central Park, NYC
        'New York',
        'Central Park, near Bethesda Fountain',
        true,
        false,
        NOW() - INTERVAL '2 days'
    );
    
    -- Create found backpack report
    v_report2_id := uuid_generate_v4();
    INSERT INTO reports (
        id, owner_id, type, status, title, description, category, colors,
        occurred_at, geo, location_city, location_address,
        reward_offered, is_resolved, created_at
    )
    VALUES (
        v_report2_id,
        v_user2_id,
        'found',
        'approved',
        'Found Blue Backpack',
        'Found a blue JanSport backpack near the library. Contains textbooks and a laptop.',
        v_category_bags,
        ARRAY['Blue', 'Gray'],
        NOW() - INTERVAL '1 day',
        ST_SetSRID(ST_MakePoint(-73.9626, 40.8075), 4326), -- Columbia University area
        'New York',
        'Columbia University, Butler Library',
        false,
        false,
        NOW() - INTERVAL '1 day'
    );
    
    RAISE NOTICE 'Created sample reports: % and %', v_report1_id, v_report2_id;
END $$;

-- Verify reports
SELECT 
    r.id,
    r.type,
    r.title,
    r.status,
    r.category,
    r.location_city,
    u.display_name AS owner,
    r.created_at
FROM reports r
JOIN users u ON r.owner_id = u.id
ORDER BY r.created_at DESC;

-- ============================================================================
-- SECTION 5: CREATE SAMPLE NOTIFICATIONS
-- ============================================================================

-- Create welcome notifications for all users
INSERT INTO notifications (id, user_id, type, title, message, is_read, created_at)
SELECT
    uuid_generate_v4(),
    id,
    'system_announcement',
    'Welcome to Lost & Found!',
    'Thank you for joining our community. Start by reporting lost or found items.',
    false,
    NOW()
FROM users
WHERE NOT EXISTS (
    SELECT 1 FROM notifications WHERE user_id = users.id AND title = 'Welcome to Lost & Found!'
);

-- Verify notifications
SELECT 
    n.title,
    n.message,
    n.type,
    n.is_read,
    u.display_name AS user_name,
    n.created_at
FROM notifications n
JOIN users u ON n.user_id = u.id
ORDER BY n.created_at DESC;

-- ============================================================================
-- SECTION 6: DATABASE STATISTICS
-- ============================================================================

-- Show record counts
SELECT 
    'users' AS table_name,
    COUNT(*) AS record_count
FROM users
UNION ALL
SELECT 'reports', COUNT(*) FROM reports
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'colors', COUNT(*) FROM colors
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications
ORDER BY table_name;

-- Show database size
SELECT
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM reports) AS total_reports,
    (SELECT COUNT(*) FROM reports WHERE type = 'lost') AS lost_reports,
    (SELECT COUNT(*) FROM reports WHERE type = 'found') AS found_reports;

-- ============================================================================
-- SECTION 7: VERIFY GEOSPATIAL DATA
-- ============================================================================

-- Check reports with geospatial data
SELECT 
    id,
    title,
    location_city,
    ST_AsText(geo) AS coordinates,
    ST_Y(geo) AS latitude,
    ST_X(geo) AS longitude
FROM reports
WHERE geo IS NOT NULL
ORDER BY created_at DESC;

-- Test distance calculation (reports within 10km of Central Park)
SELECT 
    r.id,
    r.title,
    r.location_city,
    ROUND(
        ST_Distance(
            r.geo::geography,
            ST_SetSRID(ST_MakePoint(-73.9654, 40.7829), 4326)::geography
        )::numeric / 1000,
        2
    ) AS distance_km
FROM reports r
WHERE r.geo IS NOT NULL
AND ST_DWithin(
    r.geo::geography,
    ST_SetSRID(ST_MakePoint(-73.9654, 40.7829), 4326)::geography,
    10000  -- 10km in meters
)
ORDER BY distance_km;

-- ============================================================================
-- SEED DATA COMPLETE
-- ============================================================================

-- Summary of seeded data:
SELECT 
    'Seeded Data Summary' AS status,
    (SELECT COUNT(*) FROM categories) AS categories,
    (SELECT COUNT(*) FROM colors) AS colors,
    (SELECT COUNT(*) FROM users) AS users,
    (SELECT COUNT(*) FROM reports) AS reports,
    (SELECT COUNT(*) FROM notifications) AS notifications;

-- Next Steps:
-- 1. Run PG18_04_QUERIES.sql for common operations
-- 2. Test the API endpoints
-- 3. Add more sample data as needed
-- 4. Configure backups and monitoring

COMMIT;
