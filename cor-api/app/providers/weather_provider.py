"""Weather data provider with mock implementation."""

import random
import time
from datetime import datetime, timedelta, timezone
from typing import Any

from app.core.config import settings
from app.core.logging import get_logger
from app.providers.base import BaseProvider, ProviderResult
from app.schemas.weather import (
    CurrentWeather,
    WeatherCondition,
    WeatherForecast,
    WeatherForecastItem,
    WindDirection,
)

logger = get_logger(__name__)


class WeatherProvider(BaseProvider):
    """
    Provider for weather data.

    When configured with a real URL, fetches from external weather API.
    Otherwise, returns realistic mock data for Rio de Janeiro.

    To configure with real API:
    - Set WEATHER_PROVIDER_URL environment variable
    - Set WEATHER_PROVIDER_API_KEY if required
    """

    def __init__(self):
        super().__init__(
            name="weather",
            base_url=settings.weather_provider_url,
            api_key=settings.weather_provider_api_key,
        )

    async def fetch_current(self) -> ProviderResult[CurrentWeather]:
        """
        Fetch current weather conditions.

        Returns:
            ProviderResult containing CurrentWeather data
        """
        start_time = time.perf_counter()

        if self.is_mock:
            # Return mock data
            data = self._generate_mock_current_weather()
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_success(latency_ms)
            logger.debug("Returning mock current weather data")
            return ProviderResult.ok(data, latency_ms)

        # TODO: Implement real API call when URL is configured
        # Example structure for real implementation:
        # response = await self._make_request("GET", "/current", params={"location": "Rio de Janeiro"})
        # data = self._parse_current_weather(response.json())
        # return ProviderResult.ok(data, self.metrics.latency_ms)

        raise NotImplementedError("Real weather API not yet implemented")

    async def fetch_forecast(self, hours: int = 48) -> ProviderResult[WeatherForecast]:
        """
        Fetch weather forecast.

        Args:
            hours: Number of hours to forecast (default: 48)

        Returns:
            ProviderResult containing WeatherForecast data
        """
        start_time = time.perf_counter()

        if self.is_mock:
            # Return mock data
            data = self._generate_mock_forecast(hours)
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_success(latency_ms)
            logger.debug(f"Returning mock forecast data for {hours} hours")
            return ProviderResult.ok(data, latency_ms)

        # TODO: Implement real API call when URL is configured
        raise NotImplementedError("Real weather API not yet implemented")

    async def fetch(self, **kwargs: Any) -> ProviderResult[CurrentWeather]:
        """Default fetch returns current weather."""
        return await self.fetch_current()

    def _generate_mock_current_weather(self) -> CurrentWeather:
        """Generate realistic mock current weather for Rio de Janeiro."""
        now = datetime.now(timezone.utc)

        # Rio de Janeiro typical weather patterns
        # Summer (Dec-Mar): 25-35°C, humid, afternoon thunderstorms
        # Winter (Jun-Sep): 18-25°C, drier
        month = now.month
        hour = now.hour

        if month in [12, 1, 2, 3]:  # Summer
            base_temp = 28 + random.uniform(-3, 5)
            humidity = random.randint(65, 90)
            conditions = [
                WeatherCondition.CLEAR,
                WeatherCondition.PARTLY_CLOUDY,
                WeatherCondition.CLOUDY,
                WeatherCondition.RAIN,
            ]
            weights = [0.3, 0.35, 0.2, 0.15] if hour < 14 else [0.15, 0.25, 0.3, 0.3]
        elif month in [6, 7, 8, 9]:  # Winter
            base_temp = 22 + random.uniform(-4, 3)
            humidity = random.randint(50, 75)
            conditions = [
                WeatherCondition.CLEAR,
                WeatherCondition.PARTLY_CLOUDY,
                WeatherCondition.CLOUDY,
            ]
            weights = [0.4, 0.4, 0.2]
        else:  # Transition
            base_temp = 25 + random.uniform(-3, 4)
            humidity = random.randint(55, 80)
            conditions = [
                WeatherCondition.CLEAR,
                WeatherCondition.PARTLY_CLOUDY,
                WeatherCondition.CLOUDY,
                WeatherCondition.RAIN,
            ]
            weights = [0.3, 0.35, 0.25, 0.1]

        condition = random.choices(conditions, weights=weights)[0]

        # Adjust temperature for time of day
        if 6 <= hour < 12:
            temp_adjustment = (hour - 6) * 0.8
        elif 12 <= hour < 18:
            temp_adjustment = 4.8 - (hour - 12) * 0.3
        else:
            temp_adjustment = -2 - (hour - 18) * 0.2 if hour >= 18 else -3

        temperature = base_temp + temp_adjustment

        condition_texts = {
            WeatherCondition.CLEAR: "Céu limpo",
            WeatherCondition.PARTLY_CLOUDY: "Parcialmente nublado",
            WeatherCondition.CLOUDY: "Nublado",
            WeatherCondition.RAIN: "Chuva",
            WeatherCondition.HEAVY_RAIN: "Chuva forte",
            WeatherCondition.THUNDERSTORM: "Tempestade",
            WeatherCondition.FOG: "Neblina",
            WeatherCondition.UNKNOWN: "Desconhecido",
        }

        return CurrentWeather(
            temperature=round(temperature, 1),
            feels_like=round(temperature + random.uniform(-2, 3), 1),
            humidity=humidity,
            pressure=round(1013 + random.uniform(-10, 10), 1),
            wind_speed=round(random.uniform(5, 25), 1),
            wind_direction=random.choice(list(WindDirection)),
            wind_gust=round(random.uniform(10, 35), 1) if random.random() > 0.5 else None,
            visibility=round(random.uniform(8, 15), 1),
            uv_index=random.randint(1, 11) if 6 <= hour <= 18 else 0,
            condition=condition,
            condition_text=condition_texts[condition],
            icon=f"weather_{condition.value}",
            observation_time=now,
            location="Rio de Janeiro, RJ",
        )

    def _generate_mock_forecast(self, hours: int) -> WeatherForecast:
        """Generate realistic mock weather forecast."""
        now = datetime.now(timezone.utc)
        items: list[WeatherForecastItem] = []

        # Start from current weather as baseline
        current = self._generate_mock_current_weather()
        base_temp = current.temperature

        for i in range(hours):
            forecast_time = now + timedelta(hours=i + 1)
            hour = forecast_time.hour

            # Daily temperature variation
            if 6 <= hour < 14:
                temp_mod = (hour - 6) * 0.6
            elif 14 <= hour < 20:
                temp_mod = 4.8 - (hour - 14) * 0.5
            else:
                temp_mod = -2

            temperature = base_temp + temp_mod + random.uniform(-2, 2)

            # Weather condition progression
            precip_prob = random.randint(0, 100)
            if precip_prob > 70:
                condition = WeatherCondition.RAIN
            elif precip_prob > 50:
                condition = WeatherCondition.CLOUDY
            elif precip_prob > 30:
                condition = WeatherCondition.PARTLY_CLOUDY
            else:
                condition = WeatherCondition.CLEAR

            condition_texts = {
                WeatherCondition.CLEAR: "Céu limpo",
                WeatherCondition.PARTLY_CLOUDY: "Parcialmente nublado",
                WeatherCondition.CLOUDY: "Nublado",
                WeatherCondition.RAIN: "Chuva",
            }

            items.append(
                WeatherForecastItem(
                    forecast_time=forecast_time,
                    temperature=round(temperature, 1),
                    temperature_min=round(temperature - random.uniform(1, 3), 1),
                    temperature_max=round(temperature + random.uniform(1, 3), 1),
                    feels_like=round(temperature + random.uniform(-2, 2), 1),
                    humidity=random.randint(50, 90),
                    pressure=round(1013 + random.uniform(-8, 8), 1),
                    wind_speed=round(random.uniform(5, 20), 1),
                    wind_direction=random.choice(list(WindDirection)),
                    precipitation_probability=precip_prob,
                    precipitation_mm=round(random.uniform(0, 15), 1) if precip_prob > 50 else 0,
                    condition=condition,
                    condition_text=condition_texts.get(condition, "Desconhecido"),
                    icon=f"weather_{condition.value}",
                )
            )

        return WeatherForecast(
            location="Rio de Janeiro, RJ",
            generated_at=now,
            hours_requested=hours,
            items=items,
        )
