"""Add image_hash field to reports

Revision ID: 001_image_hash
Revises: 
Create Date: 2025-10-06 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '001_image_hash'
down_revision = '0002_core_tables'
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Add image_hash column to reports table."""
    # Add image_hash column
    op.add_column(
        'reports',
        sa.Column('image_hash', sa.String(length=32), nullable=True)
    )
    
    # Create index on image_hash for faster lookups
    op.create_index(
        'ix_reports_image_hash',
        'reports',
        ['image_hash'],
        unique=False
    )


def downgrade() -> None:
    """Remove image_hash column from reports table."""
    # Drop the index first
    op.drop_index('ix_reports_image_hash', table_name='reports')
    
    # Drop the column
    op.drop_column('reports', 'image_hash')
