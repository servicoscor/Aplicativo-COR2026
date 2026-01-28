"""Add read_at to alert_deliveries

Revision ID: 004
Revises: 003
Create Date: 2025-01-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "004"
down_revision: Union[str, None] = "003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add read_at column to alert_deliveries
    op.add_column(
        "alert_deliveries",
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
    )

    # Create composite index for efficient inbox queries
    op.create_index(
        "ix_alert_deliveries_device_read",
        "alert_deliveries",
        ["device_id", "read_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_alert_deliveries_device_read", table_name="alert_deliveries")
    op.drop_column("alert_deliveries", "read_at")
