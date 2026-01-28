"""Tests for Alerta Rio weather forecast endpoints and provider."""

from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.providers.alertario_provider import AlertaRioProvider
from app.schemas.alertario import ForecastNowData, ForecastExtendedData
from app.schemas.common import CacheInfo

# Get fixtures path
FIXTURES_PATH = Path(__file__).parent / "fixtures"


def load_fixture(filename: str) -> str:
    """Load XML fixture file."""
    return (FIXTURES_PATH / filename).read_text()


class TestAlertaRioEndpoints:
    """Tests for Alerta Rio API endpoints."""

    def test_forecast_now_endpoint(
        self, client: TestClient, mock_redis_connected: None
    ) -> None:
        """Test forecast/now endpoint returns data."""
        response = client.get("/v1/alerta-rio/forecast/now")
        assert response.status_code == 200
        data = response.json()

        # Check response structure
        assert data["success"] is True
        assert "timestamp" in data
        assert "source" in data
        assert data["source"] == "AlertaRio"
        assert "fetched_at" in data
        assert "stale" in data
        assert "data" in data

    def test_forecast_now_data_structure(
        self, client: TestClient, mock_redis_connected: None
    ) -> None:
        """Test forecast/now returns properly structured data."""
        response = client.get("/v1/alerta-rio/forecast/now")
        assert response.status_code == 200
        data = response.json()

        forecast = data["data"]
        assert "city" in forecast
        assert "items" in forecast
        assert isinstance(forecast["items"], list)

    def test_forecast_extended_endpoint(
        self, client: TestClient, mock_redis_connected: None
    ) -> None:
        """Test forecast/extended endpoint returns data."""
        response = client.get("/v1/alerta-rio/forecast/extended")
        assert response.status_code == 200
        data = response.json()

        # Check response structure
        assert data["success"] is True
        assert "timestamp" in data
        assert "source" in data
        assert data["source"] == "AlertaRio"
        assert "fetched_at" in data
        assert "stale" in data
        assert "data" in data

    def test_forecast_extended_data_structure(
        self, client: TestClient, mock_redis_connected: None
    ) -> None:
        """Test forecast/extended returns properly structured data."""
        response = client.get("/v1/alerta-rio/forecast/extended")
        assert response.status_code == 200
        data = response.json()

        forecast = data["data"]
        assert "city" in forecast
        assert "days" in forecast
        assert isinstance(forecast["days"], list)


