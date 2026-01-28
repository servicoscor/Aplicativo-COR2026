"""Tests for RadarProvider with real API mocking."""

import pytest
import respx
from httpx import Response
from datetime import datetime, timezone

from app.providers.radar_provider import RadarProvider
from app.schemas.radar import RadarMetadata, RadarSnapshot


# Sample API response for mocking
MOCK_API_RESPONSE = {
    "snapshots": [
        {
            "id": "radar_202401151430",
            "timestamp": "2024-01-15T14:30:00Z",
            "image_url": "https://api.radar.example.com/images/radar_202401151430.png",
            "thumbnail_url": "https://api.radar.example.com/thumbs/radar_202401151430.png",
            "bbox": {
                "min_lon": -44.5,
                "min_lat": -23.5,
                "max_lon": -42.5,
                "max_lat": -21.5,
            },
            "resolution": "1km",
            "product_type": "reflectivity",
            "source": "INMET",
        },
        {
            "id": "radar_202401151420",
            "timestamp": "2024-01-15T14:20:00Z",
            "image_url": "https://api.radar.example.com/images/radar_202401151420.png",
            "bbox": {
                "min_lon": -44.5,
                "min_lat": -23.5,
                "max_lon": -42.5,
                "max_lat": -21.5,
            },
            "resolution": "1km",
            "product_type": "reflectivity",
            "source": "INMET",
        },
        {
            "id": "radar_202401151410",
            "timestamp": "2024-01-15T14:10:00Z",
            "image_url": "https://api.radar.example.com/images/radar_202401151410.png",
            "bbox": {
                "min_lon": -44.5,
                "min_lat": -23.5,
                "max_lon": -42.5,
                "max_lat": -21.5,
            },
            "resolution": "1km",
            "product_type": "reflectivity",
            "source": "INMET",
        },
    ],
    "metadata": {
        "station_name": "Pico do Couto",
        "station_lat": -22.4667,
        "station_lon": -43.2833,
        "range_km": 400,
        "update_interval_minutes": 10,
    },
}

MOCK_HISTORY_RESPONSE = {
    "snapshots": [
        {
            "id": f"radar_202401151{minute:02d}0",
            "timestamp": f"2024-01-15T14:{minute:02d}:00Z",
            "image_url": f"https://api.radar.example.com/images/radar_202401151{minute:02d}0.png",
            "resolution": "1km",
            "product_type": "reflectivity",
        }
        for minute in range(0, 60, 10)
    ]
}


class TestRadarProviderMock:
    """Tests for RadarProvider in mock mode (no URL configured)."""

    @pytest.mark.asyncio
    async def test_fetch_latest_mock_mode(self) -> None:
        """Test fetch_latest returns mock data when not configured."""
        provider = RadarProvider()

        # Verify it's in mock mode
        assert provider.is_mock is True
        assert provider.is_configured is False

        result = await provider.fetch_latest()

        assert result.success is True
        assert result.data is not None
        assert "latest" in result.data
        assert "metadata" in result.data
        assert "previous" in result.data

        # Check snapshot structure
        latest = result.data["latest"]
        assert isinstance(latest, RadarSnapshot)
        assert latest.source == "INMET (Mock)"
        assert latest.resolution == "1km"

        await provider.close()

    @pytest.mark.asyncio
    async def test_fetch_history_mock_mode(self) -> None:
        """Test fetch_history returns mock data when not configured."""
        provider = RadarProvider()

        result = await provider.fetch_history(count=5)

        assert result.success is True
        assert result.data is not None
        assert len(result.data) == 5

        # All snapshots should be RadarSnapshot instances
        for snapshot in result.data:
            assert isinstance(snapshot, RadarSnapshot)
            assert snapshot.source == "INMET (Mock)"

        await provider.close()

    @pytest.mark.asyncio
    async def test_metrics_recorded_mock_mode(self) -> None:
        """Test that metrics are recorded even in mock mode."""
        provider = RadarProvider()

        await provider.fetch_latest()

        metrics = provider.get_metrics()
        assert metrics.request_count >= 1
        assert metrics.latency_ms >= 0

        await provider.close()


