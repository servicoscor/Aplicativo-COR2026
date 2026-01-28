"""Tests for health check endpoint."""

import pytest
from fastapi.testclient import TestClient


def test_root_endpoint(client: TestClient) -> None:
    """Test root endpoint returns API info."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "name" in data
    assert "version" in data
    assert "docs" in data
    assert "health" in data


def test_health_endpoint_returns_ok(client: TestClient, mock_redis_connected: None) -> None:
    """Test health endpoint returns status."""
    response = client.get("/v1/health")
    assert response.status_code == 200
    data = response.json()

    # Check required fields
    assert "status" in data
    assert "version" in data
    assert "timestamp" in data
    assert "uptime_seconds" in data
    assert "sources" in data
    assert "database" in data
    assert "redis" in data


def test_health_endpoint_includes_sources(client: TestClient, mock_redis_connected: None) -> None:
    """Test health endpoint includes all data sources."""
    response = client.get("/v1/health")
    assert response.status_code == 200
    data = response.json()

    sources = data["sources"]
    source_names = [s["name"] for s in sources]

    # All sources should be present
    assert "weather" in source_names
    assert "radar" in source_names
    assert "rain_gauges" in source_names
    assert "incidents" in source_names


def test_health_endpoint_source_fields(client: TestClient, mock_redis_connected: None) -> None:
    """Test health endpoint source entries have required fields."""
    response = client.get("/v1/health")
    assert response.status_code == 200
    data = response.json()

    for source in data["sources"]:
        assert "name" in source
        assert "status" in source
        # Status should be valid value
        assert source["status"] in ["ok", "degraded", "down"]
