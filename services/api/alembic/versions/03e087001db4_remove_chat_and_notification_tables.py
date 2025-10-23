"""remove_chat_and_notification_tables

Revision ID: 03e087001db4
Revises: bd48418a6fd3
Create Date: 2025-10-20 20:06:11.139605

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '03e087001db4'
down_revision: Union[str, None] = 'bd48418a6fd3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Drop chat and notification related tables using raw SQL with IF EXISTS
    connection = op.get_bind()
    
    # Drop indexes if they exist
    connection.execute(sa.text("DROP INDEX IF EXISTS ix_notifications_created_at"))
    connection.execute(sa.text("DROP INDEX IF EXISTS ix_notifications_is_read"))
    connection.execute(sa.text("DROP INDEX IF EXISTS ix_notifications_user_id"))
    connection.execute(sa.text("DROP INDEX IF EXISTS ix_messages_sender_id"))
    connection.execute(sa.text("DROP INDEX IF EXISTS ix_messages_conversation_id"))
    connection.execute(sa.text("DROP INDEX IF EXISTS ix_conversations_match_id"))
    
    # Drop tables if they exist
    connection.execute(sa.text("DROP TABLE IF EXISTS notifications CASCADE"))
    connection.execute(sa.text("DROP TABLE IF EXISTS messages CASCADE"))
    connection.execute(sa.text("DROP TABLE IF EXISTS conversations CASCADE"))


def downgrade() -> None:
    # Recreate conversations table
    op.create_table('conversations',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('match_id', sa.String(), nullable=True),
        sa.Column('participant_one_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('participant_two_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['match_id'], ['matches.id'], ),
        sa.ForeignKeyConstraint(['participant_one_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['participant_two_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_conversations_match_id'), 'conversations', ['match_id'], unique=False)
    
    # Recreate messages table
    op.create_table('messages',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('conversation_id', sa.String(), nullable=False),
        sa.Column('sender_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('is_read', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['conversation_id'], ['conversations.id'], ),
        sa.ForeignKeyConstraint(['sender_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_messages_conversation_id'), 'messages', ['conversation_id'], unique=False)
    op.create_index(op.f('ix_messages_sender_id'), 'messages', ['sender_id'], unique=False)
    
    # Recreate notifications table
    op.create_table('notifications',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('type', sa.String(), nullable=False),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('content', sa.Text(), nullable=True),
        sa.Column('reference_id', sa.String(), nullable=True),
        sa.Column('is_read', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_notifications_user_id'), 'notifications', ['user_id'], unique=False)
    op.create_index(op.f('ix_notifications_is_read'), 'notifications', ['is_read'], unique=False)
    op.create_index(op.f('ix_notifications_created_at'), 'notifications', ['created_at'], unique=False)
