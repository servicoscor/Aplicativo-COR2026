from __future__ import annotations
"""Rain gauge SQLAlchemy models."""

from datetime import datetime
from typing import Optional, List

from geoalchemy2 import Geometry
from sqlalchemy import DateTime, Float, ForeignKey, Index, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin


class RainGaugeModel(Base, TimestampMixin):
    """Rain gauge station model."""

    __tablename__ = "rain_gauges"

    id: Mapped[str] = mapped_column(String(50), primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    altitude_m: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    neighborhood: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    region: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    status: Mapped[str] = mapped_column(String(50), default="active")

    # PostGIS geometry column for spatial queries
    geom: Mapped[Geometry] = mapped_column(
        Geometry(geometry_type="POINT", srid=4326),
        nullable=True,
    )

    # Relationships
    readings: Mapped[List["RainGaugeReadingModel"]] = relationship(
        "RainGaugeReadingModel",
        back_populates="station",
        cascade="all, delete-orphan",
        order_by="desc(RainGaugeReadingModel.timestamp)",
    )

    __table_args__ = (
        Index("ix_rain_gauges_geom", "geom", postgresql_using="gist"),
        Index("ix_rain_gauges_status", "status"),
    )


class RainGaugeReadingModel(Base):
    """Rain gauge reading model."""

    __tablename__ = "rain_gauge_readings"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    station_id: Mapped[str] = mapped_column(
        String(50),
        ForeignKey("rain_gauges.id", ondelete="CASCADE"),
        nullable=False,
    )
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    value_mm: Mapped[float] = mapped_column(Float, nullable=False)
    accumulated_15min: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    accumulated_1h: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    accumulated_24h: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    intensity: Mapped[str] = mapped_column(String(50), default="none")

    # Relationships
    station: Mapped["RainGaugeModel"] = relationship(
        "RainGaugeModel", back_populates="readings"
    )

    __table_args__ = (
        Index("ix_readings_station_timestamp", "station_id", "timestamp"),
        Index("ix_readings_timestamp", "timestamp"),
    )
