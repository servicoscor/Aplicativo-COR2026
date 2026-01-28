"""Public operational status endpoint for mobile app."""

from typing import Annotated

from fastapi import APIRouter, Depends

from app.db.session import get_db
from app.schemas.operational_status import (
    PublicOperationalStatus,
    PublicOperationalStatusResponse,
)
from app.services.operational_status_service import OperationalStatusService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter()

DbSession = Annotated[AsyncSession, Depends(get_db)]


@router.get(
    "/operational",
    response_model=PublicOperationalStatusResponse,
    summary="Get Operational Status",
    description="Get current operational status of the city (public endpoint for mobile app).",
)
async def get_operational_status(
    db: DbSession,
) -> PublicOperationalStatusResponse:
    """
    Get current operational status of the city.

    This is a public endpoint that does not require authentication.
    Used by the mobile app to display the city's operational status.

    Returns:
    - **city_stage**: 1-5 (stage of city operations)
      - 1: Normal - no significant occurrences
      - 2: Attention - risk of high impact occurrences
      - 3: Alert - occurrences impacting the city
      - 4: Critical - serious occurrences impacting the city
      - 5: Emergency - multiple serious occurrences, capacity exceeded
    - **heat_level**: 1-5 (heat alert level)
      - 1: Normal - temperatures below 36°C
      - 2: Attention - 36-40°C for 1-2 days
      - 3: Alert - 36-40°C for 3+ days (heat wave)
      - 4: Critical - 40-44°C
      - 5: Emergency - above 44°C
    - **updated_at**: When the status was last updated
    """
    service = OperationalStatusService(db)
    status = await service.get_current()

    return PublicOperationalStatusResponse(
        success=True,
        data=PublicOperationalStatus(
            city_stage=status.city_stage,
            heat_level=status.heat_level,
            updated_at=status.updated_at,
            is_stale=status.is_stale,
        ),
    )
