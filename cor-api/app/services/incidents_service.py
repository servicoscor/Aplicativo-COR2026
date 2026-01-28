from __future__ import annotations
"""Incidents service with cache and fallback support."""

from datetime import datetime, timezone
from typing import Any

from app.core.config import settings
from app.core.errors import ProviderException
from app.core.logging import get_logger
from app.providers.incidents_provider import IncidentsProvider
from app.schemas.common import CacheInfo
from app.schemas.incident import Incident, IncidentsResponse, IncidentsSummary
from app.services.cache_service import CacheService, get_cache_service

logger = get_logger(__name__)


class IncidentsService:
    """
    Service for incidents data with caching and fallback.

    Fetches data from IncidentsProvider, caches successful responses,
    and returns cached data when provider fails.
    """

    CACHE_NAMESPACE = "incidents"
    CACHE_KEY_LATEST = "latest"

    def __init__(
        self,
        provider: IncidentsProvider | None = None,
        cache: CacheService | None = None,
    ):
        """Initialize incidents service."""
        self.provider = provider or IncidentsProvider()
        self._cache = cache

    async def _get_cache(self) -> CacheService:
        """Get cache service."""
        if self._cache is None:
            self._cache = await get_cache_service()
        return self._cache

    async def get_incidents(
        self,
        bbox: str | None = None,
        since: datetime | None = None,
        incident_type: str | None = None,
    ) -> IncidentsResponse:
        """
        Get incidents with optional filters.

        Tries to fetch from provider, falls back to cache on failure.

        Args:
            bbox: Bounding box filter "min_lon,min_lat,max_lon,max_lat"
            since: Only return incidents since this time
            incident_type: Filter by incident type

        Returns:
            IncidentsResponse with incidents data
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

        # Parse incident types
        incident_types = None
        if incident_type:
            incident_types = [t.strip() for t in incident_type.split(",")]

        # Create cache key based on filters
        cache_key = self._make_cache_key(bbox, since, incident_type)

        try:
            # Try to fetch from provider
            result = await self.provider.fetch_incidents(
                bbox=bbox_tuple,
                since=since,
                incident_types=incident_types,
            )

            if result.success and result.data:
                # Extract data
                incidents = result.data["incidents"]
                summary = result.data["summary"]

                # Cache the successful response
                cache_data = {
                    "incidents": [
                        i.model_dump() if isinstance(i, Incident) else i
                        for i in incidents
                    ],
                    "summary": (
                        summary.model_dump()
                        if isinstance(summary, IncidentsSummary)
                        else summary
                    ),
                }
                await cache.set(
                    self.CACHE_NAMESPACE,
                    cache_key,
                    cache_data,
                    ttl_seconds=settings.cache_ttl_incidents * 2,
                )

                logger.debug("Returning fresh incidents data")
                return IncidentsResponse(
                    success=True,
                    timestamp=datetime.now(timezone.utc),
                    data=incidents,
                    summary=summary,
                    bbox_applied=bbox,
                    since_applied=since,
                    type_filter_applied=incident_types,
                    cache=None,
                )

        except ProviderException as e:
            logger.warning(f"Incidents provider failed: {e.message}")

        except Exception as e:
            logger.error(f"Unexpected error fetching incidents: {e}")

        # Provider failed - try cache fallback
        cached_data, cache_info = await cache.get_fallback(
            self.CACHE_NAMESPACE,
            cache_key,
        )

        if cached_data:
            logger.info(
                f"Serving stale incidents data (age: {cache_info.age_seconds}s)"
            )

            # Parse cached data
            incidents = [
                Incident.model_validate(i)
                for i in cached_data.get("incidents", [])
            ]
            summary = IncidentsSummary.model_validate(cached_data["summary"])

            return IncidentsResponse(
                success=True,
                timestamp=datetime.now(timezone.utc),
                data=incidents,
                summary=summary,
                bbox_applied=bbox,
                since_applied=since,
                type_filter_applied=incident_types,
                cache=cache_info,
            )

        # No cache available - raise error
        raise ProviderException(
            message="Incidents data unavailable",
            provider="incidents",
            code="INCIDENTS_UNAVAILABLE",
        )

    def _make_cache_key(
        self,
        bbox: str | None,
        since: datetime | None,
        incident_type: str | None,
    ) -> str:
        """Create cache key from filter parameters."""
        parts = [self.CACHE_KEY_LATEST]

        if bbox:
            parts.append(f"bbox:{bbox}")
        if since:
            parts.append(f"since:{since.isoformat()}")
        if incident_type:
            parts.append(f"type:{incident_type}")

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
