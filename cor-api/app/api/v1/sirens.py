from __future__ import annotations
"""Sirens API endpoints."""

from fastapi import APIRouter, Query

from app.api.deps import ServicesDep
from app.core.security import ApiKeyDep, RateLimitDep
from app.schemas.siren import SirensResponse

router = APIRouter()


@router.get(
    "",
    response_model=SirensResponse,
    summary="Warning Sirens",
    description="Get warning sirens with current status, optionally filtered by bounding box.",
)
async def get_sirens(
    services: ServicesDep,
    bbox: str | None = Query(
        default=None,
        description="Bounding box filter: min_lon,min_lat,max_lon,max_lat",
        example="-43.5,-23.1,-43.1,-22.7",
    ),
    _api_key: ApiKeyDep = True,
    _rate_limit: RateLimitDep = True,
) -> SirensResponse:
    """
    Get warning sirens with current status.

    Args:
        bbox: Bounding box filter in format "min_lon,min_lat,max_lon,max_lat"

    Returns list of warning sirens across Rio de Janeiro with:
    - Siren ID, name, and location (lat/lon)
    - Basin (hydrographic basin)
    - Online status (connected to monitoring system)
    - Operational status:
        - ds (Desativada) - Inactive
        - at (Ativa) - Active and ready
        - ac (Acionada) - Triggered (alarm sounding)

    Also includes summary statistics:
    - Total siren count
    - Online, active, triggered, and inactive counts

    If the siren provider is unavailable, cached data will be returned
    with `is_stale: true` indicating stale data.
    """
    return await services.sirens.get_sirens(bbox=bbox)