class TestRadarProviderReal:
    """Tests for RadarProvider with real API (mocked with respx)."""

    @pytest.fixture
    def configured_provider(self, monkeypatch: pytest.MonkeyPatch) -> RadarProvider:
        """Create a provider configured with a mock URL."""
        monkeypatch.setattr(
            "app.core.config.settings.radar_provider_url",
            "https://api.radar.example.com",
        )
        monkeypatch.setattr(
            "app.core.config.settings.radar_provider_api_key",
            "test-api-key-12345",
        )
        monkeypatch.setattr(
            "app.core.config.settings.radar_provider_timeout",
            10.0,
        )
        return RadarProvider()

    @pytest.mark.asyncio
    @respx.mock
    async def test_fetch_latest_real_api_success(
        self, configured_provider: RadarProvider
    ) -> None:
        """Test fetch_latest with successful API response."""
        # Mock the API endpoint
        respx.get("https://api.radar.example.com/latest").mock(
            return_value=Response(200, json=MOCK_API_RESPONSE)
        )

        # Verify it's in real mode
        assert configured_provider.is_mock is False
        assert configured_provider.is_configured is True

        result = await configured_provider.fetch_latest()

        assert result.success is True
        assert result.data is not None

        # Check latest snapshot
        latest = result.data["latest"]
        assert isinstance(latest, RadarSnapshot)
        assert latest.id == "radar_202401151430"
        assert latest.source == "INMET"

        # Check metadata
        metadata = result.data["metadata"]
        assert isinstance(metadata, RadarMetadata)
        assert metadata.station_name == "Pico do Couto"

        # Check previous snapshots
        previous = result.data["previous"]
        assert len(previous) == 2  # 2 previous snapshots in mock response

        await configured_provider.close()

    @pytest.mark.asyncio
    @respx.mock
    async def test_fetch_latest_api_timeout(
        self, configured_provider: RadarProvider
    ) -> None:
        """Test fetch_latest handles timeout correctly."""
        import httpx

        # Mock timeout
        respx.get("https://api.radar.example.com/latest").mock(
            side_effect=httpx.TimeoutException("Connection timed out")
        )

        from app.core.errors import ProviderException

        with pytest.raises(ProviderException) as exc_info:
            await configured_provider.fetch_latest()

        assert "timed out" in str(exc_info.value).lower()

        # Check error was recorded in metrics
        metrics = configured_provider.get_metrics()
        assert metrics.error_count >= 1

        await configured_provider.close()

    @pytest.mark.asyncio
    @respx.mock
    async def test_fetch_latest_api_error(
        self, configured_provider: RadarProvider
    ) -> None:
        """Test fetch_latest handles API errors correctly."""
        # Mock 500 error
        respx.get("https://api.radar.example.com/latest").mock(
            return_value=Response(500, json={"error": "Internal server error"})
        )

        from app.core.errors import ProviderException

        with pytest.raises(ProviderException) as exc_info:
            await configured_provider.fetch_latest()

        assert "500" in str(exc_info.value)

        await configured_provider.close()

    @pytest.mark.asyncio
    @respx.mock
    async def test_fetch_latest_invalid_response(
        self, configured_provider: RadarProvider
    ) -> None:
        """Test fetch_latest handles invalid response data."""
        # Mock empty snapshots
        respx.get("https://api.radar.example.com/latest").mock(
            return_value=Response(200, json={"snapshots": [], "metadata": {}})
        )

        result = await configured_provider.fetch_latest()

        # Should fail gracefully
        assert result.success is False
        assert "No snapshots" in result.error

        await configured_provider.close()

    @pytest.mark.asyncio
    @respx.mock
    async def test_fetch_history_real_api_success(
        self, configured_provider: RadarProvider
    ) -> None:
        """Test fetch_history with successful API response."""
        respx.get("https://api.radar.example.com/history").mock(
            return_value=Response(200, json=MOCK_HISTORY_RESPONSE)
        )

        result = await configured_provider.fetch_history(count=6)

        assert result.success is True
        assert result.data is not None
        assert len(result.data) == 6

        await configured_provider.close()

    @pytest.mark.asyncio
    @respx.mock
    async def test_auth_header_sent(
        self, configured_provider: RadarProvider
    ) -> None:
        """Test that authentication header is sent with requests."""
        route = respx.get("https://api.radar.example.com/latest").mock(
            return_value=Response(200, json=MOCK_API_RESPONSE)
        )

        await configured_provider.fetch_latest()

        # Check that auth header was sent
        assert route.called
        request = route.calls[0].request
        assert "Authorization" in request.headers
        assert "Bearer test-api-key-12345" in request.headers["Authorization"]

        await configured_provider.close()

    @pytest.mark.asyncio
    @respx.mock
    async def test_health_check_success(
        self, configured_provider: RadarProvider
    ) -> None:
        """Test health check returns True on success."""
        respx.get("https://api.radar.example.com/health").mock(
            return_value=Response(200, json={"status": "ok"})
        )

        result = await configured_provider.health_check()

        assert result is True

        await configured_provider.close()

    @pytest.mark.asyncio
    @respx.mock
    async def test_health_check_failure(
        self, configured_provider: RadarProvider
    ) -> None:
        """Test health check returns False on failure."""
        respx.get("https://api.radar.example.com/health").mock(
            return_value=Response(503, json={"status": "unavailable"})
        )

        from app.core.errors import ProviderException

        # health_check catches exceptions internally
        result = await configured_provider.health_check()

        assert result is False

        await configured_provider.close()


