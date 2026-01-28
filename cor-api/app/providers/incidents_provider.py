from __future__ import annotations
"""Incidents data provider with mock implementation."""

import random
import time
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any

from app.core.config import settings
from app.core.logging import get_logger
from app.providers.base import BaseProvider, ProviderResult
from app.schemas.incident import (
    GeometryType,
    Incident,
    IncidentGeometry,
    IncidentLocation,
    IncidentSeverity,
    IncidentsSummary,
    IncidentStatus,
    IncidentType,
)

logger = get_logger(__name__)


# Sample locations in Rio de Janeiro for mock incidents
RIO_INCIDENT_LOCATIONS = [
    {"name": "Av. Brasil", "neighborhood": "Bonsucesso", "region": "Zona Norte", "lat": -22.8576, "lon": -43.2536},
    {"name": "Linha Vermelha", "neighborhood": "Caju", "region": "Zona Norte", "lat": -22.8761, "lon": -43.2142},
    {"name": "Av. Atlântica", "neighborhood": "Copacabana", "region": "Zona Sul", "lat": -22.9714, "lon": -43.1823},
    {"name": "Túnel Rebouças", "neighborhood": "Lagoa", "region": "Zona Sul", "lat": -22.9631, "lon": -43.2178},
    {"name": "Av. das Américas", "neighborhood": "Barra da Tijuca", "region": "Zona Oeste", "lat": -22.9994, "lon": -43.3661},
    {"name": "Av. Rio Branco", "neighborhood": "Centro", "region": "Centro", "lat": -22.9068, "lon": -43.1729},
    {"name": "Linha Amarela", "neighborhood": "Jacarepaguá", "region": "Zona Oeste", "lat": -22.9320, "lon": -43.3136},
    {"name": "Av. Presidente Vargas", "neighborhood": "Centro", "region": "Centro", "lat": -22.9050, "lon": -43.1867},
    {"name": "Av. Niemeyer", "neighborhood": "São Conrado", "region": "Zona Sul", "lat": -22.9989, "lon": -43.2656},
    {"name": "Autoestrada Lagoa-Barra", "neighborhood": "Gávea", "region": "Zona Sul", "lat": -22.9847, "lon": -43.2428},
    {"name": "Av. Ayrton Senna", "neighborhood": "Barra da Tijuca", "region": "Zona Oeste", "lat": -22.9833, "lon": -43.3667},
    {"name": "Rua Voluntários da Pátria", "neighborhood": "Botafogo", "region": "Zona Sul", "lat": -22.9519, "lon": -43.1867},
]


