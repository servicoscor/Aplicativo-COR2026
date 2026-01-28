"""Tests for cache fallback functionality."""

import pytest
from datetime import datetime, timezone, timedelta
from unittest.mock import AsyncMock, MagicMock, patch

from app.providers.weather_provider import WeatherProvider
from app.providers.base import ProviderResult
from app.services.cache_service import CacheService
from app.services.weather_service import WeatherService
from app.schemas.weather import CurrentWeather, WeatherCondition, WindDirection
from app.schemas.common import CacheInfo


@pytest.fixture
def mock_current_weather() -> CurrentWeather:
    """Create mock current weather data."""
    return CurrentWeather(
        temperature=25.5,
        feels_like=27.0,
        humidity=75,
        pressure=1013.0,
        wind_speed=10.5,
        wind_direction=WindDirection.NE,
        condition=WeatherCondition.PARTLY_CLOUDY,
        condition_text="Parcialmente nublado",
        observation_time=datetime.now(timezone.utc),
        location="Rio de Janeiro",
    )


@pytest.fixture
def mock_cache_info() -> CacheInfo:
    """Create mock cache info."""
    return CacheInfo(
        stale=True,
        age_seconds=120,
        cached_at=datetime.now(timezone.utc) - timedelta(seconds=120),
    )


@pytest.mark.asyncio
async def test_weather_service_returns_fresh_data(
    mock_current_weather: CurrentWeather,
) -> None:
    """Test weather service returns fresh data from provider."""
    # Mock provider
    mock_provider = MagicMock(spec=WeatherProvider)
    mock_provider.fetch_current = AsyncMock(
        return_value=ProviderResult.ok(mock_current_weather, latency_ms=50.0)
    )

    # Mock cache
    mock_cache = MagicMock(spec=CacheService)
    mock_cache.set = AsyncMock()
    mock_cache.get_fallback = AsyncMock(return_value=(None, None))

    service = WeatherService(provider=mock_provider, cache=mock_cache)
    service._cache = mock_cache

    # Get weather
    response = await service.get_current_weather()

    # Should return fresh data
    assert response.success is True
    assert response.cache is None  # No cache info for fresh data
    assert response.data.temperature == mock_current_weather.temperature

    # Should have cached the result
    mock_cache.set.assert_called_once()


@pytest.mark.asyncio
async def test_weather_service_returns_cached_on_failure(
    mock_current_weather: CurrentWeather,
    mock_cache_info: CacheInfo,
) -> None:
    """Test weather service returns cached data when provider fails."""
    # Mock provider that fails
    mock_provider = MagicMock(spec=WeatherProvider)
    mock_provider.fetch_current = AsyncMock(
        return_value=ProviderResult.fail("Provider unavailable")
    )

    # Mock cache with data
    mock_cache = MagicMock(spec=CacheService)
    mock_cache.set = AsyncMock()
    mock_cache.get_fallback = AsyncMock(
        return_value=(mock_current_weather, mock_cache_info)
    )

    service = WeatherService(provider=mock_provider, cache=mock_cache)
    service._cache = mock_cache

    # Get weather
    response = await service.get_current_weather()

    # Should return cached data
    assert response.success is True
    assert response.cache is not None
    assert response.cache.stale is True
    assert response.cache.age_seconds == 120
    assert response.data.temperature == mock_current_weather.temperature


@pytest.mark.asyncio
async def test_weather_service_raises_when_no_cache(
) -> None:
    """Test weather service raises error when provider fails and no cache."""
    from app.core.errors import ProviderException

    # Mock provider that fails
    mock_provider = MagicMock(spec=WeatherProvider)
    mock_provider.fetch_current = AsyncMock(
        return_value=ProviderResult.fail("Provider unavailable")
    )

    # Mock cache with no data
    mock_cache = MagicMock(spec=CacheService)
    mock_cache.get_fallback = AsyncMock(return_value=(None, None))

    service = WeatherService(provider=mock_provider, cache=mock_cache)
    service._cache = mock_cache

    # Should raise exception
    with pytest.raises(ProviderException) as exc_info:
        await service.get_current_weather()

    assert "unavailable" in exc_info.value.message.lower()


@pytest.mark.asyncio
async def test_cache_info_indicates_stale_data(
    mock_current_weather: CurrentWeather,
) -> None:
    """Test cache info correctly indicates stale data."""
    cache_time = datetime.now(timezone.utc) - timedelta(seconds=300)
    cache_info = CacheInfo(
        stale=True,
        age_seconds=300,
        cached_at=cache_time,
    )

    assert cache_info.stale is True
    assert cache_info.age_seconds == 300
    assert cache_info.cached_at == cache_time


@pytest.mark.asyncio
async def test_provider_exception_triggers_fallback(
    mock_current_weather: CurrentWeather,
    mock_cache_info: CacheInfo,
) -> None:
    """Test that provider exception triggers cache fallback."""
    from app.core.errors import ProviderException

    # Mock provider that raises exception
    mock_provider = MagicMock(spec=WeatherProvider)
    mock_provider.fetch_current = AsyncMock(
        side_effect=ProviderException("Network error", provider="weather")
    )

    # Mock cache with data
    mock_cache = MagicMock(spec=CacheService)
    mock_cache.get_fallback = AsyncMock(
        return_value=(mock_current_weather, mock_cache_info)
    )

    service = WeatherService(provider=mock_provider, cache=mock_cache)
    service._cache = mock_cache

    # Should fall back to cache
    response = await service.get_current_weather()

    assert response.success is True
    assert response.cache.stale is True


def test_cache_info_fresh_data_has_no_stale_flag() -> None:
    """Test that fresh data doesn't have stale flag."""
    cache_info = CacheInfo(
        stale=False,
        age_seconds=5,
        cached_at=datetime.now(timezone.utc) - timedelta(seconds=5),
    )

    assert cache_info.stale is False