class TestAlertaRioProviderXmlParsing:
    """Tests for AlertaRio XML parsing."""

    def test_parse_forecast_now_xml(self) -> None:
        """Test parsing PrevisaoNew.xml fixture."""
        provider = AlertaRioProvider()
        xml_content = load_fixture("previsao_new.xml")

        data = provider._parse_forecast_now_xml(xml_content)

        # Check basic structure
        assert isinstance(data, ForecastNowData)
        assert data.city == "Rio de Janeiro"
        assert data.updated_at is not None

        # Check forecast items
        assert len(data.items) == 4  # 4 periods in fixture
        item = data.items[0]
        assert item.period == "Manhã"
        assert item.condition == "Nublado"
        assert item.precipitation == "Pancadas de chuva isoladas"
        assert item.wind_direction == "E/SE"
        assert item.wind_speed == "Fraco a Moderado"

        # Check synoptic summary
        assert data.synoptic is not None
        assert "sistema frontal" in data.synoptic.summary

        # Check temperatures
        assert len(data.temperatures) == 5  # 5 zones
        zona_norte = next((t for t in data.temperatures if t.zone == "Zona Norte"), None)
        assert zona_norte is not None
        assert zona_norte.temp_max == 32.0
        assert zona_norte.temp_min == 22.0

        # Check tides
        assert len(data.tides) == 4  # 4 tides
        assert data.tides[0].height == 0.3
        assert data.tides[0].level == "Baixa"

    def test_parse_forecast_extended_xml(self) -> None:
        """Test parsing PrevisaoEstendida.xml fixture."""
        provider = AlertaRioProvider()
        xml_content = load_fixture("previsao_estendida.xml")

        data = provider._parse_forecast_extended_xml(xml_content)

        # Check basic structure
        assert isinstance(data, ForecastExtendedData)
        assert data.city == "Rio de Janeiro"
        assert data.updated_at is not None

        # Check daily forecasts
        assert len(data.days) == 4  # 4 days in fixture
        day1 = data.days[0]
        assert day1.condition == "Nublado"
        assert day1.temp_min == 22.0
        assert day1.temp_max == 32.0
        assert day1.precipitation == "Chuva fraca a moderada"
        assert day1.weekday is not None  # Should have weekday name

    def test_parse_xml_with_missing_fields(self) -> None:
        """Test parser handles missing fields gracefully."""
        provider = AlertaRioProvider()
        xml_content = """<?xml version="1.0" encoding="UTF-8"?>
        <previsoes Createdate="2024-01-15T10:00:00">
            <previsao ceu="Nublado" periodo="Manhã"/>
        </previsoes>
        """

        data = provider._parse_forecast_now_xml(xml_content)

        assert len(data.items) == 1
        item = data.items[0]
        assert item.condition == "Nublado"
        assert item.period == "Manhã"
        # Missing fields should be None
        assert item.precipitation is None
        assert item.wind_direction is None
        assert item.condition_icon is None

    def test_parse_empty_xml(self) -> None:
        """Test parser handles empty XML gracefully."""
        provider = AlertaRioProvider()
        xml_content = """<?xml version="1.0" encoding="UTF-8"?>
        <previsoes Createdate="2024-01-15T10:00:00">
        </previsoes>
        """

        data = provider._parse_forecast_now_xml(xml_content)

        assert len(data.items) == 0
        assert len(data.temperatures) == 0
        assert len(data.tides) == 0
        assert data.synoptic is None


class TestAlertaRioProviderFetch:
    """Tests for AlertaRio HTTP fetching."""

    @pytest.mark.asyncio
    async def test_fetch_with_mock_response(self) -> None:
        """Test successful fetch with mocked HTTP response."""
        provider = AlertaRioProvider()
        xml_content = load_fixture("previsao_new.xml")

        with patch.object(provider, "_fetch_xml", return_value=xml_content) as mock_fetch:
            result = await provider.fetch_forecast_now()

            assert result.success is True
            assert result.data is not None
            assert len(result.data.items) == 4
            mock_fetch.assert_called_once()

    @pytest.mark.asyncio
    async def test_fetch_extended_with_mock_response(self) -> None:
        """Test successful extended fetch with mocked HTTP response."""
        provider = AlertaRioProvider()
        xml_content = load_fixture("previsao_estendida.xml")

        with patch.object(provider, "_fetch_xml", return_value=xml_content) as mock_fetch:
            result = await provider.fetch_forecast_extended()

            assert result.success is True
            assert result.data is not None
            assert len(result.data.days) == 4
            mock_fetch.assert_called_once()

    @pytest.mark.asyncio
    async def test_fetch_handles_xml_parse_error(self) -> None:
        """Test fetch handles XML parse errors gracefully."""
        from app.core.errors import ProviderException

        provider = AlertaRioProvider()

        with patch.object(provider, "_fetch_xml", return_value="<invalid xml"):
            with pytest.raises(ProviderException) as exc_info:
                await provider.fetch_forecast_now()

            assert "ALERTARIO_PARSE_ERROR" in str(exc_info.value.code)


