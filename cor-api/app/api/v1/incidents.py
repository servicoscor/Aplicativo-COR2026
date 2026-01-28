from __future__ import annotations
"""Incidents API endpoints."""

from datetime import datetime

from fastapi import APIRouter, Query

from app.api.deps import ServicesDep
from app.core.security import ApiKeyDep, RateLimitDep
from app.schemas.incident import IncidentsResponse

router = APIRouter()


@router.get(
    "",
    response_model=IncidentsResponse,
    summary="City Incidents",
    description="Get active incidents in Rio de Janeiro with optional filters.",
)
async def get_incidents(
    services: ServicesDep,
    bbox: str | None = Query(
        default=None,
        description="Bounding box filter: min_lon,min_lat,max_lon,max_lat",
        example="-43.5,-23.1,-43.1,-22.7",
    ),
    since: datetime | None = Query(
        default=None,
        description="Only return incidents since this timestamp (ISO 8601)",
        example="2024-01-01T00:00:00Z",
    ),
    type: str | None = Query(
        default=None,
        alias="type",
        description="Filter by incident type(s), comma-separated",
        example="traffic,accident,flooding",
    ),
    _api_key: ApiKeyDep = True,
    _rate_limit: RateLimitDep = True,
) -> IncidentsResponse:
    """
    Get active city incidents.

    Args:
        bbox: Bounding box filter in format "min_lon,min_lat,max_lon,max_lat"
        since: Only return incidents started after this timestamp
        type: Filter by incident type(s), comma-separated. Valid types:
            - traffic: Traffic congestion
            - flooding: Street flooding
            - landslide: Landslides
            - fire: Fires
            - accident: Traffic accidents
            - road_work: Road maintenance
            - event: Events and demonstrations
            - utility: Utility issues
            - weather_alert: Weather alerts
            - other: Other incidents

    Returns list of incidents with:
    - Incident ID, type, severity, and status
    - Title and description
    - Location (GeoJSON geometry, address, neighborhood)
    - Timestamps (started, updated, resolved)
    - Affected routes and tags

    Also includes summary with counts by type, severity, and status.

    If the incidents provider is unavailable, cached data will be returned
    with `cache.stale: true` and `cache.age_seconds` indicating data age.
    """
    return await services.incidents.get_incidents(
        bbox=bbox,
        since=since,
        incident_type=type,
    )
