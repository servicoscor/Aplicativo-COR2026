"""Tests for weather endpoints."""

import pytest
from fastapi.testclient import TestClient


def test_weather_now_endpoint(client: TestClient, mock_redis_connected: None) -> None:
    """Test current weather endpoint returns data."""
    response = client.get("/v1/weather/now")
    assert response.status_code == 200
    data = response.json()

    # Check response structure
    assert data["success"] is True
    assert "timestamp" in data
    assert "data" in data

    # Check weather data fields
    weather = data["data"]
    assert "temperature" in weather
    assert "feels_like" in weather
    assert "humidity" in weather
    assert "pressure" in weather
    assert "wind_speed" in weather
    assert "condition" in weather
    assert "condition_text" in weather
    assert "observation_time" in weather
    assert "location" in weather


def test_weather_now_temperature_range(client: TestClient, mock_redis_connected: None) -> None:
    """Test current weather temperature is in reasonable range."""
    response = client.get("/v1/weather/now")
    assert response.status_code == 200
    data = response.json()

    # Temperature should be reasonable for Rio de Janeiro
    temp = data["data"]["temperature"]
    assert -10 <= temp <= 50  # Reasonable range


def test_weather_now_humidity_range(client: TestClient, mock_redis_connected: None) -> None:
    """Test current weather humidity is in valid range."""
    response = client.get("/v1/weather/now")
    assert response.status_code == 200
    data = response.json()

    humidity = data["data"]["humidity"]
    assert 0 <= humidity <= 100


def test_weather_forecast_endpoint(client: TestClient, mock_redis_connected: None) -> None:
    """Test weather forecast endpoint returns data."""
    response = client.get("/v1/weather/forecast")
    assert response.status_code == 200
    data = response.json()

    # Check response structure
    assert data["success"] is True
    assert "timestamp" in data
    assert "data" in data

    # Check forecast data
    forecast = data["data"]
    assert "location" in forecast
    assert "generated_at" in forecast
    assert "hours_requested" in forecast
    assert "items" in forecast

    # Default is 48 hours
    assert forecast["hours_requested"] == 48


def test_weather_forecast_with_hours_param(client: TestClient, mock_redis_connected: None) -> None:
    """Test weather forecast with custom hours parameter."""
    response = client.get("/v1/weather/forecast?hours=24")
    assert response.status_code == 200
    data = response.json()

    assert data["data"]["hours_requested"] == 24
    assert len(data["data"]["items"]) == 24


def test_weather_forecast_max_hours(client: TestClient, mock_redis_connected: None) -> None:
    """Test weather forecast respects max hours limit."""
    response = client.get("/v1/weather/forecast?hours=200")
    assert response.status_code == 200
    data = response.json()

    # Should be capped at 168 hours (1 week)
    assert data["data"]["hours_requested"] <= 168


def test_weather_forecast_items_structure(client: TestClient, mock_redis_connected: None) -> None:
    """Test weather forecast items have required fields."""
    response = client.get("/v1/weather/forecast?hours=6")
    assert response.status_code == 200
    data = response.json()

    items = data["data"]["items"]
    assert len(items) > 0

    for item in items:
        assert "forecast_time" in item
        assert "temperature" in item
        assert "feels_like" in item
        assert "humidity" in item
        assert "precipitation_probability" in item
        assert "condition" in item


def test_radar_latest_endpoint(client: TestClient, mock_redis_connected: None) -> None:
    """Test radar latest endpoint returns data."""
    response = client.get("/v1/weather/radar/latest")
    assert response.status_code == 200
    data = response.json()

    # Check response structure
    assert data["success"] is True
    assert "timestamp" in data
    assert "data" in data
    assert "metadata" in data

    # Check radar snapshot data
    snapshot = data["data"]
    assert "id" in snapshot
    assert "timestamp" in snapshot
    assert "url" in snapshot
    assert "bbox" in snapshot

    # Check metadata
    metadata = data["metadata"]
    assert "station_name" in metadata
    assert "station_lat" in metadata
    assert "station_lon" in metadata


def test_radar_latest_previous_snapshots(client: TestClient, mock_redis_connected: None) -> None:
    """Test radar latest includes previous snapshots."""
    response = client.get("/v1/weather/radar/latest")
    assert response.status_code == 200
    data = response.json()

    # Previous snapshots for animation
    assert "previous_snapshots" in data
    assert isinstance(data["previous_snapshots"], list)
