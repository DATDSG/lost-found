**PostgreSQL 18 Queries for Lost & Found Application**

Complete SQL query collection optimized for PostgreSQL 18 and pgAdmin 4 (Windows)

---

## 📋 **Table of Contents**

1. [Quick Start](#quick-start)
2. [File Overview](#file-overview)
3. [Installation Guide](#installation-guide)
4. [Using in pgAdmin](#using-in-pgadmin)
5. [Query Categories](#query-categories)
6. [Troubleshooting](#troubleshooting)
7. [Performance Tips](#performance-tips)

---

## 🚀 **Quick Start**

### Prerequisites

- **PostgreSQL 18** installed and running
- **pgAdmin 4** (Windows) installed
- **Extensions Required**:
  - `pgvector` - AI embeddings and similarity search
  - `postgis` - Geospatial queries
  - `pg_trgm` - Fuzzy text matching
  - `uuid-ossp` - UUID generation

### Installation Steps

1. **Open pgAdmin** on Windows
2. **Connect to PostgreSQL server** (usually `localhost`)
3. **Execute scripts in order**:
   - `PG18_01_SETUP.sql` - Database initialization
   - Run Alembic migrations (from command prompt)
   - `PG18_02_INDEXES.sql` - Performance indexes
   - `PG18_03_SEED_DATA.sql` - Sample data
   - `PG18_04_QUERIES.sql` - Query reference

---

## 📁 **File Overview**

### **PG18_01_SETUP.sql** (Database Initialization)

**Purpose:** Initial database setup and configuration  
**Run as:** postgres superuser  
**Run when:** First time setup only

**Contents:**

- Database creation (optional)
- User/role creation
- Extension installation (pgvector, PostGIS, pg_trgm, etc.)
- Custom type creation (enums)
- Performance configuration
- Permissions setup
- Verification queries

**How to use:**

```
1. Open pgAdmin
2. Right-click on PostgreSQL server → Query Tool
3. Copy entire content of PG18_01_SETUP.sql
4. Paste into Query Tool
5. Press F5 or click Execute
```

---

### **PG18_02_INDEXES.sql** (Performance Optimization)

**Purpose:** Create optimized indexes for fast queries  
**Run as:** Database owner or postgres  
**Run when:** After tables are created (post-migration)

**Contents:**

- User table indexes
- Report table indexes (including geospatial and vector)
- Match table indexes
- Media table indexes (perceptual hashes)
- Message/conversation indexes
- Notification indexes
- Partial indexes for common filters
- Index verification queries

**Important Notes:**

- Vector indexes require at least 1000 rows for optimal performance
- HNSW indexes (commented out) require pgvector 0.5.0+
- Run ANALYZE after creating indexes

---

### **PG18_03_SEED_DATA.sql** (Sample Data)

**Purpose:** Populate database with initial/test data  
**Run as:** Database owner  
**Run when:** After indexes are created

**Contents:**

- 14 item categories (electronics, bags, jewelry, etc.)
- 18 color definitions
- 4 test users (including admin and moderator)
- 2 sample reports (lost iPhone, found backpack)
- Welcome notifications for all users
- Verification queries

**Test Credentials:**

- Email: `admin@lostfound.com`
- Password: `password123`
- Role: admin

_(All test users have same password for development)_

---

### **PG18_04_QUERIES.sql** (Query Reference)

**Purpose:** Ready-to-use queries for common operations  
**Run as:** Copy individual queries as needed  
**Run when:** Anytime during development/operation

**90+ queries organized in 10 sections:**

1. Quick Reference
2. User Queries (search, statistics, roles)
3. Report Queries (search, filters, moderation)
4. Geospatial Queries (location-based search)
5. Match Queries (similarity scores, confirmations)
6. Message Queries (conversations, unread)
7. Notification Queries (alerts, read/unread)
8. Media Queries (images, storage)
9. Analytics (dashboard stats, trends)
10. Admin & Maintenance

---

## 🛠️ **Installation Guide**

### Step 1: Install PostgreSQL 18

Download from: https://www.postgresql.org/download/windows/

**During installation:**

- Remember your postgres password
- Keep default port (5432)
- Install Stack Builder for extensions

---

### Step 2: Install Required Extensions

#### Option A: Use Stack Builder (Recommended)

1. Open Stack Builder from Start Menu
2. Select your PostgreSQL installation
3. Install:
   - PostGIS Bundle
   - pgvector (if available)

#### Option B: Manual Installation

**pgvector:**

```
Download: https://github.com/pgvector/pgvector/releases
Extract and follow Windows installation instructions
```

**PostGIS:**

```
Download: https://postgis.net/windows_downloads/
Run installer, select your PostgreSQL version
```

---

### Step 3: Run Setup Script

1. Open **pgAdmin 4**
2. Expand **Servers** → **PostgreSQL 18**
3. Right-click **Databases** → **Create** → **Database**
   - Name: `lostfound`
   - Owner: `postgres`
   - Click **Save**
4. Right-click `lostfound` database → **Query Tool**
5. Open `PG18_01_SETUP.sql`
6. Copy all content
7. Paste into Query Tool
8. Press **F5** to execute
9. Check Messages panel for success/errors

---

### Step 4: Run Alembic Migrations

Open **Command Prompt** (Windows):

```cmd
cd C:\Users\td123\OneDrive\Documents\GitHub\lost-found\services\api

# Activate virtual environment if using one
# venv\Scripts\activate

# Run migrations
alembic upgrade head
```

Verify tables were created:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

---

### Step 5: Create Indexes

1. In pgAdmin Query Tool
2. Open `PG18_02_INDEXES.sql`
3. Copy all content
4. Paste and execute (F5)
5. Wait for completion (may take 1-2 minutes)
6. Check Messages panel for confirmation

---

### Step 6: Seed Initial Data

1. Open `PG18_03_SEED_DATA.sql`
2. Copy all content
3. Paste into Query Tool
4. Execute (F5)
5. Verify data:

```sql
SELECT 'users' AS table_name, COUNT(*) FROM users
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'colors', COUNT(*) FROM colors
UNION ALL
SELECT 'reports', COUNT(*) FROM reports;
```

---

## 💻 **Using in pgAdmin**

### Opening Query Tool

**Method 1:**

- Right-click database → **Query Tool**

**Method 2:**

- Select database → **Tools** → **Query Tool**

**Keyboard Shortcut:** `Alt + Shift + Q`

---

### Running Queries

1. **Paste query** into Query Tool editor
2. **Replace placeholders** (marked with comments):
   ```sql
   WHERE id = 'USER_UUID_HERE'  -- Replace with actual UUID
   ```
3. **Execute:**
   - Press **F5**, or
   - Click **Execute/Refresh** button (▶️), or
   - **Query** → **Execute**

---

### Viewing Results

- Results appear in **Data Output** panel (bottom)
- **Grid View**: Browse data in table format
- **Geometry Viewer**: View map data (for geospatial queries)
- **Messages**: Shows query execution details

---

### Exporting Results

1. Right-click in **Data Output** grid
2. Select **Export**
3. Choose format:
   - **CSV** (Excel compatible)
   - **Plain text**
   - **HTML**
4. Save to desired location

---

### Saving Queries

**Option 1: Save as File**

1. **File** → **Save** (Ctrl+S)
2. Save as `.sql` file
3. Reopen with **File** → **Open**

**Option 2: Use Query History**

1. **View** → **Query History**
2. Browse previously executed queries
3. Click to reload

---

### Tips for pgAdmin

**Multiple Queries:**

- Separate with semicolons (`;`)
- Highlight specific query to run only that one
- F5 runs all queries, or highlighted query

**Auto-complete:**

- Type table/column names
- Press **Ctrl+Space** for suggestions

**Keyboard Shortcuts:**

- `F5` - Execute query
- `F7` - Explain query plan
- `Ctrl+/` - Comment/uncomment lines
- `Ctrl+S` - Save query
- `Ctrl+K` - Clear query window

---

## 📂 **Query Categories**

### 1. User Management

**Find user by email:**

```sql
SELECT * FROM users WHERE email = 'john@example.com';
```

**Get user statistics:**

```sql
SELECT
    display_name,
    (SELECT COUNT(*) FROM reports WHERE owner_id = users.id) AS total_reports
FROM users
WHERE id = 'your-user-id-here';
```

**List all admins:**

```sql
SELECT email, display_name, created_at
FROM users
WHERE role = 'admin' AND is_active = true;
```

---

### 2. Report Searches

**Search by keyword:**

```sql
SELECT id, title, description, category, location_city
FROM reports
WHERE
    status = 'approved'
    AND (title ILIKE '%iPhone%' OR description ILIKE '%iPhone%')
ORDER BY created_at DESC;
```

**Filter by category and location:**

```sql
SELECT id, title, type, location_city, occurred_at
FROM reports
WHERE
    category = 'electronics'
    AND location_city = 'New York'
    AND status = 'approved'
ORDER BY created_at DESC;
```

**Find items with rewards:**

```sql
SELECT id, title, category, location_city
FROM reports
WHERE reward_offered = true AND status = 'approved'
ORDER BY created_at DESC;
```

---

### 3. Geospatial Searches

**Find reports within 5km of coordinates:**

```sql
SELECT
    id,
    title,
    location_city,
    ROUND(
        ST_Distance(
            geo::geography,
            ST_SetSRID(ST_MakePoint(-73.9654, 40.7829), 4326)::geography
        )::numeric / 1000,
        2
    ) AS distance_km
FROM reports
WHERE
    status = 'approved'
    AND geo IS NOT NULL
    AND ST_DWithin(
        geo::geography,
        ST_SetSRID(ST_MakePoint(-73.9654, 40.7829), 4326)::geography,
        5000
    )
ORDER BY distance_km;
```

_(Replace -73.9654, 40.7829 with your longitude, latitude)_

---

### 4. Match Analysis

**High-quality matches (score > 0.7):**

```sql
SELECT
    m.score_total,
    r_source.title AS lost_item,
    r_candidate.title AS found_item
FROM matches m
JOIN reports r_source ON m.source_report_id = r_source.id
JOIN reports r_candidate ON m.candidate_report_id = r_candidate.id
WHERE m.score_total > 0.7
ORDER BY m.score_total DESC;
```

---

### 5. Analytics

**Dashboard overview:**

```sql
SELECT
    (SELECT COUNT(*) FROM users WHERE is_active = true) AS active_users,
    (SELECT COUNT(*) FROM reports WHERE status = 'approved') AS total_reports,
    (SELECT COUNT(*) FROM matches WHERE status = 'promoted') AS successful_matches;
```

**Reports by category:**

```sql
SELECT
    category,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE type = 'lost') AS lost,
    COUNT(*) FILTER (WHERE type = 'found') AS found
FROM reports
WHERE status = 'approved'
GROUP BY category
ORDER BY total DESC;
```

---

## 🐛 **Troubleshooting**

### Common Issues

#### **Issue:** "extension does not exist"

**Solution:**

```sql
-- Check installed extensions
SELECT extname FROM pg_extension;

-- Install missing extension (as superuser)
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS postgis;
```

---

#### **Issue:** "syntax error near '\c'"

**Solution:**  
The `\c` command is psql-specific. In pgAdmin:

- Ignore `\c lostfound` lines
- Ensure you're connected to correct database (check top of pgAdmin window)

---

#### **Issue:** "column does not exist"

**Solution:**

1. Check table exists:

```sql
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
```

2. Check column names:

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'reports';
```

3. Run migrations:

```cmd
alembic upgrade head
```

---

#### **Issue:** Vector search returns no results

**Solution:**

1. Check if embeddings exist:

```sql
SELECT COUNT(*) FROM reports WHERE embedding IS NOT NULL;
```

2. Rebuild vector index:

```sql
DROP INDEX IF EXISTS idx_reports_embedding_ivfflat;
CREATE INDEX idx_reports_embedding_ivfflat ON reports
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
```

---

#### **Issue:** Geospatial queries fail

**Solution:**

1. Verify PostGIS is installed:

```sql
SELECT postgis_version();
```

2. Check coordinate data:

```sql
SELECT id, ST_AsText(geo) FROM reports WHERE geo IS NOT NULL LIMIT 5;
```

3. Ensure SRID is correct (4326 for WGS84):

```sql
SELECT ST_SRID(geo) FROM reports WHERE geo IS NOT NULL LIMIT 1;
```

---

#### **Issue:** Slow query performance

**Solution:**

1. Check query plan:

```sql
EXPLAIN ANALYZE
SELECT * FROM reports WHERE category = 'electronics';
```

2. Ensure indexes exist:

```sql
SELECT indexname FROM pg_indexes WHERE tablename = 'reports';
```

3. Update statistics:

```sql
ANALYZE reports;
```

4. Consider vacuuming:

```sql
VACUUM ANALYZE reports;
```

---

## ⚡ **Performance Tips**

### Indexing Strategy

**Always index:**

- Foreign keys
- Columns in WHERE clauses
- Columns in JOIN conditions
- Columns in ORDER BY

**Example:**

```sql
CREATE INDEX idx_reports_category ON reports(category);
CREATE INDEX idx_reports_owner_id ON reports(owner_id);
```

---

### Query Optimization

**Bad:**

```sql
SELECT * FROM reports;  -- Returns all columns
```

**Good:**

```sql
SELECT id, title, category FROM reports LIMIT 100;  -- Specific columns, limited
```

---

**Bad:**

```sql
SELECT * FROM reports WHERE created_at::date = '2024-10-07';  -- Function on column
```

**Good:**

```sql
SELECT * FROM reports
WHERE created_at >= '2024-10-07'
AND created_at < '2024-10-08';  -- Range query
```

---

### Pagination

**Always use LIMIT and OFFSET:**

```sql
SELECT * FROM reports
ORDER BY created_at DESC
OFFSET 0 LIMIT 20;  -- First page

SELECT * FROM reports
ORDER BY created_at DESC
OFFSET 20 LIMIT 20;  -- Second page
```

---

### Using EXPLAIN ANALYZE

Check query performance:

```sql
EXPLAIN ANALYZE
SELECT * FROM reports
WHERE category = 'electronics'
AND status = 'approved';
```

Look for:

- **Seq Scan** (bad - full table scan)
- **Index Scan** (good - using index)
- **Execution Time** - should be under 100ms for most queries

---

### Connection Pooling

In application code (Python):

```python
from sqlalchemy.pool import QueuePool

engine = create_engine(
    database_url,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=0
)
```

---

### Regular Maintenance

**Weekly:**

```sql
VACUUM ANALYZE;
```

**Monthly:**

```sql
REINDEX DATABASE lostfound;
```

**Check for bloat:**

```sql
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## 📊 **Monitoring**

### Active Queries

```sql
SELECT
    pid,
    usename,
    state,
    query_start,
    LEFT(query, 100) AS query
FROM pg_stat_activity
WHERE datname = 'lostfound' AND state != 'idle';
```

---

### Slow Queries

```sql
SELECT
    query,
    calls,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

---

### Index Usage

```sql
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan AS times_used,
    pg_size_pretty(pg_relation_size(indexrelid::regclass)) AS size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

---

## 🔒 **Security Best Practices**

### Always Use Parameterized Queries

**In Python (psycopg3):**

```python
# Bad - SQL injection risk
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")

# Good - parameterized
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
```

---

### Grant Minimal Permissions

```sql
-- Application user should NOT have:
REVOKE DROP ON ALL TABLES IN SCHEMA public FROM lostfound;
REVOKE TRUNCATE ON ALL TABLES IN SCHEMA public FROM lostfound;

-- Application user SHOULD have:
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO lostfound;
```

---

### Use Transactions

```sql
BEGIN;

UPDATE users SET is_active = false WHERE id = 'user-id';
UPDATE reports SET status = 'removed' WHERE owner_id = 'user-id';

-- Check before committing
SELECT * FROM users WHERE id = 'user-id';

COMMIT;  -- or ROLLBACK; if something's wrong
```

---

## 📚 **Additional Resources**

- **PostgreSQL 18 Documentation:** https://www.postgresql.org/docs/18/
- **pgvector Guide:** https://github.com/pgvector/pgvector
- **PostGIS Documentation:** https://postgis.net/documentation/
- **pgAdmin Documentation:** https://www.pgadmin.org/docs/
- **SQL Performance:** https://use-the-index-luke.com/

---

## 🆘 **Getting Help**

1. **Check PostgreSQL logs:**

   - Windows: `C:\Program Files\PostgreSQL\18\data\log`
   - View in pgAdmin: **Tools** → **Server Status** → **Log**

2. **Review query execution plan:**

   ```sql
   EXPLAIN ANALYZE your_query_here;
   ```

3. **Check database status:**

   ```sql
   SELECT * FROM pg_stat_database WHERE datname = 'lostfound';
   ```

4. **Verify extensions:**
   ```sql
   SELECT extname, extversion FROM pg_extension;
   ```

---

## ✅ **Checklist: Fresh Installation**

- [ ] PostgreSQL 18 installed
- [ ] pgAdmin 4 installed and connected
- [ ] Database `lostfound` created
- [ ] Extensions installed (pgvector, PostGIS, pg_trgm)
- [ ] `PG18_01_SETUP.sql` executed successfully
- [ ] Alembic migrations completed (`alembic upgrade head`)
- [ ] `PG18_02_INDEXES.sql` executed
- [ ] `PG18_03_SEED_DATA.sql` executed
- [ ] Sample queries tested from `PG18_04_QUERIES.sql`
- [ ] API server running and connected to database
- [ ] First test user login successful

---

**Last Updated:** October 2024  
**PostgreSQL Version:** 18  
**Compatible with:** Windows 10/11, pgAdmin 4.x

---

**Ready to start querying! 🚀**
