"""API v1 router aggregator."""

from fastapi import APIRouter

from app.api.v1.alertario import router as alertario_router
from app.api.v1.alerts import router as alerts_router
from app.api.v1.devices import router as devices_router
from app.api.v1.health import router as health_router
from app.api.v1.incidents import router as incidents_router
from app.api.v1.map_layers import router as map_layers_router
from app.api.v1.rain_gauges import router as rain_gauges_router
from app.api.v1.reference import router as reference_router
from app.api.v1.sirens import router as sirens_router
from app.api.v1.status import router as status_router
from app.api.v1.weather import router as weather_router

# Admin router
from app.api.v1.admin import admin_router

api_router = APIRouter()

# Include all routers
api_router.include_router(health_router, tags=["health"])
api_router.include_router(weather_router, prefix="/weather", tags=["weather"])
api_router.include_router(alertario_router, prefix="/alerta-rio", tags=["alerta-rio"])
api_router.include_router(rain_gauges_router, prefix="/rain-gauges", tags=["rain-gauges"])
api_router.include_router(sirens_router, prefix="/sirens", tags=["sirens"])
api_router.include_router(incidents_router, prefix="/incidents", tags=["incidents"])
api_router.include_router(map_layers_router, prefix="/map", tags=["map"])
api_router.include_router(devices_router, prefix="/devices", tags=["devices"])
api_router.include_router(alerts_router, prefix="/alerts", tags=["alerts"])
api_router.include_router(status_router, prefix="/status", tags=["status"])
api_router.include_router(reference_router, prefix="/reference", tags=["reference"])

# Admin API (authentication required)
api_router.include_router(admin_router)
