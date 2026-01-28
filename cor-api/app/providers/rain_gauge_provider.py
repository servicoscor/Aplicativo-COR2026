from __future__ import annotations
"""Rain gauge data provider - WebSirene Rio official data.

Fetches rain gauge data from the official Rio de Janeiro WebSirene API.
Source: http://websirene.rio.rj.gov.br/xml/chuvas.xml
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
from app.schemas.rain_gauge import (
    RainGauge,
    RainGaugeReading,
    RainGaugesSummary,
    RainIntensity,
)

logger = get_logger(__name__)

# WebSirene rain gauge API (XML)
WEBSIRENE_CHUVAS_URL = "http://websirene.rio.rj.gov.br/xml/chuvas.xml"


class RainGaugeProvider(BaseProvider):
    """
    Provider for rain gauge data from WebSirene Rio.

    Fetches real-time pluviometric data from the official WebSirene API.
    Data includes 83+ monitoring stations across Rio de Janeiro with
    measurements for 5min, 15min, 1h, 4h, 24h, 96h, and monthly accumulation.
    """

    DEFAULT_TIMEOUT = 15.0
    MAX_RETRIES = 2

    def __init__(self):
        # Use configured URL or default to WebSirene API
        base_url = settings.rain_gauge_provider_url or WEBSIRENE_CHUVAS_URL
        super().__init__(
            name="rain_gauges",
            base_url=base_url,
            api_key=settings.rain_gauge_provider_api_key,
            timeout=getattr(settings, "rain_gauge_provider_timeout", self.DEFAULT_TIMEOUT),
        )

    @property
    def is_configured(self) -> bool:
        """Rain gauges are always configured (uses official public API)."""
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
        Fetch latest readings from all rain gauge stations.

        Args:
            bbox: Bounding box filter (min_lon, min_lat, max_lon, max_lat)

        Returns:
            ProviderResult containing list of rain gauges and summary
        """
        start_time = time.perf_counter()

        try:
            # Fetch XML from WebSirene API
            xml_content, fetch_time = await self._fetch_xml()

            # Parse XML into RainGauge objects
            gauges, summary = self._parse_xml(xml_content, fetch_time, bbox=bbox)

            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_success(latency_ms)

            logger.info(
                f"Rain gauges: {len(gauges)} stations fetched "
                f"({summary.stations_with_rain} with rain, "
                f"max 15min: {summary.max_rain_15min}mm, "
                f"latency: {latency_ms:.0f}ms)"
            )

            return ProviderResult.ok(
                {"gauges": gauges, "summary": summary},
                latency_ms
            )

        except ProviderException:
            raise

        except Exception as e:
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_error(f"Unexpected error: {e}")
            raise ProviderException(
                message=f"Unexpected error fetching rain gauges: {e}",
                provider=self.name,
                code="RAIN_GAUGE_UNEXPECTED_ERROR",
            ) from e

    async def fetch(self, **kwargs: Any) -> ProviderResult[dict[str, Any]]:
        """Default fetch returns latest readings."""
        return await self.fetch_latest(**kwargs)

    async def _fetch_xml(self) -> tuple[str, datetime]:
        """
        Fetch XML data from the WebSirene API.

        Returns:
            Tuple of (XML content string, fetch timestamp)

        Raises:
            ProviderException: If request fails after retries
        """
        last_error: Exception | None = None

        # Build URL with current date/time for fresh data
        now = datetime.now()
        url = f"{self.base_url}?time={now.strftime('%m/%d/%Y')}"

        for attempt in range(self.MAX_RETRIES + 1):
            try:
                async with httpx.AsyncClient(
                    timeout=httpx.Timeout(self.timeout),
                ) as client:
                    response = await client.get(url)
                    response.raise_for_status()
                    return response.text, datetime.now(timezone.utc)

            except httpx.TimeoutException as e:
                last_error = e
                logger.warning(
                    f"Rain gauge API timeout (attempt {attempt + 1}/{self.MAX_RETRIES + 1})"
                )

            except httpx.HTTPStatusError as e:
                last_error = e
                logger.warning(
                    f"Rain gauge API HTTP error {e.response.status_code} "
                    f"(attempt {attempt + 1}/{self.MAX_RETRIES + 1})"
                )

            except httpx.RequestError as e:
                last_error = e
                logger.warning(
                    f"Rain gauge API request error (attempt {attempt + 1}/{self.MAX_RETRIES + 1}): {e}"
                )

        # All retries failed
        error_msg = str(last_error) if last_error else "Unknown error"
        self.metrics.record_error(f"All retries failed: {error_msg}")
        raise ProviderException(
            message=f"Failed to fetch rain gauges after {self.MAX_RETRIES + 1} attempts",
            provider=self.name,
            code="RAIN_GAUGE_FETCH_FAILED",
            details={"url": url, "last_error": error_msg},
        )

    def _parse_xml(
        self,
        xml_content: str,
        fetch_time: datetime,
        bbox: tuple[float, float, float, float] | None = None,
    ) -> tuple[list[RainGauge], RainGaugesSummary]:
        """
        Parse XML content into RainGauge objects.

        WebSirene XML format:
        <estacoes hora="2026-01-26T18:32:27.820523+00:00">
          <estacao id="1" nome="Adeus 1" type="plv">
            <localizacao latitude="-22.8636" longitude="-43.2636" bacia="-"/>
            <chuvas hora="..." m5="0.0" m15="0.0" h01="0.0" h04="16.2" h24="33.2" h96="75.8" mes="213.2"/>
          </estacao>
        </estacoes>

        Args:
            xml_content: XML string from API
            fetch_time: Timestamp when data was fetched
            bbox: Optional bounding box filter (min_lon, min_lat, max_lon, max_lat)

        Returns:
            Tuple of (list of RainGauge, summary)
        """
        try:
            root = ET.fromstring(xml_content)
        except ET.ParseError as e:
            raise ProviderException(
                message=f"Failed to parse rain gauge XML: {e}",
                provider=self.name,
                code="RAIN_GAUGE_PARSE_ERROR",
            ) from e

        gauges: list[RainGauge] = []
        stations_with_rain = 0
        max_rain_15min = 0.0
        max_rain_1h = 0.0
        total_rain_1h = 0.0

        # Find all station elements
        stations = root.findall(".//estacao")

        for idx, station in enumerate(stations):
            try:
                gauge = self._parse_station(station, idx, fetch_time)

                # Apply bbox filter if provided
                if bbox:
                    min_lon, min_lat, max_lon, max_lat = bbox
                    if not (min_lat <= gauge.latitude <= max_lat and
                            min_lon <= gauge.longitude <= max_lon):
                        continue

                gauges.append(gauge)

                # Update statistics
                if gauge.last_reading:
                    rain_15min = gauge.last_reading.accumulated_15min or 0
                    rain_1h = gauge.last_reading.accumulated_1h or 0

                    if rain_15min > 0:
                        stations_with_rain += 1

                    max_rain_15min = max(max_rain_15min, rain_15min)
                    max_rain_1h = max(max_rain_1h, rain_1h)
                    total_rain_1h += rain_1h

            except Exception as e:
                logger.warning(f"Failed to parse rain gauge station: {e}")
                continue

        # Calculate summary
        avg_rain_1h = total_rain_1h / len(gauges) if gauges else 0

        summary = RainGaugesSummary(
            total_stations=len(gauges),
            active_stations=len(gauges),
            stations_with_rain=stations_with_rain,
            max_rain_15min=round(max_rain_15min, 1),
            max_rain_1h=round(max_rain_1h, 1),
            avg_rain_1h=round(avg_rain_1h, 2),
        )

        return gauges, summary

    def _parse_station(
        self,
        station: ET.Element,
        idx: int,
        fetch_time: datetime,
    ) -> RainGauge:
        """
        Parse a single station element into a RainGauge.

        WebSirene format:
        <estacao id="1" nome="Adeus 1" type="plv">
          <localizacao latitude="-22.8636" longitude="-43.2636" bacia="-"/>
          <chuvas hora="..." m5="0.0" m15="0.0" h01="0.0" h04="16.2" h24="33.2" h96="75.8" mes="213.2"/>
        </estacao>

        Args:
            station: XML Element for the station
            idx: Station index (used as fallback ID)
            fetch_time: Data fetch timestamp

        Returns:
            RainGauge object
        """
        # Extract station info from attributes
        station_id = station.get("id", str(idx))
        name = station.get("nome", f"Estação {idx}")

        # Extract location from localizacao element attributes
        loc_elem = station.find("localizacao")
        if loc_elem is not None:
            latitude = self._safe_float(loc_elem.get("latitude", "0"))
            longitude = self._safe_float(loc_elem.get("longitude", "0"))
            basin = loc_elem.get("bacia")
            # Clean up basin if it's just "-"
            if basin == "-":
                basin = None
        else:
            latitude = 0.0
            longitude = 0.0
            basin = None

        # Extract rainfall data from chuvas element attributes
        chuvas_elem = station.find("chuvas")
        if chuvas_elem is not None:
            rain_5min = self._safe_float(chuvas_elem.get("m5", "0"))
            rain_15min = self._safe_float(chuvas_elem.get("m15", "0"))
            rain_1h = self._safe_float(chuvas_elem.get("h01", "0"))
            rain_4h = self._safe_float(chuvas_elem.get("h04", "0"))
            rain_24h = self._safe_float(chuvas_elem.get("h24", "0"))
            rain_96h = self._safe_float(chuvas_elem.get("h96", "0"))
            rain_month = self._safe_float(chuvas_elem.get("mes", "0"))

            # Parse reading timestamp from chuvas hora attribute
            reading_time_str = chuvas_elem.get("hora")
            if reading_time_str:
                try:
                    reading_time = datetime.fromisoformat(reading_time_str.replace("Z", "+00:00"))
                except Exception:
                    reading_time = fetch_time
            else:
                reading_time = fetch_time
        else:
            rain_5min = rain_15min = rain_1h = rain_4h = rain_24h = rain_96h = rain_month = 0.0
            reading_time = fetch_time

        # Generate consistent station ID
        station_id = f"ws_{station_id}"

        # Determine intensity classification
        intensity = self._classify_intensity(rain_15min)

        # Create reading with all accumulation periods
        reading = RainGaugeReading(
            timestamp=reading_time,
            value_mm=rain_15min,
            accumulated_5min=rain_5min,
            accumulated_15min=rain_15min,
            accumulated_1h=rain_1h,
            accumulated_4h=rain_4h,
            accumulated_24h=rain_24h,
            accumulated_96h=rain_96h,
            accumulated_month=rain_month,
            intensity=intensity,
        )

        # Infer region from station name or basin
        region = self._infer_region(name, basin)

        return RainGauge(
            id=station_id,
            name=name,
            latitude=latitude,
            longitude=longitude,
            altitude_m=None,
            neighborhood=basin or name,
            region=region,
            status="active",
            last_reading=reading,
            last_updated=reading_time,
        )

    def _safe_float(self, value: str | None) -> float:
        """
        Safely convert value to float, returning 0 if invalid.

        Handles Brazilian number format with comma as decimal separator.
        """
        if value is None:
            return 0.0
        try:
            # Replace comma with dot for Brazilian format
            str_value = str(value).replace(",", ".")
            return float(str_value)
        except (ValueError, TypeError):
            return 0.0

    def _classify_intensity(self, rain_mm: float) -> RainIntensity:
        """
        Classify rain intensity based on 15-minute accumulation.

        Classification based on typical meteorological standards:
        - None: 0 mm
        - Light: 0.1 - 2.5 mm
        - Moderate: 2.5 - 7.5 mm
        - Heavy: 7.5 - 15 mm
        - Very Heavy: > 15 mm
        """
        if rain_mm <= 0:
            return RainIntensity.NONE
        elif rain_mm < 2.5:
            return RainIntensity.LIGHT
        elif rain_mm < 7.5:
            return RainIntensity.MODERATE
        elif rain_mm < 15:
            return RainIntensity.HEAVY
        else:
            return RainIntensity.VERY_HEAVY

    def _infer_region(self, station_name: str, basin: str | None) -> str | None:
        """
        Infer region from station name or basin.

        Returns region based on known neighborhood locations.
        """
        name_lower = (station_name + " " + (basin or "")).lower()

        # Zona Sul
        zona_sul = ["copacabana", "ipanema", "leblon", "botafogo", "urca",
                    "laranjeiras", "flamengo", "catete", "vidigal", "rocinha",
                    "lagoa", "gávea", "jardim botânico", "humaitá", "leme",
                    "são conrado", "cosme velho", "santa marta", "tijuca"]

        # Zona Norte
        zona_norte = ["maracanã", "vila isabel", "grajaú", "méier",
                     "penha", "olaria", "ramos", "bonsucesso", "manguinhos",
                     "ilha do governador", "pavuna", "irajá", "anchieta",
                     "engenho de dentro", "piedade", "abolição", "pilares",
                     "cascadura", "madureira", "benfica", "higienópolis",
                     "acari", "complexo do alemão", "maré", "inhaúma"]

        # Zona Oeste
        zona_oeste = ["barra", "recreio", "jacarepaguá", "campo grande",
                     "santa cruz", "bangu", "realengo", "padre miguel",
                     "sepetiba", "guaratiba", "vargem", "tanque", "praça seca",
                     "taquara", "sulacap", "magalhães bastos", "deodoro",
                     "curicica", "pechincha", "freguesia", "anil",
                     "camorim", "grota funda", "mendanha"]

        # Centro / Grande Tijuca
        centro = ["centro", "santa teresa", "lapa", "glória", "saúde",
                 "gamboa", "praça mauá", "cidade nova", "praça da bandeira",
                 "alto da boa vista", "sumaré", "grajaú"]

        for area in zona_sul:
            if area in name_lower:
                return "Zona Sul"

        for area in zona_norte:
            if area in name_lower:
                return "Zona Norte"

        for area in zona_oeste:
            if area in name_lower:
                return "Zona Oeste"

        for area in centro:
            if area in name_lower:
                return "Centro"

        return None
