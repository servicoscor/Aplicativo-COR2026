"""SQLAlchemy models."""

from app.models.base import Base, TimestampMixin
from app.models.rain_gauge import RainGaugeModel, RainGaugeReadingModel
from app.models.incident import IncidentModel
from app.models.radar_snapshot import RadarSnapshotModel
from app.models.device import DeviceModel
from app.models.alert import AlertModel, AlertAreaModel, AlertDeliveryModel

# Admin models
from app.models.admin_user import AdminUserModel
from app.models.operational_status import (
    OperationalStatusCurrentModel,
    OperationalStatusHistoryModel,
)
from app.models.audit_log import AuditLogModel

__all__ = [
    "Base",
    "TimestampMixin",
    "RainGaugeModel",
    "RainGaugeReadingModel",
    "IncidentModel",
    "RadarSnapshotModel",
    "DeviceModel",
    "AlertModel",
    "AlertAreaModel",
    "AlertDeliveryModel",
    # Admin models
    "AdminUserModel",
    "OperationalStatusCurrentModel",
    "OperationalStatusHistoryModel",
    "AuditLogModel",
]
