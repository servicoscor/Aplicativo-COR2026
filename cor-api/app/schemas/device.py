from __future__ import annotations
"""Device-related schemas."""

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.common import BaseResponse


class DevicePlatform(str, Enum):
    """Device platform types."""

    IOS = "ios"
    ANDROID = "android"


class DeviceRegister(BaseModel):
    """Schema for registering a device."""

    model_config = ConfigDict(populate_by_name=True)

    platform: DevicePlatform = Field(..., description="Device platform")
    push_token: str = Field(
        ...,
        min_length=10,
        max_length=500,
        description="Push notification token",
    )
    neighborhoods: list[str] | None = Field(
        default=None,
        description="Favorite neighborhoods for alerts",
    )

    @field_validator("push_token")
    @classmethod
    def validate_push_token(cls, v: str) -> str:
        return v.strip()

    @field_validator("neighborhoods", mode="before")
    @classmethod
    def validate_neighborhoods(cls, v: list[str] | None) -> list[str] | None:
        if v is not None:
            return [n.strip().lower() for n in v if n.strip()]
        return v


class DeviceLocationUpdate(BaseModel):
    """Schema for updating device location."""

    model_config = ConfigDict(populate_by_name=True)

    lat: float = Field(..., ge=-90, le=90, description="Latitude")
    lon: float = Field(..., ge=-180, le=180, description="Longitude")


class Device(BaseModel):
    """Device response model."""

    model_config = ConfigDict(populate_by_name=True)

    id: str = Field(..., description="Device ID")
    platform: DevicePlatform = Field(..., description="Device platform")
    push_token: str = Field(..., description="Push token (masked)")
    has_location: bool = Field(..., description="Whether device has location")
    neighborhoods: list[str] | None = Field(
        default=None, description="Favorite neighborhoods"
    )
    last_location_at: datetime | None = Field(
        default=None, description="Last location update"
    )
    created_at: datetime = Field(..., description="Registration time")
    updated_at: datetime = Field(..., description="Last update time")


class DeviceRegisterResponse(BaseResponse):
    """Response for device registration."""

    data: Device = Field(..., description="Registered device")


class DeviceLocationResponse(BaseResponse):
    """Response for location update."""

    data: Device = Field(..., description="Updated device")
    message: str = Field(default="Location updated", description="Status message")


class SubscriptionsUpdate(BaseModel):
    """Schema for updating device subscriptions."""

    model_config = ConfigDict(populate_by_name=True)

    subscribed_neighborhoods: list[str] = Field(
        ...,
        description="List of neighborhoods to subscribe to",
    )

    @field_validator("subscribed_neighborhoods", mode="before")
    @classmethod
    def validate_neighborhoods(cls, v: list[str]) -> list[str]:
        return [n.strip().lower() for n in v if n.strip()]


class SubscriptionsResponse(BaseResponse):
    """Response for subscriptions operations."""

    subscribed_neighborhoods: list[str] = Field(
        default_factory=list,
        description="List of subscribed neighborhoods",
    )
    count: int = Field(default=0, description="Number of subscribed neighborhoods")