class IncidentsProvider(BaseProvider):
    """
    Provider for city incidents data.

    When configured with a real URL, fetches from COR or other incident APIs.
    Otherwise, returns mock incidents based on real Rio de Janeiro locations.

    To configure with real API:
    - Set INCIDENTS_PROVIDER_URL environment variable
    - Set INCIDENTS_PROVIDER_API_KEY if required
    """

    def __init__(self):
        super().__init__(
            name="incidents",
            base_url=settings.incidents_provider_url,
            api_key=settings.incidents_provider_api_key,
        )

    async def fetch_incidents(
        self,
        bbox: tuple[float, float, float, float] | None = None,
        since: datetime | None = None,
        incident_types: list[str] | None = None,
        include_closed: bool = False,
    ) -> ProviderResult[dict[str, Any]]:
        """
        Fetch incidents with optional filters.

        Args:
            bbox: Bounding box filter (min_lon, min_lat, max_lon, max_lat)
            since: Only return incidents since this time
            incident_types: Filter by incident types
            include_closed: Whether to include closed incidents

        Returns:
            ProviderResult containing list of incidents and summary
        """
        start_time = time.perf_counter()

        if self.is_mock:
            # Return mock data
            data = self._generate_mock_incidents(
                bbox=bbox,
                since=since,
                incident_types=incident_types,
                include_closed=include_closed,
            )
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_success(latency_ms)
            logger.debug("Returning mock incidents data")
            return ProviderResult.ok(data, latency_ms)

        # TODO: Implement real API call when URL is configured
        raise NotImplementedError("Real incidents API not yet implemented")

    async def fetch(self, **kwargs: Any) -> ProviderResult[dict[str, Any]]:
        """Default fetch returns active incidents."""
        return await self.fetch_incidents(**kwargs)

    def _generate_mock_incidents(
        self,
        bbox: tuple[float, float, float, float] | None = None,
        since: datetime | None = None,
        incident_types: list[str] | None = None,
        include_closed: bool = False,
    ) -> dict[str, Any]:
        """Generate mock incidents data."""
        now = datetime.now(timezone.utc)

        # Generate a random but consistent set of incidents
        random.seed(now.hour)  # Same incidents for the same hour

        incidents: list[Incident] = []
        type_counts: dict[str, int] = {}
        severity_counts: dict[str, int] = {}
        status_counts: dict[str, int] = {}

        # Generate 5-15 active incidents
        num_incidents = random.randint(5, 15)

        for i in range(num_incidents):
            location = random.choice(RIO_INCIDENT_LOCATIONS)

            # Filter by bbox if provided
            if bbox:
                min_lon, min_lat, max_lon, max_lat = bbox
                if not (min_lat <= location["lat"] <= max_lat and
                        min_lon <= location["lon"] <= max_lon):
                    continue

            # Random incident type with realistic weights
            incident_type = random.choices(
                [
                    IncidentType.TRAFFIC,
                    IncidentType.FLOODING,
                    IncidentType.ACCIDENT,
                    IncidentType.ROAD_WORK,
                    IncidentType.EVENT,
                    IncidentType.LANDSLIDE,
                    IncidentType.FIRE,
                ],
                weights=[0.35, 0.15, 0.20, 0.15, 0.08, 0.04, 0.03],
            )[0]

            # Filter by type if provided
            if incident_types and incident_type.value not in incident_types:
                continue

            # Random severity
            severity = random.choices(
                [
                    IncidentSeverity.LOW,
                    IncidentSeverity.MEDIUM,
                    IncidentSeverity.HIGH,
                    IncidentSeverity.CRITICAL,
                ],
                weights=[0.3, 0.4, 0.2, 0.1],
            )[0]

            # Status - mostly open/in_progress
            status = random.choices(
                [
                    IncidentStatus.OPEN,
                    IncidentStatus.IN_PROGRESS,
                    IncidentStatus.RESOLVED,
                    IncidentStatus.CLOSED,
                ],
                weights=[0.4, 0.35, 0.15, 0.1],
            )[0]

            # Skip closed if not requested
            if not include_closed and status in [IncidentStatus.RESOLVED, IncidentStatus.CLOSED]:
                continue

            # Random start time (within last 24 hours)
            started_at = now - timedelta(
                hours=random.randint(0, 24),
                minutes=random.randint(0, 59),
            )

            # Filter by since if provided
            if since and started_at < since:
                continue

            # Create incident
            incident_id = f"INC-{now.strftime('%Y%m%d')}-{i:04d}"

            # Add small random offset to location
            lat = location["lat"] + random.uniform(-0.005, 0.005)
            lon = location["lon"] + random.uniform(-0.005, 0.005)

            # Incident titles by type
            titles = {
                IncidentType.TRAFFIC: [
                    "Congestionamento intenso",
                    "Trânsito lento",
                    "Retenção no trânsito",
                    "Fluxo intenso de veículos",
                ],
                IncidentType.FLOODING: [
                    "Alagamento na pista",
                    "Bolsão d'água",
                    "Via alagada",
                    "Ponto de alagamento",
                ],
                IncidentType.ACCIDENT: [
                    "Acidente de trânsito",
                    "Colisão entre veículos",
                    "Veículo avariado",
                    "Acidente com vítima",
                ],
                IncidentType.ROAD_WORK: [
                    "Obra na via",
                    "Manutenção na pista",
                    "Interdição para obras",
                    "Trabalho de reparo",
                ],
                IncidentType.EVENT: [
                    "Evento na região",
                    "Manifestação",
                    "Evento cultural",
                    "Bloqueio para evento",
                ],
                IncidentType.LANDSLIDE: [
                    "Deslizamento de terra",
                    "Queda de barreira",
                    "Risco de deslizamento",
                ],
                IncidentType.FIRE: [
                    "Incêndio em vegetação",
                    "Fogo em área próxima",
                    "Fumaça na via",
                ],
            }

            title = random.choice(titles.get(incident_type, ["Ocorrência"]))

            incident = Incident(
                id=incident_id,
                type=incident_type,
                severity=severity,
                status=status,
                title=f"{title} - {location['name']}",
                description=f"Ocorrência registrada na {location['name']}, {location['neighborhood']}.",
                geometry=IncidentGeometry(
                    type=GeometryType.POINT,
                    coordinates=[lon, lat],
                ),
                location=IncidentLocation(
                    address=location["name"],
                    neighborhood=location["neighborhood"],
                    region=location["region"],
                    reference=f"Próximo a {location['neighborhood']}",
                ),
                started_at=started_at,
                updated_at=now - timedelta(minutes=random.randint(1, 60)),
                resolved_at=(
                    now - timedelta(minutes=random.randint(1, 30))
                    if status in [IncidentStatus.RESOLVED, IncidentStatus.CLOSED]
                    else None
                ),
                source="COR (Mock)",
                affected_routes=[location["name"]],
                tags=[incident_type.value, severity.value],
            )

            incidents.append(incident)

            # Update counts
            type_counts[incident_type.value] = type_counts.get(incident_type.value, 0) + 1
            severity_counts[severity.value] = severity_counts.get(severity.value, 0) + 1
            status_counts[status.value] = status_counts.get(status.value, 0) + 1

        # Reset random seed
        random.seed()

        summary = IncidentsSummary(
            total=len(incidents),
            by_type=type_counts,
            by_severity=severity_counts,
            by_status=status_counts,
        )

        return {
            "incidents": incidents,
            "summary": summary,
        }
