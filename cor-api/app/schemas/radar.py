from __future__ import annotations
"""Radar-related schemas."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.common import BaseResponse, BoundingBox


class RadarSnapshot(BaseModel):
    """Radar snapshot metadata."""

    model_config = ConfigDict(populate_by_name=True)

    id: str = Field(..., description="Unique snapshot identifier")
    timestamp: datetime = Field(..., description="Radar image timestamp")
    url: str = Field(..., description="URL to the radar image")
    thumbnail_url: str | None = Field(
        default=None, description="URL to thumbnail image"
    )
    bbox: BoundingBox = Field(
        ...,
        description="Geographic bounding box",
        serialization_alias="bounding_box",
    )
    resolution: str = Field(
        default="1km", description="Radar resolution (e.g., '1km', '500m')"
    )
    product_type: str = Field(
        default="reflectivity", description="Radar product type"
    )
    source: str = Field(default="INMET", description="Data source")
    valid_until: datetime | None = Field(
        default=None, description="Validity end time"
    )


class RadarMetadata(BaseModel):
    """Additional radar metadata."""

    model_config = ConfigDict(populate_by_name=True)

    station_name: str = Field(
        default="Pico do Couto", description="Radar station name"
    )
    station_lat: float = Field(
        default=-22.4667, description="Station latitude"
    )
    station_lon: float = Field(
        default=-43.2833, description="Station longitude"
    )
    range_km: int = Field(default=400, description="Radar range in km")
    update_interval_minutes: int = Field(
        default=10, description="Update interval in minutes"
    )


class RadarLatestResponse(BaseResponse):
    """Response for latest radar endpoint."""

    data: RadarSnapshot = Field(..., description="Latest radar snapshot")
    metadata: RadarMetadata = Field(
        default_factory=RadarMetadata,
        description="Radar metadata",
    )
    previous_snapshots: list[RadarSnapshot] = Field(
        default_factory=list,
        description="Previous radar snapshots for animation",
        max_length=12,
    )
