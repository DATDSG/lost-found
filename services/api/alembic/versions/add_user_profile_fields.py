"""Add additional user profile fields

Revision ID: add_user_profile_fields
Revises: 03e087001db4
Create Date: 2025-01-22 20:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'add_user_profile_fields'
down_revision = '03e087001db4'
branch_labels = None
depends_on = None


def upgrade():
    # Add new columns to users table
    op.add_column('users', sa.Column('bio', sa.Text(), nullable=True))
    op.add_column('users', sa.Column('location', sa.String(length=100), nullable=True))
    op.add_column('users', sa.Column('gender', sa.String(length=20), nullable=True))
    op.add_column('users', sa.Column('date_of_birth', sa.DateTime(), nullable=True))


def downgrade():
    # Remove the added columns
    op.drop_column('users', 'date_of_birth')
    op.drop_column('users', 'gender')
    op.drop_column('users', 'location')
    op.drop_column('users', 'bio')
