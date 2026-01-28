from __future__ import annotations
"""Weather API endpoints."""

from typing import Dict, Tuple

import httpx
from fastapi import APIRouter, Path, Query
from fastapi.responses import Response

from app.api.deps import ServicesDep
from app.core.security import ApiKeyDep, RateLimitDep
from app.schemas.radar import RadarLatestResponse
from app.schemas.weather import WeatherForecastResponse, WeatherNowResponse

router = APIRouter()

# Cache simples para imagens do radar (evita requests repetidos)
_radar_image_cache: Dict[str, Tuple[bytes, float]] = {}
RADAR_CACHE_TTL = 60  # 60 segundos


@router.get(
    "/now",
    response_model=WeatherNowResponse,
    summary="Current Weather",
    description="Get current weather conditions for Rio de Janeiro.",
)
async def get_current_weather(
    services: ServicesDep,
    _api_key: ApiKeyDep = True,
    _rate_limit: RateLimitDep = True,
) -> WeatherNowResponse:
    """
    Get current weather conditions.

    Returns:
    - Temperature (current and feels like)
    - Humidity and pressure
    - Wind speed and direction
    - Weather condition and description
    - Visibility and UV index

    If the weather provider is unavailable, cached data will be returned
    with `cache.stale: true` and `cache.age_seconds` indicating data age.
    """
    return await services.weather.get_current_weather()


@router.get(
    "/forecast",
    response_model=WeatherForecastResponse,
    summary="Weather Forecast",
    description="Get weather forecast for Rio de Janeiro.",
)
async def get_weather_forecast(
    services: ServicesDep,
    hours: int = Query(
        default=48,
        ge=1,
        le=168,
        description="Number of hours to forecast (1-168)",
    ),
    _api_key: ApiKeyDep = True,
    _rate_limit: RateLimitDep = True,
) -> WeatherForecastResponse:
    """
    Get hourly weather forecast.

    Args:
        hours: Number of hours to forecast (default: 48, max: 168)

    Returns:
    - List of hourly forecasts with:
        - Temperature (current, min, max, feels like)
        - Humidity and pressure
        - Wind speed and direction
        - Precipitation probability and amount
        - Weather condition

    If the weather provider is unavailable, cached data will be returned
    with `cache.stale: true` and `cache.age_seconds` indicating data age.
    """
    return await services.weather.get_forecast(hours=hours)


@router.get(
    "/radar/latest",
    response_model=RadarLatestResponse,
    summary="Latest Radar",
    description="Get latest weather radar snapshot and metadata.",
)
async def get_radar_latest(
    services: ServicesDep,
    _api_key: ApiKeyDep = True,
    _rate_limit: RateLimitDep = True,
) -> RadarLatestResponse:
    """
    Get latest radar image snapshot.

    Returns:
    - Latest radar snapshot with:
        - Image URL (proxied through API)
        - Timestamp
        - Bounding box
        - Resolution and product type
    - Radar metadata (station info, range, update interval)
    - Previous snapshots for animation (up to 12)

    The radar images cover the Rio de Janeiro metropolitan area
    from the Pico do Couto station.

    If the radar provider is unavailable, cached data will be returned
    with `cache.stale: true` and `cache.age_seconds` indicating data age.
    """
    return await services.radar.get_latest_radar()


@router.get(
    "/radar/image/{frame}",
    summary="Radar Image Proxy",
    description="Proxy for Alerta Rio radar images (serves via HTTPS).",
    responses={
        200: {"content": {"image/png": {}}},
        404: {"description": "Radar image not found"},
        502: {"description": "Failed to fetch radar image"},
    },
)
async def get_radar_image(
    frame: int = Path(..., ge=1, le=20, description="Frame number (1-20, where 20 is most recent)"),
) -> Response:
    """
    Proxy radar images from Alerta Rio.

    This endpoint fetches radar images from the HTTP source and serves them
    via HTTPS, solving iOS App Transport Security restrictions.

    Args:
        frame: Frame number from 1 (oldest) to 20 (most recent)

    Returns:
        PNG image of the radar frame
    """
    import time

    cache_key = f"radar_{frame:03d}"
    current_time = time.time()

    # Verifica cache
    if cache_key in _radar_image_cache:
        cached_data, cached_time = _radar_image_cache[cache_key]
        if current_time - cached_time < RADAR_CACHE_TTL:
            return Response(
                content=cached_data,
                media_type="image/png",
                headers={
                    "Cache-Control": "public, max-age=60",
                    "X-Cache": "HIT",
                },
            )

    # Busca imagem do Alerta Rio
    url = f"http://alertario.rio.rj.gov.br/upload/Mapa/semfundo/radar{frame:03d}.png"

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(url)

            if response.status_code == 404:
                return Response(
                    content=b"Radar image not found",
                    status_code=404,
                    media_type="text/plain",
                )

            response.raise_for_status()
            image_data = response.content

            # Salva no cache
            _radar_image_cache[cache_key] = (image_data, current_time)

            # Limpa cache antigo (mantém apenas últimos 20 frames)
            if len(_radar_image_cache) > 25:
                oldest_keys = sorted(
                    _radar_image_cache.keys(),
                    key=lambda k: _radar_image_cache[k][1]
                )[:5]
                for k in oldest_keys:
                    del _radar_image_cache[k]

            return Response(
                content=image_data,
                media_type="image/png",
                headers={
                    "Cache-Control": "public, max-age=60",
                    "X-Cache": "MISS",
                },
            )

    except httpx.HTTPError as e:
        return Response(
            content=f"Failed to fetch radar image: {str(e)}",
            status_code=502,
            media_type="text/plain",
        )
