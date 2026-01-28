from __future__ import annotations
from typing import Optional, List
"""Radar snapshot SQLAlchemy model."""

from datetime import datetime

from sqlalchemy import DateTime, Float, Index, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class RadarSnapshotModel(Base, TimestampMixin):
    """Radar snapshot model for storing radar image metadata."""

    __tablename__ = "radar_snapshots"

    id: Mapped[str] = mapped_column(String(100), primary_key=True)
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, index=True
    )
    url: Mapped[str] = mapped_column(Text, nullable=False)
    thumbnail_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Bounding box
    bbox_min_lon: Mapped[float] = mapped_column(Float, nullable=False)
    bbox_min_lat: Mapped[float] = mapped_column(Float, nullable=False)
    bbox_max_lon: Mapped[float] = mapped_column(Float, nullable=False)
    bbox_max_lat: Mapped[float] = mapped_column(Float, nullable=False)

    # Metadata
    resolution: Mapped[str] = mapped_column(String(20), default="1km")
    product_type: Mapped[str] = mapped_column(String(50), default="reflectivity")
    source: Mapped[str] = mapped_column(String(100), default="INMET")
    valid_until: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Additional metadata as JSON
    extra_data: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)

    __table_args__ = (
        Index("ix_radar_snapshots_timestamp_desc", timestamp.desc()),
        Index("ix_radar_snapshots_source", "source"),
    )
