from __future__ import annotations
"""Weather-related schemas."""

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.common import BaseResponse, CacheInfo


class WeatherCondition(str, Enum):
    """Weather condition types."""

    CLEAR = "clear"
    PARTLY_CLOUDY = "partly_cloudy"
    CLOUDY = "cloudy"
    RAIN = "rain"
    HEAVY_RAIN = "heavy_rain"
    THUNDERSTORM = "thunderstorm"
    FOG = "fog"
    UNKNOWN = "unknown"


class WindDirection(str, Enum):
    """Wind direction cardinal points."""

    N = "N"
    NE = "NE"
    E = "E"
    SE = "SE"
    S = "S"
    SW = "SW"
    W = "W"
    NW = "NW"


class CurrentWeather(BaseModel):
    """Current weather conditions."""

    model_config = ConfigDict(populate_by_name=True)

    temperature: float = Field(..., description="Temperature in Celsius")
    feels_like: float = Field(..., description="Feels like temperature in Celsius")
    humidity: int = Field(..., ge=0, le=100, description="Relative humidity percentage")
    pressure: float = Field(..., description="Atmospheric pressure in hPa")
    wind_speed: float = Field(..., ge=0, description="Wind speed in km/h")
    wind_direction: WindDirection | None = Field(
        default=None, description="Wind direction"
    )
    wind_gust: float | None = Field(default=None, ge=0, description="Wind gust in km/h")
    visibility: float | None = Field(
        default=None, ge=0, description="Visibility in km"
    )
    uv_index: int | None = Field(default=None, ge=0, le=11, description="UV index")
    condition: WeatherCondition = Field(..., description="Weather condition")
    condition_text: str = Field(..., description="Human readable condition")
    icon: str | None = Field(default=None, description="Weather icon code")
    observation_time: datetime = Field(..., description="Observation timestamp")
    location: str = Field(default="Rio de Janeiro", description="Location name")


class WeatherNowResponse(BaseResponse):
    """Response for current weather endpoint."""

    data: CurrentWeather = Field(..., description="Current weather data")


class WeatherForecastItem(BaseModel):
    """Single forecast item."""

    model_config = ConfigDict(populate_by_name=True)

    forecast_time: datetime = Field(..., description="Forecast timestamp")
    temperature: float = Field(..., description="Temperature in Celsius")
    temperature_min: float | None = Field(
        default=None, description="Minimum temperature"
    )
    temperature_max: float | None = Field(
        default=None, description="Maximum temperature"
    )
    feels_like: float = Field(..., description="Feels like temperature")
    humidity: int = Field(..., ge=0, le=100, description="Humidity percentage")
    pressure: float = Field(..., description="Pressure in hPa")
    wind_speed: float = Field(..., ge=0, description="Wind speed in km/h")
    wind_direction: WindDirection | None = Field(
        default=None, description="Wind direction"
    )
    precipitation_probability: int = Field(
        ..., ge=0, le=100, description="Precipitation probability"
    )
    precipitation_mm: float = Field(
        default=0, ge=0, description="Expected precipitation in mm"
    )
    condition: WeatherCondition = Field(..., description="Weather condition")
    condition_text: str = Field(..., description="Human readable condition")
    icon: str | None = Field(default=None, description="Weather icon code")


class WeatherForecast(BaseModel):
    """Weather forecast data."""

    model_config = ConfigDict(populate_by_name=True)

    location: str = Field(default="Rio de Janeiro", description="Location name")
    generated_at: datetime = Field(..., description="Forecast generation timestamp")
    hours_requested: int = Field(..., description="Number of hours requested")
    items: list[WeatherForecastItem] = Field(
        default_factory=list, description="Forecast items"
    )


class WeatherForecastResponse(BaseResponse):
    """Response for weather forecast endpoint."""

    data: WeatherForecast = Field(..., description="Weather forecast data")
