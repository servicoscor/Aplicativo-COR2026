from __future__ import annotations
"""Alerts API endpoints."""

from typing import Annotated

from fastapi import APIRouter, Depends, Header, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import ApiKeyDep, RateLimitDep
from app.db.session import get_db
from app.schemas.alert import (
    Alert,
    AlertCreate,
    AlertDetailResponse,
    AlertListResponse,
    AlertSendResponse,
    AlertStatus,
    InboxResponse,
    MarkAsReadResponse,
)
from app.services.alert_service import AlertService

router = APIRouter()

DbSession = Annotated[AsyncSession, Depends(get_db)]


# ==================== Admin Endpoints (require API key) ====================


@router.post(
    "",
    response_model=AlertDetailResponse,
    summary="Create Alert",
    description="Create a new alert (draft status).",
)
async def create_alert(
    data: AlertCreate,
    db: DbSession,
    _api_key: ApiKeyDep = True,
    _rate_limit: RateLimitDep = True,
) -> AlertDetailResponse:
    """
    Create a new alert in draft status.

    The alert can target users via:
    - broadcast=True: Send to all registered devices
    - area.geojson: GeoJSON Polygon/MultiPolygon for geo-fencing
    - area.circle: Circular area (center + radius)
    - neighborhoods: List of neighborhoods (fallback for devices without location)

    Args:
        data: Alert creation data including:
            - title: Alert title (max 200 chars)
            - body: Alert message (max 2000 chars)
            - severity: info, alert, or emergency
            - broadcast: If true, sends to all devices
            - area: Optional geographic targeting
            - neighborhoods: Optional neighborhood targeting
            - expires_at: Optional expiration time

    Returns:
        Created alert details
    """
    service = AlertService(db)
    alert = await service.create_alert(data)

    return AlertDetailResponse(data=alert)


@router.get(
    "",
    response_model=AlertListResponse,
    summary="List Alerts",
    description="List alerts with optional filtering.",
)
async def list_alerts(
    db: DbSession,
    status: AlertStatus | None = Query(
        default=None,
        description="Filter by status (draft, sent, canceled)",
    ),
    limit: int = Query(default=50, ge=1, le=100, description="Max results"),
    offset: int = Query(default=0, ge=0, description="Pagination offset"),
    _api_key: ApiKeyDep = True,
    _rate_limit: RateLimitDep = True,
) -> AlertListResponse:
    """
    List alerts with optional filtering.

    Args:
        status: Filter by alert status
        limit: Maximum number of results (1-100)
        offset: Pagination offset

    Returns:
        List of alerts and total count
    """
    service = AlertService(db)
    alerts, total = await service.list_alerts(
        status=status,
        limit=limit,
        offset=offset,
    )

    return AlertListResponse(data=alerts, total=total)


# ==================== Public Endpoints ====================


@router.get(
    "/inbox",
    response_model=InboxResponse,
    summary="Get Alerts Inbox",
    description="Get alerts relevant to the device.",
)
async def get_inbox(
    db: DbSession,
    x_push_token: str = Header(
        ...,
        alias="X-Push-Token",
        description="Device push token for identification",
    ),
    lat: float | None = Query(
        default=None,
        ge=-90,
        le=90,
        description="Current latitude (for geo-matching)",
    ),
    lon: float | None = Query(
        default=None,
        ge=-180,
        le=180,
        description="Current longitude (for geo-matching)",
    ),
    severity: str | None = Query(
        default=None,
        description="Filter by severity (info, alert, emergency)",
    ),
    neighborhood: str | None = Query(
        default=None,
        description="Filter by neighborhood",
    ),
    unread_only: bool = Query(
        default=False,
        description="Only return unread alerts",
    ),
    _rate_limit: RateLimitDep = True,
) -> InboxResponse:
    """
    Get alerts inbox for a device.

    Returns alerts that match the device via:
    - broadcast: All broadcast alerts
    - geo: Alerts where device location is within the alert area
    - neighborhood: Alerts targeting device's neighborhoods

    Args:
        x_push_token: Device push token (in header)
        lat: Optional current latitude
        lon: Optional current longitude
        severity: Optional severity filter
        neighborhood: Optional neighborhood filter
        unread_only: If true, only return unread alerts

    Returns:
        List of matching alerts with match_type indicator and unread count
    """
    service = AlertService(db)
    alerts, unread_count = await service.get_inbox(
        device_token=x_push_token,
        lat=lat,
        lon=lon,
        severity_filter=severity,
        neighborhood_filter=neighborhood,
        unread_only=unread_only,
    )

    return InboxResponse(data=alerts, unread_count=unread_count)


@router.post(
    "/inbox/{alert_id}/read",
    response_model=MarkAsReadResponse,
    summary="Mark Alert as Read",
    description="Mark an alert as read for the current device.",
)
async def mark_alert_read(
    alert_id: str,
    db: DbSession,
    x_push_token: str = Header(
        ...,
        alias="X-Push-Token",
        description="Device push token for identification",
    ),
    _rate_limit: RateLimitDep = True,
) -> MarkAsReadResponse:
    """
    Mark an alert as read for the current device.

    Args:
        alert_id: Alert ID to mark as read
        x_push_token: Device push token (in header)

    Returns:
        Confirmation with alert ID and read timestamp
    """
    service = AlertService(db)
    read_at = await service.mark_alert_as_read(
        alert_id=alert_id,
        device_token=x_push_token,
    )

    return MarkAsReadResponse(alert_id=alert_id, read_at=read_at)


@router.get(
    "/{alert_id}",
    response_model=AlertDetailResponse,
    summary="Get Alert",
    description="Get alert details by ID.",
)
async def get_alert(
    alert_id: str,
    db: DbSession,
    _api_key: ApiKeyDep = True,
    _rate_limit: RateLimitDep = True,
) -> AlertDetailResponse:
    """
    Get alert details by ID.

    Args:
        alert_id: Alert ID

    Returns:
        Alert details including areas and delivery count
    """
    service = AlertService(db)
    alert = await service.get_alert(alert_id)

    return AlertDetailResponse(data=alert)


@router.post(
    "/{alert_id}/send",
    response_model=AlertSendResponse,
    summary="Send Alert",
    description="Send a draft alert to targeted devices.",
)
async def send_alert(
    alert_id: str,
    db: DbSession,
    _api_key: ApiKeyDep = True,
    _rate_limit: RateLimitDep = True,
) -> AlertSendResponse:
    """
    Send an alert to targeted devices.

    This endpoint:
    1. Validates the alert is in draft status
    2. Counts targeted devices based on targeting rules
    3. Updates alert status to "sent"
    4. Triggers async Celery task for actual delivery

    Targeting rules:
    - broadcast=True: All devices
    - area: Devices with location inside the area
    - neighborhoods: Devices without location but matching neighborhoods

    Args:
        alert_id: Alert ID to send

    Returns:
        Updated alert, number of devices targeted, and Celery task ID
    """
    service = AlertService(db)
    alert, devices_targeted, task_id = await service.send_alert(alert_id)

    return AlertSendResponse(
        data=alert,
        devices_targeted=devices_targeted,
        task_id=task_id,
    )
