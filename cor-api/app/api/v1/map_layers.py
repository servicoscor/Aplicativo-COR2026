"""Map layers API endpoints."""

from datetime import datetime, timezone

from fastapi import APIRouter

from app.core.security import ApiKeyDep, RateLimitDep
from app.schemas.map_layer import (
    LayerCategory,
    LayerType,
    MapLayer,
    MapLayerParameter,
    MapLayersResponse,
)

router = APIRouter()


# Static layer definitions
AVAILABLE_LAYERS = [
    MapLayer(
        id="weather-radar",
        name="Radar Meteorológico",
        description="Imagens do radar meteorológico com reflexividade",
        type=LayerType.TILE,
        category=LayerCategory.WEATHER,
        url_template=None,
        endpoint="/v1/weather/radar/latest",
        parameters=[],
        min_zoom=8,
        max_zoom=14,
        default_visible=True,
        refresh_interval_seconds=180,
        attribution="INMET / COR",
        style={"opacity": 0.7},
    ),
    MapLayer(
        id="rain-gauges",
        name="Pluviômetros",
        description="Estações pluviométricas com leituras em tempo real",
        type=LayerType.GEOJSON,
        category=LayerCategory.SENSORS,
        endpoint="/v1/rain-gauges",
        parameters=[],
        min_zoom=10,
        max_zoom=18,
        default_visible=True,
        refresh_interval_seconds=120,
        attribution="AlertaRio / COR",
        style={
            "circleRadius": 8,
            "circleColor": [
                "case",
                ["==", ["get", "intensity"], "none"], "#00ff00",
                ["==", ["get", "intensity"], "light"], "#ffff00",
                ["==", ["get", "intensity"], "moderate"], "#ffa500",
                ["==", ["get", "intensity"], "heavy"], "#ff0000",
                "#800080"
            ],
        },
    ),
    MapLayer(
        id="incidents",
        name="Ocorrências",
        description="Ocorrências ativas na cidade (trânsito, alagamentos, etc)",
        type=LayerType.GEOJSON,
        category=LayerCategory.INCIDENTS,
        endpoint="/v1/incidents",
        parameters=[
            MapLayerParameter(
                name="bbox",
                type="string",
                required=False,
                description="Bounding box filter: min_lon,min_lat,max_lon,max_lat",
            ),
            MapLayerParameter(
                name="type",
                type="string",
                required=False,
                description="Incident type filter",
                options=[
                    "traffic",
                    "flooding",
                    "landslide",
                    "fire",
                    "accident",
                    "road_work",
                    "event",
                    "utility",
                    "weather_alert",
                ],
            ),
        ],
        min_zoom=10,
        max_zoom=18,
        default_visible=True,
        refresh_interval_seconds=45,
        attribution="COR",
        style={
            "iconSize": 24,
            "iconColor": {
                "traffic": "#ff6600",
                "flooding": "#0066ff",
                "accident": "#ff0000",
                "road_work": "#ffcc00",
            },
        },
    ),
    MapLayer(
        id="weather-current",
        name="Condições Atuais",
        description="Condições meteorológicas atuais",
        type=LayerType.GEOJSON,
        category=LayerCategory.WEATHER,
        endpoint="/v1/weather/now",
        parameters=[],
        min_zoom=8,
        max_zoom=18,
        default_visible=False,
        refresh_interval_seconds=60,
        attribution="COR",
    ),
]


@router.get(
    "/layers",
    response_model=MapLayersResponse,
    summary="Available Map Layers",
    description="Get list of available map layers with their configuration.",
)
async def get_map_layers(
    _api_key: ApiKeyDep = True,
    _rate_limit: RateLimitDep = True,
) -> MapLayersResponse:
    """
    Get available map layers.

    Returns list of available map layers with:
    - Layer ID and display name
    - Layer type (tile, geojson, wms, vector, heatmap)
    - Category (weather, infrastructure, incidents, sensors, basemap)
    - API endpoint or URL template
    - Available parameters
    - Zoom level constraints
    - Refresh interval
    - Default style configuration

    Use this endpoint to discover available data layers and their
    configuration for map visualization.
    """
    # Update last_updated for dynamic layers
    now = datetime.now(timezone.utc)
    layers = []
    for layer in AVAILABLE_LAYERS:
        layer_copy = layer.model_copy()
        layer_copy.last_updated = now
        layers.append(layer_copy)

    # Get unique categories
    categories = sorted(set(layer.category.value for layer in layers))

    return MapLayersResponse(
        success=True,
        timestamp=now,
        data=layers,
        categories=categories,
    )
