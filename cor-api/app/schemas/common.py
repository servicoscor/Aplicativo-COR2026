from __future__ import annotations
"""Common schema definitions used across the API."""

from datetime import datetime
from enum import Enum
from typing import Any, Generic, TypeVar

from pydantic import BaseModel, ConfigDict, Field


class SourceStatus(str, Enum):
    """Status of a data source."""

    OK = "ok"
    DEGRADED = "degraded"
    DOWN = "down"


class CacheInfo(BaseModel):
    """Information about cached data."""

    model_config = ConfigDict(populate_by_name=True)

    stale: bool = Field(
        default=False,
        description="Whether the data is stale (served from cache due to provider failure)",
    )
    age_seconds: int | None = Field(
        default=None,
        description="Age of the cached data in seconds",
    )
    cached_at: datetime | None = Field(
        default=None,
        description="Timestamp when the data was cached",
    )


class BaseResponse(BaseModel):
    """Base response model with common fields."""

    model_config = ConfigDict(populate_by_name=True)

    success: bool = Field(default=True, description="Whether the request was successful")
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(),
        description="Response timestamp",
    )
    cache: CacheInfo | None = Field(
        default=None,
        description="Cache information if data was served from cache",
    )


DataT = TypeVar("DataT")


class PaginatedResponse(BaseResponse, Generic[DataT]):
    """Paginated response model."""

    data: list[DataT] = Field(default_factory=list, description="List of items")
    total: int = Field(default=0, description="Total number of items")
    page: int = Field(default=1, description="Current page number")
    page_size: int = Field(default=50, description="Number of items per page")
    has_more: bool = Field(default=False, description="Whether there are more items")


class ErrorDetail(BaseModel):
    """Error detail model."""

    code: str = Field(..., description="Error code")
    message: str = Field(..., description="Error message")
    details: dict[str, Any] = Field(
        default_factory=dict, description="Additional error details"
    )


class ErrorResponse(BaseModel):
    """Error response model."""

    model_config = ConfigDict(populate_by_name=True)

    success: bool = Field(default=False)
    timestamp: datetime = Field(default_factory=lambda: datetime.now())
    error: ErrorDetail = Field(..., description="Error information")


class Coordinates(BaseModel):
    """Geographic coordinates."""

    latitude: float = Field(..., ge=-90, le=90, description="Latitude")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude")


class BoundingBox(BaseModel):
    """Geographic bounding box."""

    model_config = ConfigDict(populate_by_name=True)

    min_lon: float = Field(..., ge=-180, le=180, description="Minimum longitude (west)", serialization_alias="west")
    min_lat: float = Field(..., ge=-90, le=90, description="Minimum latitude (south)", serialization_alias="south")
    max_lon: float = Field(..., ge=-180, le=180, description="Maximum longitude (east)", serialization_alias="east")
    max_lat: float = Field(..., ge=-90, le=90, description="Maximum latitude (north)", serialization_alias="north")

    @property
    def west(self) -> float:
        """Alias for min_lon."""
        return self.min_lon

    @property
    def south(self) -> float:
        """Alias for min_lat."""
        return self.min_lat

    @property
    def east(self) -> float:
        """Alias for max_lon."""
        return self.max_lon

    @property
    def north(self) -> float:
        """Alias for max_lat."""
        return self.max_lat

    @classmethod
    def from_string(cls, bbox_str: str) -> "BoundingBox":
        """Parse bounding box from comma-separated string."""
        parts = [float(x.strip()) for x in bbox_str.split(",")]
        if len(parts) != 4:
            raise ValueError("Bounding box must have 4 values: min_lon,min_lat,max_lon,max_lat")
        return cls(
            min_lon=parts[0],
            min_lat=parts[1],
            max_lon=parts[2],
            max_lat=parts[3],
        )
