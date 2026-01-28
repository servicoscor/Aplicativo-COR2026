from __future__ import annotations
from typing import Optional, List
"""Device SQLAlchemy model."""

from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import DateTime, Enum, Index, String
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin


class DeviceModel(Base, TimestampMixin):
    """Device model for storing user devices."""

    __tablename__ = "devices"

    id: Mapped[str] = mapped_column(String(100), primary_key=True)
    platform: Mapped[str] = mapped_column(
        Enum("ios", "android", name="device_platform"),
        nullable=False,
    )
    push_token: Mapped[str] = mapped_column(
        String(500), unique=True, nullable=False, index=True
    )
    last_location: Mapped[Optional[Geometry]] = mapped_column(
        Geometry(geometry_type="POINT", srid=4326),
        nullable=True,
    )
    last_location_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    neighborhoods: Mapped[Optional[List[str]]] = mapped_column(
        ARRAY(String(100)), nullable=True
    )

    # Relationships
    deliveries: Mapped[List["AlertDeliveryModel"]] = relationship(
        "AlertDeliveryModel",
        back_populates="device",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        Index("ix_devices_last_location", "last_location", postgresql_using="gist"),
        Index("ix_devices_platform", "platform"),
        Index("ix_devices_neighborhoods", "neighborhoods", postgresql_using="gin"),
    )


# Import for type hints
from app.models.alert import AlertDeliveryModel  # noqa: E402, F401
