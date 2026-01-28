"""Devices API endpoints."""

from typing import Annotated

from fastapi import APIRouter, Depends, Header, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import RateLimitDep
from app.db.session import get_db
from app.schemas.device import (
    Device,
    DeviceLocationResponse,
    DeviceLocationUpdate,
    DeviceRegister,
    DeviceRegisterResponse,
    SubscriptionsResponse,
    SubscriptionsUpdate,
)
from app.services.device_service import DeviceService

router = APIRouter()

DbSession = Annotated[AsyncSession, Depends(get_db)]


@router.post(
    "/register",
    response_model=DeviceRegisterResponse,
    summary="Register Device",
    description="Register a new device or update existing one for push notifications.",
)
async def register_device(
    data: DeviceRegister,
    db: DbSession,
    _rate_limit: RateLimitDep = True,
) -> DeviceRegisterResponse:
    """
    Register or update a device for push notifications.

    If a device with the same push_token already exists, it will be updated.
    Otherwise, a new device will be created.

    Args:
        data: Device registration data including:
            - platform: "ios" or "android"
            - push_token: Device push notification token
            - neighborhoods: Optional list of favorite neighborhoods

    Returns:
        Registered device information (push_token is masked in response)
    """
    service = DeviceService(db)
    device = await service.register_device(data)

    return DeviceRegisterResponse(data=device)


@router.post(
    "/location",
    response_model=DeviceLocationResponse,
    summary="Update Device Location",
    description="Update device's last known location for geo-targeted alerts.",
)
async def update_location(
    data: DeviceLocationUpdate,
    db: DbSession,
    x_push_token: str = Header(
        ...,
        alias="X-Push-Token",
        description="Device push token for identification",
    ),
    _rate_limit: RateLimitDep = True,
) -> DeviceLocationResponse:
    """
    Update device location for geo-targeted alerts.

    The location is used to determine which geographic alerts
    should be sent to this device.

    Args:
        data: Location data with lat/lon coordinates
        x_push_token: Device push token (in header)

    Returns:
        Updated device information
    """
    service = DeviceService(db)
    device = await service.update_location(x_push_token, data)

    return DeviceLocationResponse(
        data=device,
        message="Location updated successfully",
    )


@router.get(
    "/me",
    response_model=DeviceRegisterResponse,
    summary="Get Device Info",
    description="Get current device information.",
)
async def get_device_info(
    db: DbSession,
    x_push_token: str = Header(
        ...,
        alias="X-Push-Token",
        description="Device push token for identification",
    ),
    _rate_limit: RateLimitDep = True,
) -> DeviceRegisterResponse:
    """
    Get device information.

    Args:
        x_push_token: Device push token (in header)

    Returns:
        Device information (push_token is masked in response)
    """
    from app.core.errors import NotFoundError

    service = DeviceService(db)
    device = await service.get_device_by_token(x_push_token)

    if not device:
        raise NotFoundError(
            message="Device not found",
            resource="device",
        )

    return DeviceRegisterResponse(data=device)


@router.get(
    "/subscriptions",
    response_model=SubscriptionsResponse,
    summary="Get Subscriptions",
    description="Get device's subscribed neighborhoods.",
)
async def get_subscriptions(
    db: DbSession,
    x_push_token: str = Header(
        ...,
        alias="X-Push-Token",
        description="Device push token for identification",
    ),
    _rate_limit: RateLimitDep = True,
) -> SubscriptionsResponse:
    """
    Get device's subscribed neighborhoods.

    Args:
        x_push_token: Device push token (in header)

    Returns:
        List of subscribed neighborhoods
    """
    service = DeviceService(db)
    neighborhoods = await service.get_subscriptions(x_push_token)

    return SubscriptionsResponse(
        subscribed_neighborhoods=neighborhoods,
        count=len(neighborhoods),
    )


@router.post(
    "/subscriptions",
    response_model=SubscriptionsResponse,
    summary="Update Subscriptions",
    description="Update device's subscribed neighborhoods.",
)
async def update_subscriptions(
    data: SubscriptionsUpdate,
    db: DbSession,
    x_push_token: str = Header(
        ...,
        alias="X-Push-Token",
        description="Device push token for identification",
    ),
    _rate_limit: RateLimitDep = True,
) -> SubscriptionsResponse:
    """
    Update device's subscribed neighborhoods.

    Args:
        data: List of neighborhoods to subscribe to
        x_push_token: Device push token (in header)

    Returns:
        Updated list of subscribed neighborhoods
    """
    service = DeviceService(db)
    neighborhoods = await service.update_subscriptions(
        push_token=x_push_token,
        neighborhoods=data.subscribed_neighborhoods,
    )

    return SubscriptionsResponse(
        subscribed_neighborhoods=neighborhoods,
        count=len(neighborhoods),
    )
