"""Audit log endpoints."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query

from app.core.security import require_role
from app.db.session import get_db
from app.schemas.admin_user import AdminRole, AdminUser
from app.schemas.audit_log import AuditLogResponse
from app.services.audit_service import AuditService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter()

DbSession = Annotated[AsyncSession, Depends(get_db)]
AdminOnly = Annotated[
    AdminUser,
    Depends(require_role([AdminRole.ADMIN])),
]


@router.get(
    "",
    response_model=AuditLogResponse,
    summary="List Audit Logs",
    description="List audit logs with optional filtering. Admin only.",
)
async def list_audit_logs(
    current_user: AdminOnly,
    db: DbSession,
    user_id: Optional[str] = Query(default=None, description="Filter by user ID"),
    action: Optional[str] = Query(default=None, description="Filter by action"),
    resource: Optional[str] = Query(default=None, description="Filter by resource type"),
    start_date: Optional[datetime] = Query(default=None, description="Filter by start date"),
    end_date: Optional[datetime] = Query(default=None, description="Filter by end date"),
    limit: int = Query(default=100, ge=1, le=500, description="Max entries to return"),
    offset: int = Query(default=0, ge=0, description="Entries to skip"),
) -> AuditLogResponse:
    """
    List audit logs with optional filtering.

    Requires **admin** role.

    Filters:
    - **user_id**: Filter by specific user
    - **action**: Filter by action type (login, change_status, create_alert, etc.)
    - **resource**: Filter by resource type (auth, operational_status, alert, etc.)
    - **start_date**: Filter entries after this date
    - **end_date**: Filter entries before this date

    Returns paginated list of audit log entries.
    """
    service = AuditService(db)

    entries, total = await service.list_logs(
        user_id=user_id,
        action=action,
        resource=resource,
        start_date=start_date,
        end_date=end_date,
        limit=limit,
        offset=offset,
    )

    return AuditLogResponse(
        success=True,
        data=entries,
        total=total,
    )


@router.get(
    "/actions",
    summary="List Available Actions",
    description="List all available audit action types.",
)
async def list_actions(
    current_user: AdminOnly,
) -> dict:
    """
    List all available audit action types.

    Useful for filtering audit logs.
    """
    from app.schemas.audit_log import AuditAction

    return {
        "success": True,
        "data": {
            "actions": [
                {"value": AuditAction.LOGIN, "label": "Login"},
                {"value": AuditAction.LOGOUT, "label": "Logout"},
                {"value": AuditAction.LOGIN_FAILED, "label": "Failed Login"},
                {"value": AuditAction.CHANGE_STATUS, "label": "Change Status"},
                {"value": AuditAction.CREATE_ALERT, "label": "Create Alert"},
                {"value": AuditAction.UPDATE_ALERT, "label": "Update Alert"},
                {"value": AuditAction.SEND_ALERT, "label": "Send Alert"},
                {"value": AuditAction.CANCEL_ALERT, "label": "Cancel Alert"},
                {"value": AuditAction.CREATE_USER, "label": "Create User"},
                {"value": AuditAction.UPDATE_USER, "label": "Update User"},
                {"value": AuditAction.DELETE_USER, "label": "Delete User"},
                {"value": AuditAction.DISABLE_USER, "label": "Disable User"},
            ],
        },
    }


@router.get(
    "/resources",
    summary="List Available Resources",
    description="List all available audit resource types.",
)
async def list_resources(
    current_user: AdminOnly,
) -> dict:
    """
    List all available audit resource types.

    Useful for filtering audit logs.
    """
    from app.schemas.audit_log import AuditResource

    return {
        "success": True,
        "data": {
            "resources": [
                {"value": AuditResource.AUTH, "label": "Authentication"},
                {"value": AuditResource.OPERATIONAL_STATUS, "label": "Operational Status"},
                {"value": AuditResource.ALERT, "label": "Alert"},
                {"value": AuditResource.USER, "label": "Admin User"},
            ],
        },
    }
