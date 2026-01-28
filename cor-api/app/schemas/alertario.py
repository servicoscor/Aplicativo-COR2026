from __future__ import annotations
"""Alerta Rio forecast schemas.

Schemas for weather forecasts from Sistema Alerta Rio.
Data source: https://www.sistema-alerta-rio.com.br
"""

from datetime import date, datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.common import BaseResponse


class ForecastPeriod(str, Enum):
    """Time periods for daily forecasts."""

    MADRUGADA = "madrugada"  # Dawn/early morning
    MANHA = "manhã"  # Morning
    TARDE = "tarde"  # Afternoon
    NOITE = "noite"  # Night


class TemperatureZone(BaseModel):
    """Temperature data for a specific zone of the city."""

    model_config = ConfigDict(populate_by_name=True)

    zone: str = Field(..., description="Zone name (e.g., 'Zona Norte', 'Zona Sul')")
    temp_min: float | None = Field(default=None, description="Minimum temperature in Celsius")
    temp_max: float | None = Field(default=None, description="Maximum temperature in Celsius")


class TideInfo(BaseModel):
    """Tide information."""

    model_config = ConfigDict(populate_by_name=True)

    time: datetime = Field(..., description="Time of tide")
    height: float = Field(..., description="Tide height in meters")
    level: str = Field(..., description="Tide level (Alta/Baixa)")


class ForecastNowItem(BaseModel):
    """Single forecast item for current/short-term forecast."""

    model_config = ConfigDict(populate_by_name=True)

    period: str = Field(
        ...,
        description="Time period (e.g., 'manhã', 'tarde', 'noite', 'madrugada')",
    )
    forecast_date: date | None = Field(
        default=None, alias="date", description="Forecast date"
    )
    condition: str = Field(..., description="Sky/weather condition (e.g., 'Nublado')")
    condition_icon: str | None = Field(
        default=None, description="Icon filename (e.g., 'nub_chuva.gif')"
    )
    precipitation: str | None = Field(
        default=None,
        description="Precipitation description (e.g., 'Pancadas de chuva isoladas')",
    )
    temperature_trend: str | None = Field(
        default=None, description="Temperature trend (e.g., 'Estável', 'Em elevação')"
    )
    wind_direction: str | None = Field(
        default=None, description="Wind direction (e.g., 'E/SE', 'N/NE')"
    )
    wind_speed: str | None = Field(
        default=None, description="Wind speed description (e.g., 'Fraco a Moderado')"
    )


class SynopticSummary(BaseModel):
    """Synoptic weather summary."""

    model_config = ConfigDict(populate_by_name=True)

    summary: str = Field(..., description="Synoptic summary text")
    created_at: datetime | None = Field(default=None, description="Summary creation time")


class ForecastNowData(BaseModel):
    """Complete current/short-term forecast data."""

    model_config = ConfigDict(populate_by_name=True)

    city: str = Field(default="Rio de Janeiro", description="City name")
    updated_at: datetime | None = Field(
        default=None, description="When the forecast was last updated"
    )
    items: list[ForecastNowItem] = Field(
        default_factory=list, description="Forecast items by period"
    )
    synoptic: SynopticSummary | None = Field(
        default=None, description="Synoptic weather summary"
    )
    temperatures: list[TemperatureZone] = Field(
        default_factory=list, description="Temperature by zone"
    )
    tides: list[TideInfo] = Field(default_factory=list, description="Tide information")


class ForecastNowResponse(BaseResponse):
    """Response for current/short-term forecast endpoint."""

    source: str = Field(default="AlertaRio", description="Data source name")
    fetched_at: datetime = Field(
        default_factory=lambda: datetime.now(),
        description="When the data was fetched",
    )
    stale: bool = Field(
        default=False, description="Whether data is stale (from cache fallback)"
    )
    age_seconds: int | None = Field(
        default=None, description="Age of cached data in seconds"
    )
    data: ForecastNowData = Field(..., description="Forecast data")


class ForecastExtendedDay(BaseModel):
    """Single day in extended forecast."""

    model_config = ConfigDict(populate_by_name=True)

    forecast_date: date = Field(..., alias="date", description="Forecast date")
    weekday: str | None = Field(default=None, description="Day of week in Portuguese")
    condition: str = Field(..., description="Sky/weather condition")
    condition_icon: str | None = Field(default=None, description="Icon filename")
    temp_min: float | None = Field(default=None, description="Minimum temperature in Celsius")
    temp_max: float | None = Field(default=None, description="Maximum temperature in Celsius")
    precipitation: str | None = Field(
        default=None, description="Precipitation description"
    )
    temperature_trend: str | None = Field(
        default=None, description="Temperature trend description"
    )
    wind_direction: str | None = Field(default=None, description="Wind direction")
    wind_speed: str | None = Field(default=None, description="Wind speed description")


class ForecastExtendedData(BaseModel):
    """Extended forecast data (multiple days)."""

    model_config = ConfigDict(populate_by_name=True)

    city: str = Field(default="Rio de Janeiro", description="City name")
    updated_at: datetime | None = Field(
        default=None, description="When the forecast was last updated"
    )
    days: list[ForecastExtendedDay] = Field(
        default_factory=list, description="Daily forecasts"
    )


class ForecastExtendedResponse(BaseResponse):
    """Response for extended forecast endpoint."""

    source: str = Field(default="AlertaRio", description="Data source name")
    fetched_at: datetime = Field(
        default_factory=lambda: datetime.now(),
        description="When the data was fetched",
    )
    stale: bool = Field(
        default=False, description="Whether data is stale (from cache fallback)"
    )
    age_seconds: int | None = Field(
        default=None, description="Age of cached data in seconds"
    )
    data: ForecastExtendedData = Field(..., description="Extended forecast data")
