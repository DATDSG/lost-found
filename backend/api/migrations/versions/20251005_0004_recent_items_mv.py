"""Add recent items materialized view (phase 1 performance)

Revision ID: recent_items_mv_001
Revises: performance_opt_001
Create Date: 2025-10-05 00:00:00

Notes:
- Uses CONCURRENTLY only on REFRESH (manual / scheduled), not creation.
- View is safe to drop/recreate; no business logic relies on it directly yet.
"""
from alembic import op

# revision identifiers, used by Alembic.
revision = 'recent_items_mv_001'
down_revision = 'performance_opt_001'
branch_labels = None
depends_on = None

CREATE_VIEW = """
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_recent_items AS
SELECT id,
       status,
       category,
       created_at,
       location_point
FROM items
WHERE is_deleted = FALSE
  AND created_at > (NOW() - INTERVAL '30 days');
"""

DROP_VIEW = "DROP MATERIALIZED VIEW IF EXISTS mv_recent_items;"

CREATE_INDEXES = [
    "CREATE INDEX IF NOT EXISTS idx_mv_recent_items_status_created_at ON mv_recent_items (status, created_at DESC);",
    "CREATE INDEX IF NOT EXISTS idx_mv_recent_items_category_created_at ON mv_recent_items (category, created_at DESC);"
]


def upgrade():
    op.execute(CREATE_VIEW)
    for stmt in CREATE_INDEXES:
        op.execute(stmt)


def downgrade():
    op.execute(DROP_VIEW)
