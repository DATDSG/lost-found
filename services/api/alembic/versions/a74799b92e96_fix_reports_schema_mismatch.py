"""fix_reports_schema_mismatch

Revision ID: a74799b92e96
Revises: 03e087001db4
Create Date: 2025-10-20 22:39:33.984757

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a74799b92e96'
down_revision: Union[str, None] = '03e087001db4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
