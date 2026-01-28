"""Operational status SQLAlchemy models."""

from __future__ import annotations

from datetime import datetime, timezone as tz
from typing import Optional,  TYPE_CHECKING

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.admin_user import AdminUserModel


class OperationalStatusCurrentModel(Base):
    """Current operational status (singleton table with single row id=1)."""

    __tablename__ = "operational_status_current"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=False, default=1)
    city_stage: Mapped[int] = mapped_column(
        Integer,
        default=1,
        server_default="1",
        nullable=False,
    )
    heat_level: Mapped[int] = mapped_column(
        Integer,
        default=1,
        server_default="1",
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(tz.utc),
        server_default=func.now(),
        nullable=False,
    )
    updated_by_id: Mapped[Optional[str]] = mapped_column(
        String(100),
        ForeignKey("admin_users.id", ondelete="SET NULL"),
        nullable=True,
    )

    # Relationship
    updated_by: Mapped[Optional["AdminUserModel"]] = relationship(
        "AdminUserModel",
        foreign_keys=[updated_by_id],
        lazy="selectin",
    )

    __table_args__ = (
        CheckConstraint("city_stage >= 1 AND city_stage <= 5", name="ck_city_stage_range"),
        CheckConstraint("heat_level >= 1 AND heat_level <= 5", name="ck_heat_level_range"),
        CheckConstraint("id = 1", name="ck_single_row"),
    )

    def __repr__(self) -> str:
        return f"<OperationalStatusCurrent(city_stage={self.city_stage}, heat_level={self.heat_level})>"


class OperationalStatusHistoryModel(Base):
    """History of operational status changes."""

    __tablename__ = "operational_status_history"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    city_stage: Mapped[int] = mapped_column(Integer, nullable=False)
    heat_level: Mapped[int] = mapped_column(Integer, nullable=False)
    reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    source: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    changed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(tz.utc),
        server_default=func.now(),
        nullable=False,
    )
    changed_by_id: Mapped[Optional[str]] = mapped_column(
        String(100),
        ForeignKey("admin_users.id", ondelete="SET NULL"),
        nullable=True,
    )
    ip_address: Mapped[Optional[str]] = mapped_column(String(45), nullable=True)

    # Relationship
    changed_by_user: Mapped[Optional["AdminUserModel"]] = relationship(
        "AdminUserModel",
        back_populates="status_changes",
        foreign_keys=[changed_by_id],
        lazy="selectin",
    )

    __table_args__ = (
        CheckConstraint("city_stage >= 1 AND city_stage <= 5", name="ck_history_city_stage"),
        CheckConstraint("heat_level >= 1 AND heat_level <= 5", name="ck_history_heat_level"),
        Index("ix_operational_status_history_changed_at", "changed_at"),
        Index("ix_operational_status_history_changed_by", "changed_by_id"),
    )

    def __repr__(self) -> str:
        return f"<OperationalStatusHistory(id={self.id}, city_stage={self.city_stage}, heat_level={self.heat_level})>"
