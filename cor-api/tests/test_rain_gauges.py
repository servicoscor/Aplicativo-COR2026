"""Tests for rain gauges endpoint."""

import pytest
from fastapi.testclient import TestClient


def test_rain_gauges_endpoint(client: TestClient, mock_redis_connected: None) -> None:
    """Test rain gauges endpoint returns data."""
    response = client.get("/v1/rain-gauges")
    assert response.status_code == 200
    data = response.json()

    # Check response structure
    assert data["success"] is True
    assert "timestamp" in data
    assert "data" in data
    assert "summary" in data


def test_rain_gauges_returns_multiple_stations(client: TestClient, mock_redis_connected: None) -> None:
    """Test rain gauges returns multiple stations."""
    response = client.get("/v1/rain-gauges")
    assert response.status_code == 200
    data = response.json()

    gauges = data["data"]
    assert len(gauges) > 0


def test_rain_gauge_station_fields(client: TestClient, mock_redis_connected: None) -> None:
    """Test rain gauge stations have required fields."""
    response = client.get("/v1/rain-gauges")
    assert response.status_code == 200
    data = response.json()

    for gauge in data["data"]:
        assert "id" in gauge
        assert "name" in gauge
        assert "latitude" in gauge
        assert "longitude" in gauge
        assert "status" in gauge

        # Location should be in Rio de Janeiro area
        assert -24 <= gauge["latitude"] <= -22
        assert -44 <= gauge["longitude"] <= -42


def test_rain_gauge_last_reading(client: TestClient, mock_redis_connected: None) -> None:
    """Test rain gauge includes last reading."""
    response = client.get("/v1/rain-gauges")
    assert response.status_code == 200
    data = response.json()

    # At least one station should have reading
    stations_with_readings = [
        g for g in data["data"] if g.get("last_reading") is not None
    ]
    assert len(stations_with_readings) > 0

    for gauge in stations_with_readings:
        reading = gauge["last_reading"]
        assert "timestamp" in reading
        assert "value_mm" in reading
        assert "intensity" in reading
        assert reading["value_mm"] >= 0


def test_rain_gauges_summary(client: TestClient, mock_redis_connected: None) -> None:
    """Test rain gauges summary statistics."""
    response = client.get("/v1/rain-gauges")
    assert response.status_code == 200
    data = response.json()

    summary = data["summary"]
    assert "total_stations" in summary
    assert "active_stations" in summary
    assert "stations_with_rain" in summary
    assert "max_rain_15min" in summary
    assert "max_rain_1h" in summary
    assert "avg_rain_1h" in summary

    # Validate counts
    assert summary["total_stations"] >= summary["active_stations"]
    assert summary["active_stations"] >= summary["stations_with_rain"]
    assert summary["max_rain_15min"] >= 0
    assert summary["max_rain_1h"] >= 0
    assert summary["avg_rain_1h"] >= 0


def test_rain_gauge_intensity_values(client: TestClient, mock_redis_connected: None) -> None:
    """Test rain gauge intensity has valid values."""
    response = client.get("/v1/rain-gauges")
    assert response.status_code == 200
    data = response.json()

    valid_intensities = ["none", "light", "moderate", "heavy", "very_heavy"]

    for gauge in data["data"]:
        if gauge.get("last_reading"):
            assert gauge["last_reading"]["intensity"] in valid_intensities


def test_rain_gauges_bbox_filter(client: TestClient, mock_redis_connected: None) -> None:
    """Test rain gauges bbox filter."""
    bbox = "-43.5,-23.1,-43.1,-22.7"
    response = client.get(f"/v1/rain-gauges?bbox={bbox}")
    assert response.status_code == 200
    data = response.json()

    # Response should include bbox_applied field
    assert data["bbox_applied"] == bbox

    # All returned stations should be within bbox
    min_lon, min_lat, max_lon, max_lat = -43.5, -23.1, -43.1, -22.7
    for gauge in data["data"]:
        assert min_lat <= gauge["latitude"] <= max_lat
        assert min_lon <= gauge["longitude"] <= max_lon


def test_rain_gauges_bbox_filter_zona_sul(client: TestClient, mock_redis_connected: None) -> None:
    """Test rain gauges bbox filter for Zona Sul area."""
    # Zona Sul bbox (Copacabana, Ipanema, Leblon area)
    bbox = "-43.25,-23.01,-43.15,-22.95"
    response = client.get(f"/v1/rain-gauges?bbox={bbox}")
    assert response.status_code == 200
    data = response.json()

    assert data["bbox_applied"] == bbox

    # All returned stations should be within the Zona Sul bbox
    min_lon, min_lat, max_lon, max_lat = -43.25, -23.01, -43.15, -22.95
    for gauge in data["data"]:
        assert min_lat <= gauge["latitude"] <= max_lat
        assert min_lon <= gauge["longitude"] <= max_lon


def test_rain_gauges_bbox_empty_area(client: TestClient, mock_redis_connected: None) -> None:
    """Test rain gauges bbox filter with area that has no stations."""
    # Very small bbox in the ocean
    bbox = "-40.0,-25.0,-39.5,-24.5"
    response = client.get(f"/v1/rain-gauges?bbox={bbox}")
    assert response.status_code == 200
    data = response.json()

    assert data["bbox_applied"] == bbox
    # Should return empty list for ocean area
    assert len(data["data"]) == 0


def test_rain_gauges_no_bbox_returns_all(client: TestClient, mock_redis_connected: None) -> None:
    """Test rain gauges without bbox returns all stations."""
    response = client.get("/v1/rain-gauges")
    assert response.status_code == 200
    data = response.json()

    # Without bbox, should return all mock stations (20)
    assert len(data["data"]) == 20
    assert data.get("bbox_applied") is None


def test_rain_gauges_invalid_bbox_format(client: TestClient, mock_redis_connected: None) -> None:
    """Test rain gauges with invalid bbox format still works."""
    # Invalid bbox format should be ignored
    bbox = "invalid,bbox,format"
    response = client.get(f"/v1/rain-gauges?bbox={bbox}")
    assert response.status_code == 200
    data = response.json()

    # Should still return data (bbox is ignored if invalid)
    assert len(data["data"]) > 0
