from __future__ import annotations
"""Siren schemas for WebSirene Rio data."""

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class SirenStatus(str, Enum):
    """Siren operational status."""

    INACTIVE = "ds"  # Desativada
    ACTIVE = "at"    # Ativa (pronta)
    TRIGGERED = "ac"  # Acionada (em alarme)
    UNKNOWN = "unknown"


class Siren(BaseModel):
    """Siren station model."""

    id: str = Field(..., description="Unique siren identifier")
    name: str = Field(..., description="Siren name/location")
    latitude: float = Field(..., description="Latitude coordinate")
    longitude: float = Field(..., description="Longitude coordinate")
    basin: str | None = Field(None, description="Hydrographic basin")
    online: bool = Field(False, description="Whether siren is connected")
    status: SirenStatus = Field(SirenStatus.UNKNOWN, description="Operational status")
    status_label: str = Field("Desconhecido", description="Human-readable status")

    @property
    def is_triggered(self) -> bool:
        """Check if siren is currently triggered (alarm active)."""
        return self.status == SirenStatus.TRIGGERED

    @property
    def is_operational(self) -> bool:
        """Check if siren is operational (active or triggered)."""
        return self.status in (SirenStatus.ACTIVE, SirenStatus.TRIGGERED)


class SirensSummary(BaseModel):
    """Summary statistics for sirens."""

    total_sirens: int = Field(0, description="Total number of sirens")
    online_sirens: int = Field(0, description="Number of online sirens")
    active_sirens: int = Field(0, description="Number of active sirens")
    triggered_sirens: int = Field(0, description="Number of triggered sirens")
    inactive_sirens: int = Field(0, description="Number of inactive sirens")


class SirensResponse(BaseModel):
    """Response model for sirens endpoint."""

    success: bool = Field(True, description="Whether request was successful")
    timestamp: datetime = Field(..., description="Response timestamp")
    data: list[Siren] = Field(default_factory=list, description="List of sirens")
    summary: SirensSummary = Field(..., description="Sirens summary")
    data_timestamp: datetime | None = Field(None, description="When data was collected")
    is_stale: bool = Field(False, description="Whether data is from cache fallback")
