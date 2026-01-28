"""Admin API router aggregator."""

from fastapi import APIRouter

from app.api.v1.admin.auth import router as auth_router
from app.api.v1.admin.status import router as status_router
from app.api.v1.admin.alerts import router as alerts_router
from app.api.v1.admin.audit import router as audit_router

admin_router = APIRouter(prefix="/admin", tags=["admin"])

# Include sub-routers
admin_router.include_router(auth_router, prefix="/auth", tags=["admin-auth"])
admin_router.include_router(status_router, prefix="/status", tags=["admin-status"])
admin_router.include_router(alerts_router, prefix="/alerts", tags=["admin-alerts"])
admin_router.include_router(audit_router, prefix="/audit", tags=["admin-audit"])
