"""Add admin system tables

Revision ID: 003
Revises: 002
Create Date: 2024-01-26 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create enum type for admin roles
    op.execute("CREATE TYPE admin_role AS ENUM ('admin', 'comunicacao', 'viewer')")

    # Create admin_users table
    op.create_table(
        "admin_users",
        sa.Column("id", sa.String(100), primary_key=True),
        sa.Column("email", sa.String(255), unique=True, nullable=False),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column(
            "role",
            postgresql.ENUM("admin", "comunicacao", "viewer", name="admin_role", create_type=False),
            server_default="viewer",
            nullable=False,
        ),
        sa.Column("is_active", sa.Boolean, server_default="true", nullable=False),
        sa.Column("last_login_at", sa.DateTime(timezone=True), nullable=True),
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
    op.create_index("ix_admin_users_email", "admin_users", ["email"])
    op.create_index("ix_admin_users_role", "admin_users", ["role"])
    op.create_index("ix_admin_users_is_active", "admin_users", ["is_active"])

    # Create operational_status_current table (singleton - always has id=1)
    op.create_table(
        "operational_status_current",
        sa.Column("id", sa.Integer, primary_key=True, autoincrement=False),
        sa.Column(
            "city_stage",
            sa.Integer,
            sa.CheckConstraint("city_stage >= 1 AND city_stage <= 5", name="ck_city_stage_range"),
            server_default="1",
            nullable=False,
        ),
        sa.Column(
            "heat_level",
            sa.Integer,
            sa.CheckConstraint("heat_level >= 1 AND heat_level <= 5", name="ck_heat_level_range"),
            server_default="1",
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_by_id",
            sa.String(100),
            sa.ForeignKey("admin_users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.CheckConstraint("id = 1", name="ck_single_row"),
    )
    # Insert initial row with default values
    op.execute(
        "INSERT INTO operational_status_current (id, city_stage, heat_level) VALUES (1, 1, 1)"
    )

    # Create operational_status_history table
    op.create_table(
        "operational_status_history",
        sa.Column("id", sa.Integer, primary_key=True, autoincrement=True),
        sa.Column(
            "city_stage",
            sa.Integer,
            sa.CheckConstraint("city_stage >= 1 AND city_stage <= 5", name="ck_history_city_stage"),
            nullable=False,
        ),
        sa.Column(
            "heat_level",
            sa.Integer,
            sa.CheckConstraint("heat_level >= 1 AND heat_level <= 5", name="ck_history_heat_level"),
            nullable=False,
        ),
        sa.Column("reason", sa.Text, nullable=True),
        sa.Column("source", sa.String(100), nullable=True),
        sa.Column(
            "changed_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "changed_by_id",
            sa.String(100),
            sa.ForeignKey("admin_users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("ip_address", sa.String(45), nullable=True),
    )
    op.create_index(
        "ix_operational_status_history_changed_at",
        "operational_status_history",
        ["changed_at"],
    )
    op.create_index(
        "ix_operational_status_history_changed_by",
        "operational_status_history",
        ["changed_by_id"],
    )

    # Create audit_logs table
    op.create_table(
        "audit_logs",
        sa.Column("id", sa.Integer, primary_key=True, autoincrement=True),
        sa.Column(
            "user_id",
            sa.String(100),
            sa.ForeignKey("admin_users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("action", sa.String(100), nullable=False),
        sa.Column("resource", sa.String(100), nullable=False),
        sa.Column("resource_id", sa.String(100), nullable=True),
        sa.Column("payload_summary", postgresql.JSONB, nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("user_agent", sa.Text, nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("ix_audit_logs_user_id", "audit_logs", ["user_id"])
    op.create_index("ix_audit_logs_action", "audit_logs", ["action"])
    op.create_index("ix_audit_logs_resource", "audit_logs", ["resource"])
    op.create_index("ix_audit_logs_resource_id", "audit_logs", ["resource_id"])
    op.create_index("ix_audit_logs_created_at", "audit_logs", ["created_at"])


def downgrade() -> None:
    op.drop_table("audit_logs")
    op.drop_table("operational_status_history")
    op.drop_table("operational_status_current")
    op.drop_table("admin_users")
    op.execute("DROP TYPE IF EXISTS admin_role")
