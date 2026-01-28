from __future__ import annotations
"""Siren service with cache and fallback support."""

from datetime import datetime, timezone
from typing import Any

from app.core.config import settings
from app.core.errors import ProviderException
from app.core.logging import get_logger
from app.providers.siren_provider import SirenProvider
from app.schemas.common import CacheInfo
from app.schemas.siren import Siren, SirensResponse, SirensSummary
from app.services.cache_service import CacheService, get_cache_service

logger = get_logger(__name__)


class SirenService:
    """
    Service for siren data with caching and fallback.

    Fetches data from SirenProvider, caches successful responses,
    and returns cached data when provider fails.
    """

    CACHE_NAMESPACE = "sirens"
    CACHE_KEY_LATEST = "latest"
    CACHE_TTL_SECONDS = 120  # 2 minutes

    def __init__(
        self,
        provider: SirenProvider | None = None,
        cache: CacheService | None = None,
    ):
        """Initialize siren service."""
        self.provider = provider or SirenProvider()
        self._cache = cache

    async def _get_cache(self) -> CacheService:
        """Get cache service."""
        if self._cache is None:
            self._cache = await get_cache_service()
        return self._cache

    async def get_sirens(
        self,
        bbox: str | None = None,
    ) -> SirensResponse:
        """
        Get all sirens with current status.

        Tries to fetch from provider, falls back to cache on failure.

        Args:
            bbox: Bounding box filter "min_lon,min_lat,max_lon,max_lat"

        Returns:
            SirensResponse with siren data
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
                sirens = result.data["sirens"]
                summary = result.data["summary"]
                data_timestamp = result.data.get("data_timestamp")

                # Cache the successful response
                cache_data = {
                    "sirens": [
                        s.model_dump() if isinstance(s, Siren) else s for s in sirens
                    ],
                    "summary": (
                        summary.model_dump()
                        if isinstance(summary, SirensSummary)
                        else summary
                    ),
                    "data_timestamp": (
                        data_timestamp.isoformat() if data_timestamp else None
                    ),
                }
                await cache.set(
                    self.CACHE_NAMESPACE,
                    cache_key,
                    cache_data,
                    ttl_seconds=self.CACHE_TTL_SECONDS * 2,
                )

                logger.debug("Returning fresh siren data")
                return SirensResponse(
                    success=True,
                    timestamp=datetime.now(timezone.utc),
                    data=sirens,
                    summary=summary,
                    data_timestamp=data_timestamp,
                    is_stale=False,
                )

        except ProviderException as e:
            logger.warning(f"Siren provider failed: {e.message}")

        except Exception as e:
            logger.error(f"Unexpected error fetching sirens: {e}")

        # Provider failed - try cache fallback
        cached_data, cache_info = await cache.get_fallback(
            self.CACHE_NAMESPACE,
            cache_key,
        )

        if cached_data:
            logger.info(f"Serving stale siren data (age: {cache_info.age_seconds}s)")

            # Parse cached data
            sirens = [Siren.model_validate(s) for s in cached_data.get("sirens", [])]
            summary = SirensSummary.model_validate(cached_data["summary"])

            data_timestamp = None
            if cached_data.get("data_timestamp"):
                try:
                    data_timestamp = datetime.fromisoformat(
                        cached_data["data_timestamp"]
                    )
                except Exception:
                    pass

            return SirensResponse(
                success=True,
                timestamp=datetime.now(timezone.utc),
                data=sirens,
                summary=summary,
                data_timestamp=data_timestamp,
                is_stale=True,
            )

        # No cache available - raise error
        raise ProviderException(
            message="Siren data unavailable",
            provider="sirens",
            code="SIRENS_UNAVAILABLE",
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
