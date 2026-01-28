"""Tests for map layers endpoint."""

import pytest
from fastapi.testclient import TestClient


def test_map_layers_endpoint(client: TestClient, mock_redis_connected: None) -> None:
    """Test map layers endpoint returns data."""
    response = client.get("/v1/map/layers")
    assert response.status_code == 200
    data = response.json()

    # Check response structure
    assert data["success"] is True
    assert "timestamp" in data
    assert "data" in data
    assert "categories" in data


def test_map_layers_returns_multiple_layers(client: TestClient, mock_redis_connected: None) -> None:
    """Test map layers returns multiple layers."""
    response = client.get("/v1/map/layers")
    assert response.status_code == 200
    data = response.json()

    layers = data["data"]
    assert len(layers) > 0


def test_map_layer_fields(client: TestClient, mock_redis_connected: None) -> None:
    """Test map layers have required fields."""
    response = client.get("/v1/map/layers")
    assert response.status_code == 200
    data = response.json()

    for layer in data["data"]:
        assert "id" in layer
        assert "name" in layer
        assert "type" in layer
        assert "category" in layer
        assert "min_zoom" in layer
        assert "max_zoom" in layer


def test_map_layer_types(client: TestClient, mock_redis_connected: None) -> None:
    """Test map layers have valid type values."""
    response = client.get("/v1/map/layers")
    assert response.status_code == 200
    data = response.json()

    valid_types = ["tile", "geojson", "wms", "vector", "heatmap"]

    for layer in data["data"]:
        assert layer["type"] in valid_types


def test_map_layer_categories(client: TestClient, mock_redis_connected: None) -> None:
    """Test map layers have valid category values."""
    response = client.get("/v1/map/layers")
    assert response.status_code == 200
    data = response.json()

    valid_categories = ["weather", "infrastructure", "incidents", "sensors", "basemap"]

    for layer in data["data"]:
        assert layer["category"] in valid_categories


def test_map_layers_categories_list(client: TestClient, mock_redis_connected: None) -> None:
    """Test categories list contains all used categories."""
    response = client.get("/v1/map/layers")
    assert response.status_code == 200
    data = response.json()

    categories_in_layers = set(layer["category"] for layer in data["data"])
    returned_categories = set(data["categories"])

    # All categories used in layers should be in the list
    assert categories_in_layers <= returned_categories


def test_map_layer_zoom_levels(client: TestClient, mock_redis_connected: None) -> None:
    """Test map layers have valid zoom levels."""
    response = client.get("/v1/map/layers")
    assert response.status_code == 200
    data = response.json()

    for layer in data["data"]:
        assert 1 <= layer["min_zoom"] <= 22
        assert 1 <= layer["max_zoom"] <= 22
        assert layer["min_zoom"] <= layer["max_zoom"]
