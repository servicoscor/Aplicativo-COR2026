"""Operational status Pydantic schemas."""

from __future__ import annotations

from datetime import datetime
from typing import List, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.common import BaseResponse


class OperationalStatusBase(BaseModel):
    """Base operational status fields."""

    model_config = ConfigDict(populate_by_name=True)

    city_stage: int = Field(..., ge=1, le=5, description="City stage (1-5)")
    heat_level: int = Field(..., ge=1, le=5, description="Heat level (1-5)")


class OperationalStatusUpdate(OperationalStatusBase):
    """Schema for updating operational status."""

    reason: str = Field(
        ...,
        min_length=1,
        max_length=500,
        description="Reason for the status change (required)",
    )
    source: Literal["manual", "alerta_rio", "cor", "sistema"] = Field(
        default="manual",
        description="Source of the status change",
    )


class OperationalStatusCurrent(OperationalStatusBase):
    """Current operational status response."""

    updated_at: datetime = Field(..., description="Last update timestamp")
    updated_by: Optional[str] = Field(default=None, description="Name of user who made the update")
    is_stale: bool = Field(default=False, description="Whether data is stale (from cache)")


class OperationalStatusResponse(BaseResponse):
    """Current operational status response wrapper."""

    data: OperationalStatusCurrent


class OperationalStatusHistory(OperationalStatusBase):
    """Operational status history entry."""

    id: int = Field(..., description="History entry ID")
    reason: Optional[str] = Field(default=None, description="Reason for change")
    source: Optional[str] = Field(default=None, description="Source of change")
    changed_at: datetime = Field(..., description="Change timestamp")
    changed_by: Optional[str] = Field(default=None, description="Name of user who made the change")
    ip_address: Optional[str] = Field(default=None, description="IP address of the user")


class OperationalStatusHistoryResponse(BaseResponse):
    """Status history response."""

    data: List[OperationalStatusHistory] = Field(default_factory=list)
    total: int = Field(default=0, description="Total number of history entries")


# ============================================================================
# Public API Schemas (for mobile app)
# ============================================================================


class PublicOperationalStatus(OperationalStatusBase):
    """Public operational status for mobile app (simplified)."""

    model_config = ConfigDict(populate_by_name=True)

    updated_at: datetime = Field(..., description="Last update timestamp")
    is_stale: bool = Field(default=False, description="Whether data is stale")


class PublicOperationalStatusResponse(BaseResponse):
    """Public operational status response for mobile app."""

    data: PublicOperationalStatus
