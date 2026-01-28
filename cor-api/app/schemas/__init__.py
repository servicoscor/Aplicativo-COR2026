"""Pydantic schemas for API request/response models."""

from app.schemas.common import (
    BaseResponse,
    CacheInfo,
    ErrorResponse,
    PaginatedResponse,
    SourceStatus,
)
from app.schemas.health import HealthResponse, SourceHealth
from app.schemas.weather import (
    CurrentWeather,
    WeatherForecast,
    WeatherForecastItem,
    WeatherNowResponse,
    WeatherForecastResponse,
)
from app.schemas.radar import RadarSnapshot, RadarLatestResponse
from app.schemas.rain_gauge import RainGauge, RainGaugeReading, RainGaugesResponse
from app.schemas.incident import Incident, IncidentGeometry, IncidentsResponse
from app.schemas.map_layer import MapLayer, MapLayersResponse
from app.schemas.alert import (
    Alert,
    AlertCreate,
    AlertSeverity,
    AlertStatus,
    AlertListResponse,
    AlertDetailResponse,
    AlertSendResponse,
    InboxAlert,
    InboxResponse,
)
from app.schemas.device import (
    Device,
    DevicePlatform,
    DeviceRegister,
    DeviceLocationUpdate,
    DeviceRegisterResponse,
    DeviceLocationResponse,
)

__all__ = [
    # Common
    "BaseResponse",
    "CacheInfo",
    "ErrorResponse",
    "PaginatedResponse",
    "SourceStatus",
    # Health
    "HealthResponse",
    "SourceHealth",
    # Weather
    "CurrentWeather",
    "WeatherForecast",
    "WeatherForecastItem",
    "WeatherNowResponse",
    "WeatherForecastResponse",
    # Radar
    "RadarSnapshot",
    "RadarLatestResponse",
    # Rain Gauge
    "RainGauge",
    "RainGaugeReading",
    "RainGaugesResponse",
    # Incident
    "Incident",
    "IncidentGeometry",
    "IncidentsResponse",
    # Map Layer
    "MapLayer",
    "MapLayersResponse",
    # Alert
    "Alert",
    "AlertCreate",
    "AlertSeverity",
    "AlertStatus",
    "AlertListResponse",
    "AlertDetailResponse",
    "AlertSendResponse",
    "InboxAlert",
    "InboxResponse",
    # Device
    "Device",
    "DevicePlatform",
    "DeviceRegister",
    "DeviceLocationUpdate",
    "DeviceRegisterResponse",
    "DeviceLocationResponse",
]