class TestRadarProviderParsing:
    """Tests for response parsing logic."""

    def test_parse_snapshot_basic(self) -> None:
        """Test parsing a basic snapshot."""
        provider = RadarProvider()

        snapshot_data = {
            "id": "radar_test",
            "timestamp": "2024-01-15T14:30:00Z",
            "image_url": "https://example.com/image.png",
            "resolution": "500m",
            "product_type": "velocity",
            "source": "TestSource",
        }

        snapshot = provider._parse_snapshot(snapshot_data)

        assert snapshot.id == "radar_test"
        assert snapshot.timestamp == datetime(2024, 1, 15, 14, 30, 0, tzinfo=timezone.utc)
        assert snapshot.resolution == "500m"
        assert snapshot.product_type == "velocity"
        assert snapshot.source == "TestSource"
        # URL should be proxied
        assert snapshot.url == "/v1/weather/radar/image/radar_test"

    def test_parse_snapshot_alternative_field_names(self) -> None:
        """Test parsing with alternative field names."""
        provider = RadarProvider()

        # Using 'time' instead of 'timestamp', 'bounding_box' instead of 'bbox'
        snapshot_data = {
            "id": "radar_alt",
            "time": "2024-01-15T12:00:00Z",
            "url": "https://example.com/image.png",
            "bounding_box": {
                "min_lon": -45.0,
                "min_lat": -24.0,
                "max_lon": -43.0,
                "max_lat": -22.0,
            },
        }

        snapshot = provider._parse_snapshot(snapshot_data)

        assert snapshot.id == "radar_alt"
        assert snapshot.bbox.min_lon == -45.0
        assert snapshot.bbox.max_lat == -22.0

    def test_parse_snapshot_missing_optional_fields(self) -> None:
        """Test parsing with missing optional fields uses defaults."""
        provider = RadarProvider()

        snapshot_data = {
            "timestamp": "2024-01-15T10:00:00Z",
        }

        snapshot = provider._parse_snapshot(snapshot_data)

        # Should use defaults
        assert snapshot.resolution == "1km"
        assert snapshot.product_type == "reflectivity"
        assert snapshot.source == "INMET"
        # Should use default bbox
        assert snapshot.bbox.min_lon == -44.5

    def test_parse_history_various_formats(self) -> None:
        """Test parsing history with various response formats."""
        provider = RadarProvider()

        # Format 1: snapshots key
        response1 = {"snapshots": [{"timestamp": "2024-01-15T10:00:00Z"}]}
        result1 = provider._parse_history_response(response1)
        assert len(result1) == 1

        # Format 2: history key
        response2 = {"history": [{"timestamp": "2024-01-15T10:00:00Z"}]}
        result2 = provider._parse_history_response(response2)
        assert len(result2) == 1

        # Format 3: data key
        response3 = {"data": [{"timestamp": "2024-01-15T10:00:00Z"}]}
        result3 = provider._parse_history_response(response3)
        assert len(result3) == 1


class TestRadarProviderMetrics:
    """Tests for metrics tracking."""

    @pytest.mark.asyncio
    async def test_success_metrics(self) -> None:
        """Test metrics are updated on success."""
        provider = RadarProvider()

        await provider.fetch_latest()

        metrics = provider.get_metrics()
        assert metrics.request_count >= 1
        assert metrics.last_success is not None
        assert metrics.status.value == "ok"

        await provider.close()

    @pytest.mark.asyncio
    @respx.mock
    async def test_error_metrics(self, monkeypatch: pytest.MonkeyPatch) -> None:
        """Test metrics are updated on error."""
        monkeypatch.setattr(
            "app.core.config.settings.radar_provider_url",
            "https://api.radar.example.com",
        )

        provider = RadarProvider()

        # Mock error
        respx.get("https://api.radar.example.com/latest").mock(
            return_value=Response(500, json={"error": "Server error"})
        )

        from app.core.errors import ProviderException

        with pytest.raises(ProviderException):
            await provider.fetch_latest()

        metrics = provider.get_metrics()
        assert metrics.error_count >= 1
        assert metrics.last_error is not None

        await provider.close()

    @pytest.mark.asyncio
    @respx.mock
    async def test_degraded_status_after_errors(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        """Test status becomes degraded after multiple errors."""
        monkeypatch.setattr(
            "app.core.config.settings.radar_provider_url",
            "https://api.radar.example.com",
        )

        provider = RadarProvider()

        # Mock error
        respx.get("https://api.radar.example.com/latest").mock(
            return_value=Response(500, json={"error": "Server error"})
        )

        from app.core.errors import ProviderException

        # Trigger multiple errors
        for _ in range(3):
            try:
                await provider.fetch_latest()
            except ProviderException:
                pass

        metrics = provider.get_metrics()
        assert metrics.status.value in ["degraded", "down"]

        await provider.close()
