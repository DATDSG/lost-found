# Database Queries Collection

This directory contains comprehensive SQL queries for the Lost & Found application database.

## 📁 Query Files

### 1. Setup Queries (`01_setup_queries.sql`)

Database initialization and configuration queries.

**Contents:**

- Database and user creation
- Extension setup (pgvector, PostGIS, pg_trgm)
- Custom types (enums) creation
- Performance optimization settings
- Monitoring and logging setup
- Verification queries

**Usage:**

```bash
# Run as PostgreSQL superuser
psql -U postgres -f 01_setup_queries.sql

# Or with specific database
psql -U postgres -d lostfound -f 01_setup_queries.sql
```

### 2. Common Queries (`02_common_queries.sql`)

Frequently used queries for application features.

**Sections:**

- **User Queries**: Login, search, statistics
- **Report Queries**: CRUD operations, search, filters
- **Match Queries**: Find matches, rankings
- **Message/Conversation Queries**: Chat functionality
- **Notification Queries**: User notifications
- **Taxonomy Queries**: Categories and colors
- **Media Queries**: Image management
- **Audit Log Queries**: Activity tracking
- **Analytics Queries**: Dashboard statistics

**Use Cases:**

- Backend API implementations
- Feature development
- Testing and debugging
- Data exploration

### 3. Admin Queries (`03_admin_queries.sql`)

Administrative and moderation operations.

**Sections:**

- **User Management**: Activate/deactivate, role changes, bulk operations
- **Report Moderation**: Approve/reject reports, content review
- **Match Management**: Review matches, cleanup low-quality matches
- **Content Moderation**: Spam detection, flagged content
- **System Health**: Database monitoring, performance metrics
- **Audit Log Analysis**: Admin activity tracking
- **Data Cleanup**: Remove old data, orphaned records
- **Performance Optimization**: Vacuum, reindex, analyze
- **Export Queries**: CSV exports for reports

**Use Cases:**

- Admin panel functionality
- Moderation workflows
- Database maintenance
- System monitoring
- Bulk operations

### 4. Advanced Queries (`04_advanced_queries.sql`)

Complex queries for advanced features.

**Sections:**

- **Vector Similarity Search**: NLP-based semantic matching using pgvector
- **Geospatial Queries**: Location-based search using PostGIS
- **Image Similarity**: Perceptual hash matching
- **Multi-Signal Matching**: Combined scoring algorithm
- **Time-Series Analytics**: Trends and patterns over time
- **User Behavior Analytics**: Engagement, cohorts, retention
- **Category Analytics**: Popularity, success rates
- **Matching Performance**: Match quality analysis
- **Full-Text Search**: Advanced text search with ranking

**Use Cases:**

- Matching algorithm implementation
- Advanced search features
- Analytics dashboards
- Performance tuning
- Research and insights

## 🚀 Quick Start

### Prerequisites

1. **PostgreSQL 15+** installed
2. **Extensions installed**:

   - `pgvector` - Vector similarity search
   - `postgis` - Geospatial queries
   - `pg_trgm` - Fuzzy text matching
   - `uuid-ossp` - UUID generation

3. **Database created**: `lostfound`

### Installation Steps

```bash
# 1. Navigate to queries directory
cd data/queries

# 2. Run setup queries (as postgres superuser)
psql -U postgres < 01_setup_queries.sql

# 3. Verify setup
psql -U postgres -d lostfound -c "SELECT extname, extversion FROM pg_extension;"

# 4. Test common queries
psql -U lostfound -d lostfound < 02_common_queries.sql
```

## 📖 Query Examples

### Find Similar Reports (Vector Search)

```sql
-- Find reports with similar descriptions using NLP embeddings
SELECT
    r.id,
    r.title,
    1 - (r.embedding <=> (SELECT embedding FROM reports WHERE id = 'your-report-id')) AS similarity
FROM reports r
WHERE r.embedding IS NOT NULL
ORDER BY r.embedding <=> (SELECT embedding FROM reports WHERE id = 'your-report-id')
LIMIT 10;
```

### Location-Based Search (Geospatial)

```sql
-- Find reports within 5km radius
SELECT
    r.id,
    r.title,
    ST_Distance(
        r.location_point::geography,
        ST_SetSRID(ST_MakePoint(-122.4194, 37.7749), 4326)::geography
    ) / 1000 AS distance_km
FROM reports r
WHERE ST_DWithin(
    r.location_point::geography,
    ST_SetSRID(ST_MakePoint(-122.4194, 37.7749), 4326)::geography,
    5000
)
ORDER BY distance_km;
```

### Multi-Signal Matching

```sql
-- Combined score using text, category, geo, time signals
SELECT
    r.id,
    r.title,
    (
        text_score * 0.35 +
        category_score * 0.20 +
        geo_score * 0.20 +
        time_score * 0.15 +
        color_score * 0.10
    ) as overall_score
FROM candidate_matches
WHERE overall_score > 0.4
ORDER BY overall_score DESC;
```

### Dashboard Statistics

```sql
-- Quick stats for admin dashboard
SELECT
    (SELECT COUNT(*) FROM users WHERE is_active = true) as active_users,
    (SELECT COUNT(*) FROM reports WHERE status = 'approved') as approved_reports,
    (SELECT COUNT(*) FROM matches WHERE status = 'promoted') as successful_matches,
    (SELECT COUNT(*) FROM messages WHERE created_at > NOW() - INTERVAL '24 hours') as messages_today;
```

## 🔍 Query Patterns

### Pagination

```sql
-- Standard pagination pattern
SELECT * FROM reports
WHERE status = 'approved'
ORDER BY created_at DESC
OFFSET (page - 1) * page_size
LIMIT page_size;
```

### Search with Filters

