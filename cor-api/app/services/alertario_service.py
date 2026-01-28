from __future__ import annotations
"""Alerta Rio service with cache and fallback support."""

from datetime import datetime, timezone
from typing import Any

from app.core.config import settings
from app.core.errors import ProviderException
from app.core.logging import get_logger
from app.providers.alertario_provider import AlertaRioProvider
from app.schemas.alertario import (
    ForecastExtendedData,
    ForecastExtendedResponse,
    ForecastNowData,
    ForecastNowResponse,
)
from app.schemas.common import CacheInfo
from app.services.cache_service import CacheService, get_cache_service

logger = get_logger(__name__)


class AlertaRioService:
    """
    Service for Alerta Rio weather forecasts with caching and fallback.

    Fetches data from AlertaRioProvider, caches successful responses,
    and returns cached data when the provider fails.
    """

    CACHE_NAMESPACE = "alertario"
    CACHE_KEY_FORECAST_NOW = "forecast_now"
    CACHE_KEY_FORECAST_EXTENDED = "forecast_extended"

    def __init__(
        self,
        provider: AlertaRioProvider | None = None,
        cache: CacheService | None = None,
    ):
        """Initialize Alerta Rio service."""
        self.provider = provider or AlertaRioProvider()
        self._cache = cache

    async def _get_cache(self) -> CacheService:
        """Get cache service."""
        if self._cache is None:
            self._cache = await get_cache_service()
        return self._cache

    async def get_forecast_now(self) -> ForecastNowResponse:
        """
        Get current/short-term weather forecast from Alerta Rio.

        Tries to fetch from provider, falls back to cache on failure.

        Returns:
            ForecastNowResponse with current forecast data
        """
        cache = await self._get_cache()
        cache_info: CacheInfo | None = None

        try:
            # Try to fetch from provider
            result = await self.provider.fetch_forecast_now()

            if result.success and result.data:
                # Cache the successful response
                cache_ttl = getattr(settings, "cache_ttl_alertario", 300)
                await cache.set(
                    self.CACHE_NAMESPACE,
                    self.CACHE_KEY_FORECAST_NOW,
                    result.data,
                    ttl_seconds=cache_ttl * 2,  # Keep longer for fallback
                )

                logger.debug("Returning fresh AlertaRio forecast/now data")
                return ForecastNowResponse(
                    success=True,
                    timestamp=datetime.now(timezone.utc),
                    source="AlertaRio",
                    fetched_at=result.fetched_at,
                    stale=False,
                    age_seconds=None,
                    data=result.data,
                    cache=None,
                )

        except ProviderException as e:
            logger.warning(f"AlertaRio forecast/now provider failed: {e.message}")

        except Exception as e:
            logger.error(f"Unexpected error fetching AlertaRio forecast/now: {e}")

        # Provider failed - try cache fallback
        cached_data, cache_info = await cache.get_fallback(
            self.CACHE_NAMESPACE,
            self.CACHE_KEY_FORECAST_NOW,
            ForecastNowData,
        )

        if cached_data:
            logger.info(
                f"Serving stale AlertaRio forecast/now data "
                f"(age: {cache_info.age_seconds}s)"
            )
            return ForecastNowResponse(
                success=True,
                timestamp=datetime.now(timezone.utc),
                source="AlertaRio",
                fetched_at=cache_info.cached_at if cache_info else None,
                stale=True,
                age_seconds=cache_info.age_seconds if cache_info else None,
                data=cached_data,
                cache=cache_info,
            )

        # No cache available - raise error
        raise ProviderException(
            message="AlertaRio forecast data unavailable",
            provider="alertario",
            code="ALERTARIO_UNAVAILABLE",
        )

    async def get_forecast_extended(self) -> ForecastExtendedResponse:
        """
        Get extended weather forecast from Alerta Rio.

        Tries to fetch from provider, falls back to cache on failure.

        Returns:
            ForecastExtendedResponse with extended forecast data
        """
        cache = await self._get_cache()
        cache_info: CacheInfo | None = None

        try:
            # Try to fetch from provider
            result = await self.provider.fetch_forecast_extended()

            if result.success and result.data:
                # Cache the successful response (extended forecasts can be cached longer)
                cache_ttl = getattr(settings, "cache_ttl_alertario_extended", 600)
                await cache.set(
                    self.CACHE_NAMESPACE,
                    self.CACHE_KEY_FORECAST_EXTENDED,
                    result.data,
                    ttl_seconds=cache_ttl * 2,  # Keep longer for fallback
                )

                logger.debug("Returning fresh AlertaRio forecast/extended data")
                return ForecastExtendedResponse(
                    success=True,
                    timestamp=datetime.now(timezone.utc),
                    source="AlertaRio",
                    fetched_at=result.fetched_at,
                    stale=False,
                    age_seconds=None,
                    data=result.data,
                    cache=None,
                )

        except ProviderException as e:
            logger.warning(f"AlertaRio forecast/extended provider failed: {e.message}")

        except Exception as e:
            logger.error(f"Unexpected error fetching AlertaRio forecast/extended: {e}")

        # Provider failed - try cache fallback
        cached_data, cache_info = await cache.get_fallback(
            self.CACHE_NAMESPACE,
            self.CACHE_KEY_FORECAST_EXTENDED,
            ForecastExtendedData,
        )

        if cached_data:
            logger.info(
                f"Serving stale AlertaRio forecast/extended data "
                f"(age: {cache_info.age_seconds}s)"
            )
            return ForecastExtendedResponse(
                success=True,
                timestamp=datetime.now(timezone.utc),
                source="AlertaRio",
                fetched_at=cache_info.cached_at if cache_info else None,
                stale=True,
                age_seconds=cache_info.age_seconds if cache_info else None,
                data=cached_data,
                cache=cache_info,
            )

        # No cache available - raise error
        raise ProviderException(
            message="AlertaRio extended forecast data unavailable",
            provider="alertario",
            code="ALERTARIO_EXTENDED_UNAVAILABLE",
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
