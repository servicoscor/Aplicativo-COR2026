"""Audit log service for tracking admin actions."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.logging import get_logger
from app.models.admin_user import AdminUserModel
from app.models.audit_log import AuditLogModel
from app.schemas.admin_user import AdminUser
from app.schemas.audit_log import AuditLogCreate, AuditLogEntry

logger = get_logger(__name__)


class AuditService:
    """Service for audit log operations."""

    def __init__(self, db: AsyncSession):
        """Initialize service with database session."""
        self.db = db

    async def log_action(
        self,
        action: str,
        resource: str,
        resource_id: Optional[str] = None,
        user: Optional[AdminUser] = None,
        payload_summary: Optional[Dict[str, Any]] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
    ) -> AuditLogEntry:
        """
        Create an audit log entry.

        Args:
            action: Action performed (e.g., "create_alert", "change_status")
            resource: Resource type (e.g., "alert", "operational_status")
            resource_id: ID of the affected resource
            user: User who performed the action
            payload_summary: Summary of the action payload (sensitive data should be omitted)
            ip_address: IP address of the user
            user_agent: User agent string

        Returns:
            Created audit log entry
        """
        entry = AuditLogModel(
            user_id=user.id if user else None,
            action=action,
            resource=resource,
            resource_id=resource_id,
            payload_summary=payload_summary,
            ip_address=ip_address,
            user_agent=user_agent,
        )

        self.db.add(entry)
        await self.db.commit()
        await self.db.refresh(entry)

        logger.info(
            f"Audit log: {action} on {resource}"
            + (f"/{resource_id}" if resource_id else "")
            + (f" by {user.email}" if user else " (anonymous)")
        )

        return AuditLogEntry(
            id=entry.id,
            user_id=entry.user_id,
            user_email=user.email if user else None,
            user_name=user.name if user else None,
            action=entry.action,
            resource=entry.resource,
            resource_id=entry.resource_id,
            payload_summary=entry.payload_summary,
            ip_address=entry.ip_address,
            user_agent=entry.user_agent,
            created_at=entry.created_at,
        )

    async def list_logs(
        self,
        user_id: Optional[str] = None,
        action: Optional[str] = None,
        resource: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        limit: int = 100,
        offset: int = 0,
    ) -> Tuple[List[AuditLogEntry], int]:
        """
        List audit log entries with optional filtering.

        Args:
            user_id: Filter by user ID
            action: Filter by action
            resource: Filter by resource type
            start_date: Filter by start date
            end_date: Filter by end date
            limit: Maximum number of entries to return
            offset: Number of entries to skip

        Returns:
            Tuple of (log entries, total count)
        """
        # Base query
        stmt = select(AuditLogModel)

        # Apply filters
        if user_id:
            stmt = stmt.where(AuditLogModel.user_id == user_id)
        if action:
            stmt = stmt.where(AuditLogModel.action == action)
        if resource:
            stmt = stmt.where(AuditLogModel.resource == resource)
        if start_date:
            stmt = stmt.where(AuditLogModel.created_at >= start_date)
        if end_date:
            stmt = stmt.where(AuditLogModel.created_at <= end_date)

        # Count total
        count_stmt = select(func.count()).select_from(stmt.subquery())
        count_result = await self.db.execute(count_stmt)
        total = count_result.scalar() or 0

        # Apply pagination and ordering
        stmt = stmt.order_by(AuditLogModel.created_at.desc())
        stmt = stmt.offset(offset).limit(limit)

        result = await self.db.execute(stmt)
        entries = result.scalars().all()

        # Get user details for all entries
        user_ids = [e.user_id for e in entries if e.user_id]
        user_data = {}

        if user_ids:
            user_stmt = select(AdminUserModel).where(AdminUserModel.id.in_(user_ids))
            user_result = await self.db.execute(user_stmt)
            for user in user_result.scalars().all():
                user_data[user.id] = {"email": user.email, "name": user.name}

        return (
            [
                AuditLogEntry(
                    id=e.id,
                    user_id=e.user_id,
                    user_email=user_data.get(e.user_id, {}).get("email") if e.user_id else None,
                    user_name=user_data.get(e.user_id, {}).get("name") if e.user_id else None,
                    action=e.action,
                    resource=e.resource,
                    resource_id=e.resource_id,
                    payload_summary=e.payload_summary,
                    ip_address=e.ip_address,
                    user_agent=e.user_agent,
                    created_at=e.created_at,
                )
                for e in entries
            ],
            total,
        )

    async def get_user_activity(
        self,
        user_id: str,
        limit: int = 50,
    ) -> List[AuditLogEntry]:
        """
        Get recent activity for a specific user.

        Args:
            user_id: User ID
            limit: Maximum number of entries to return

        Returns:
            List of audit log entries
        """
        entries, _ = await self.list_logs(user_id=user_id, limit=limit)
        return entries

    async def get_resource_history(
        self,
        resource: str,
        resource_id: str,
        limit: int = 50,
    ) -> List[AuditLogEntry]:
        """
        Get audit history for a specific resource.

        Args:
            resource: Resource type
            resource_id: Resource ID
            limit: Maximum number of entries to return

        Returns:
            List of audit log entries
        """
        stmt = (
            select(AuditLogModel)
            .where(AuditLogModel.resource == resource)
            .where(AuditLogModel.resource_id == resource_id)
            .order_by(AuditLogModel.created_at.desc())
            .limit(limit)
        )

        result = await self.db.execute(stmt)
        entries = result.scalars().all()

        # Get user details
        user_ids = [e.user_id for e in entries if e.user_id]
        user_data = {}

        if user_ids:
            user_stmt = select(AdminUserModel).where(AdminUserModel.id.in_(user_ids))
            user_result = await self.db.execute(user_stmt)
            for user in user_result.scalars().all():
                user_data[user.id] = {"email": user.email, "name": user.name}

        return [
            AuditLogEntry(
                id=e.id,
                user_id=e.user_id,
                user_email=user_data.get(e.user_id, {}).get("email") if e.user_id else None,
                user_name=user_data.get(e.user_id, {}).get("name") if e.user_id else None,
                action=e.action,
                resource=e.resource,
                resource_id=e.resource_id,
                payload_summary=e.payload_summary,
                ip_address=e.ip_address,
                user_agent=e.user_agent,
                created_at=e.created_at,
            )
            for e in entries
        ]
