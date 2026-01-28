from __future__ import annotations
"""Rain gauges API endpoints."""

from fastapi import APIRouter, Query

from app.api.deps import ServicesDep
from app.core.security import ApiKeyDep, RateLimitDep
from app.schemas.rain_gauge import RainGaugesResponse

router = APIRouter()


@router.get(
    "",
    response_model=RainGaugesResponse,
    summary="Rain Gauge Stations",
    description="Get rain gauge stations with latest readings, optionally filtered by bounding box.",
)
async def get_rain_gauges(
    services: ServicesDep,
    bbox: str | None = Query(
        default=None,
        description="Bounding box filter: min_lon,min_lat,max_lon,max_lat",
        example="-43.5,-23.1,-43.1,-22.7",
    ),
    _api_key: ApiKeyDep = True,
    _rate_limit: RateLimitDep = True,
) -> RainGaugesResponse:
    """
    Get rain gauge stations with latest readings.

    Args:
        bbox: Bounding box filter in format "min_lon,min_lat,max_lon,max_lat"

    Returns list of rain gauge stations across Rio de Janeiro with:
    - Station ID, name, and location (lat/lon)
    - Neighborhood and region
    - Latest reading:
        - Current precipitation value (mm)
        - 15-minute, 1-hour, and 24-hour accumulated values
        - Intensity classification (none/light/moderate/heavy/very_heavy)
    - Last update timestamp

    Also includes summary statistics:
    - Total and active station counts
    - Stations currently reporting rain
    - Maximum and average rainfall values

    If the rain gauge provider is unavailable, cached data will be returned
    with `cache.stale: true` and `cache.age_seconds` indicating data age.
    """
    return await services.rain_gauges.get_rain_gauges(bbox=bbox)
