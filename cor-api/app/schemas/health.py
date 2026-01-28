from __future__ import annotations
"""Health check schemas."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.common import SourceStatus


class SourceHealth(BaseModel):
    """Health status of a data source."""

    model_config = ConfigDict(populate_by_name=True)

    name: str = Field(..., description="Source name")
    status: SourceStatus = Field(..., description="Current status")
    mode: str = Field(
        default="mock",
        description="Provider mode: 'mock' or 'real'",
    )
    last_success: datetime | None = Field(
        default=None, description="Last successful fetch timestamp"
    )
    last_error: str | None = Field(
        default=None, description="Last error message if any"
    )
    latency_ms: float | None = Field(
        default=None, description="Last request latency in milliseconds"
    )
    cache_age_seconds: int | None = Field(
        default=None, description="Age of cached data in seconds"
    )


class HealthResponse(BaseModel):
    """Health check response."""

    model_config = ConfigDict(populate_by_name=True)

    status: str = Field(..., description="Overall service status")
    version: str = Field(..., description="API version")
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(),
        description="Response timestamp",
    )
    uptime_seconds: float = Field(..., description="Service uptime in seconds")
    sources: list[SourceHealth] = Field(
        default_factory=list, description="Status of data sources"
    )
    database: str = Field(default="unknown", description="Database connection status")
    redis: str = Field(default="unknown", description="Redis connection status")
