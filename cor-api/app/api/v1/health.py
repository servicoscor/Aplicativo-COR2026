"""Health check endpoints."""

from fastapi import APIRouter

from app.api.deps import ServicesDep
from app.schemas.health import HealthResponse

router = APIRouter()


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Health Check",
    description="Get service health status including database, cache, and data source statuses.",
)
async def health_check(services: ServicesDep) -> HealthResponse:
    """
    Health check endpoint.

    Returns comprehensive health status including:
    - Overall service status (healthy/degraded/unhealthy)
    - Database connection status
    - Redis connection status
    - Status of each data source (weather, radar, rain gauges, incidents)
    - Cache age for each data source
    - Service uptime
    """
    return await services.health.get_health()
