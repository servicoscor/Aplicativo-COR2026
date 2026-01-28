"""Audit log Pydantic schemas."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.common import BaseResponse


class AuditLogEntry(BaseModel):
    """Audit log entry response schema."""

    model_config = ConfigDict(populate_by_name=True)

    id: int = Field(..., description="Log entry ID")
    user_id: Optional[str] = Field(default=None, description="User ID who performed the action")
    user_email: Optional[str] = Field(default=None, description="User email")
    user_name: Optional[str] = Field(default=None, description="User name")
    action: str = Field(..., description="Action performed (e.g., create_alert, change_status)")
    resource: str = Field(..., description="Resource type (e.g., alert, operational_status)")
    resource_id: Optional[str] = Field(default=None, description="Resource ID affected")
    payload_summary: Optional[Dict[str, Any]] = Field(default=None, description="Summary of the action payload")
    ip_address: Optional[str] = Field(default=None, description="IP address of the user")
    user_agent: Optional[str] = Field(default=None, description="User agent string")
    created_at: datetime = Field(..., description="Timestamp when action was performed")


class AuditLogResponse(BaseResponse):
    """Audit log list response."""

    data: List[AuditLogEntry] = Field(default_factory=list)
    total: int = Field(default=0, description="Total number of log entries")


class AuditLogCreate(BaseModel):
    """Internal schema for creating an audit log entry."""

    user_id: Optional[str] = None
    action: str
    resource: str
    resource_id: Optional[str] = None
    payload_summary: Optional[Dict[str, Any]] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None


# ============================================================================
# Audit Action Constants
# ============================================================================


class AuditAction:
    """Constants for audit actions."""

    # Auth actions
    LOGIN = "login"
    LOGOUT = "logout"
    LOGIN_FAILED = "login_failed"

    # Status actions
    CHANGE_STATUS = "change_status"

    # Alert actions
    CREATE_ALERT = "create_alert"
    UPDATE_ALERT = "update_alert"
    SEND_ALERT = "send_alert"
    CANCEL_ALERT = "cancel_alert"

    # User management actions
    CREATE_USER = "create_user"
    UPDATE_USER = "update_user"
    DELETE_USER = "delete_user"
    DISABLE_USER = "disable_user"


class AuditResource:
    """Constants for audit resources."""

    AUTH = "auth"
    OPERATIONAL_STATUS = "operational_status"
    ALERT = "alert"
    USER = "admin_user"
