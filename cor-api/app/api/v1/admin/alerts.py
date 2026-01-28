"""Admin alert management endpoints."""

from __future__ import annotations

from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query, Request

from app.core.security import get_current_admin_user, require_role
from app.db.session import get_db
from app.schemas.admin_user import AdminRole, AdminUser
from app.schemas.alert import (
    Alert,
    AlertCreate,
    AlertListResponse,
    AlertResponse,
    AlertSendResponse,
    AlertStatus,
)
from app.schemas.audit_log import AuditAction, AuditResource
from app.services.alert_service import AlertService
from app.services.audit_service import AuditService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter()

DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[AdminUser, Depends(get_current_admin_user)]
ComunicacaoUser = Annotated[
    AdminUser,
    Depends(require_role([AdminRole.ADMIN, AdminRole.COMUNICACAO])),
]


def _get_client_ip(request: Request) -> str:
    """Extract client IP from request."""
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    if request.client:
        return request.client.host
    return "unknown"


@router.post(
    "",
    response_model=AlertResponse,
    summary="Create Alert",
    description="Create a new alert. Requires admin or comunicacao role.",
)
async def create_alert(
    data: AlertCreate,
    request: Request,
    current_user: ComunicacaoUser,
    db: DbSession,
) -> AlertResponse:
    """
    Create a new alert in draft status.

    Requires **admin** or **comunicacao** role.

    - **title**: Alert title (max 200 chars)
    - **body**: Alert body/message (max 2000 chars)
    - **severity**: info, alert, or emergency
    - **broadcast**: Send to all devices
    - **area**: Geographic area (GeoJSON or circle)
    - **neighborhoods**: List of neighborhoods for fallback targeting
    - **expires_at**: Optional expiration datetime

    The alert is created with 'draft' status and must be sent separately.
    """
    ip_address = _get_client_ip(request)

    service = AlertService(db)
    audit_service = AuditService(db)

    # Create alert with user attribution
    alert = await service.create_alert(data, created_by=current_user.id)

    # Log audit
    await audit_service.log_action(
        action=AuditAction.CREATE_ALERT,
        resource=AuditResource.ALERT,
        resource_id=alert.id,
        user=current_user,
        ip_address=ip_address,
        user_agent=request.headers.get("User-Agent"),
        payload_summary={
            "title": data.title,
            "severity": data.severity.value,
            "broadcast": data.broadcast,
        },
    )

    return AlertResponse(
        success=True,
        data=alert,
    )


@router.get(
    "",
    response_model=AlertListResponse,
    summary="List Alerts",
    description="List alerts with optional filtering.",
)
async def list_alerts(
    current_user: CurrentUser,
    db: DbSession,
    status: Optional[AlertStatus] = Query(default=None, description="Filter by status"),
    limit: int = Query(default=50, ge=1, le=100, description="Max alerts to return"),
    offset: int = Query(default=0, ge=0, description="Alerts to skip"),
) -> AlertListResponse:
    """
    List alerts with optional filtering.

    - **status**: Filter by draft, sent, or canceled
    - **limit**: Maximum number of alerts (default 50)
    - **offset**: Skip first N alerts
    """
    service = AlertService(db)
    alerts, total = await service.list_alerts(
        status=status,
        limit=limit,
        offset=offset,
    )

    return AlertListResponse(
        success=True,
        data=alerts,
        total=total,
    )


@router.get(
    "/{alert_id}",
    response_model=AlertResponse,
    summary="Get Alert",
    description="Get alert details by ID.",
)
async def get_alert(
    alert_id: str,
    current_user: CurrentUser,
    db: DbSession,
) -> AlertResponse:
    """
    Get alert details by ID.

    Returns full alert information including targeting areas and delivery count.
    """
    service = AlertService(db)
    alert = await service.get_alert(alert_id)

    return AlertResponse(
        success=True,
        data=alert,
    )


@router.post(
    "/{alert_id}/send",
    response_model=AlertSendResponse,
    summary="Send Alert",
    description="Send an alert to targeted devices. Requires admin or comunicacao role.",
)
async def send_alert(
    alert_id: str,
    request: Request,
    current_user: ComunicacaoUser,
    db: DbSession,
) -> AlertSendResponse:
    """
    Send an alert to targeted devices.

    Requires **admin** or **comunicacao** role.

    The alert must be in 'draft' status. After sending:
    - Status changes to 'sent'
    - Push notifications are queued via Celery
    - Delivery tracking records are created

    Returns the number of devices targeted and the background task ID.
    """
    ip_address = _get_client_ip(request)

    service = AlertService(db)
    audit_service = AuditService(db)

    # Send alert
    alert, devices_targeted, task_id = await service.send_alert(alert_id)

    # Log audit
    await audit_service.log_action(
        action=AuditAction.SEND_ALERT,
        resource=AuditResource.ALERT,
        resource_id=alert_id,
        user=current_user,
        ip_address=ip_address,
        user_agent=request.headers.get("User-Agent"),
        payload_summary={
            "devices_targeted": devices_targeted,
            "task_id": task_id,
        },
    )

    return AlertSendResponse(
        success=True,
        data=alert,
        devices_targeted=devices_targeted,
        task_id=task_id,
    )


@router.get(
    "/{alert_id}/stats",
    summary="Alert Statistics",
    description="Get delivery statistics for an alert.",
)
async def get_alert_stats(
    alert_id: str,
    current_user: CurrentUser,
    db: DbSession,
) -> dict:
    """
    Get delivery statistics for an alert.

    Returns:
    - **selected_devices**: Number of devices targeted
    - **sent**: Number of successfully sent notifications
    - **pending**: Number of pending notifications
    - **failed**: Number of failed notifications
    """
    service = AlertService(db)

    # Get alert to verify it exists
    alert = await service.get_alert(alert_id)

    # Get delivery stats
    stats = await service.get_delivery_stats(alert_id)

    return {
        "success": True,
        "data": {
            "alert_id": alert_id,
            "status": alert.status.value,
            "selected_devices": stats.get("total", 0),
            "sent": stats.get("sent", 0),
            "pending": stats.get("pending", 0),
            "failed": stats.get("failed", 0),
        },
    }
