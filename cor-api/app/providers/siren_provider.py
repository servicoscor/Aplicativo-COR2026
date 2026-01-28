from __future__ import annotations
"""Siren data provider - WebSirene Rio official data.

Fetches siren data from the official Rio de Janeiro city API.
Source: http://websirene.rio.rj.gov.br/xml/sirenes.xml
"""

import time
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from typing import Any

import httpx

from app.core.config import settings
from app.core.errors import ProviderException
from app.core.logging import get_logger
from app.providers.base import BaseProvider, ProviderResult
from app.schemas.siren import Siren, SirensSummary, SirenStatus

logger = get_logger(__name__)

# Official Rio de Janeiro sirens API
WEBSIRENE_URL = "http://websirene.rio.rj.gov.br/xml/sirenes.xml"


class SirenProvider(BaseProvider):
    """
    Provider for siren data from WebSirene Rio.

    Fetches real-time siren status from the official city API.
    Data includes ~170+ warning sirens across Rio de Janeiro with
    status information (active, triggered, inactive).
    """

    DEFAULT_TIMEOUT = 10.0
    MAX_RETRIES = 2

    def __init__(self):
        base_url = getattr(settings, "siren_provider_url", None) or WEBSIRENE_URL
        super().__init__(
            name="sirens",
            base_url=base_url,
            api_key=getattr(settings, "siren_provider_api_key", None),
            timeout=getattr(settings, "siren_provider_timeout", self.DEFAULT_TIMEOUT),
        )

    @property
    def is_configured(self) -> bool:
        """Sirens are always configured (uses official public API)."""
        return True

    @property
    def is_mock(self) -> bool:
        """Never use mock data - always fetch from official API."""
        return False

    async def fetch_latest(
        self,
        bbox: tuple[float, float, float, float] | None = None,
    ) -> ProviderResult[dict[str, Any]]:
        """
        Fetch latest status from all sirens.

        Args:
            bbox: Bounding box filter (min_lon, min_lat, max_lon, max_lat)

        Returns:
            ProviderResult containing list of sirens and summary
        """
        start_time = time.perf_counter()

        try:
            # Fetch from official API
            xml_content, data_timestamp = await self._fetch_xml()

            # Parse XML into Siren objects
            sirens, summary = self._parse_xml(xml_content, bbox=bbox)

            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_success(latency_ms)

            logger.info(
                f"Sirens: {len(sirens)} stations fetched "
                f"({summary.triggered_sirens} triggered, "
                f"{summary.active_sirens} active, "
                f"latency: {latency_ms:.0f}ms)"
            )

            return ProviderResult.ok(
                {
                    "sirens": sirens,
                    "summary": summary,
                    "data_timestamp": data_timestamp,
                },
                latency_ms,
            )

        except ProviderException:
            raise

        except Exception as e:
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_error(f"Unexpected error: {e}")
            raise ProviderException(
                message=f"Unexpected error fetching sirens: {e}",
                provider=self.name,
                code="SIREN_UNEXPECTED_ERROR",
            ) from e

    async def fetch(self, **kwargs: Any) -> ProviderResult[dict[str, Any]]:
        """Default fetch returns latest readings."""
        return await self.fetch_latest(**kwargs)

    async def _fetch_xml(self) -> tuple[str, datetime | None]:
        """
        Fetch XML data from the official API.

        Returns:
            Tuple of (XML content string, data timestamp)

        Raises:
            ProviderException: If request fails after retries
        """
        last_error: Exception | None = None

        for attempt in range(self.MAX_RETRIES + 1):
            try:
                async with httpx.AsyncClient(
                    timeout=httpx.Timeout(self.timeout),
                ) as client:
                    response = await client.get(self.base_url)
                    response.raise_for_status()
                    return response.text, datetime.now(timezone.utc)

            except httpx.TimeoutException as e:
                last_error = e
                logger.warning(
                    f"Siren API timeout (attempt {attempt + 1}/{self.MAX_RETRIES + 1})"
                )

            except httpx.HTTPStatusError as e:
                last_error = e
                logger.warning(
                    f"Siren API HTTP error {e.response.status_code} "
                    f"(attempt {attempt + 1}/{self.MAX_RETRIES + 1})"
                )

            except httpx.RequestError as e:
                last_error = e
                logger.warning(
                    f"Siren API request error (attempt {attempt + 1}/{self.MAX_RETRIES + 1}): {e}"
                )

        # All retries failed
        error_msg = str(last_error) if last_error else "Unknown error"
        self.metrics.record_error(f"All retries failed: {error_msg}")
        raise ProviderException(
            message=f"Failed to fetch sirens after {self.MAX_RETRIES + 1} attempts",
            provider=self.name,
            code="SIREN_FETCH_FAILED",
            details={"url": self.base_url, "last_error": error_msg},
        )

    def _parse_xml(
        self,
        xml_content: str,
        bbox: tuple[float, float, float, float] | None = None,
    ) -> tuple[list[Siren], SirensSummary]:
        """
        Parse XML data into Siren objects.

        Args:
            xml_content: XML string from API
            bbox: Optional bounding box filter (min_lon, min_lat, max_lon, max_lat)

        Returns:
            Tuple of (list of Siren, summary)
        """
        try:
            root = ET.fromstring(xml_content)
        except ET.ParseError as e:
            logger.error(f"Failed to parse siren XML: {e}")
            raise ProviderException(
                message=f"Failed to parse siren XML: {e}",
                provider=self.name,
                code="SIREN_PARSE_ERROR",
            ) from e

        sirens: list[Siren] = []
        online_count = 0
        active_count = 0
        triggered_count = 0
        inactive_count = 0

        for estacao in root.findall(".//estacao"):
            try:
                siren = self._parse_estacao(estacao)

                # Apply bbox filter if provided
                if bbox:
                    min_lon, min_lat, max_lon, max_lat = bbox
                    if not (
                        min_lat <= siren.latitude <= max_lat
                        and min_lon <= siren.longitude <= max_lon
                    ):
                        continue

                sirens.append(siren)

                # Update statistics
                if siren.online:
                    online_count += 1

                if siren.status == SirenStatus.TRIGGERED:
                    triggered_count += 1
                elif siren.status == SirenStatus.ACTIVE:
                    active_count += 1
                elif siren.status == SirenStatus.INACTIVE:
                    inactive_count += 1

            except Exception as e:
                logger.warning(f"Failed to parse siren element: {e}")
                continue

        summary = SirensSummary(
            total_sirens=len(sirens),
            online_sirens=online_count,
            active_sirens=active_count,
            triggered_sirens=triggered_count,
            inactive_sirens=inactive_count,
        )

        return sirens, summary

    def _parse_estacao(self, estacao: ET.Element) -> Siren:
        """
        Parse a single <estacao> element into a Siren.

        Args:
            estacao: XML Element for a siren station

        Returns:
            Siren object
        """
        siren_id = estacao.get("id", "")
        name = estacao.get("nome", "Unknown")

        # Parse location
        localizacao = estacao.find("localizacao")
        latitude = 0.0
        longitude = 0.0
        basin = None

        if localizacao is not None:
            latitude = self._safe_float(localizacao.get("latitude"))
            longitude = self._safe_float(localizacao.get("longitude"))
            basin_value = localizacao.get("bacia")
            if basin_value and basin_value != "-":
                basin = basin_value

        # Parse status
        status_elem = estacao.find("status")
        online = False
        status = SirenStatus.UNKNOWN
        status_label = "Desconhecido"

        if status_elem is not None:
            online_str = status_elem.get("online", "False")
            online = online_str.lower() == "true"

            status_code = status_elem.get("status", "")
            status, status_label = self._parse_status(status_code)

        return Siren(
            id=siren_id,
            name=name,
            latitude=latitude,
            longitude=longitude,
            basin=basin,
            online=online,
            status=status,
            status_label=status_label,
        )

    def _safe_float(self, value: str | None) -> float:
        """Safely convert string to float."""
        if value is None:
            return 0.0
        try:
            return float(value.replace(",", "."))
        except (ValueError, TypeError):
            return 0.0

    def _parse_status(self, status_code: str) -> tuple[SirenStatus, str]:
        """
        Parse status code to enum and label.

        Args:
            status_code: Status code from XML (ds, at, ac)

        Returns:
            Tuple of (SirenStatus enum, human-readable label)
        """
        status_map = {
            "ds": (SirenStatus.INACTIVE, "Desativada"),
            "at": (SirenStatus.ACTIVE, "Ativa"),
            "ac": (SirenStatus.TRIGGERED, "Acionada"),
        }
        return status_map.get(
            status_code.lower(), (SirenStatus.UNKNOWN, "Desconhecido")
        )
