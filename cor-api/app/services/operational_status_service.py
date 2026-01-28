"""Operational status service for managing city stage and heat level."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import List, Optional, Tuple

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.logging import get_logger
from app.models.admin_user import AdminUserModel
from app.models.operational_status import (
    OperationalStatusCurrentModel,
    OperationalStatusHistoryModel,
)
from app.schemas.admin_user import AdminUser
from app.schemas.operational_status import (
    OperationalStatusCurrent,
    OperationalStatusHistory,
    OperationalStatusUpdate,
)

logger = get_logger(__name__)


class OperationalStatusService:
    """Service for operational status operations."""

    def __init__(self, db: AsyncSession):
        """Initialize service with database session."""
        self.db = db

    async def get_current(self) -> OperationalStatusCurrent:
        """
        Get current operational status.

        Returns:
            Current operational status

        Note:
            This will create the initial status if it doesn't exist.
        """
        stmt = select(OperationalStatusCurrentModel).where(
            OperationalStatusCurrentModel.id == 1
        )
        result = await self.db.execute(stmt)
        status = result.scalar_one_or_none()

        # Create initial status if not exists
        if not status:
            status = OperationalStatusCurrentModel(
                id=1,
                city_stage=1,
                heat_level=1,
            )
            self.db.add(status)
            await self.db.commit()
            await self.db.refresh(status)

        # Get updater name if available
        updated_by_name = None
        if status.updated_by_id:
            user_stmt = select(AdminUserModel).where(
                AdminUserModel.id == status.updated_by_id
            )
            user_result = await self.db.execute(user_stmt)
            user = user_result.scalar_one_or_none()
            if user:
                updated_by_name = user.name

        return OperationalStatusCurrent(
            city_stage=status.city_stage,
            heat_level=status.heat_level,
            updated_at=status.updated_at,
            updated_by=updated_by_name,
            is_stale=False,
        )

    async def update(
        self,
        data: OperationalStatusUpdate,
        current_user: AdminUser,
        ip_address: Optional[str] = None,
    ) -> OperationalStatusCurrent:
        """
        Update operational status and record history.

        Args:
            data: New status data
            current_user: User making the change
            ip_address: IP address of the user

        Returns:
            Updated status
        """
        # Get current status
        stmt = select(OperationalStatusCurrentModel).where(
            OperationalStatusCurrentModel.id == 1
        )
        result = await self.db.execute(stmt)
        status = result.scalar_one_or_none()

        # Create initial status if not exists
        if not status:
            status = OperationalStatusCurrentModel(id=1)
            self.db.add(status)

        # Check if there's actually a change
        if status.city_stage == data.city_stage and status.heat_level == data.heat_level:
            logger.info("No status change needed - values are the same")
            return OperationalStatusCurrent(
                city_stage=status.city_stage,
                heat_level=status.heat_level,
                updated_at=status.updated_at,
                updated_by=current_user.name,
                is_stale=False,
            )

        # Update current status
        old_stage = status.city_stage
        old_heat = status.heat_level

        status.city_stage = data.city_stage
        status.heat_level = data.heat_level
        status.updated_at = datetime.now(timezone.utc)
        status.updated_by_id = current_user.id

        # Create history entry
        history = OperationalStatusHistoryModel(
            city_stage=data.city_stage,
            heat_level=data.heat_level,
            reason=data.reason,
            source=data.source,
            changed_by_id=current_user.id,
            ip_address=ip_address,
        )
        self.db.add(history)

        await self.db.commit()
        await self.db.refresh(status)

        logger.info(
            f"Operational status updated: "
            f"stage {old_stage}->{data.city_stage}, "
            f"heat {old_heat}->{data.heat_level} "
            f"by {current_user.email} "
            f"(reason: {data.reason})"
        )

        return OperationalStatusCurrent(
            city_stage=status.city_stage,
            heat_level=status.heat_level,
            updated_at=status.updated_at,
            updated_by=current_user.name,
            is_stale=False,
        )

    async def get_history(
        self,
        limit: int = 50,
        offset: int = 0,
    ) -> Tuple[List[OperationalStatusHistory], int]:
        """
        Get operational status change history.

        Args:
            limit: Maximum number of entries to return
            offset: Number of entries to skip

        Returns:
            Tuple of (history entries, total count)
        """
        # Count total
        count_stmt = select(func.count(OperationalStatusHistoryModel.id))
        count_result = await self.db.execute(count_stmt)
        total = count_result.scalar() or 0

        # Get history entries with user names
        stmt = (
            select(OperationalStatusHistoryModel)
            .order_by(OperationalStatusHistoryModel.changed_at.desc())
            .offset(offset)
            .limit(limit)
        )

        result = await self.db.execute(stmt)
        entries = result.scalars().all()

        # Get user names for all entries
        user_ids = [e.changed_by_id for e in entries if e.changed_by_id]
        user_names = {}

        if user_ids:
            user_stmt = select(AdminUserModel).where(AdminUserModel.id.in_(user_ids))
            user_result = await self.db.execute(user_stmt)
            for user in user_result.scalars().all():
                user_names[user.id] = user.name

        return (
            [
                OperationalStatusHistory(
                    id=e.id,
                    city_stage=e.city_stage,
                    heat_level=e.heat_level,
                    reason=e.reason,
                    source=e.source,
                    changed_at=e.changed_at,
                    changed_by=user_names.get(e.changed_by_id) if e.changed_by_id else None,
                    ip_address=e.ip_address,
                )
                for e in entries
            ],
            total,
        )
