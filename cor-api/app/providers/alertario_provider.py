from __future__ import annotations
"""Alerta Rio weather forecast provider.

Fetches weather forecasts from Sistema Alerta Rio XML feeds.
Sources:
- Short-term: https://www.sistema-alerta-rio.com.br/upload/xml/PrevisaoNew.xml
- Extended: https://www.sistema-alerta-rio.com.br/upload/xml/PrevisaoEstendida.xml
"""

import time
import xml.etree.ElementTree as ET
from datetime import date, datetime, timezone
from typing import Any

import httpx

from app.core.config import settings
from app.core.errors import ProviderException
from app.core.logging import get_logger
from app.providers.base import BaseProvider, ProviderResult
from app.schemas.alertario import (
    ForecastExtendedData,
    ForecastExtendedDay,
    ForecastNowData,
    ForecastNowItem,
    SynopticSummary,
    TemperatureZone,
    TideInfo,
)

logger = get_logger(__name__)

# Constants for Alerta Rio URLs
ALERTARIO_FORECAST_NOW_URL = (
    "https://www.sistema-alerta-rio.com.br/upload/xml/PrevisaoNew.xml"
)
ALERTARIO_FORECAST_EXTENDED_URL = (
    "https://www.sistema-alerta-rio.com.br/upload/xml/PrevisaoEstendida.xml"
)

# Weekday names in Portuguese
WEEKDAYS_PT = {
    0: "Segunda-feira",
    1: "Terça-feira",
    2: "Quarta-feira",
    3: "Quinta-feira",
    4: "Sexta-feira",
    5: "Sábado",
    6: "Domingo",
}


