"""Admin user SQLAlchemy model."""

from __future__ import annotations

from datetime import datetime
from typing import Optional, TYPE_CHECKING, List

from sqlalchemy import Boolean, DateTime, Enum, Index, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.audit_log import AuditLogModel
    from app.models.operational_status import OperationalStatusHistoryModel


class AdminUserModel(Base, TimestampMixin):
    """Admin user model for authentication and RBAC."""

    __tablename__ = "admin_users"

    id: Mapped[str] = mapped_column(String(100), primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[str] = mapped_column(
        Enum("admin", "comunicacao", "viewer", name="admin_role"),
        default="viewer",
        server_default="viewer",
        nullable=False,
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        server_default="true",
        nullable=False,
    )
    last_login_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    # Relationships
    audit_logs: Mapped[List["AuditLogModel"]] = relationship(
        "AuditLogModel",
        back_populates="user",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    status_changes: Mapped[List["OperationalStatusHistoryModel"]] = relationship(
        "OperationalStatusHistoryModel",
        back_populates="changed_by_user",
        lazy="selectin",
    )

    __table_args__ = (
        Index("ix_admin_users_role", "role"),
        Index("ix_admin_users_is_active", "is_active"),
    )

    def __repr__(self) -> str:
        return f"<AdminUser(id={self.id}, email={self.email}, role={self.role})>"
