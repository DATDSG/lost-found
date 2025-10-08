"""Add vector and geometry columns to reports table

Revision ID: 0003_vector_geo
Revises: 001_image_hash
Create Date: 2025-10-06
"""
from alembic import op
import sqlalchemy as sa

revision = '0003_vector_geo'
down_revision = '001_image_hash'
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Replace placeholder columns with proper vector and geometry types."""
    conn = op.get_bind()
    
    # Check if PostGIS is available
    postgis_available = False
    try:
        result = conn.execute(sa.text("SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'postgis')"))
        postgis_available = result.scalar()
    except Exception:
        pass
    
    # Replace TEXT geo column with proper geometry if PostGIS is available
    if postgis_available:
        op.execute("""
            ALTER TABLE reports 
            ALTER COLUMN geo TYPE geometry(Point,4326) 
            USING CASE 
                WHEN geo IS NOT NULL AND geo != '' THEN ST_GeomFromText(geo, 4326)
                ELSE NULL 
            END
        """)
        # Create spatial index
        op.execute("CREATE INDEX IF NOT EXISTS ix_reports_geo ON reports USING GIST (geo)")
    
    # Replace BYTEA embedding column with vector type
    op.execute("ALTER TABLE reports DROP COLUMN IF EXISTS embedding")
    op.execute("ALTER TABLE reports ADD COLUMN embedding vector(384)")
    
    # Create vector index for similarity search (using HNSW for better performance)
    op.execute("CREATE INDEX IF NOT EXISTS ix_reports_embedding ON reports USING hnsw (embedding vector_cosine_ops)")


def downgrade() -> None:
    """Revert to placeholder column types."""
    conn = op.get_bind()
    
    # Check if PostGIS is available
    postgis_available = False
    try:
        result = conn.execute(sa.text("SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'postgis')"))
        postgis_available = result.scalar()
    except Exception:
        pass
    
    # Drop indexes
    op.execute("DROP INDEX IF EXISTS ix_reports_embedding")
    if postgis_available:
        op.execute("DROP INDEX IF EXISTS ix_reports_geo")
    
    # Revert embedding to BYTEA
    op.execute("ALTER TABLE reports DROP COLUMN IF EXISTS embedding")
    op.execute("ALTER TABLE reports ADD COLUMN embedding BYTEA")
    
    # Revert geo to TEXT if PostGIS is available
    if postgis_available:
        op.execute("""
            ALTER TABLE reports 
            ALTER COLUMN geo TYPE TEXT 
            USING CASE 
                WHEN geo IS NOT NULL THEN ST_AsText(geo)
                ELSE NULL 
            END
        """)
    else:
        # If PostGIS wasn't available, column is already TEXT
        pass
