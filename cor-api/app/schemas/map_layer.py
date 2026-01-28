from __future__ import annotations
"""Map layer schemas."""

from datetime import datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.common import BaseResponse


class LayerType(str, Enum):
    """Map layer types."""

    TILE = "tile"
    GEOJSON = "geojson"
    WMS = "wms"
    VECTOR = "vector"
    HEATMAP = "heatmap"


class LayerCategory(str, Enum):
    """Layer categories."""

    WEATHER = "weather"
    INFRASTRUCTURE = "infrastructure"
    INCIDENTS = "incidents"
    SENSORS = "sensors"
    BASEMAP = "basemap"


class MapLayerParameter(BaseModel):
    """Parameter definition for map layers."""

    model_config = ConfigDict(populate_by_name=True)

    name: str = Field(..., description="Parameter name")
    type: str = Field(..., description="Parameter type (string, number, boolean)")
    required: bool = Field(default=False, description="Whether parameter is required")
    default: Any | None = Field(default=None, description="Default value")
    description: str | None = Field(default=None, description="Parameter description")
    options: list[str] | None = Field(
        default=None, description="Valid options for enum parameters"
    )


class MapLayer(BaseModel):
    """Map layer definition."""

    model_config = ConfigDict(populate_by_name=True)

    id: str = Field(..., description="Unique layer identifier")
    name: str = Field(..., description="Display name")
    description: str | None = Field(default=None, description="Layer description")
    type: LayerType = Field(..., description="Layer type")
    category: LayerCategory = Field(..., description="Layer category")
    url_template: str | None = Field(
        default=None, description="URL template for tile/WMS layers"
    )
    endpoint: str | None = Field(
        default=None, description="API endpoint for dynamic data"
    )
    parameters: list[MapLayerParameter] = Field(
        default_factory=list, description="Available parameters"
    )
    min_zoom: int = Field(default=1, ge=1, le=22, description="Minimum zoom level")
    max_zoom: int = Field(default=18, ge=1, le=22, description="Maximum zoom level")
    default_visible: bool = Field(
        default=False, description="Whether layer is visible by default"
    )
    refresh_interval_seconds: int | None = Field(
        default=None, description="Auto-refresh interval in seconds"
    )
    attribution: str | None = Field(
        default=None, description="Data attribution/source"
    )
    style: dict[str, Any] | None = Field(
        default=None, description="Default style configuration"
    )
    last_updated: datetime | None = Field(
        default=None, description="Last data update timestamp"
    )


class MapLayersResponse(BaseResponse):
    """Response for map layers endpoint."""

    data: list[MapLayer] = Field(
        default_factory=list, description="Available map layers"
    )
    categories: list[str] = Field(
        default_factory=list, description="Available categories"
    )
