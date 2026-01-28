from __future__ import annotations
"""Rain gauge schemas."""

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.common import BaseResponse


class RainIntensity(str, Enum):
    """Rain intensity classification."""

    NONE = "none"  # 0 mm
    LIGHT = "light"  # 0.1 - 2.5 mm/h
    MODERATE = "moderate"  # 2.5 - 10 mm/h
    HEAVY = "heavy"  # 10 - 50 mm/h
    VERY_HEAVY = "very_heavy"  # > 50 mm/h


class RainGaugeReading(BaseModel):
    """Single rain gauge reading."""

    model_config = ConfigDict(populate_by_name=True)

    timestamp: datetime = Field(..., description="Reading timestamp")
    value_mm: float = Field(..., ge=0, description="Precipitation in mm")
    accumulated_5min: float | None = Field(
        default=None, ge=0, description="5-minute accumulated precipitation"
    )
    accumulated_15min: float | None = Field(
        default=None, ge=0, description="15-minute accumulated precipitation"
    )
    accumulated_1h: float | None = Field(
        default=None, ge=0, description="1-hour accumulated precipitation"
    )
    accumulated_4h: float | None = Field(
        default=None, ge=0, description="4-hour accumulated precipitation"
    )
    accumulated_24h: float | None = Field(
        default=None, ge=0, description="24-hour accumulated precipitation"
    )
    accumulated_96h: float | None = Field(
        default=None, ge=0, description="96-hour (4-day) accumulated precipitation"
    )
    accumulated_month: float | None = Field(
        default=None, ge=0, description="Monthly accumulated precipitation"
    )
    intensity: RainIntensity = Field(
        default=RainIntensity.NONE, description="Rain intensity classification"
    )


class RainGauge(BaseModel):
    """Rain gauge station with latest reading."""

    model_config = ConfigDict(populate_by_name=True)

    id: str = Field(..., description="Station identifier")
    name: str = Field(..., description="Station name")
    latitude: float = Field(..., ge=-90, le=90, description="Station latitude")
    longitude: float = Field(..., ge=-180, le=180, description="Station longitude")
    altitude_m: float | None = Field(
        default=None, description="Station altitude in meters"
    )
    neighborhood: str | None = Field(
        default=None, description="Neighborhood/district name"
    )
    region: str | None = Field(default=None, description="City region")
    status: str = Field(default="active", description="Station status")
    last_reading: RainGaugeReading | None = Field(
        default=None, description="Most recent reading"
    )
    last_updated: datetime | None = Field(
        default=None, description="Last data update timestamp"
    )


class RainGaugesSummary(BaseModel):
    """Summary statistics for rain gauges."""

    model_config = ConfigDict(populate_by_name=True)

    total_stations: int = Field(..., description="Total number of stations")
    active_stations: int = Field(..., description="Number of active stations")
    stations_with_rain: int = Field(
        default=0, description="Stations currently reporting rain"
    )
    max_rain_15min: float = Field(
        default=0, ge=0, description="Maximum 15-min rainfall across all stations"
    )
    max_rain_1h: float = Field(
        default=0, ge=0, description="Maximum 1-hour rainfall across all stations"
    )
    avg_rain_1h: float = Field(
        default=0, ge=0, description="Average 1-hour rainfall across all stations"
    )


class RainGaugesResponse(BaseResponse):
    """Response for rain gauges endpoint."""

    data: list[RainGauge] = Field(
        default_factory=list, description="List of rain gauge stations"
    )
    summary: RainGaugesSummary = Field(..., description="Summary statistics")
    bbox_applied: str | None = Field(
        default=None, description="Bounding box filter that was applied"
    )
