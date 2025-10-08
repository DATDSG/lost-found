"""Enable PostGIS and pgvector extensions

Revision ID: 0001_enable_extensions
Revises: 
Create Date: 2025-10-06
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '0001_enable_extensions'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    # Enable pgvector (required)
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")
    
    # Try to enable PostGIS (optional - may not be available in pgvector image)
    conn = op.get_bind()
    try:
        conn.execute(sa.text("SAVEPOINT before_postgis"))
        conn.execute(sa.text("CREATE EXTENSION IF NOT EXISTS postgis"))
        conn.execute(sa.text("RELEASE SAVEPOINT before_postgis"))
    except Exception as e:
        conn.execute(sa.text("ROLLBACK TO SAVEPOINT before_postgis"))
        print(f"Warning: PostGIS extension not available: {e}")
        print("Skipping PostGIS - geographic features will not be available")


def downgrade() -> None:
    # Typically leave extensions; for symmetry we can drop (commented out to avoid data loss)
    # op.execute("DROP EXTENSION IF EXISTS vector")
    # op.execute("DROP EXTENSION IF EXISTS postgis")
    pass
