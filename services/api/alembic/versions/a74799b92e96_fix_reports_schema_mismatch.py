"""fix_reports_schema_mismatch

Revision ID: a74799b92e96
Revises: 03e087001db4
Create Date: 2025-10-20 22:39:33.984757

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from pgvector.sqlalchemy import Vector


# revision identifiers, used by Alembic.
revision: str = 'a74799b92e96'
down_revision: Union[str, None] = '03e087001db4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add missing columns that the API model expects
    op.add_column('reports', sa.Column('images', postgresql.ARRAY(sa.String()), nullable=True))
    op.add_column('reports', sa.Column('image_hashes', postgresql.ARRAY(sa.String()), nullable=True))
    
    # Add text_embedding column and copy data from embedding
    op.add_column('reports', sa.Column('text_embedding', Vector(384), nullable=True))
    op.execute("UPDATE reports SET text_embedding = embedding WHERE embedding IS NOT NULL")
    
    # Drop the old columns
    op.drop_column('reports', 'embedding')
    op.drop_column('reports', 'image_hash')


def downgrade() -> None:
    # Restore the old schema
    op.add_column('reports', sa.Column('image_hash', sa.String(32), nullable=True))
    op.add_column('reports', sa.Column('embedding', Vector(384), nullable=True))
    
    # Drop the new columns
    op.drop_column('reports', 'text_embedding')
    op.drop_column('reports', 'image_hashes')
    op.drop_column('reports', 'images')
