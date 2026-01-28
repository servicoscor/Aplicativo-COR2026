"""Tests for alerts CRUD and inbox endpoints."""

from datetime import datetime, timezone, timedelta
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.schemas.alert import (
    Alert,
    AlertSeverity,
    AlertStatus,
    InboxAlert,
)


@pytest.fixture
def mock_alert() -> Alert:
    """Create a mock alert for testing."""
    return Alert(
        id="alert-123",
        title="Test Alert",
        body="This is a test alert message",
        severity=AlertSeverity.INFO,
        status=AlertStatus.DRAFT,
        broadcast=False,
        neighborhoods=["copacabana", "ipanema"],
        expires_at=datetime.now(timezone.utc) + timedelta(hours=24),
        created_at=datetime.now(timezone.utc),
        sent_at=None,
        created_by="test-user",
        areas=[],
        delivery_count=0,
    )


@pytest.fixture
def mock_broadcast_alert() -> Alert:
    """Create a mock broadcast alert."""
    return Alert(
        id="alert-broadcast-456",
        title="Emergency Broadcast",
        body="This is an emergency broadcast to all users",
        severity=AlertSeverity.EMERGENCY,
        status=AlertStatus.SENT,
        broadcast=True,
        neighborhoods=None,
        expires_at=datetime.now(timezone.utc) + timedelta(hours=6),
        created_at=datetime.now(timezone.utc),
        sent_at=datetime.now(timezone.utc),
        created_by="admin",
        areas=[],
        delivery_count=150,
    )


@pytest.fixture
def mock_inbox_alert() -> InboxAlert:
    """Create a mock inbox alert."""
    return InboxAlert(
        id="alert-inbox-789",
        title="Inbox Alert",
        body="Alert message for inbox",
        severity=AlertSeverity.ALERT,
        sent_at=datetime.now(timezone.utc),
        expires_at=datetime.now(timezone.utc) + timedelta(hours=12),
        match_type="broadcast",
    )


def test_create_alert_success(
    client: TestClient,
    mock_redis_connected: None,
    mock_alert: Alert,
) -> None:
    """Test create alert endpoint."""
    with patch("app.api.v1.alerts.AlertService") as MockService:
        mock_service = MagicMock()
        mock_service.create_alert = AsyncMock(return_value=mock_alert)
        MockService.return_value = mock_service

        response = client.post(
            "/v1/alerts",
            json={
                "title": "Test Alert",
                "body": "This is a test alert message",
                "severity": "info",
                "broadcast": False,
                "neighborhoods": ["copacabana", "ipanema"],
            },
            headers={"X-API-Key": "test-api-key"},
        )

        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert data["data"]["title"] == "Test Alert"
        assert data["data"]["status"] == "draft"


