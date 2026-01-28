from __future__ import annotations
"""API dependencies."""

from typing import Annotated, AsyncGenerator

from fastapi import Depends

from app.services.alertario_service import AlertaRioService
from app.services.cache_service import CacheService, get_cache_service
from app.services.health_service import HealthService
from app.services.incidents_service import IncidentsService
from app.services.radar_service import RadarService
from app.services.rain_gauge_service import RainGaugeService
from app.services.siren_service import SirenService
from app.services.weather_service import WeatherService


class Services:
    """Container for all services."""

    def __init__(self, cache: CacheService):
        """Initialize services with shared cache."""
        self.cache = cache
        self.weather = WeatherService(cache=cache)
        self.radar = RadarService(cache=cache)
        self.rain_gauges = RainGaugeService(cache=cache)
        self.sirens = SirenService(cache=cache)
        self.incidents = IncidentsService(cache=cache)
        self.alertario = AlertaRioService(cache=cache)
        self.health = HealthService()


_services: Services | None = None


async def get_services() -> Services:
    """Get or create services container."""
    global _services
    if _services is None:
        cache = await get_cache_service()
        _services = Services(cache)
    return _services


# Type alias for dependency injection
ServicesDep = Annotated[Services, Depends(get_services)]
