from __future__ import annotations
from typing import Optional, List
"""Alert SQLAlchemy models."""

from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Index, String, Text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin


class AlertModel(Base, TimestampMixin):
    """Alert model for storing alerts."""

    __tablename__ = "alerts"

    id: Mapped[str] = mapped_column(String(100), primary_key=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    severity: Mapped[str] = mapped_column(
        Enum("info", "alert", "emergency", name="alert_severity"),
        default="info",
        nullable=False,
    )
    status: Mapped[str] = mapped_column(
        Enum("draft", "sent", "canceled", name="alert_status"),
        default="draft",
        nullable=False,
    )
    broadcast: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    neighborhoods: Mapped[Optional[List[str]]] = mapped_column(
        ARRAY(String(100)), nullable=True
    )
    expires_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    sent_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_by: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)

    # Relationships
    areas: Mapped[List["AlertAreaModel"]] = relationship(
        "AlertAreaModel",
        back_populates="alert",
        cascade="all, delete-orphan",
    )
    deliveries: Mapped[List["AlertDeliveryModel"]] = relationship(
        "AlertDeliveryModel",
        back_populates="alert",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        Index("ix_alerts_status", "status"),
        Index("ix_alerts_severity", "severity"),
        Index("ix_alerts_sent_at", "sent_at"),
        Index("ix_alerts_expires_at", "expires_at"),
        Index("ix_alerts_broadcast", "broadcast"),
    )


class AlertAreaModel(Base):
    """Alert area model for geographic targeting."""

    __tablename__ = "alert_areas"

    id: Mapped[str] = mapped_column(String(100), primary_key=True)
    alert_id: Mapped[str] = mapped_column(
        String(100),
        ForeignKey("alerts.id", ondelete="CASCADE"),
        nullable=False,
    )
    geom: Mapped[Geometry] = mapped_column(
        Geometry(geometry_type="MULTIPOLYGON", srid=4326),
        nullable=False,
    )

    # Relationship
    alert: Mapped["AlertModel"] = relationship("AlertModel", back_populates="areas")

    __table_args__ = (
        Index("ix_alert_areas_geom", "geom", postgresql_using="gist"),
        Index("ix_alert_areas_alert_id", "alert_id"),
    )


class AlertDeliveryModel(Base):
    """Alert delivery tracking model."""

    __tablename__ = "alert_deliveries"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    alert_id: Mapped[str] = mapped_column(
        String(100),
        ForeignKey("alerts.id", ondelete="CASCADE"),
        nullable=False,
    )
    device_id: Mapped[str] = mapped_column(
        String(100),
        ForeignKey("devices.id", ondelete="CASCADE"),
        nullable=False,
    )
    sent_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    read_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    provider_status: Mapped[str] = mapped_column(
        String(50), default="pending", nullable=False
    )
    error_message: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Relationships
    alert: Mapped["AlertModel"] = relationship("AlertModel", back_populates="deliveries")
    device: Mapped["DeviceModel"] = relationship("DeviceModel", back_populates="deliveries")

    __table_args__ = (
        Index("ix_alert_deliveries_alert_id", "alert_id"),
        Index("ix_alert_deliveries_device_id", "device_id"),
        Index("ix_alert_deliveries_sent_at", "sent_at"),
        Index("ix_alert_deliveries_device_read", "device_id", "read_at"),
    )


# Import DeviceModel for type hints (avoid circular import at runtime)
from app.models.device import DeviceModel  # noqa: E402
