"""Alerta Rio weather forecast API endpoints.

Provides weather forecasts from Sistema Alerta Rio.
Data source: https://www.sistema-alerta-rio.com.br
"""

from fastapi import APIRouter

from app.api.deps import ServicesDep
from app.core.security import ApiKeyDep, RateLimitDep
from app.schemas.alertario import ForecastExtendedResponse, ForecastNowResponse

router = APIRouter()


@router.get(
    "/forecast/now",
    response_model=ForecastNowResponse,
    summary="Current Forecast (Alerta Rio)",
    description="Get current/short-term weather forecast from Sistema Alerta Rio.",
)
async def get_forecast_now(
    services: ServicesDep,
    _api_key: ApiKeyDep = True,
    _rate_limit: RateLimitDep = True,
) -> ForecastNowResponse:
    """
    Get current/short-term weather forecast from Sistema Alerta Rio.

    Returns forecast data organized by time periods (madrugada, manhã, tarde, noite)
    along with additional information:

    **Forecast Items (by period):**
    - Weather condition (sky description)
    - Precipitation description
    - Temperature trend
    - Wind direction and speed

    **Additional Data:**
    - Synoptic summary (weather overview text)
    - Temperatures by zone (Zona Norte, Zona Sul, etc.)
    - Tide information (times and heights)

    **Metadata:**
    - `source`: "AlertaRio"
    - `fetched_at`: When data was retrieved
    - `stale`: true if data is from cache fallback
    - `age_seconds`: Age of cached data (if stale)

    If the Alerta Rio service is unavailable, cached data will be returned
    with `stale: true` and `age_seconds` indicating data age.

    **Example response:**
    ```json
    {
        "success": true,
        "source": "AlertaRio",
        "stale": false,
        "data": {
            "city": "Rio de Janeiro",
            "updated_at": "2024-01-15T10:00:00Z",
            "items": [
                {
                    "period": "manhã",
                    "condition": "Nublado",
                    "precipitation": "Pancadas de chuva isoladas",
                    "wind_direction": "E/SE",
                    "wind_speed": "Fraco a Moderado"
                }
            ],
            "synoptic": {
                "summary": "Um sistema frontal se aproxima..."
            },
            "temperatures": [
                {"zone": "Zona Norte", "temp_min": 22, "temp_max": 32}
            ],
            "tides": [
                {"time": "2024-01-15T05:30:00Z", "height": 0.3, "level": "Baixa"}
            ]
        }
    }
    ```
    """
    return await services.alertario.get_forecast_now()


@router.get(
    "/forecast/extended",
    response_model=ForecastExtendedResponse,
    summary="Extended Forecast (Alerta Rio)",
    description="Get extended weather forecast (multiple days) from Sistema Alerta Rio.",
)
async def get_forecast_extended(
    services: ServicesDep,
    _api_key: ApiKeyDep = True,
    _rate_limit: RateLimitDep = True,
) -> ForecastExtendedResponse:
    """
    Get extended weather forecast from Sistema Alerta Rio.

    Returns daily forecasts for the next several days (typically 4-5 days).

    **Daily Forecast Data:**
    - Date and weekday name (in Portuguese)
    - Weather condition (sky description)
    - Condition icon
    - Minimum and maximum temperatures
    - Precipitation description
    - Temperature trend
    - Wind direction and speed

    **Metadata:**
    - `source`: "AlertaRio"
    - `fetched_at`: When data was retrieved
    - `stale`: true if data is from cache fallback
    - `age_seconds`: Age of cached data (if stale)

    If the Alerta Rio service is unavailable, cached data will be returned
    with `stale: true` and `age_seconds` indicating data age.

    **Example response:**
    ```json
    {
        "success": true,
        "source": "AlertaRio",
        "stale": false,
        "data": {
            "city": "Rio de Janeiro",
            "updated_at": "2024-01-15T10:00:00Z",
            "days": [
                {
                    "date": "2024-01-16",
                    "weekday": "Terça-feira",
                    "condition": "Nublado",
                    "temp_min": 22.0,
                    "temp_max": 32.0,
                    "precipitation": "Chuva fraca a moderada isolada",
                    "wind_speed": "Fraco a Moderado"
                }
            ]
        }
    }
    ```
    """
    return await services.alertario.get_forecast_extended()
