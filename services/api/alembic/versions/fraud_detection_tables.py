"""Add fraud detection tables

Revision ID: fraud_detection_tables
Revises: bd48418a6fd3
Create Date: 2024-01-01 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'fraud_detection_tables'
down_revision = 'bd48418a6fd3'
branch_labels = None
depends_on = None


def upgrade():
    # Create fraud_detection_results table
    op.create_table('fraud_detection_results',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('report_id', sa.String(), nullable=False),
        sa.Column('risk_level', sa.String(), nullable=False),
        sa.Column('fraud_score', sa.Float(), nullable=False),
        sa.Column('confidence', sa.Float(), nullable=False),
        sa.Column('flags', sa.JSON(), nullable=True),
        sa.Column('details', sa.JSON(), nullable=True),
        sa.Column('model_version', sa.String(), nullable=False),
        sa.Column('is_reviewed', sa.Boolean(), nullable=True),
        sa.Column('is_confirmed_fraud', sa.Boolean(), nullable=True),
        sa.Column('reviewer_notes', sa.Text(), nullable=True),
        sa.Column('detected_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('reviewed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['report_id'], ['reports.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_fraud_detection_results_report_id'), 'fraud_detection_results', ['report_id'], unique=False)
    op.create_index(op.f('ix_fraud_detection_results_risk_level'), 'fraud_detection_results', ['risk_level'], unique=False)

    # Create fraud_patterns table
    op.create_table('fraud_patterns',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('pattern_type', sa.String(), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('weight', sa.Float(), nullable=False),
        sa.Column('regex_pattern', sa.Text(), nullable=True),
        sa.Column('keywords', sa.JSON(), nullable=True),
        sa.Column('conditions', sa.JSON(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('is_auto_enabled', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_fraud_patterns_pattern_type'), 'fraud_patterns', ['pattern_type'], unique=False)

    # Create fraud_detection_logs table
    op.create_table('fraud_detection_logs',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('report_id', sa.String(), nullable=False),
        sa.Column('detection_result_id', sa.String(), nullable=True),
        sa.Column('action_type', sa.String(), nullable=False),
        sa.Column('action_details', sa.JSON(), nullable=True),
        sa.Column('processing_time_ms', sa.Integer(), nullable=True),
        sa.Column('model_version', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['detection_result_id'], ['fraud_detection_results.id'], ),
        sa.ForeignKeyConstraint(['report_id'], ['reports.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_fraud_detection_logs_report_id'), 'fraud_detection_logs', ['report_id'], unique=False)

    # Insert default fraud patterns
    op.execute("""
        INSERT INTO fraud_patterns (id, pattern_type, description, weight, keywords, is_active, is_auto_enabled) VALUES
        ('pattern_1', 'suspicious_text', 'Contains suspicious keywords', 0.3, '["urgent", "reward", "cash", "money", "expensive", "valuable", "rare"]', true, true),
        ('pattern_2', 'duplicate_content', 'Similar content detected', 0.4, null, true, true),
        ('pattern_3', 'spam_patterns', 'Spam-like content patterns', 0.5, null, true, true),
        ('pattern_4', 'fake_contact', 'Suspicious contact information', 0.6, null, true, true),
        ('pattern_5', 'excessive_reward', 'Unusually high reward amount', 0.7, null, true, true),
        ('pattern_6', 'location_inconsistency', 'Location data inconsistencies', 0.4, null, true, true),
        ('pattern_7', 'rapid_posting', 'Rapid successive postings', 0.5, null, true, true),
        ('pattern_8', 'image_manipulation', 'Potential image manipulation', 0.6, null, true, true);
    """)


def downgrade():
    # Drop tables in reverse order
    op.drop_index(op.f('ix_fraud_detection_logs_report_id'), table_name='fraud_detection_logs')
    op.drop_table('fraud_detection_logs')
    
    op.drop_index(op.f('ix_fraud_patterns_pattern_type'), table_name='fraud_patterns')
    op.drop_table('fraud_patterns')
    
    op.drop_index(op.f('ix_fraud_detection_results_risk_level'), table_name='fraud_detection_results')
    op.drop_index(op.f('ix_fraud_detection_results_report_id'), table_name='fraud_detection_results')
    op.drop_table('fraud_detection_results')
