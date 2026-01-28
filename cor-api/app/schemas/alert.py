"""Alert-related schemas."""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.common import BaseResponse


class AlertSeverity(str, Enum):
    """Alert severity levels."""

    INFO = "info"
    ALERT = "alert"
    EMERGENCY = "emergency"


class AlertStatus(str, Enum):
    """Alert status."""

    DRAFT = "draft"
    SENT = "sent"
    CANCELED = "canceled"


# ==================== Area Schemas ====================

class GeoJSONGeometry(BaseModel):
    """GeoJSON geometry for alert areas."""

    model_config = ConfigDict(populate_by_name=True)

    type: str = Field(..., description="Geometry type (Polygon or MultiPolygon)")
    coordinates: List[Any] = Field(..., description="Geometry coordinates")

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        allowed = ["Polygon", "MultiPolygon"]
        if v not in allowed:
            raise ValueError(f"Geometry type must be one of {allowed}")
        return v


class CircleArea(BaseModel):
    """Circle area defined by center and radius."""

    model_config = ConfigDict(populate_by_name=True)

    center_lat: float = Field(..., ge=-90, le=90, description="Center latitude")
    center_lon: float = Field(..., ge=-180, le=180, description="Center longitude")
    radius_m: float = Field(..., gt=0, le=50000, description="Radius in meters (max 50km)")


class AlertAreaInput(BaseModel):
    """Input for alert area - either GeoJSON or circle."""

    model_config = ConfigDict(populate_by_name=True)

    geojson: Optional[GeoJSONGeometry] = Field(
        default=None, description="GeoJSON Polygon/MultiPolygon"
    )
    circle: Optional[CircleArea] = Field(
        default=None, description="Circle defined by center and radius"
    )

    @field_validator("circle", mode="after")
    @classmethod
    def validate_at_least_one(cls, v: Optional[CircleArea], info) -> Optional[CircleArea]:
        geojson = info.data.get("geojson")
        if v is None and geojson is None:
            # Both can be None for broadcast alerts
            pass
        return v


# ==================== Alert Schemas ====================

class AlertCreate(BaseModel):
    """Schema for creating an alert."""

    model_config = ConfigDict(populate_by_name=True)

    title: str = Field(..., min_length=1, max_length=200, description="Alert title")
    body: str = Field(..., min_length=1, max_length=2000, description="Alert body/message")
    severity: AlertSeverity = Field(
        default=AlertSeverity.INFO, description="Alert severity"
    )
    broadcast: bool = Field(
        default=False, description="Send to all users (ignores area)"
    )
    area: Optional[AlertAreaInput] = Field(
        default=None, description="Geographic area for targeting"
    )
    neighborhoods: Optional[List[str]] = Field(
        default=None, description="Target neighborhoods (fallback)"
    )
    expires_at: Optional[datetime] = Field(
        default=None, description="Alert expiration time"
    )

    @field_validator("neighborhoods", mode="before")
    @classmethod
    def validate_neighborhoods(cls, v: Optional[List[str]]) -> Optional[List[str]]:
        if v is not None:
            return [n.strip().lower() for n in v if n.strip()]
        return v


class AlertUpdate(BaseModel):
    """Schema for updating an alert (only draft)."""

    model_config = ConfigDict(populate_by_name=True)

    title: Optional[str] = Field(default=None, max_length=200)
    body: Optional[str] = Field(default=None, max_length=2000)
    severity: Optional[AlertSeverity] = None
    expires_at: Optional[datetime] = None


class AlertAreaResponse(BaseModel):
    """Alert area in response."""

    model_config = ConfigDict(populate_by_name=True)

    id: str = Field(..., description="Area ID")
    geojson: Optional[Dict[str, Any]] = Field(
        default=None, description="GeoJSON representation"
    )


class Alert(BaseModel):
    """Alert response model."""

    model_config = ConfigDict(populate_by_name=True)

    id: str = Field(..., description="Alert ID")
    title: str = Field(..., description="Alert title")
    body: str = Field(..., description="Alert body")
    severity: AlertSeverity = Field(..., description="Severity level")
    status: AlertStatus = Field(..., description="Current status")
    broadcast: bool = Field(..., description="Is broadcast alert")
    neighborhoods: Optional[List[str]] = Field(
        default=None, description="Target neighborhoods"
    )
    expires_at: Optional[datetime] = Field(default=None, description="Expiration time")
    created_at: datetime = Field(..., description="Creation time")
    sent_at: Optional[datetime] = Field(default=None, description="Send time")
    created_by: Optional[str] = Field(default=None, description="Creator identifier")
    areas: List[AlertAreaResponse] = Field(
        default_factory=list, description="Geographic areas"
    )
    delivery_count: int = Field(default=0, description="Number of deliveries")


class AlertListResponse(BaseResponse):
    """Response for alerts list."""

    data: List[Alert] = Field(default_factory=list, description="List of alerts")
    total: int = Field(default=0, description="Total count")


class AlertDetailResponse(BaseResponse):
    """Response for single alert."""

    data: Alert = Field(..., description="Alert details")


class AlertSendResponse(BaseResponse):
    """Response after sending alert."""

    data: Alert = Field(..., description="Updated alert")
    devices_targeted: int = Field(
        default=0, description="Number of devices targeted"
    )
    task_id: Optional[str] = Field(
        default=None, description="Celery task ID"
    )


# ==================== Inbox Schemas ====================

class InboxAlert(BaseModel):
    """Alert in user's inbox."""

    model_config = ConfigDict(populate_by_name=True)

    id: str = Field(..., description="Alert ID")
    title: str = Field(..., description="Alert title")
    body: str = Field(..., description="Alert body")
    severity: AlertSeverity = Field(..., description="Severity level")
    sent_at: datetime = Field(..., description="When alert was sent")
    expires_at: Optional[datetime] = Field(default=None, description="Expiration time")
    neighborhoods: Optional[List[str]] = Field(
        default=None, description="Target neighborhoods"
    )
    match_type: str = Field(
        ..., description="How this alert matched (broadcast/geo/neighborhood)"
    )
    is_read: bool = Field(default=False, description="Whether user has read this alert")
    read_at: Optional[datetime] = Field(default=None, description="When user read the alert")


class InboxResponse(BaseResponse):
    """Response for alerts inbox."""

    data: List[InboxAlert] = Field(
        default_factory=list, description="Alerts for this user"
    )
    unread_count: int = Field(default=0, description="Number of unread alerts")


class MarkAsReadResponse(BaseResponse):
    """Response for marking alert as read."""

    alert_id: str = Field(..., description="Alert ID that was marked as read")
    read_at: datetime = Field(..., description="Timestamp when marked as read")


# Alias for backward compatibility
AlertResponse = AlertDetailResponse
