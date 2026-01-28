from __future__ import annotations
"""Weather service with cache and fallback support."""

from datetime import datetime, timezone
from typing import Any

from app.core.config import settings
from app.core.errors import ProviderException
from app.core.logging import get_logger
from app.providers.weather_provider import WeatherProvider
from app.schemas.common import CacheInfo
from app.schemas.weather import (
    CurrentWeather,
    WeatherForecast,
    WeatherForecastResponse,
    WeatherNowResponse,
)
from app.services.cache_service import CacheService, get_cache_service

logger = get_logger(__name__)


class WeatherService:
    """
    Service for weather data with caching and fallback.

    Fetches data from WeatherProvider, caches successful responses,
    and returns cached data when provider fails.
    """

    CACHE_NAMESPACE = "weather"
    CACHE_KEY_NOW = "now"
    CACHE_KEY_FORECAST = "forecast"

    def __init__(
        self,
        provider: WeatherProvider | None = None,
        cache: CacheService | None = None,
    ):
        """Initialize weather service."""
        self.provider = provider or WeatherProvider()
        self._cache = cache

    async def _get_cache(self) -> CacheService:
        """Get cache service."""
        if self._cache is None:
            self._cache = await get_cache_service()
        return self._cache

    async def get_current_weather(self) -> WeatherNowResponse:
        """
        Get current weather conditions.

        Tries to fetch from provider, falls back to cache on failure.

        Returns:
            WeatherNowResponse with current weather data
        """
        cache = await self._get_cache()
        cache_info: CacheInfo | None = None

        try:
            # Try to fetch from provider
            result = await self.provider.fetch_current()

            if result.success and result.data:
                # Cache the successful response
                await cache.set(
                    self.CACHE_NAMESPACE,
                    self.CACHE_KEY_NOW,
                    result.data,
                    ttl_seconds=settings.cache_ttl_weather_now * 2,  # Keep longer for fallback
                )

                logger.debug("Returning fresh weather data")
                return WeatherNowResponse(
                    success=True,
                    timestamp=datetime.now(timezone.utc),
                    data=result.data,
                    cache=None,
                )

        except ProviderException as e:
            logger.warning(f"Weather provider failed: {e.message}")

        except Exception as e:
            logger.error(f"Unexpected error fetching weather: {e}")

        # Provider failed - try cache fallback
        cached_data, cache_info = await cache.get_fallback(
            self.CACHE_NAMESPACE,
            self.CACHE_KEY_NOW,
            CurrentWeather,
        )

        if cached_data:
            logger.info(
                f"Serving stale weather data (age: {cache_info.age_seconds}s)"
            )
            return WeatherNowResponse(
                success=True,
                timestamp=datetime.now(timezone.utc),
                data=cached_data,
                cache=cache_info,
            )

        # No cache available - raise error
        raise ProviderException(
            message="Weather data unavailable",
            provider="weather",
            code="WEATHER_UNAVAILABLE",
        )

    async def get_forecast(self, hours: int = 48) -> WeatherForecastResponse:
        """
        Get weather forecast.

        Tries to fetch from provider, falls back to cache on failure.

        Args:
            hours: Number of hours to forecast (max 168)

        Returns:
            WeatherForecastResponse with forecast data
        """
        # Limit hours
        hours = min(hours, 168)

        cache = await self._get_cache()
        cache_key = f"{self.CACHE_KEY_FORECAST}:{hours}"
        cache_info: CacheInfo | None = None

        try:
            # Try to fetch from provider
            result = await self.provider.fetch_forecast(hours=hours)

            if result.success and result.data:
                # Cache the successful response
                await cache.set(
                    self.CACHE_NAMESPACE,
                    cache_key,
                    result.data,
                    ttl_seconds=settings.cache_ttl_weather_forecast * 2,
                )

                logger.debug(f"Returning fresh forecast data for {hours} hours")
                return WeatherForecastResponse(
                    success=True,
                    timestamp=datetime.now(timezone.utc),
                    data=result.data,
                    cache=None,
                )

        except ProviderException as e:
            logger.warning(f"Weather forecast provider failed: {e.message}")

        except Exception as e:
            logger.error(f"Unexpected error fetching forecast: {e}")

        # Provider failed - try cache fallback
        cached_data, cache_info = await cache.get_fallback(
            self.CACHE_NAMESPACE,
            cache_key,
            WeatherForecast,
        )

        if cached_data:
            logger.info(
                f"Serving stale forecast data (age: {cache_info.age_seconds}s)"
            )
            return WeatherForecastResponse(
                success=True,
                timestamp=datetime.now(timezone.utc),
                data=cached_data,
                cache=cache_info,
            )

        # No cache available - raise error
        raise ProviderException(
            message="Weather forecast unavailable",
            provider="weather",
            code="FORECAST_UNAVAILABLE",
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