class TestAlertaRioCacheFallback:
    """Tests for Alerta Rio cache fallback behavior."""

    @pytest.mark.asyncio
    async def test_service_caches_successful_response(self) -> None:
        """Test service caches successful provider response."""
        from app.providers.base import ProviderResult
        from app.services.alertario_service import AlertaRioService

        mock_provider = MagicMock()
        mock_data = ForecastNowData(
            city="Rio de Janeiro",
            updated_at=datetime.now(timezone.utc),
            items=[],
            temperatures=[],
            tides=[],
        )
        mock_provider.fetch_forecast_now = AsyncMock(
            return_value=ProviderResult.ok(mock_data, latency_ms=100)
        )

        mock_cache = MagicMock()
        mock_cache.set = AsyncMock()
        mock_cache.get_fallback = AsyncMock(return_value=(None, None))

        service = AlertaRioService(provider=mock_provider, cache=mock_cache)
        response = await service.get_forecast_now()

        assert response.success is True
        assert response.stale is False
        mock_cache.set.assert_called_once()

    @pytest.mark.asyncio
    async def test_service_returns_cached_on_provider_failure(self) -> None:
        """Test service returns cached data when provider fails."""
        from app.core.errors import ProviderException
        from app.services.alertario_service import AlertaRioService

        mock_provider = MagicMock()
        mock_provider.fetch_forecast_now = AsyncMock(
            side_effect=ProviderException(
                message="Provider unavailable",
                provider="alertario",
                code="ALERTARIO_FETCH_FAILED",
            )
        )

        cached_data = ForecastNowData(
            city="Rio de Janeiro",
            updated_at=datetime.now(timezone.utc),
            items=[],
            temperatures=[],
            tides=[],
        )
        cache_info = CacheInfo(stale=True, age_seconds=120)

        mock_cache = MagicMock()
        mock_cache.get_fallback = AsyncMock(return_value=(cached_data, cache_info))

        service = AlertaRioService(provider=mock_provider, cache=mock_cache)
        response = await service.get_forecast_now()

        assert response.success is True
        assert response.stale is True
        assert response.age_seconds == 120

    @pytest.mark.asyncio
    async def test_service_raises_when_no_cache_available(self) -> None:
        """Test service raises exception when provider fails and no cache."""
        from app.core.errors import ProviderException
        from app.services.alertario_service import AlertaRioService

        mock_provider = MagicMock()
        mock_provider.fetch_forecast_now = AsyncMock(
            side_effect=ProviderException(
                message="Provider unavailable",
                provider="alertario",
                code="ALERTARIO_FETCH_FAILED",
            )
        )

        mock_cache = MagicMock()
        mock_cache.get_fallback = AsyncMock(return_value=(None, None))

        service = AlertaRioService(provider=mock_provider, cache=mock_cache)

        with pytest.raises(ProviderException) as exc_info:
            await service.get_forecast_now()

        assert "ALERTARIO_UNAVAILABLE" in str(exc_info.value.code)


class TestAlertaRioHelperMethods:
    """Tests for AlertaRio provider helper methods."""

    def test_safe_parse_float(self) -> None:
        """Test safe float parsing."""
        provider = AlertaRioProvider()

        assert provider._safe_parse_float("32.5") == 32.5
        assert provider._safe_parse_float("32,5") == 32.5  # Brazilian format
        assert provider._safe_parse_float("") is None
        assert provider._safe_parse_float(None) is None
        assert provider._safe_parse_float("invalid") is None

    def test_safe_parse_date(self) -> None:
        """Test safe date parsing."""
        from datetime import date

        provider = AlertaRioProvider()

        assert provider._safe_parse_date("2024-01-15") == date(2024, 1, 15)
        assert provider._safe_parse_date("") is None
        assert provider._safe_parse_date(None) is None
        assert provider._safe_parse_date("invalid") is None
        assert provider._safe_parse_date("15/01/2024") is None  # Wrong format

    def test_safe_parse_datetime(self) -> None:
        """Test safe datetime parsing."""
        provider = AlertaRioProvider()

        # ISO format
        result = provider._safe_parse_datetime("2024-01-15T10:30:00")
        assert result is not None
        assert result.hour == 10
        assert result.minute == 30

        # With microseconds
        result = provider._safe_parse_datetime("2024-01-15T10:30:00.123456")
        assert result is not None

        # Invalid formats
        assert provider._safe_parse_datetime("") is None
        assert provider._safe_parse_datetime(None) is None
        assert provider._safe_parse_datetime("invalid") is None
