"""Add alerts and devices tables

Revision ID: 002
Revises: 001
Create Date: 2024-01-15 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
import geoalchemy2

# revision identifiers, used by Alembic.
revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create enum types
    op.execute("CREATE TYPE alert_severity AS ENUM ('info', 'alert', 'emergency')")
    op.execute("CREATE TYPE alert_status AS ENUM ('draft', 'sent', 'canceled')")
    op.execute("CREATE TYPE device_platform AS ENUM ('ios', 'android')")

    # Create devices table
    op.create_table(
        "devices",
        sa.Column("id", sa.String(100), primary_key=True),
        sa.Column(
            "platform",
            postgresql.ENUM("ios", "android", name="device_platform", create_type=False),
            nullable=False,
        ),
        sa.Column("push_token", sa.String(500), unique=True, nullable=False),
        sa.Column(
            "last_location",
            geoalchemy2.Geometry(geometry_type="POINT", srid=4326),
            nullable=True,
        ),
        sa.Column("last_location_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("neighborhoods", postgresql.ARRAY(sa.String(100)), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            onupdate=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("ix_devices_push_token", "devices", ["push_token"])
    op.create_index(
        "ix_devices_last_location",
        "devices",
        ["last_location"],
        postgresql_using="gist",
    )
    op.create_index("ix_devices_platform", "devices", ["platform"])
    op.create_index(
        "ix_devices_neighborhoods",
        "devices",
        ["neighborhoods"],
        postgresql_using="gin",
    )

    # Create alerts table
    op.create_table(
        "alerts",
        sa.Column("id", sa.String(100), primary_key=True),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("body", sa.Text, nullable=False),
        sa.Column(
            "severity",
            postgresql.ENUM("info", "alert", "emergency", name="alert_severity", create_type=False),
            server_default="info",
            nullable=False,
        ),
        sa.Column(
            "status",
            postgresql.ENUM("draft", "sent", "canceled", name="alert_status", create_type=False),
            server_default="draft",
            nullable=False,
        ),
        sa.Column("broadcast", sa.Boolean, server_default="false", nullable=False),
        sa.Column("neighborhoods", postgresql.ARRAY(sa.String(100)), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_by", sa.String(100), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            onupdate=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("ix_alerts_status", "alerts", ["status"])
    op.create_index("ix_alerts_severity", "alerts", ["severity"])
    op.create_index("ix_alerts_sent_at", "alerts", ["sent_at"])
    op.create_index("ix_alerts_expires_at", "alerts", ["expires_at"])
    op.create_index("ix_alerts_broadcast", "alerts", ["broadcast"])

    # Create alert_areas table
    op.create_table(
        "alert_areas",
        sa.Column("id", sa.String(100), primary_key=True),
        sa.Column(
            "alert_id",
            sa.String(100),
            sa.ForeignKey("alerts.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "geom",
            geoalchemy2.Geometry(geometry_type="MULTIPOLYGON", srid=4326),
            nullable=False,
        ),
    )
    op.create_index(
        "ix_alert_areas_geom",
        "alert_areas",
        ["geom"],
        postgresql_using="gist",
    )
    op.create_index("ix_alert_areas_alert_id", "alert_areas", ["alert_id"])

    # Create alert_deliveries table
    op.create_table(
        "alert_deliveries",
        sa.Column("id", sa.Integer, primary_key=True, autoincrement=True),
        sa.Column(
            "alert_id",
            sa.String(100),
            sa.ForeignKey("alerts.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "device_id",
            sa.String(100),
            sa.ForeignKey("devices.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("provider_status", sa.String(50), server_default="pending", nullable=False),
        sa.Column("error_message", sa.Text, nullable=True),
    )
    op.create_index("ix_alert_deliveries_alert_id", "alert_deliveries", ["alert_id"])
    op.create_index("ix_alert_deliveries_device_id", "alert_deliveries", ["device_id"])
    op.create_index("ix_alert_deliveries_sent_at", "alert_deliveries", ["sent_at"])


def downgrade() -> None:
    op.drop_table("alert_deliveries")
    op.drop_table("alert_areas")
    op.drop_table("alerts")
    op.drop_table("devices")

    op.execute("DROP TYPE IF EXISTS device_platform")
    op.execute("DROP TYPE IF EXISTS alert_status")
    op.execute("DROP TYPE IF EXISTS alert_severity")
