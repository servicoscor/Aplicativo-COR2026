from __future__ import annotations
"""Health check service."""

import time
from datetime import datetime, timezone
from typing import Any

from app.core.config import settings
from app.core.logging import get_logger
from app.providers.incidents_provider import IncidentsProvider
from app.providers.radar_provider import RadarProvider
from app.providers.rain_gauge_provider import RainGaugeProvider
from app.providers.weather_provider import WeatherProvider
from app.schemas.common import SourceStatus
from app.schemas.health import HealthResponse, SourceHealth
from app.services.cache_service import CacheService, get_cache_service

logger = get_logger(__name__)

# Track service start time
_start_time = time.time()


class HealthService:
    """Service for health checks and status reporting."""

    def __init__(self):
        """Initialize health service with all providers."""
        self.weather_provider = WeatherProvider()
        self.radar_provider = RadarProvider()
        self.rain_gauge_provider = RainGaugeProvider()
        self.incidents_provider = IncidentsProvider()
        self._cache: CacheService | None = None

    async def _get_cache(self) -> CacheService:
        """Get cache service."""
        if self._cache is None:
            self._cache = await get_cache_service()
        return self._cache

    async def get_health(self) -> HealthResponse:
        """
        Get comprehensive health status.

        Returns:
            HealthResponse with service and source statuses
        """
        # Calculate uptime
        uptime_seconds = time.time() - _start_time

        # Check database connection
        db_status = await self._check_database()

        # Check Redis connection
        redis_status = await self._check_redis()

        # Get source statuses
        sources = await self._get_source_statuses()

        # Determine overall status
        overall_status = self._calculate_overall_status(
            db_status, redis_status, sources
        )

        return HealthResponse(
            status=overall_status,
            version=settings.app_version,
            timestamp=datetime.now(timezone.utc),
            uptime_seconds=uptime_seconds,
            sources=sources,
            database=db_status,
            redis=redis_status,
        )

    async def _check_database(self) -> str:
        """Check database connection status."""
        try:
            # Import here to avoid circular imports
            from app.db.session import get_db

            async for db in get_db():
                await db.execute("SELECT 1")
                return "connected"
        except Exception as e:
            logger.error(f"Database health check failed: {e}")
            return "disconnected"

    async def _check_redis(self) -> str:
        """Check Redis connection status."""
        try:
            cache = await self._get_cache()
            if await cache.health_check():
                return "connected"
            return "disconnected"
        except Exception as e:
            logger.error(f"Redis health check failed: {e}")
            return "disconnected"

    async def _get_source_statuses(self) -> list[SourceHealth]:
        """Get status of all data sources."""
        cache = await self._get_cache()

        sources = []

        # Weather source
        weather_metrics = self.weather_provider.get_metrics()
        weather_cache_age = await cache.get_cache_age("weather", "now")
        sources.append(
            SourceHealth(
                name="weather",
                status=weather_metrics.status,
                mode="mock" if self.weather_provider.is_mock else "real",
                last_success=weather_metrics.last_success,
                last_error=weather_metrics.last_error,
                latency_ms=weather_metrics.latency_ms,
                cache_age_seconds=weather_cache_age,
            )
        )

        # Radar source
        radar_metrics = self.radar_provider.get_metrics()
        radar_cache_age = await cache.get_cache_age("radar", "latest")
        sources.append(
            SourceHealth(
                name="radar",
                status=radar_metrics.status,
                mode="mock" if self.radar_provider.is_mock else "real",
                last_success=radar_metrics.last_success,
                last_error=radar_metrics.last_error,
                latency_ms=radar_metrics.latency_ms,
                cache_age_seconds=radar_cache_age,
            )
        )

        # Rain gauges source
        rain_metrics = self.rain_gauge_provider.get_metrics()
        rain_cache_age = await cache.get_cache_age("rain_gauges", "latest")
        sources.append(
            SourceHealth(
                name="rain_gauges",
                status=rain_metrics.status,
                mode="mock" if self.rain_gauge_provider.is_mock else "real",
                last_success=rain_metrics.last_success,
                last_error=rain_metrics.last_error,
                latency_ms=rain_metrics.latency_ms,
                cache_age_seconds=rain_cache_age,
            )
        )

        # Incidents source
        incidents_metrics = self.incidents_provider.get_metrics()
        incidents_cache_age = await cache.get_cache_age("incidents", "latest")
        sources.append(
            SourceHealth(
                name="incidents",
                status=incidents_metrics.status,
                mode="mock" if self.incidents_provider.is_mock else "real",
                last_success=incidents_metrics.last_success,
                last_error=incidents_metrics.last_error,
                latency_ms=incidents_metrics.latency_ms,
                cache_age_seconds=incidents_cache_age,
            )
        )

        return sources

    def _calculate_overall_status(
        self,
        db_status: str,
        redis_status: str,
        sources: list[SourceHealth],
    ) -> str:
        """Calculate overall service status."""
        # Critical: database or redis down
        if db_status != "connected" or redis_status != "connected":
            return "unhealthy"

        # Count source statuses
        down_count = sum(1 for s in sources if s.status == SourceStatus.DOWN)
        degraded_count = sum(
            1 for s in sources if s.status == SourceStatus.DEGRADED
        )

        # If more than half sources are down
        if down_count > len(sources) / 2:
            return "unhealthy"

        # If any sources are degraded or down
        if down_count > 0 or degraded_count > 0:
            return "degraded"

        return "healthy"
