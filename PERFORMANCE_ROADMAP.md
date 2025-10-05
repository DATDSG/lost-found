# Performance & Scalability Roadmap

This document expands upon the brief roadmap in the main README, adding rationale, data modeling considerations, and phased roll‑out guidance.

## Guiding Principles

1. Protect OLTP latency first – heavy analytics and refresh operations must never block primary writes.
2. Prefer incremental / append-only structures where possible to minimize rewrite cost.
3. Make performance changes observable: add metrics & logging around cache hit ratio, match latency, queue depth.
4. Only introduce ML / vector layers when baseline filters are already efficient.

## Phase 0 (Current Baseline)

- Composite & geospatial indexes on core item filters (status, created_at, geohash, owner_id)
- Trigram/text indexes (planned) for fuzzy title/description search
- Matching pipeline executes synchronously via background task trigger + DB queries

## Phase 1 – Read Query Acceleration

| Component       | Action                                               | Notes                                            |
| --------------- | ---------------------------------------------------- | ------------------------------------------------ |
| Recent Items    | Materialized view `mv_recent_items`                  | 30‑day sliding window; CONCURRENT refresh        |
| User Item Lists | Covering index `(owner_id, status, created_at DESC)` | Already partially covered; ensure matching order |
| Search          | Add functional index on lower(title)                 | For case-insensitive prefix search               |
| Counts / Badges | Cached counters in Redis                             | Invalidate on item write                         |

Materialized view template:

```sql
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_recent_items AS
SELECT id, status, category, created_at, location_point
FROM items
WHERE is_deleted = FALSE
  AND created_at > (NOW() - INTERVAL '30 days');

-- Add index for fast geospatial + status filtering
CREATE INDEX IF NOT EXISTS idx_mv_recent_items_status_created_at
  ON mv_recent_items (status, created_at DESC);

-- Refresh pattern (cron / Celery beat)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_recent_items;
```

## Phase 2 – Matching Throughput

| Goal                  | Strategy                                   | Detail                                            |
| --------------------- | ------------------------------------------ | ------------------------------------------------- |
| Reduce candidate scan | Pre-bucket items by `(geohash6, category)` | Auxiliary table or Redis sorted sets              |
| Asynchronous scoring  | Decouple matching from item creation path  | Queue scoring job; optimistic initial score set   |
| Attribute weighting   | Persist normalized feature vectors         | JSONB or separate table for numeric weight inputs |

Auxiliary bucket table:

```sql
CREATE TABLE IF NOT EXISTS item_buckets (
  geohash6 varchar(12) NOT NULL,
  category varchar(100) NOT NULL,
  item_id bigint NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (geohash6, category, item_id)
);
CREATE INDEX IF NOT EXISTS idx_item_buckets_recent ON item_buckets (created_at DESC);
```

## Phase 3 – Semantic & Vector Search

| Component       | Action                             | Notes                                             |
| --------------- | ---------------------------------- | ------------------------------------------------- |
| Text Embeddings | pgvector extension                 | store 384-dim (or smaller) normalized vectors     |
| Hybrid Query    | Boolean + ANN                      | Filter by category/geohash then vector similarity |
| Refresh         | On item update (description/title) | Re-embed only changed records                     |

Example pgvector integration:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
ALTER TABLE items ADD COLUMN IF NOT EXISTS text_embedding vector(384);
CREATE INDEX IF NOT EXISTS idx_items_embedding_ivfflat ON items USING ivfflat (text_embedding vector_cosine_ops) WITH (lists = 100);
```

## Phase 4 – Partitioning & Archival

| Table      | Partition Key                            | Rationale                     |
| ---------- | ---------------------------------------- | ----------------------------- |
| audit_logs | by month (created_at)                    | Large append-only table       |
| matches    | by month or status                       | Retire old match computations |
| items      | by year (created_at) [only if >50M rows] | Defer until clearly needed    |

Archival flow: move partitions older than retention window to cheaper storage (S3 parquet) via batch job.

## Phase 5 – Advanced Caching / CQRS

| Aspect                    | Strategy                                                |
| ------------------------- | ------------------------------------------------------- |
| Hot lookups               | Redis hash of item public projection                    |
| Read model                | Separate denormalized projection for mobile feed (CQRS) |
| Event sourcing (optional) | Capture item lifecycle events for analytics             |

## Observability Enhancements

Add metrics (Prometheus):

- `matching_job_duration_seconds`
- `item_search_latency_seconds`
- `cache_hit_ratio`
- `db_connection_usage`
- `embedding_refresh_queue_depth`

Alerting thresholds:

- Match job p95 > 2s
- Cache hit ratio < 0.6 sustained
- DB connection usage > 85%

## Rollback Strategy

Each phase introduces additive structures. Rollback is safe by:

1. Stop writers to auxiliary structure.
2. Drop or detach new indexes/materialized views.
3. Remove feature flags pointing to new paths.

## Suggested Next Immediate Tasks

1. Add simple materialized view + refresh job (Phase 1).
2. Introduce bucket table & population trigger (Phase 2 partial).
3. Instrument Prometheus counters around matching.

---

Document version: 2025-10-05
