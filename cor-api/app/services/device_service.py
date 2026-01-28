from __future__ import annotations
"""Device service for managing user devices."""

import uuid
from datetime import datetime, timezone

from geoalchemy2.functions import ST_SetSRID, ST_MakePoint
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError, ValidationException
from app.core.logging import get_logger
from app.models.device import DeviceModel
from app.schemas.device import (
    Device,
    DevicePlatform,
    DeviceRegister,
    DeviceLocationUpdate,
)

logger = get_logger(__name__)


class DeviceService:
    """Service for device operations."""

    def __init__(self, db: AsyncSession):
        """Initialize device service."""
        self.db = db

    async def register_device(self, data: DeviceRegister) -> Device:
        """
        Register or update a device.

        If push_token already exists, updates the existing device.
        Otherwise, creates a new device.

        Args:
            data: Device registration data

        Returns:
            Registered/updated device
        """
        # Check if device exists by push_token
        stmt = select(DeviceModel).where(DeviceModel.push_token == data.push_token)
        result = await self.db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            # Update existing device
            existing.platform = data.platform.value
            existing.neighborhoods = data.neighborhoods
            existing.updated_at = datetime.now(timezone.utc)

            await self.db.commit()
            await self.db.refresh(existing)

            logger.info(f"Updated device {existing.id}")
            return self._to_schema(existing)

        # Create new device
        device = DeviceModel(
            id=str(uuid.uuid4()),
            platform=data.platform.value,
            push_token=data.push_token,
            neighborhoods=data.neighborhoods,
        )

        self.db.add(device)
        await self.db.commit()
        await self.db.refresh(device)

        logger.info(f"Registered new device {device.id}")
        return self._to_schema(device)

    async def update_location(
        self,
        push_token: str,
        data: DeviceLocationUpdate,
    ) -> Device:
        """
        Update device location.

        Args:
            push_token: Device push token
            data: Location update data (lat, lon)

        Returns:
            Updated device

        Raises:
            NotFoundError: If device not found
        """
        # Find device by push_token
        stmt = select(DeviceModel).where(DeviceModel.push_token == push_token)
        result = await self.db.execute(stmt)
        device = result.scalar_one_or_none()

        if not device:
            raise NotFoundError(
                message="Device not found",
                resource="device",
            )

        # Update location using PostGIS
        # ST_SetSRID(ST_MakePoint(lon, lat), 4326)
        device.last_location = ST_SetSRID(
            ST_MakePoint(data.lon, data.lat),
            4326,
        )
        device.last_location_at = datetime.now(timezone.utc)
        device.updated_at = datetime.now(timezone.utc)

        await self.db.commit()
        await self.db.refresh(device)

        logger.info(f"Updated location for device {device.id}")
        return self._to_schema(device)

    async def get_device_by_token(self, push_token: str) -> Device | None:
        """Get device by push token."""
        stmt = select(DeviceModel).where(DeviceModel.push_token == push_token)
        result = await self.db.execute(stmt)
        device = result.scalar_one_or_none()

        if device:
            return self._to_schema(device)
        return None

    async def get_device_by_id(self, device_id: str) -> Device | None:
        """Get device by ID."""
        stmt = select(DeviceModel).where(DeviceModel.id == device_id)
        result = await self.db.execute(stmt)
        device = result.scalar_one_or_none()

        if device:
            return self._to_schema(device)
        return None

    async def get_subscriptions(self, push_token: str) -> list[str]:
        """
        Get device's subscribed neighborhoods.

        Args:
            push_token: Device push token

        Returns:
            List of subscribed neighborhoods

        Raises:
            NotFoundError: If device not found
        """
        stmt = select(DeviceModel).where(DeviceModel.push_token == push_token)
        result = await self.db.execute(stmt)
        device = result.scalar_one_or_none()

        if not device:
            raise NotFoundError(
                message="Device not found",
                resource="device",
            )

        return device.neighborhoods or []

    async def update_subscriptions(
        self,
        push_token: str,
        neighborhoods: list[str],
    ) -> list[str]:
        """
        Update device's subscribed neighborhoods.

        Args:
            push_token: Device push token
            neighborhoods: List of neighborhoods to subscribe to

        Returns:
            Updated list of subscribed neighborhoods

        Raises:
            NotFoundError: If device not found
        """
        stmt = select(DeviceModel).where(DeviceModel.push_token == push_token)
        result = await self.db.execute(stmt)
        device = result.scalar_one_or_none()

        if not device:
            raise NotFoundError(
                message="Device not found",
                resource="device",
            )

        device.neighborhoods = neighborhoods
        device.updated_at = datetime.now(timezone.utc)

        await self.db.commit()
        await self.db.refresh(device)

        logger.info(f"Updated subscriptions for device {device.id}: {len(neighborhoods)} neighborhoods")
        return device.neighborhoods or []

    def _to_schema(self, model: DeviceModel) -> Device:
        """Convert model to schema."""
        return Device(
            id=model.id,
            platform=DevicePlatform(model.platform),
            push_token=self._mask_token(model.push_token),
            has_location=model.last_location is not None,
            neighborhoods=model.neighborhoods,
            last_location_at=model.last_location_at,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    def _mask_token(self, token: str) -> str:
        """Mask push token for privacy."""
        if len(token) <= 10:
            return "***"
        return f"{token[:6]}...{token[-4:]}"
