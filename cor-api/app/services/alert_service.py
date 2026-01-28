from __future__ import annotations
"""Alert service for managing alerts and geo-targeting."""

import json
import uuid
from datetime import datetime, timezone
from typing import Any

from geoalchemy2.functions import (
    ST_Contains,
    ST_DWithin,
    ST_GeomFromGeoJSON,
    ST_SetSRID,
    ST_MakePoint,
    ST_AsGeoJSON,
    ST_Buffer,
    ST_Transform,
)
from geoalchemy2.shape import to_shape
from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.errors import NotFoundError, ValidationException
from app.core.logging import get_logger
from app.models.alert import AlertAreaModel, AlertDeliveryModel, AlertModel
from app.models.device import DeviceModel
from app.schemas.alert import (
    Alert,
    AlertAreaInput,
    AlertAreaResponse,
    AlertCreate,
    AlertSeverity,
    AlertStatus,
    CircleArea,
    GeoJSONGeometry,
    InboxAlert,
)

logger = get_logger(__name__)


class AlertService:
    """Service for alert operations and geo-targeting."""

    def __init__(self, db: AsyncSession):
        """Initialize alert service."""
        self.db = db

    async def create_alert(
        self,
        data: AlertCreate,
        created_by: str | None = None,
    ) -> Alert:
        """
        Create a new alert.

        Args:
            data: Alert creation data
            created_by: Creator identifier

        Returns:
            Created alert
        """
        alert_id = str(uuid.uuid4())

        # Create alert
        alert = AlertModel(
            id=alert_id,
            title=data.title,
            body=data.body,
            severity=data.severity.value,
            status="draft",
            broadcast=data.broadcast,
            neighborhoods=data.neighborhoods,
            expires_at=data.expires_at,
            created_by=created_by,
        )

        self.db.add(alert)

        # Create areas if provided
        if data.area:
            await self._create_alert_areas(alert_id, data.area)

        await self.db.commit()
        await self.db.refresh(alert)

        # Load relationships
        stmt = (
            select(AlertModel)
            .options(selectinload(AlertModel.areas))
            .options(selectinload(AlertModel.deliveries))
            .where(AlertModel.id == alert_id)
        )
        result = await self.db.execute(stmt)
        alert = result.scalar_one()

        logger.info(f"Created alert {alert_id}")
        return await self._to_schema(alert)

    async def _create_alert_areas(
        self,
        alert_id: str,
        area: AlertAreaInput,
    ) -> None:
        """Create alert areas from input."""
        if area.geojson:
            # Direct GeoJSON polygon
            geojson_str = json.dumps({
                "type": area.geojson.type,
                "coordinates": area.geojson.coordinates,
            })

            # Convert to MultiPolygon if it's a Polygon
            if area.geojson.type == "Polygon":
                geom = func.ST_Multi(
                    ST_SetSRID(ST_GeomFromGeoJSON(geojson_str), 4326)
                )
            else:
                geom = ST_SetSRID(ST_GeomFromGeoJSON(geojson_str), 4326)

            area_model = AlertAreaModel(
                id=str(uuid.uuid4()),
                alert_id=alert_id,
                geom=geom,
            )
            self.db.add(area_model)

        elif area.circle:
            # Circle defined by center and radius
            # Create a circular polygon using ST_Buffer
            # Need to transform to a meter-based projection, buffer, then back
            center_point = ST_SetSRID(
                ST_MakePoint(area.circle.center_lon, area.circle.center_lat),
                4326,
            )

            # Buffer in geography mode (meters) and convert to MultiPolygon
            # ST_Buffer with geography type uses meters
            buffered = func.ST_Multi(
                func.ST_Buffer(
                    func.Geography(center_point),
                    area.circle.radius_m,
                )
            )

            area_model = AlertAreaModel(
                id=str(uuid.uuid4()),
                alert_id=alert_id,
                geom=func.Geometry(buffered),
            )
            self.db.add(area_model)

    async def get_alert(self, alert_id: str) -> Alert:
        """
        Get alert by ID.

        Args:
            alert_id: Alert ID

        Returns:
            Alert details

        Raises:
            NotFoundError: If alert not found
        """
        stmt = (
            select(AlertModel)
            .options(selectinload(AlertModel.areas))
            .options(selectinload(AlertModel.deliveries))
            .where(AlertModel.id == alert_id)
        )
        result = await self.db.execute(stmt)
        alert = result.scalar_one_or_none()

        if not alert:
            raise NotFoundError(
                message="Alert not found",
                resource="alert",
            )

        return await self._to_schema(alert)

    async def list_alerts(
        self,
        status: AlertStatus | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> tuple[list[Alert], int]:
        """
        List alerts with optional filtering.

        Args:
            status: Filter by status
            limit: Max results
            offset: Pagination offset

        Returns:
            Tuple of (alerts, total_count)
        """
        # Build query
        query = select(AlertModel).options(
            selectinload(AlertModel.areas),
            selectinload(AlertModel.deliveries),
        )

        count_query = select(func.count(AlertModel.id))

        if status:
            query = query.where(AlertModel.status == status.value)
            count_query = count_query.where(AlertModel.status == status.value)

        # Get total count
        count_result = await self.db.execute(count_query)
        total = count_result.scalar()

        # Get paginated results
        query = query.order_by(AlertModel.created_at.desc())
        query = query.limit(limit).offset(offset)

        result = await self.db.execute(query)
        alerts = result.scalars().all()

        return [await self._to_schema(a) for a in alerts], total

    async def send_alert(self, alert_id: str) -> tuple[Alert, int, str | None]:
        """
        Mark alert as sent and return targeted device count.

        The actual sending is done via Celery task.

        Args:
            alert_id: Alert ID

        Returns:
            Tuple of (alert, devices_targeted, task_id)

        Raises:
            NotFoundError: If alert not found
            ValidationException: If alert already sent
        """
        # Get alert
        stmt = (
            select(AlertModel)
            .options(selectinload(AlertModel.areas))
            .where(AlertModel.id == alert_id)
        )
        result = await self.db.execute(stmt)
        alert = result.scalar_one_or_none()

        if not alert:
            raise NotFoundError(
                message="Alert not found",
                resource="alert",
            )

        if alert.status == "sent":
            raise ValidationException(
                message="Alert already sent",
                field="status",
            )

        if alert.status == "canceled":
            raise ValidationException(
                message="Alert was canceled",
                field="status",
            )

        # Count targeted devices
        devices_count = await self._count_targeted_devices(alert)

        # Update alert status
        alert.status = "sent"
        alert.sent_at = datetime.now(timezone.utc)

        await self.db.commit()
        await self.db.refresh(alert)

        # Trigger Celery task
        task_id = None
        try:
            from app.jobs.tasks import send_alert_task
            task = send_alert_task.delay(alert_id)
            task_id = task.id
            logger.info(f"Triggered send_alert task {task_id} for alert {alert_id}")
        except Exception as e:
            logger.error(f"Failed to trigger send_alert task: {e}")

        # Reload with relationships
        stmt = (
            select(AlertModel)
            .options(selectinload(AlertModel.areas))
            .options(selectinload(AlertModel.deliveries))
            .where(AlertModel.id == alert_id)
        )
        result = await self.db.execute(stmt)
        alert = result.scalar_one()

        return await self._to_schema(alert), devices_count, task_id

    async def _count_targeted_devices(self, alert: AlertModel) -> int:
        """Count devices that will receive the alert."""
        query = await self._build_device_query(alert)
        count_result = await self.db.execute(
            select(func.count()).select_from(query.subquery())
        )
        return count_result.scalar() or 0

    async def get_targeted_devices(self, alert: AlertModel) -> list[DeviceModel]:
        """Get devices that match the alert targeting."""
        query = await self._build_device_query(alert)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def _build_device_query(self, alert: AlertModel):
        """Build SQLAlchemy query for targeted devices."""
        # Base query - all devices with valid push_token
        base_query = select(DeviceModel).where(
            DeviceModel.push_token.isnot(None)
        )

        if alert.broadcast:
            # Broadcast: return all devices
            return base_query

        conditions = []

        # Geo-targeting: devices within alert areas
        if alert.areas:
            for area in alert.areas:
                # Devices with location inside the area
                geo_condition = and_(
                    DeviceModel.last_location.isnot(None),
                    ST_Contains(area.geom, DeviceModel.last_location),
                )
                conditions.append(geo_condition)

        # Neighborhood fallback: devices without location but matching neighborhoods
        if alert.neighborhoods:
            # Devices without location but with matching neighborhoods
            neighborhood_condition = and_(
                DeviceModel.last_location.is_(None),
                DeviceModel.neighborhoods.isnot(None),
                DeviceModel.neighborhoods.overlap(alert.neighborhoods),
            )
            conditions.append(neighborhood_condition)

        if not conditions:
            # No targeting criteria - return empty
            return base_query.where(False)

        # Combine with OR
        return base_query.where(or_(*conditions))

    async def get_inbox(
        self,
        device_token: str,
        lat: float | None = None,
        lon: float | None = None,
        neighborhoods: list[str] | None = None,
        severity_filter: str | None = None,
        neighborhood_filter: str | None = None,
        unread_only: bool = False,
    ) -> tuple[list[InboxAlert], int]:
        """
        Get alerts inbox for a device.

        Returns alerts that are:
        - Broadcast OR
        - Geo-match (if location provided) OR
        - Neighborhood match (if neighborhoods provided)

        And are:
        - Status = sent
        - Not expired

        Args:
            device_token: Device push token
            lat: Optional latitude (for geo-matching)
            lon: Optional longitude (for geo-matching)
            neighborhoods: Optional neighborhoods (for fallback)
            severity_filter: Optional severity filter
            neighborhood_filter: Optional neighborhood filter
            unread_only: If true, only return unread alerts

        Returns:
            Tuple of (list of matching alerts, unread count)
        """
        now = datetime.now(timezone.utc)

        # Get device to check stored location/neighborhoods
        stmt = select(DeviceModel).where(DeviceModel.push_token == device_token)
        result = await self.db.execute(stmt)
        device = result.scalar_one_or_none()

        if not device:
            return [], 0

        # Use device's stored location if not provided
        device_lat = lat
        device_lon = lon
        device_neighborhoods = neighborhoods

        if device.last_location and (lat is None or lon is None):
            # Extract lat/lon from stored location
            pass  # TODO: extract from geometry if needed

        if device.neighborhoods and not neighborhoods:
            device_neighborhoods = device.neighborhoods

        # Build query for matching alerts
        alerts_query = (
            select(AlertModel)
            .options(selectinload(AlertModel.areas))
            .where(
                and_(
                    AlertModel.status == "sent",
                    or_(
                        AlertModel.expires_at.is_(None),
                        AlertModel.expires_at > now,
                    ),
                )
            )
            .order_by(AlertModel.sent_at.desc())
            .limit(100)
        )

        # Apply severity filter
        if severity_filter:
            alerts_query = alerts_query.where(AlertModel.severity == severity_filter)

        # Apply neighborhood filter
        if neighborhood_filter:
            alerts_query = alerts_query.where(
                AlertModel.neighborhoods.contains([neighborhood_filter])
            )

        result = await self.db.execute(alerts_query)
        all_alerts = result.scalars().all()

        # Get delivery read status for this device
        delivery_query = (
            select(AlertDeliveryModel)
            .where(AlertDeliveryModel.device_id == device.id)
        )
        delivery_result = await self.db.execute(delivery_query)
        deliveries = {d.alert_id: d for d in delivery_result.scalars().all()}

        # Filter and annotate matches
        inbox_alerts: list[InboxAlert] = []
        unread_count = 0

        for alert in all_alerts:
            match_type = await self._check_alert_match(
                alert,
                device_lat,
                device_lon,
                device_neighborhoods,
            )

            if match_type:
                # Get delivery for read status
                delivery = deliveries.get(alert.id)
                is_read = delivery.read_at is not None if delivery else False
                read_at = delivery.read_at if delivery else None

                if not is_read:
                    unread_count += 1

                # Skip if unread_only and already read
                if unread_only and is_read:
                    continue

                inbox_alerts.append(
                    InboxAlert(
                        id=alert.id,
                        title=alert.title,
                        body=alert.body,
                        severity=AlertSeverity(alert.severity),
                        sent_at=alert.sent_at,
                        expires_at=alert.expires_at,
                        neighborhoods=alert.neighborhoods,
                        match_type=match_type,
                        is_read=is_read,
                        read_at=read_at,
                    )
                )

        return inbox_alerts, unread_count

    async def mark_alert_as_read(
        self,
        alert_id: str,
        device_token: str,
    ) -> datetime:
        """
        Mark an alert as read for a device.

        Args:
            alert_id: Alert ID to mark as read
            device_token: Device push token

        Returns:
            Timestamp when marked as read

        Raises:
            NotFoundError: If device or alert not found
        """
        # Get device
        stmt = select(DeviceModel).where(DeviceModel.push_token == device_token)
        result = await self.db.execute(stmt)
        device = result.scalar_one_or_none()

        if not device:
            raise NotFoundError(message="Device not found", resource="device")

        # Get alert
        stmt = select(AlertModel).where(AlertModel.id == alert_id)
        result = await self.db.execute(stmt)
        alert = result.scalar_one_or_none()

        if not alert:
            raise NotFoundError(message="Alert not found", resource="alert")

        # Find or create delivery record
        stmt = select(AlertDeliveryModel).where(
            and_(
                AlertDeliveryModel.alert_id == alert_id,
                AlertDeliveryModel.device_id == device.id,
            )
        )
        result = await self.db.execute(stmt)
        delivery = result.scalar_one_or_none()

        read_at = datetime.now(timezone.utc)

        if delivery:
            # Update existing delivery
            if not delivery.read_at:
                delivery.read_at = read_at
        else:
            # Create new delivery record (for alerts that matched but weren't pushed)
            delivery = AlertDeliveryModel(
                alert_id=alert_id,
                device_id=device.id,
                sent_at=alert.sent_at or read_at,
                read_at=read_at,
                provider_status="read",
            )
            self.db.add(delivery)

        await self.db.commit()
        logger.info(f"Marked alert {alert_id} as read for device {device.id}")

        return read_at

    async def _check_alert_match(
        self,
        alert: AlertModel,
        lat: float | None,
        lon: float | None,
        neighborhoods: list[str] | None,
    ) -> str | None:
        """
        Check if alert matches the given criteria.

        Returns match type or None if no match.
        """
        # Broadcast always matches
        if alert.broadcast:
            return "broadcast"

        # Geo-match
        if lat is not None and lon is not None and alert.areas:
            for area in alert.areas:
                # Check if point is within area using PostGIS
                point = ST_SetSRID(ST_MakePoint(lon, lat), 4326)
                check_query = select(ST_Contains(area.geom, point))
                result = await self.db.execute(check_query)
                if result.scalar():
                    return "geo"

        # Neighborhood match (fallback when no location)
        if neighborhoods and alert.neighborhoods:
            # Check overlap
            common = set(neighborhoods) & set(alert.neighborhoods)
            if common:
                return "neighborhood"

        return None

    async def _to_schema(self, model: AlertModel) -> Alert:
        """Convert model to schema."""
        # Convert areas to response format
        areas = []
        for area in model.areas:
            # Get GeoJSON representation
            geojson_query = select(ST_AsGeoJSON(area.geom))
            result = await self.db.execute(geojson_query)
            geojson_str = result.scalar()

            areas.append(
                AlertAreaResponse(
                    id=area.id,
                    geojson=json.loads(geojson_str) if geojson_str else None,
                )
            )

        return Alert(
            id=model.id,
            title=model.title,
            body=model.body,
            severity=AlertSeverity(model.severity),
            status=AlertStatus(model.status),
            broadcast=model.broadcast,
            neighborhoods=model.neighborhoods,
            expires_at=model.expires_at,
            created_at=model.created_at,
            sent_at=model.sent_at,
            created_by=model.created_by,
            areas=areas,
            delivery_count=len(model.deliveries),
        )

    async def get_delivery_stats(self, alert_id: str) -> dict:
        """
        Get delivery statistics for an alert.

        Returns dict with:
        - total: Total deliveries attempted
        - sent: Successfully sent
        - pending: Still pending
        - failed: Failed deliveries
        """
        from app.models.alert import AlertDeliveryModel

        # Count by status
        stats_query = select(
            AlertDeliveryModel.provider_status,
            func.count(AlertDeliveryModel.id).label("count"),
        ).where(
            AlertDeliveryModel.alert_id == alert_id
        ).group_by(
            AlertDeliveryModel.provider_status
        )

        result = await self.db.execute(stats_query)
        rows = result.all()

        stats = {
            "total": 0,
            "sent": 0,
            "pending": 0,
            "failed": 0,
        }

        for status, count in rows:
            stats["total"] += count
            if status == "sent":
                stats["sent"] += count
            elif status == "pending":
                stats["pending"] += count
            elif status in ("failed", "invalid_token", "expired_token"):
                stats["failed"] += count

        return stats
