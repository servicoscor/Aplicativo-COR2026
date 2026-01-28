from __future__ import annotations
"""Rain gauge service with cache and fallback support."""

from datetime import datetime, timezone
from typing import Any

from app.core.config import settings
from app.core.errors import ProviderException
from app.core.logging import get_logger
from app.providers.rain_gauge_provider import RainGaugeProvider
from app.schemas.common import CacheInfo
from app.schemas.rain_gauge import RainGauge, RainGaugesResponse, RainGaugesSummary
from app.services.cache_service import CacheService, get_cache_service

logger = get_logger(__name__)


class RainGaugeService:
    """
    Service for rain gauge data with caching and fallback.

    Fetches data from RainGaugeProvider, caches successful responses,
    and returns cached data when provider fails.
    """

    CACHE_NAMESPACE = "rain_gauges"
    CACHE_KEY_LATEST = "latest"

    def __init__(
        self,
        provider: RainGaugeProvider | None = None,
        cache: CacheService | None = None,
    ):
        """Initialize rain gauge service."""
        self.provider = provider or RainGaugeProvider()
        self._cache = cache

    async def _get_cache(self) -> CacheService:
        """Get cache service."""
        if self._cache is None:
            self._cache = await get_cache_service()
        return self._cache

    async def get_rain_gauges(
        self,
        bbox: str | None = None,
    ) -> RainGaugesResponse:
        """
        Get all rain gauge stations with latest readings.

        Tries to fetch from provider, falls back to cache on failure.

        Args:
            bbox: Bounding box filter "min_lon,min_lat,max_lon,max_lat"

        Returns:
            RainGaugesResponse with rain gauge data
        """
        cache = await self._get_cache()
        cache_info: CacheInfo | None = None

        # Parse bbox
        bbox_tuple = None
        if bbox:
            try:
                parts = [float(x.strip()) for x in bbox.split(",")]
                if len(parts) == 4:
                    bbox_tuple = (parts[0], parts[1], parts[2], parts[3])
            except ValueError:
                logger.warning(f"Invalid bbox format: {bbox}")

        # Create cache key based on filters
        cache_key = self._make_cache_key(bbox)

        try:
            # Try to fetch from provider
            result = await self.provider.fetch_latest(bbox=bbox_tuple)

            if result.success and result.data:
                # Extract data
                gauges = result.data["gauges"]
                summary = result.data["summary"]

                # Cache the successful response
                cache_data = {
                    "gauges": [
                        g.model_dump() if isinstance(g, RainGauge) else g
                        for g in gauges
                    ],
                    "summary": (
                        summary.model_dump()
                        if isinstance(summary, RainGaugesSummary)
                        else summary
                    ),
                }
                await cache.set(
                    self.CACHE_NAMESPACE,
                    cache_key,
                    cache_data,
                    ttl_seconds=settings.cache_ttl_rain_gauges * 2,
                )

                logger.debug("Returning fresh rain gauge data")
                return RainGaugesResponse(
                    success=True,
                    timestamp=datetime.now(timezone.utc),
                    data=gauges,
                    summary=summary,
                    bbox_applied=bbox,
                    cache=None,
                )

        except ProviderException as e:
            logger.warning(f"Rain gauge provider failed: {e.message}")

        except Exception as e:
            logger.error(f"Unexpected error fetching rain gauges: {e}")

        # Provider failed - try cache fallback
        cached_data, cache_info = await cache.get_fallback(
            self.CACHE_NAMESPACE,
            cache_key,
        )

        if cached_data:
            logger.info(
                f"Serving stale rain gauge data (age: {cache_info.age_seconds}s)"
            )

            # Parse cached data
            gauges = [
                RainGauge.model_validate(g)
                for g in cached_data.get("gauges", [])
            ]
            summary = RainGaugesSummary.model_validate(cached_data["summary"])

            return RainGaugesResponse(
                success=True,
                timestamp=datetime.now(timezone.utc),
                data=gauges,
                summary=summary,
                bbox_applied=bbox,
                cache=cache_info,
            )

        # No cache available - raise error
        raise ProviderException(
            message="Rain gauge data unavailable",
            provider="rain_gauges",
            code="RAIN_GAUGES_UNAVAILABLE",
        )

    def _make_cache_key(self, bbox: str | None) -> str:
        """Create cache key from filter parameters."""
        parts = [self.CACHE_KEY_LATEST]

        if bbox:
            parts.append(f"bbox:{bbox}")

        return ":".join(parts)

    def get_provider_metrics(self) -> dict[str, Any]:
        """Get provider metrics."""
        metrics = self.provider.get_metrics()
        return {
            "name": metrics.name,
            "status": metrics.status.value,
            "last_success": metrics.last_success,
            "last_error": metrics.last_error,
            "latency_ms": metrics.latency_ms,
            "request_count": metrics.request_count,
            "error_count": metrics.error_count,
        }