def test_create_broadcast_alert(
    client: TestClient,
    mock_redis_connected: None,
    mock_broadcast_alert: Alert,
) -> None:
    """Test create broadcast alert."""
    mock_broadcast_alert.status = AlertStatus.DRAFT

    with patch("app.api.v1.alerts.AlertService") as MockService:
        mock_service = MagicMock()
        mock_service.create_alert = AsyncMock(return_value=mock_broadcast_alert)
        MockService.return_value = mock_service

        response = client.post(
            "/v1/alerts",
            json={
                "title": "Emergency Broadcast",
                "body": "This is an emergency broadcast",
                "severity": "emergency",
                "broadcast": True,
            },
            headers={"X-API-Key": "test-api-key"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["broadcast"] is True
        assert data["data"]["severity"] == "emergency"


def test_create_alert_with_circle_area(
    client: TestClient,
    mock_redis_connected: None,
    mock_alert: Alert,
) -> None:
    """Test create alert with circular geo-targeting."""
    with patch("app.api.v1.alerts.AlertService") as MockService:
        mock_service = MagicMock()
        mock_service.create_alert = AsyncMock(return_value=mock_alert)
        MockService.return_value = mock_service

        response = client.post(
            "/v1/alerts",
            json={
                "title": "Local Alert",
                "body": "Alert for specific area",
                "severity": "alert",
                "area": {
                    "circle": {
                        "center_lat": -22.9068,
                        "center_lon": -43.1729,
                        "radius_m": 5000,
                    }
                },
            },
            headers={"X-API-Key": "test-api-key"},
        )

        assert response.status_code == 200


def test_create_alert_with_polygon_area(
    client: TestClient,
    mock_redis_connected: None,
    mock_alert: Alert,
) -> None:
    """Test create alert with polygon geo-targeting."""
    with patch("app.api.v1.alerts.AlertService") as MockService:
        mock_service = MagicMock()
        mock_service.create_alert = AsyncMock(return_value=mock_alert)
        MockService.return_value = mock_service

        response = client.post(
            "/v1/alerts",
            json={
                "title": "Polygon Alert",
                "body": "Alert for polygon area",
                "severity": "info",
                "area": {
                    "geojson": {
                        "type": "Polygon",
                        "coordinates": [
                            [
                                [-43.2, -22.9],
                                [-43.1, -22.9],
                                [-43.1, -22.8],
                                [-43.2, -22.8],
                                [-43.2, -22.9],
                            ]
                        ],
                    }
                },
            },
            headers={"X-API-Key": "test-api-key"},
        )

        assert response.status_code == 200


def test_create_alert_missing_title(
    client: TestClient,
    mock_redis_connected: None,
) -> None:
    """Test create alert without required title."""
    response = client.post(
        "/v1/alerts",
        json={
            "body": "Alert without title",
            "severity": "info",
        },
        headers={"X-API-Key": "test-api-key"},
    )

    assert response.status_code == 422


def test_list_alerts(
    client: TestClient,
    mock_redis_connected: None,
    mock_alert: Alert,
) -> None:
    """Test list alerts endpoint."""
    with patch("app.api.v1.alerts.AlertService") as MockService:
        mock_service = MagicMock()
        mock_service.list_alerts = AsyncMock(return_value=([mock_alert], 1))
        MockService.return_value = mock_service

        response = client.get(
            "/v1/alerts",
            headers={"X-API-Key": "test-api-key"},
        )

        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "total" in data
        assert data["total"] == 1
        assert len(data["data"]) == 1


def test_list_alerts_filter_by_status(
    client: TestClient,
    mock_redis_connected: None,
    mock_broadcast_alert: Alert,
) -> None:
    """Test list alerts with status filter."""
    with patch("app.api.v1.alerts.AlertService") as MockService:
        mock_service = MagicMock()
        mock_service.list_alerts = AsyncMock(return_value=([mock_broadcast_alert], 1))
        MockService.return_value = mock_service

        response = client.get(
            "/v1/alerts?status=sent",
            headers={"X-API-Key": "test-api-key"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1


def test_get_alert_by_id(
    client: TestClient,
    mock_redis_connected: None,
    mock_alert: Alert,
) -> None:
    """Test get single alert by ID."""
    with patch("app.api.v1.alerts.AlertService") as MockService:
        mock_service = MagicMock()
        mock_service.get_alert = AsyncMock(return_value=mock_alert)
        MockService.return_value = mock_service

        response = client.get(
            "/v1/alerts/alert-123",
            headers={"X-API-Key": "test-api-key"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "alert-123"


def test_get_alert_not_found(
    client: TestClient,
    mock_redis_connected: None,
) -> None:
    """Test get alert that doesn't exist."""
    from app.core.errors import NotFoundError

    with patch("app.api.v1.alerts.AlertService") as MockService:
        mock_service = MagicMock()
        mock_service.get_alert = AsyncMock(
            side_effect=NotFoundError(message="Alert not found", resource="alert")
        )
        MockService.return_value = mock_service

        response = client.get(
            "/v1/alerts/nonexistent-alert",
            headers={"X-API-Key": "test-api-key"},
        )

        assert response.status_code == 404


def test_send_alert_success(
    client: TestClient,
    mock_redis_connected: None,
    mock_broadcast_alert: Alert,
) -> None:
    """Test send alert endpoint."""
    with patch("app.api.v1.alerts.AlertService") as MockService:
        mock_service = MagicMock()
        mock_service.send_alert = AsyncMock(
            return_value=(mock_broadcast_alert, 150, "task-abc-123")
        )
        MockService.return_value = mock_service

        response = client.post(
            "/v1/alerts/alert-broadcast-456/send",
            headers={"X-API-Key": "test-api-key"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"]["status"] == "sent"
        assert data["devices_targeted"] == 150
        assert data["task_id"] == "task-abc-123"


def test_send_alert_already_sent(
    client: TestClient,
    mock_redis_connected: None,
) -> None:
    """Test sending an already sent alert."""
    from app.core.errors import ValidationException

    with patch("app.api.v1.alerts.AlertService") as MockService:
        mock_service = MagicMock()
        mock_service.send_alert = AsyncMock(
            side_effect=ValidationException(
                message="Alert already sent", field="status"
            )
        )
        MockService.return_value = mock_service

        response = client.post(
            "/v1/alerts/already-sent-alert/send",
            headers={"X-API-Key": "test-api-key"},
        )

        assert response.status_code == 422


def test_get_inbox_success(
    client: TestClient,
    mock_redis_connected: None,
    mock_inbox_alert: InboxAlert,
) -> None:
    """Test get alerts inbox endpoint."""
    with patch("app.api.v1.alerts.AlertService") as MockService:
        mock_service = MagicMock()
        mock_service.get_inbox = AsyncMock(return_value=[mock_inbox_alert])
        MockService.return_value = mock_service

        response = client.get(
            "/v1/alerts/inbox",
            headers={"X-Push-Token": "test-push-token-12345"},
        )

        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert len(data["data"]) == 1
        assert data["data"][0]["match_type"] == "broadcast"


def test_get_inbox_with_location(
    client: TestClient,
    mock_redis_connected: None,
    mock_inbox_alert: InboxAlert,
) -> None:
    """Test get inbox with location parameters."""
    mock_inbox_alert.match_type = "geo"

    with patch("app.api.v1.alerts.AlertService") as MockService:
        mock_service = MagicMock()
        mock_service.get_inbox = AsyncMock(return_value=[mock_inbox_alert])
        MockService.return_value = mock_service

        response = client.get(
            "/v1/alerts/inbox?lat=-22.9068&lon=-43.1729",
            headers={"X-Push-Token": "test-push-token-12345"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["data"][0]["match_type"] == "geo"


def test_get_inbox_missing_token(
    client: TestClient,
    mock_redis_connected: None,
) -> None:
    """Test inbox without push token header."""
    response = client.get("/v1/alerts/inbox")

    assert response.status_code == 422


def test_alert_severity_levels(
    client: TestClient,
    mock_redis_connected: None,
) -> None:
    """Test creating alerts with different severity levels."""
    for severity in ["info", "alert", "emergency"]:
        mock_alert = Alert(
            id=f"alert-{severity}",
            title=f"{severity.title()} Alert",
            body=f"Test {severity} message",
            severity=AlertSeverity(severity),
            status=AlertStatus.DRAFT,
            broadcast=True,
            neighborhoods=None,
            expires_at=None,
            created_at=datetime.now(timezone.utc),
            sent_at=None,
            created_by=None,
            areas=[],
            delivery_count=0,
        )

        with patch("app.api.v1.alerts.AlertService") as MockService:
            mock_service = MagicMock()
            mock_service.create_alert = AsyncMock(return_value=mock_alert)
            MockService.return_value = mock_service

            response = client.post(
                "/v1/alerts",
                json={
                    "title": f"{severity.title()} Alert",
                    "body": f"Test {severity} message",
                    "severity": severity,
                    "broadcast": True,
                },
                headers={"X-API-Key": "test-api-key"},
            )

            assert response.status_code == 200
            data = response.json()
            assert data["data"]["severity"] == severity