```sql
-- Combined search and filters
SELECT * FROM reports
WHERE
    status = 'approved'
    AND (title ILIKE '%keyword%' OR description ILIKE '%keyword%')
    AND category = 'electronics'
    AND location_city = 'San Francisco'
ORDER BY created_at DESC;
```

### Aggregation with Filtering

```sql
-- Count with conditional aggregation
SELECT
    status,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE type = 'lost') as lost,
    COUNT(*) FILTER (WHERE type = 'found') as found
FROM reports
GROUP BY status;
```

## 🛠️ Development Tips

### Using Queries in Application

**Python (SQLAlchemy):**

```python
from sqlalchemy import text

# Execute raw query
result = db.execute(
    text("""
        SELECT * FROM reports
        WHERE category = :category
    """),
    {"category": "electronics"}
)
```

**Python (psycopg3):**

```python
async with pool.connection() as conn:
    async with conn.cursor() as cur:
        await cur.execute("""
            SELECT * FROM reports WHERE id = %s
        """, (report_id,))
        result = await cur.fetchone()
```

### Testing Queries

```bash
# Test a specific query
psql -U lostfound -d lostfound -c "SELECT COUNT(*) FROM users;"

# Run query from file
psql -U lostfound -d lostfound -f my_query.sql

# Output to CSV
psql -U lostfound -d lostfound -c "COPY (SELECT * FROM users) TO STDOUT WITH CSV HEADER" > users.csv
```

### Query Performance

```sql
-- Explain query plan
EXPLAIN ANALYZE
SELECT * FROM reports
WHERE category = 'electronics'
AND status = 'approved';

-- Check index usage
SELECT
    schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

## 📊 Query Performance Guidelines

### Best Practices

1. **Use Indexes**: Ensure frequently queried columns have indexes
2. **Limit Results**: Always use `LIMIT` for large result sets
3. **Avoid SELECT \***: Select only needed columns
4. **Use Prepared Statements**: Prevent SQL injection and improve performance
5. **Analyze Queries**: Use `EXPLAIN ANALYZE` to optimize slow queries

### Common Indexes

```sql
-- Text search
CREATE INDEX idx_reports_title ON reports USING gin(to_tsvector('english', title));

-- Geographic queries
CREATE INDEX idx_reports_location ON reports USING gist(location_point);

-- Vector similarity
CREATE INDEX idx_reports_embedding ON reports USING ivfflat(embedding vector_cosine_ops);

-- Foreign keys
CREATE INDEX idx_reports_owner_id ON reports(owner_id);
CREATE INDEX idx_matches_source_id ON matches(source_report_id);
```

### Query Optimization

```sql
-- Before optimization
SELECT * FROM reports WHERE owner_id = 'user-id';

-- After optimization (select specific columns, use index)
SELECT id, title, status, created_at
FROM reports
WHERE owner_id = 'user-id'
ORDER BY created_at DESC
LIMIT 20;
```

## 🔒 Security Considerations

### Parameterized Queries

**Bad (SQL Injection Risk):**

```sql
SELECT * FROM users WHERE email = 'user@example.com';
```

**Good (Parameterized):**

```python
# Python
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))

# JavaScript/Node.js
client.query("SELECT * FROM users WHERE email = $1", [email])
```

### Permission Control

```sql
-- Grant minimal permissions
GRANT SELECT, INSERT, UPDATE ON reports TO lostfound;
GRANT SELECT ON categories TO lostfound;

-- Revoke dangerous permissions
REVOKE DELETE ON users FROM lostfound;
```

## 📈 Monitoring Queries

### Active Queries

```sql
-- See currently running queries
SELECT
    pid,
    usename,
    application_name,
    state,
    query_start,
    query
FROM pg_stat_activity
WHERE datname = 'lostfound' AND state != 'idle';
```

### Slow Queries

```sql
-- Find slow queries (requires pg_stat_statements)
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'lostfound')
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### Database Size

```sql
-- Check database and table sizes
SELECT
    pg_size_pretty(pg_database_size('lostfound')) as db_size,
    (SELECT COUNT(*) FROM reports) as report_count,
    (SELECT pg_size_pretty(pg_total_relation_size('reports'))) as reports_table_size;
```

## 🐛 Troubleshooting

### Common Issues

**Issue: Slow vector similarity search**

```sql
-- Create IVFFlat index for faster vector search
CREATE INDEX idx_reports_embedding ON reports
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
```

**Issue: Slow geospatial queries**

```sql
-- Create spatial index
CREATE INDEX idx_reports_location ON reports
USING gist(location_point);

-- Analyze table
ANALYZE reports;
```

**Issue: Missing indexes**

```sql
-- Find missing indexes
SELECT
    schemaname, tablename, attname
FROM pg_stats
WHERE schemaname = 'public'
  AND n_distinct > 100
  AND correlation < 0.1;
```

## 📝 Notes

- All queries assume PostgreSQL 15+ with required extensions
- Replace placeholder values (e.g., `'user-uuid-here'`) with actual values
- Test queries on development database before running in production
- Use transactions for bulk operations
- Always backup database before running destructive queries

## 🔗 Related Documentation

- [Database Setup Guide](../DATABASE_SETUP.md)
- [API Endpoints](../../API_ENDPOINTS.md)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [pgvector Documentation](https://github.com/pgvector/pgvector)
- [PostGIS Documentation](https://postgis.net/documentation/)

## 📞 Support

For issues or questions about database queries:

1. Check PostgreSQL logs
2. Review query execution plans with `EXPLAIN ANALYZE`
3. Consult the documentation files
4. Check application logs for error details

---

**Last Updated:** 2024  
**PostgreSQL Version:** 15+  
**Required Extensions:** pgvector, PostGIS, pg_trgm, uuid-ossp
