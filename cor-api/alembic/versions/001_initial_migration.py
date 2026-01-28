"""Initial migration - create tables

Revision ID: 001
Revises:
Create Date: 2024-01-01 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
import geoalchemy2

# revision identifiers, used by Alembic.
revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Enable PostGIS extension
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")

    # Create rain_gauges table
    op.create_table(
        "rain_gauges",
        sa.Column("id", sa.String(50), primary_key=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("latitude", sa.Float, nullable=False),
        sa.Column("longitude", sa.Float, nullable=False),
        sa.Column("altitude_m", sa.Float, nullable=True),
        sa.Column("neighborhood", sa.String(255), nullable=True),
        sa.Column("region", sa.String(100), nullable=True),
        sa.Column("status", sa.String(50), server_default="active"),
        sa.Column(
            "geom",
            geoalchemy2.Geometry(geometry_type="POINT", srid=4326),
            nullable=True,
        ),
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
    op.create_index(
        "ix_rain_gauges_geom",
        "rain_gauges",
        ["geom"],
        postgresql_using="gist",
    )
    op.create_index("ix_rain_gauges_status", "rain_gauges", ["status"])

    # Create rain_gauge_readings table
    op.create_table(
        "rain_gauge_readings",
        sa.Column("id", sa.Integer, primary_key=True, autoincrement=True),
        sa.Column(
            "station_id",
            sa.String(50),
            sa.ForeignKey("rain_gauges.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False),
        sa.Column("value_mm", sa.Float, nullable=False),
        sa.Column("accumulated_15min", sa.Float, nullable=True),
        sa.Column("accumulated_1h", sa.Float, nullable=True),
        sa.Column("accumulated_24h", sa.Float, nullable=True),
        sa.Column("intensity", sa.String(50), server_default="none"),
    )
    op.create_index(
        "ix_readings_station_timestamp",
        "rain_gauge_readings",
        ["station_id", "timestamp"],
    )
    op.create_index("ix_readings_timestamp", "rain_gauge_readings", ["timestamp"])

    # Create incidents table
    op.create_table(
        "incidents",
        sa.Column("id", sa.String(100), primary_key=True),
        sa.Column("type", sa.String(50), nullable=False),
        sa.Column("severity", sa.String(20), server_default="medium"),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("title", sa.String(500), nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column(
            "geom",
            geoalchemy2.Geometry(geometry_type="GEOMETRY", srid=4326),
            nullable=True,
        ),
        sa.Column("location_data", postgresql.JSONB, nullable=True),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("source", sa.String(100), server_default="COR"),
        sa.Column("affected_routes", postgresql.ARRAY(sa.String(100)), nullable=True),
        sa.Column("tags", postgresql.ARRAY(sa.String(50)), nullable=True),
        sa.Column("raw_data", postgresql.JSONB, nullable=True),
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
    op.create_index(
        "ix_incidents_geom",
        "incidents",
        ["geom"],
        postgresql_using="gist",
    )
    op.create_index("ix_incidents_type", "incidents", ["type"])
    op.create_index("ix_incidents_status", "incidents", ["status"])
    op.create_index("ix_incidents_severity", "incidents", ["severity"])
    op.create_index("ix_incidents_started_at", "incidents", ["started_at"])
    op.create_index("ix_incidents_type_status", "incidents", ["type", "status"])

    # Create radar_snapshots table
    op.create_table(
        "radar_snapshots",
        sa.Column("id", sa.String(100), primary_key=True),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False),
        sa.Column("url", sa.Text, nullable=False),
        sa.Column("thumbnail_url", sa.Text, nullable=True),
        sa.Column("bbox_min_lon", sa.Float, nullable=False),
        sa.Column("bbox_min_lat", sa.Float, nullable=False),
        sa.Column("bbox_max_lon", sa.Float, nullable=False),
        sa.Column("bbox_max_lat", sa.Float, nullable=False),
        sa.Column("resolution", sa.String(20), server_default="1km"),
        sa.Column("product_type", sa.String(50), server_default="reflectivity"),
        sa.Column("source", sa.String(100), server_default="INMET"),
        sa.Column("valid_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("extra_data", postgresql.JSONB, nullable=True),
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
    op.create_index("ix_radar_snapshots_timestamp", "radar_snapshots", ["timestamp"])
    op.create_index("ix_radar_snapshots_source", "radar_snapshots", ["source"])


def downgrade() -> None:
    op.drop_table("radar_snapshots")
    op.drop_table("incidents")
    op.drop_table("rain_gauge_readings")
    op.drop_table("rain_gauges")
    op.execute("DROP EXTENSION IF EXISTS postgis")
