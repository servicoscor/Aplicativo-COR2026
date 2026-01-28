from __future__ import annotations
from typing import Optional, List
"""Incident SQLAlchemy model."""

from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import DateTime, Index, String, Text
from sqlalchemy.dialects.postgresql import ARRAY, JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class IncidentModel(Base, TimestampMixin):
    """Incident model for storing city incidents."""

    __tablename__ = "incidents"

    id: Mapped[str] = mapped_column(String(100), primary_key=True)
    type: Mapped[str] = mapped_column(String(50), nullable=False)
    severity: Mapped[str] = mapped_column(String(20), default="medium")
    status: Mapped[str] = mapped_column(String(30), nullable=False)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # GeoJSON geometry stored as PostGIS geometry
    # Can be Point, LineString, or Polygon
    geom: Mapped[Geometry] = mapped_column(
        Geometry(geometry_type="GEOMETRY", srid=4326),
        nullable=True,
    )

    # Location details as JSON
    location_data: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)

    # Timestamps
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    resolved_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Source and metadata
    source: Mapped[str] = mapped_column(String(100), default="COR")
    affected_routes: Mapped[Optional[List[str]]] = mapped_column(
        ARRAY(String(100)), nullable=True
    )
    tags: Mapped[Optional[List[str]]] = mapped_column(
        ARRAY(String(50)), nullable=True
    )

    # Raw data for debugging/auditing
    raw_data: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)

    __table_args__ = (
        Index("ix_incidents_geom", "geom", postgresql_using="gist"),
        Index("ix_incidents_type", "type"),
        Index("ix_incidents_status", "status"),
        Index("ix_incidents_severity", "severity"),
        Index("ix_incidents_started_at", "started_at"),
        Index("ix_incidents_type_status", "type", "status"),
    )
