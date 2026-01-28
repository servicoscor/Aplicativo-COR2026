"""Tests for incidents endpoint."""

import pytest
from fastapi.testclient import TestClient


def test_incidents_endpoint(client: TestClient, mock_redis_connected: None) -> None:
    """Test incidents endpoint returns data."""
    response = client.get("/v1/incidents")
    assert response.status_code == 200
    data = response.json()

    # Check response structure
    assert data["success"] is True
    assert "timestamp" in data
    assert "data" in data
    assert "summary" in data


def test_incidents_fields(client: TestClient, mock_redis_connected: None) -> None:
    """Test incidents have required fields."""
    response = client.get("/v1/incidents")
    assert response.status_code == 200
    data = response.json()

    for incident in data["data"]:
        assert "id" in incident
        assert "type" in incident
        assert "severity" in incident
        assert "status" in incident
        assert "title" in incident
        assert "geometry" in incident
        assert "started_at" in incident
        assert "updated_at" in incident


def test_incidents_geometry(client: TestClient, mock_redis_connected: None) -> None:
    """Test incidents have valid geometry."""
    response = client.get("/v1/incidents")
    assert response.status_code == 200
    data = response.json()

    for incident in data["data"]:
        geometry = incident["geometry"]
        assert "type" in geometry
        assert "coordinates" in geometry
        assert geometry["type"] in ["Point", "LineString", "Polygon"]


def test_incidents_type_filter(client: TestClient, mock_redis_connected: None) -> None:
    """Test incidents type filter."""
    response = client.get("/v1/incidents?type=traffic")
    assert response.status_code == 200
    data = response.json()

    assert data["type_filter_applied"] == ["traffic"]


def test_incidents_bbox_filter(client: TestClient, mock_redis_connected: None) -> None:
    """Test incidents bbox filter."""
    bbox = "-43.5,-23.1,-43.1,-22.7"
    response = client.get(f"/v1/incidents?bbox={bbox}")
    assert response.status_code == 200
    data = response.json()

    assert data["bbox_applied"] == bbox


def test_incidents_summary(client: TestClient, mock_redis_connected: None) -> None:
    """Test incidents summary statistics."""
    response = client.get("/v1/incidents")
    assert response.status_code == 200
    data = response.json()

    summary = data["summary"]
    assert "total" in summary
    assert "by_type" in summary
    assert "by_severity" in summary
    assert "by_status" in summary


def test_incidents_valid_types(client: TestClient, mock_redis_connected: None) -> None:
    """Test incidents have valid type values."""
    response = client.get("/v1/incidents")
    assert response.status_code == 200
    data = response.json()

    valid_types = [
        "traffic", "flooding", "landslide", "fire",
        "accident", "road_work", "event", "utility",
        "weather_alert", "other"
    ]

    for incident in data["data"]:
        assert incident["type"] in valid_types


def test_incidents_valid_severity(client: TestClient, mock_redis_connected: None) -> None:
    """Test incidents have valid severity values."""
    response = client.get("/v1/incidents")
    assert response.status_code == 200
    data = response.json()

    valid_severities = ["low", "medium", "high", "critical"]

    for incident in data["data"]:
        assert incident["severity"] in valid_severities


def test_incidents_valid_status(client: TestClient, mock_redis_connected: None) -> None:
    """Test incidents have valid status values."""
    response = client.get("/v1/incidents")
    assert response.status_code == 200
    data = response.json()

    valid_statuses = ["open", "in_progress", "resolved", "closed"]

    for incident in data["data"]:
        assert incident["status"] in valid_statuses
