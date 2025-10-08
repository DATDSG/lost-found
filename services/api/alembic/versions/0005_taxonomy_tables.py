"""Add categories and colors taxonomy tables

Revision ID: 0005_taxonomy_tables
Revises: 0004_schema_improvements
Create Date: 2025-10-07
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '0005_taxonomy_tables'
down_revision = '0004_schema_improvements'
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create taxonomy tables for categories and colors."""
    
    # Create categories table
    op.create_table(
        'categories',
        sa.Column('id', sa.String(64), primary_key=True),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('icon', sa.String(50), nullable=True),
        sa.Column('sort_order', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
    )
    
    # Create colors table
    op.create_table(
        'colors',
        sa.Column('id', sa.String(32), primary_key=True),
        sa.Column('name', sa.String(50), nullable=False),
        sa.Column('hex_code', sa.String(7), nullable=True),
        sa.Column('sort_order', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
    )
    
    # Insert default categories
    op.execute("""
        INSERT INTO categories (id, name, icon, sort_order, is_active) VALUES
        ('electronics', 'Electronics', '📱', 1, true),
        ('accessories', 'Accessories', '👜', 2, true),
        ('jewelry', 'Jewelry', '💍', 3, true),
        ('documents', 'Documents', '📄', 4, true),
        ('keys', 'Keys', '🔑', 5, true),
        ('wallets', 'Wallets & Bags', '👛', 6, true),
        ('clothing', 'Clothing', '👕', 7, true),
        ('pets', 'Pets', '🐕', 8, true),
        ('vehicles', 'Vehicles', '🚗', 9, true),
        ('sports', 'Sports Equipment', '⚽', 10, true),
        ('books', 'Books & Media', '📚', 11, true),
        ('toys', 'Toys', '🧸', 12, true),
        ('musical', 'Musical Instruments', '🎸', 13, true),
        ('medical', 'Medical Items', '💊', 14, true),
        ('other', 'Other', '📦', 99, true)
    """)
    
    # Insert default colors
    op.execute("""
        INSERT INTO colors (id, name, hex_code, sort_order, is_active) VALUES
        ('black', 'Black', '#000000', 1, true),
        ('white', 'White', '#FFFFFF', 2, true),
        ('gray', 'Gray', '#808080', 3, true),
        ('silver', 'Silver', '#C0C0C0', 4, true),
        ('red', 'Red', '#FF0000', 5, true),
        ('pink', 'Pink', '#FFC0CB', 6, true),
        ('orange', 'Orange', '#FFA500', 7, true),
        ('yellow', 'Yellow', '#FFFF00', 8, true),
        ('gold', 'Gold', '#FFD700', 9, true),
        ('green', 'Green', '#008000', 10, true),
        ('blue', 'Blue', '#0000FF', 11, true),
        ('navy', 'Navy', '#000080', 12, true),
        ('purple', 'Purple', '#800080', 13, true),
        ('brown', 'Brown', '#8B4513', 14, true),
        ('beige', 'Beige', '#F5F5DC', 15, true),
        ('multicolor', 'Multicolor', NULL, 16, true)
    """)
    
    # Create indexes
    op.create_index('ix_categories_active_sort', 'categories', ['is_active', 'sort_order'])
    op.create_index('ix_colors_active_sort', 'colors', ['is_active', 'sort_order'])


def downgrade() -> None:
    """Drop taxonomy tables."""
    op.drop_index('ix_colors_active_sort', table_name='colors')
    op.drop_index('ix_categories_active_sort', table_name='categories')
    op.drop_table('colors')
    op.drop_table('categories')