class AlertaRioProvider(BaseProvider):
    """
    Provider for Alerta Rio weather forecasts.

    Fetches XML data from Sistema Alerta Rio and parses into structured schemas.
    Uses short timeouts (5s) and implements defensive parsing to handle
    variations in XML structure.
    """

    # Short timeout for Alerta Rio (recommended: 5s)
    DEFAULT_TIMEOUT = 5.0
    MAX_RETRIES = 2

    def __init__(self):
        super().__init__(
            name="alertario",
            base_url=settings.alertario_provider_url,
            timeout=getattr(settings, "alertario_provider_timeout", self.DEFAULT_TIMEOUT),
        )
        # Override headers for XML
        self._xml_headers = {
            "Accept": "application/xml, text/xml, */*",
            "User-Agent": f"COR-API/{settings.app_version}",
        }

    @property
    def is_configured(self) -> bool:
        """Alerta Rio is always configured (uses public URLs)."""
        return True

    @property
    def is_mock(self) -> bool:
        """Alerta Rio never uses mock data."""
        return False

    async def _fetch_xml(self, url: str) -> str:
        """
        Fetch XML content from URL with retries.

        Args:
            url: URL to fetch

        Returns:
            XML string content

        Raises:
            ProviderException: If all retries fail
        """
        last_error: Exception | None = None

        for attempt in range(self.MAX_RETRIES + 1):
            try:
                async with httpx.AsyncClient(
                    timeout=httpx.Timeout(self.timeout),
                    headers=self._xml_headers,
                ) as client:
                    response = await client.get(url)
                    response.raise_for_status()
                    return response.text

            except httpx.TimeoutException as e:
                last_error = e
                logger.warning(
                    f"AlertaRio timeout (attempt {attempt + 1}/{self.MAX_RETRIES + 1}): {url}"
                )

            except httpx.HTTPStatusError as e:
                last_error = e
                logger.warning(
                    f"AlertaRio HTTP error {e.response.status_code} "
                    f"(attempt {attempt + 1}/{self.MAX_RETRIES + 1}): {url}"
                )

            except httpx.RequestError as e:
                last_error = e
                logger.warning(
                    f"AlertaRio request error (attempt {attempt + 1}/{self.MAX_RETRIES + 1}): {e}"
                )

        # All retries failed
        error_msg = str(last_error) if last_error else "Unknown error"
        self.metrics.record_error(f"All retries failed: {error_msg}")
        raise ProviderException(
            message=f"Failed to fetch from AlertaRio after {self.MAX_RETRIES + 1} attempts",
            provider=self.name,
            code="ALERTARIO_FETCH_FAILED",
            details={"url": url, "last_error": error_msg},
        )

    def _safe_get_attr(
        self, element: ET.Element, attr: str, default: str | None = None
    ) -> str | None:
        """Safely get attribute from XML element."""
        return element.get(attr, default)

    def _safe_parse_float(self, value: str | None) -> float | None:
        """Safely parse float from string."""
        if not value:
            return None
        try:
            return float(value.replace(",", "."))
        except (ValueError, AttributeError):
            return None

    def _safe_parse_date(self, value: str | None) -> date | None:
        """Safely parse date from string (YYYY-MM-DD format)."""
        if not value:
            return None
        try:
            return datetime.strptime(value, "%Y-%m-%d").date()
        except (ValueError, AttributeError):
            return None

    def _safe_parse_datetime(self, value: str | None) -> datetime | None:
        """Safely parse datetime from string (various formats)."""
        if not value:
            return None

        formats = [
            "%Y-%m-%dT%H:%M:%S.%f",
            "%Y-%m-%dT%H:%M:%S",
            "%Y-%m-%d %H:%M:%S",
            "%d/%m/%Y %H:%M:%S",
            "%d/%m/%Y %H:%M",
        ]

        for fmt in formats:
            try:
                return datetime.strptime(value, fmt).replace(tzinfo=timezone.utc)
            except ValueError:
                continue

        return None

    def _parse_forecast_now_xml(self, xml_content: str) -> ForecastNowData:
        """
        Parse PrevisaoNew.xml content into ForecastNowData.

        Implements defensive parsing - missing fields return None instead of errors.
        """
        root = ET.fromstring(xml_content)

        # Parse creation date from root
        updated_at = self._safe_parse_datetime(root.get("Createdate"))

        # Parse forecast items (previsao elements)
        items: list[ForecastNowItem] = []
        for previsao in root.findall(".//previsao"):
            item = ForecastNowItem(
                period=self._safe_get_attr(previsao, "periodo", "") or "",
                forecast_date=self._safe_parse_date(self._safe_get_attr(previsao, "datePeriodo")),
                condition=self._safe_get_attr(previsao, "ceu", "") or "Desconhecido",
                condition_icon=self._safe_get_attr(previsao, "condicaoIcon"),
                precipitation=self._safe_get_attr(previsao, "precipitacao"),
                temperature_trend=self._safe_get_attr(previsao, "temperatura"),
                wind_direction=self._safe_get_attr(previsao, "dirVento"),
                wind_speed=self._safe_get_attr(previsao, "velVento"),
            )
            items.append(item)

        # Parse synoptic summary (quadroSinotico)
        synoptic: SynopticSummary | None = None
        quadro = root.find(".//quadroSinotico")
        if quadro is not None:
            synoptic_text = self._safe_get_attr(quadro, "sinotico")
            if synoptic_text:
                synoptic = SynopticSummary(
                    summary=synoptic_text,
                    created_at=self._safe_parse_datetime(quadro.get("Createdate")),
                )

        # Parse temperatures by zone
        temperatures: list[TemperatureZone] = []
        temp_root = root.find(".//Temperatura")
        if temp_root is not None:
            for zona in temp_root.findall(".//Zona"):
                zone_name = self._safe_get_attr(zona, "zona")
                if zone_name:
                    temperatures.append(
                        TemperatureZone(
                            zone=zone_name,
                            temp_min=self._safe_parse_float(
                                self._safe_get_attr(zona, "minima")
                            ),
                            temp_max=self._safe_parse_float(
                                self._safe_get_attr(zona, "maxima")
                            ),
                        )
                    )

        # Parse tides (TabuasMares)
        tides: list[TideInfo] = []
        for tabua in root.findall(".//tabua"):
            tide_time = self._safe_parse_datetime(self._safe_get_attr(tabua, "date"))
            height = self._safe_parse_float(self._safe_get_attr(tabua, "altura"))
            level = self._safe_get_attr(tabua, "elevacao", "")

            if tide_time is not None and height is not None:
                tides.append(
                    TideInfo(
                        time=tide_time,
                        height=height,
                        level=level or "Desconhecido",
                    )
                )

        return ForecastNowData(
            city="Rio de Janeiro",
            updated_at=updated_at,
            items=items,
            synoptic=synoptic,
            temperatures=temperatures,
            tides=tides,
        )

    def _parse_forecast_extended_xml(self, xml_content: str) -> ForecastExtendedData:
        """
        Parse PrevisaoEstendida.xml content into ForecastExtendedData.

        Implements defensive parsing - missing fields return None instead of errors.
        """
        root = ET.fromstring(xml_content)

        # Parse creation date from root
        updated_at = self._safe_parse_datetime(root.get("Createdate"))

        # Parse daily forecasts (previsaoEstendida elements)
        days: list[ForecastExtendedDay] = []
        for prev in root.findall(".//previsaoEstendida"):
            date_val = self._safe_parse_date(self._safe_get_attr(prev, "data"))

            # Calculate weekday name
            weekday: str | None = None
            if date_val:
                weekday = WEEKDAYS_PT.get(date_val.weekday())

            if date_val:  # Only add if we have a valid date
                days.append(
                    ForecastExtendedDay(
                        forecast_date=date_val,
                        weekday=weekday,
                        condition=self._safe_get_attr(prev, "ceu", "") or "Desconhecido",
                        condition_icon=self._safe_get_attr(prev, "condicaoIcon"),
                        temp_min=self._safe_parse_float(
                            self._safe_get_attr(prev, "minTemp")
                        ),
                        temp_max=self._safe_parse_float(
                            self._safe_get_attr(prev, "maxTemp")
                        ),
                        precipitation=self._safe_get_attr(prev, "precipitacao"),
                        temperature_trend=self._safe_get_attr(prev, "temperatura"),
                        wind_direction=self._safe_get_attr(prev, "dirVento"),
                        wind_speed=self._safe_get_attr(prev, "velVento"),
                    )
                )

        return ForecastExtendedData(
            city="Rio de Janeiro",
            updated_at=updated_at,
            days=days,
        )

    async def fetch_forecast_now(self) -> ProviderResult[ForecastNowData]:
        """
        Fetch current/short-term weather forecast.

        Returns:
            ProviderResult containing ForecastNowData
        """
        start_time = time.perf_counter()

        try:
            xml_content = await self._fetch_xml(ALERTARIO_FORECAST_NOW_URL)
            logger.debug(f"Fetched {len(xml_content)} bytes from AlertaRio forecast/now")

            data = self._parse_forecast_now_xml(xml_content)
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_success(latency_ms)

            logger.info(
                f"AlertaRio forecast/now: {len(data.items)} periods, "
                f"{len(data.temperatures)} zones, {len(data.tides)} tides "
                f"(latency: {latency_ms:.0f}ms)"
            )
            return ProviderResult.ok(data, latency_ms)

        except ProviderException:
            raise

        except ET.ParseError as e:
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_error(f"XML parse error: {e}")
            raise ProviderException(
                message=f"Failed to parse AlertaRio XML: {e}",
                provider=self.name,
                code="ALERTARIO_PARSE_ERROR",
            ) from e

        except Exception as e:
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_error(f"Unexpected error: {e}")
            raise ProviderException(
                message=f"Unexpected error fetching AlertaRio: {e}",
                provider=self.name,
                code="ALERTARIO_UNEXPECTED_ERROR",
            ) from e

    async def fetch_forecast_extended(self) -> ProviderResult[ForecastExtendedData]:
        """
        Fetch extended weather forecast (multiple days).

        Returns:
            ProviderResult containing ForecastExtendedData
        """
        start_time = time.perf_counter()

        try:
            xml_content = await self._fetch_xml(ALERTARIO_FORECAST_EXTENDED_URL)
            logger.debug(
                f"Fetched {len(xml_content)} bytes from AlertaRio forecast/extended"
            )

            data = self._parse_forecast_extended_xml(xml_content)
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_success(latency_ms)

            logger.info(
                f"AlertaRio forecast/extended: {len(data.days)} days "
                f"(latency: {latency_ms:.0f}ms)"
            )
            return ProviderResult.ok(data, latency_ms)

        except ProviderException:
            raise

        except ET.ParseError as e:
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_error(f"XML parse error: {e}")
            raise ProviderException(
                message=f"Failed to parse AlertaRio XML: {e}",
                provider=self.name,
                code="ALERTARIO_PARSE_ERROR",
            ) from e

        except Exception as e:
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_error(f"Unexpected error: {e}")
            raise ProviderException(
                message=f"Unexpected error fetching AlertaRio: {e}",
                provider=self.name,
                code="ALERTARIO_UNEXPECTED_ERROR",
            ) from e

    async def fetch(self, **kwargs: Any) -> ProviderResult[ForecastNowData]:
        """Default fetch returns current/short-term forecast."""
        return await self.fetch_forecast_now()
