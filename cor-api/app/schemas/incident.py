from __future__ import annotations
"""Incident-related schemas."""

from datetime import datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.common import BaseResponse


class IncidentType(str, Enum):
    """Types of incidents."""

    TRAFFIC = "traffic"
    FLOODING = "flooding"
    LANDSLIDE = "landslide"
    FIRE = "fire"
    ACCIDENT = "accident"
    ROAD_WORK = "road_work"
    EVENT = "event"
    UTILITY = "utility"
    WEATHER_ALERT = "weather_alert"
    OTHER = "other"


class IncidentSeverity(str, Enum):
    """Incident severity levels."""

    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class IncidentStatus(str, Enum):
    """Incident status."""

    OPEN = "open"
    IN_PROGRESS = "in_progress"
    RESOLVED = "resolved"
    CLOSED = "closed"


class GeometryType(str, Enum):
    """GeoJSON geometry types."""

    POINT = "Point"
    LINE_STRING = "LineString"
    POLYGON = "Polygon"
    MULTI_POINT = "MultiPoint"
    MULTI_LINE_STRING = "MultiLineString"
    MULTI_POLYGON = "MultiPolygon"


class IncidentGeometry(BaseModel):
    """GeoJSON-like geometry for incidents."""

    model_config = ConfigDict(populate_by_name=True)

    type: GeometryType = Field(..., description="Geometry type")
    coordinates: list[Any] = Field(..., description="Geometry coordinates")


class IncidentLocation(BaseModel):
    """Incident location details."""

    model_config = ConfigDict(populate_by_name=True)

    address: str | None = Field(default=None, description="Street address")
    neighborhood: str | None = Field(default=None, description="Neighborhood name")
    region: str | None = Field(default=None, description="City region")
    reference: str | None = Field(default=None, description="Location reference")


class Incident(BaseModel):
    """Incident information."""

    model_config = ConfigDict(populate_by_name=True)

    id: str = Field(..., description="Unique incident identifier")
    type: IncidentType = Field(..., description="Incident type")
    severity: IncidentSeverity = Field(
        default=IncidentSeverity.MEDIUM, description="Incident severity"
    )
    status: IncidentStatus = Field(..., description="Current status")
    title: str = Field(..., description="Incident title/headline")
    description: str | None = Field(default=None, description="Detailed description")
    geometry: IncidentGeometry = Field(..., description="Location geometry")
    location: IncidentLocation = Field(
        default_factory=IncidentLocation, description="Location details"
    )
    started_at: datetime = Field(..., description="Incident start time")
    updated_at: datetime = Field(..., description="Last update time")
    resolved_at: datetime | None = Field(
        default=None, description="Resolution time if resolved"
    )
    source: str = Field(default="COR", description="Data source")
    affected_routes: list[str] = Field(
        default_factory=list, description="Affected routes/roads"
    )
    tags: list[str] = Field(default_factory=list, description="Incident tags")


class IncidentsSummary(BaseModel):
    """Summary of incidents."""

    model_config = ConfigDict(populate_by_name=True)

    total: int = Field(..., description="Total number of incidents")
    by_type: dict[str, int] = Field(
        default_factory=dict, description="Count by incident type"
    )
    by_severity: dict[str, int] = Field(
        default_factory=dict, description="Count by severity"
    )
    by_status: dict[str, int] = Field(
        default_factory=dict, description="Count by status"
    )


class IncidentsResponse(BaseResponse):
    """Response for incidents endpoint."""

    data: list[Incident] = Field(
        default_factory=list, description="List of incidents"
    )
    summary: IncidentsSummary = Field(..., description="Incidents summary")
    bbox_applied: str | None = Field(
        default=None, description="Bounding box filter applied"
    )
    since_applied: datetime | None = Field(
        default=None, description="Since filter applied"
    )
    type_filter_applied: list[str] | None = Field(
        default=None, description="Type filter applied"
    )
