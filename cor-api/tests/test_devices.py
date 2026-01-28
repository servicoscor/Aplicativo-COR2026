"""Tests for device registration and location endpoints."""

from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.schemas.device import Device, DevicePlatform


@pytest.fixture
def mock_device() -> Device:
    """Create a mock device for testing."""
    return Device(
        id="test-device-123",
        platform=DevicePlatform.IOS,
        push_token="abc123...xyz9",
        has_location=False,
        neighborhoods=["copacabana", "ipanema"],
        last_location_at=None,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )


@pytest.fixture
def mock_device_with_location(mock_device: Device) -> Device:
    """Create a mock device with location."""
    return Device(
        id=mock_device.id,
        platform=mock_device.platform,
        push_token=mock_device.push_token,
        has_location=True,
        neighborhoods=mock_device.neighborhoods,
        last_location_at=datetime.now(timezone.utc),
        created_at=mock_device.created_at,
        updated_at=datetime.now(timezone.utc),
    )


@pytest.fixture
def mock_device_service(mock_device: Device) -> MagicMock:
    """Create mock device service."""
    service = MagicMock()
    service.register_device = AsyncMock(return_value=mock_device)
    service.update_location = AsyncMock(return_value=mock_device)
    service.get_device_by_token = AsyncMock(return_value=mock_device)
    return service


def test_register_device_success(
    client: TestClient,
    mock_redis_connected: None,
    mock_device: Device,
) -> None:
    """Test device registration endpoint."""
    with patch("app.api.v1.devices.DeviceService") as MockService:
        mock_service = MagicMock()
        mock_service.register_device = AsyncMock(return_value=mock_device)
        MockService.return_value = mock_service

        response = client.post(
            "/v1/devices/register",
            json={
                "platform": "ios",
                "push_token": "test-push-token-12345",
                "neighborhoods": ["copacabana", "ipanema"],
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert data["data"]["platform"] == "ios"
        assert data["data"]["has_location"] is False


def test_register_device_android(
    client: TestClient,
    mock_redis_connected: None,
) -> None:
    """Test device registration with Android platform."""
    mock_device = Device(
        id="android-device-123",
        platform=DevicePlatform.ANDROID,
        push_token="fcm123...xyz9",
        has_location=False,
        neighborhoods=None,
        last_location_at=None,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )

    with patch("app.api.v1.devices.DeviceService") as MockService:
        mock_service = MagicMock()
        mock_service.register_device = AsyncMock(return_value=mock_device)
        MockService.return_value = mock_service

        response = client.post(
            "/v1/devices/register",
            json={
                "platform": "android",
                "push_token": "fcm-test-push-token-12345",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["platform"] == "android"


def test_register_device_invalid_platform(
    client: TestClient,
    mock_redis_connected: None,
) -> None:
    """Test device registration with invalid platform."""
    response = client.post(
        "/v1/devices/register",
        json={
            "platform": "windows",
            "push_token": "test-push-token-12345",
        },
    )

    assert response.status_code == 422


def test_register_device_short_token(
    client: TestClient,
    mock_redis_connected: None,
) -> None:
    """Test device registration with too short push token."""
    response = client.post(
        "/v1/devices/register",
        json={
            "platform": "ios",
            "push_token": "short",
        },
    )

    assert response.status_code == 422


def test_update_location_success(
    client: TestClient,
    mock_redis_connected: None,
    mock_device_with_location: Device,
) -> None:
    """Test device location update endpoint."""
    with patch("app.api.v1.devices.DeviceService") as MockService:
        mock_service = MagicMock()
        mock_service.update_location = AsyncMock(return_value=mock_device_with_location)
        MockService.return_value = mock_service

        response = client.post(
            "/v1/devices/location",
            json={
                "lat": -22.9068,
                "lon": -43.1729,
            },
            headers={"X-Push-Token": "test-push-token-12345"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["has_location"] is True
        assert data["message"] == "Location updated successfully"


def test_update_location_missing_token(
    client: TestClient,
    mock_redis_connected: None,
) -> None:
    """Test location update without push token header."""
    response = client.post(
        "/v1/devices/location",
        json={
            "lat": -22.9068,
            "lon": -43.1729,
        },
    )

    assert response.status_code == 422


def test_update_location_invalid_coordinates(
    client: TestClient,
    mock_redis_connected: None,
) -> None:
    """Test location update with invalid coordinates."""
    response = client.post(
        "/v1/devices/location",
        json={
            "lat": 100,  # Invalid latitude
            "lon": -43.1729,
        },
        headers={"X-Push-Token": "test-push-token-12345"},
    )

    assert response.status_code == 422


def test_get_device_info_success(
    client: TestClient,
    mock_redis_connected: None,
    mock_device: Device,
) -> None:
    """Test get device info endpoint."""
    with patch("app.api.v1.devices.DeviceService") as MockService:
        mock_service = MagicMock()
        mock_service.get_device_by_token = AsyncMock(return_value=mock_device)
        MockService.return_value = mock_service

        response = client.get(
            "/v1/devices/me",
            headers={"X-Push-Token": "test-push-token-12345"},
        )

        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert data["data"]["id"] == mock_device.id


def test_get_device_info_not_found(
    client: TestClient,
    mock_redis_connected: None,
) -> None:
    """Test get device info when not found."""
    with patch("app.api.v1.devices.DeviceService") as MockService:
        mock_service = MagicMock()
        mock_service.get_device_by_token = AsyncMock(return_value=None)
        MockService.return_value = mock_service

        response = client.get(
            "/v1/devices/me",
            headers={"X-Push-Token": "nonexistent-token"},
        )

        assert response.status_code == 404
