from __future__ import annotations
"""Radar service with cache and fallback support."""

from datetime import datetime, timezone
from typing import Any

from app.core.config import settings
from app.core.errors import ProviderException
from app.core.logging import get_logger
from app.providers.radar_provider import RadarProvider
from app.schemas.common import CacheInfo
from app.schemas.radar import RadarLatestResponse, RadarMetadata, RadarSnapshot
from app.services.cache_service import CacheService, get_cache_service

logger = get_logger(__name__)


class RadarService:
    """
    Service for radar data with caching and fallback.

    Fetches data from RadarProvider, caches successful responses,
    and returns cached data when provider fails.
    """

    CACHE_NAMESPACE = "radar"
    CACHE_KEY_LATEST = "latest"

    def __init__(
        self,
        provider: RadarProvider | None = None,
        cache: CacheService | None = None,
    ):
        """Initialize radar service."""
        self.provider = provider or RadarProvider()
        self._cache = cache

    async def _get_cache(self) -> CacheService:
        """Get cache service."""
        if self._cache is None:
            self._cache = await get_cache_service()
        return self._cache

    async def get_latest_radar(self) -> RadarLatestResponse:
        """
        Get latest radar snapshot with metadata.

        Tries to fetch from provider, falls back to cache on failure.

        Returns:
            RadarLatestResponse with radar data
        """
        cache = await self._get_cache()
        cache_info: CacheInfo | None = None

        try:
            # Try to fetch from provider
            result = await self.provider.fetch_latest()

            if result.success and result.data:
                # Extract data
                latest = result.data["latest"]
                metadata = result.data["metadata"]
                previous = result.data.get("previous", [])

                # Cache the successful response (use by_alias for proper serialization)
                # Cache errors should not prevent returning data
                try:
                    cache_data = {
                        "latest": latest.model_dump(by_alias=True) if isinstance(latest, RadarSnapshot) else latest,
                        "metadata": metadata.model_dump(by_alias=True) if isinstance(metadata, RadarMetadata) else metadata,
                        "previous": [
                            p.model_dump(by_alias=True) if isinstance(p, RadarSnapshot) else p
                            for p in previous
                        ],
                    }
                    await cache.set(
                        self.CACHE_NAMESPACE,
                        self.CACHE_KEY_LATEST,
                        cache_data,
                        ttl_seconds=settings.cache_ttl_radar * 2,
                    )
                except Exception as cache_err:
                    logger.warning(f"Failed to cache radar data (non-critical): {cache_err}")

                logger.debug("Returning fresh radar data")
                return RadarLatestResponse(
                    success=True,
                    timestamp=datetime.now(timezone.utc),
                    data=latest,
                    metadata=metadata,
                    previous_snapshots=previous,
                    cache=None,
                )

        except ProviderException as e:
            logger.warning(f"Radar provider failed: {e.message}")

        except Exception as e:
            logger.error(f"Unexpected error fetching radar: {e}")

        # Provider failed - try cache fallback
        cached_data, cache_info = await cache.get_fallback(
            self.CACHE_NAMESPACE,
            self.CACHE_KEY_LATEST,
        )

        if cached_data:
            logger.info(
                f"Serving stale radar data (age: {cache_info.age_seconds}s)"
            )

            # Parse cached data
            latest = RadarSnapshot.model_validate(cached_data["latest"])
            metadata = RadarMetadata.model_validate(cached_data["metadata"])
            previous = [
                RadarSnapshot.model_validate(p)
                for p in cached_data.get("previous", [])
            ]

            return RadarLatestResponse(
                success=True,
                timestamp=datetime.now(timezone.utc),
                data=latest,
                metadata=metadata,
                previous_snapshots=previous,
                cache=cache_info,
            )

        # No cache available - raise error
        raise ProviderException(
            message="Radar data unavailable",
            provider="radar",
            code="RADAR_UNAVAILABLE",
        )

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
