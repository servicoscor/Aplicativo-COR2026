"""Operational status admin endpoints."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request

from app.core.security import get_current_admin_user, require_role
from app.db.session import get_db
from app.schemas.admin_user import AdminRole, AdminUser
from app.schemas.audit_log import AuditAction, AuditResource
from app.schemas.operational_status import (
    OperationalStatusHistoryResponse,
    OperationalStatusResponse,
    OperationalStatusUpdate,
)
from app.services.audit_service import AuditService
from app.services.operational_status_service import OperationalStatusService
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


@router.get(
    "/operational",
    response_model=OperationalStatusResponse,
    summary="Get Current Status",
    description="Get current operational status (city_stage 1-5 and heat_level 1-5).",
)
async def get_operational_status(
    current_user: CurrentUser,
    db: DbSession,
) -> OperationalStatusResponse:
    """
    Get current operational status of the city.

    Returns:
    - **city_stage**: 1-5 (stage of city operations)
    - **heat_level**: 1-5 (heat alert level)
    - **updated_at**: When the status was last updated
    - **updated_by**: Name of user who last updated
    """
    service = OperationalStatusService(db)
    status = await service.get_current()

    return OperationalStatusResponse(
        success=True,
        data=status,
    )


@router.post(
    "/operational",
    response_model=OperationalStatusResponse,
    summary="Update Operational Status",
    description="Update operational status. Requires admin or comunicacao role.",
)
async def update_operational_status(
    data: OperationalStatusUpdate,
    request: Request,
    current_user: ComunicacaoUser,
    db: DbSession,
) -> OperationalStatusResponse:
    """
    Update operational status of the city.

    Requires **admin** or **comunicacao** role.

    - **city_stage**: New city stage (1-5)
    - **heat_level**: New heat level (1-5)
    - **reason**: Reason for the change (required)
    - **source**: Source of the change (manual, alerta_rio, cor, sistema)

    The change is recorded in history with timestamp, user, and IP address.
    """
    ip_address = _get_client_ip(request)

    service = OperationalStatusService(db)
    audit_service = AuditService(db)

    # Update status
    status = await service.update(
        data=data,
        current_user=current_user,
        ip_address=ip_address,
    )

    # Log audit
    await audit_service.log_action(
        action=AuditAction.CHANGE_STATUS,
        resource=AuditResource.OPERATIONAL_STATUS,
        user=current_user,
        ip_address=ip_address,
        user_agent=request.headers.get("User-Agent"),
        payload_summary={
            "city_stage": data.city_stage,
            "heat_level": data.heat_level,
            "reason": data.reason,
            "source": data.source,
        },
    )

    return OperationalStatusResponse(
        success=True,
        data=status,
    )


@router.get(
    "/history",
    response_model=OperationalStatusHistoryResponse,
    summary="Get Status History",
    description="Get history of operational status changes.",
)
async def get_status_history(
    current_user: CurrentUser,
    db: DbSession,
    limit: int = Query(default=50, ge=1, le=200, description="Max entries to return"),
    offset: int = Query(default=0, ge=0, description="Entries to skip"),
) -> OperationalStatusHistoryResponse:
    """
    Get history of operational status changes.

    Returns list of status changes with:
    - Old and new values
    - Timestamp
    - User who made the change
    - Reason for the change
    - IP address
    """
    service = OperationalStatusService(db)
    entries, total = await service.get_history(limit=limit, offset=offset)

    return OperationalStatusHistoryResponse(
        success=True,
        data=entries,
        total=total,
    )
