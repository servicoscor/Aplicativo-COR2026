from __future__ import annotations
"""Radar data provider with Alerta Rio integration."""

import time
from datetime import datetime, timedelta, timezone
from typing import Any

import httpx

from app.core.config import settings
from app.core.errors import ProviderException
from app.core.logging import get_logger
from app.providers.base import BaseProvider, ProviderResult
from app.schemas.common import BoundingBox
from app.schemas.radar import RadarMetadata, RadarSnapshot

logger = get_logger(__name__)


class RadarProvider(BaseProvider):
    """
    Provider for radar data from Alerta Rio.

    Fetches radar images from:
    http://alertario.rio.rj.gov.br/upload/Mapa/semfundo/radarXXX.png

    The images are updated every ~2 minutes with 20 frames available
    (radar001.png to radar020.png), where radar020.png is the most recent.

    The images are transparent PNGs showing only rain nuclei,
    perfect for overlaying on dark map tiles.
    """

    # Alerta Rio radar image base URL
    ALERTARIO_RADAR_BASE_URL = "http://alertario.rio.rj.gov.br/upload/Mapa/semfundo"

    # Rio de Janeiro area bounding box for radar
    # Coordenadas oficiais do Alerta Rio
    # Fonte: https://www.sistema-alerta-rio.com.br/upload/Mapa/mapaRadar.js
    # L.latLngBounds(L.latLng(-24.431567, -45.336972), L.latLng(-21.478793, -41.159092))
    RIO_RADAR_BBOX = BoundingBox(
        min_lon=-45.336972,  # West
        min_lat=-24.431567,  # South
        max_lon=-41.159092,  # East
        max_lat=-21.478793,  # North
    )

    # Sumaré radar station coordinates (official)
    # Fonte: https://www.sistema-alerta-rio.com.br/upload/Mapa/mapaRadar.js
    # L.circle([-22.960849, -43.2646667], {radius: 138900})
    STATION_LAT = -22.960849
    STATION_LON = -43.2646667

    # Number of radar frames available (001-020)
    NUM_FRAMES = 20

    # Update interval in minutes (approximate, based on Alerta Rio updates)
    UPDATE_INTERVAL_MINUTES = 2

    def __init__(self):
        super().__init__(
            name="radar",
            base_url=self.ALERTARIO_RADAR_BASE_URL,
            api_key=None,
            timeout=settings.radar_provider_timeout,
        )

    def _get_default_headers(self) -> dict[str, str]:
        """Get default headers for requests."""
        return {
            "Accept": "image/png,*/*",
            "User-Agent": f"COR-API/{settings.app_version}",
        }

    def _get_image_url(self, frame_number: int) -> str:
        """Get the proxy URL for a radar frame image."""
        # Retorna URL relativa do proxy (será servida via HTTPS pela API)
        return f"/v1/weather/radar/image/{frame_number}"

    def _get_source_url(self, frame_number: int) -> str:
        """Get the original Alerta Rio URL for a radar frame (used for health checks)."""
        return f"{self.ALERTARIO_RADAR_BASE_URL}/radar{frame_number:03d}.png"

    def _generate_alertario_snapshots(self, count: int = 12) -> list[RadarSnapshot]:
        """
        Generate radar snapshots from Alerta Rio images.

        The images radar001.png to radar020.png are updated every ~2 minutes.
        radar020.png is the most recent, radar001.png is the oldest.

        Args:
            count: Number of snapshots to include (max 20)

        Returns:
            List of RadarSnapshot objects, newest first
        """
        now = datetime.now(timezone.utc)
        # Round to nearest 2 minutes
        minutes = (now.minute // 2) * 2
        base_time = now.replace(minute=minutes, second=0, microsecond=0)

        snapshots = []
        actual_count = min(count, self.NUM_FRAMES)

        for i in range(actual_count):
            # Frame numbers: 020 (newest) down to 001 (oldest)
            frame_number = self.NUM_FRAMES - i

            # Estimate timestamp (each frame is ~2 minutes apart)
            snapshot_time = base_time - timedelta(minutes=self.UPDATE_INTERVAL_MINUTES * i)
            snapshot_id = f"alertario_radar{frame_number:03d}"

            # URL do proxy da API (HTTPS) para evitar bloqueio de HTTP no iOS
            image_url = self._get_image_url(frame_number)

            snapshots.append(
                RadarSnapshot(
                    id=snapshot_id,
                    timestamp=snapshot_time,
                    url=image_url,  # URL relativa do proxy (/v1/weather/radar/image/XX)
                    thumbnail_url=None,
                    bbox=self.RIO_RADAR_BBOX,
                    resolution="1km",
                    product_type="reflectivity",
                    source="Alerta Rio",
                    valid_until=snapshot_time + timedelta(minutes=10),
                )
            )

        return snapshots

    async def fetch_latest(self) -> ProviderResult[dict[str, Any]]:
        """
        Fetch the latest radar snapshot from Alerta Rio.

        Returns:
            ProviderResult containing radar snapshot data and metadata
        """
        start_time = time.perf_counter()

        try:
            # Verify that the latest image is accessible (use source URL for health check)
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                # Check if radar020.png (most recent) is available
                test_url = self._get_source_url(self.NUM_FRAMES)
                response = await client.head(test_url, headers=self._get_default_headers())

                if response.status_code != 200:
                    raise ProviderException(
                        message=f"Alerta Rio radar image not available (status: {response.status_code})",
                        provider=self.name,
                        code="ALERTARIO_RADAR_UNAVAILABLE",
                    )

            # Generate snapshots
            all_snapshots = self._generate_alertario_snapshots(count=12)

            latest = all_snapshots[0]
            previous = all_snapshots[1:] if len(all_snapshots) > 1 else []

            metadata = RadarMetadata(
                station_name="Sumaré (Alerta Rio)",
                station_lat=self.STATION_LAT,
                station_lon=self.STATION_LON,
                range_km=139,  # 138.9 km oficial
                update_interval_minutes=self.UPDATE_INTERVAL_MINUTES,
            )

            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_success(latency_ms)

            logger.info(
                f"Fetched Alerta Rio radar data (latency: {latency_ms:.2f}ms, "
                f"snapshots: {len(all_snapshots)})"
            )

            return ProviderResult.ok(
                {
                    "latest": latest,
                    "metadata": metadata,
                    "previous": previous,
                },
                latency_ms,
            )

        except ProviderException:
            raise

        except Exception as e:
            latency_ms = (time.perf_counter() - start_time) * 1000
            error_msg = f"Failed to fetch Alerta Rio radar data: {str(e)}"
            self.metrics.record_error(error_msg)
            logger.error(error_msg)
            return ProviderResult.fail(error_msg, latency_ms)

    async def fetch_history(
        self, count: int = 12
    ) -> ProviderResult[list[RadarSnapshot]]:
        """
        Fetch radar snapshot history for animation.

        Args:
            count: Number of snapshots to retrieve (default: 12, max: 20)

        Returns:
            ProviderResult containing list of radar snapshots
        """
        start_time = time.perf_counter()

        try:
            snapshots = self._generate_alertario_snapshots(count=count)
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_success(latency_ms)

            logger.info(
                f"Generated {len(snapshots)} Alerta Rio radar snapshots "
                f"(latency: {latency_ms:.2f}ms)"
            )
            return ProviderResult.ok(snapshots, latency_ms)

        except Exception as e:
            latency_ms = (time.perf_counter() - start_time) * 1000
            error_msg = f"Failed to generate radar history: {str(e)}"
            self.metrics.record_error(error_msg)
            logger.error(error_msg)
            return ProviderResult.fail(error_msg, latency_ms)

    async def fetch(self, **kwargs: Any) -> ProviderResult[dict[str, Any]]:
        """Default fetch returns latest radar."""
        return await self.fetch_latest()

    async def get_image_url(self, snapshot_id: str) -> str | None:
        """
        Get the image URL for a snapshot.

        For Alerta Rio, the URLs are public and don't need proxying.

        Args:
            snapshot_id: Snapshot ID (e.g., 'alertario_radar020')

        Returns:
            Direct URL to the radar image
        """
        try:
            # Extract frame number from snapshot_id
            if snapshot_id.startswith("alertario_radar"):
                frame_str = snapshot_id.replace("alertario_radar", "")
                frame_number = int(frame_str)
                return self._get_image_url(frame_number)
            return None
        except (ValueError, IndexError) as e:
            logger.error(f"Failed to parse snapshot ID '{snapshot_id}': {e}")
            return None

    async def health_check(self) -> bool:
        """
        Check if the Alerta Rio radar is accessible.

        Returns:
            True if radar images are available
        """
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                test_url = self._get_source_url(self.NUM_FRAMES)
                response = await client.head(test_url)
                return response.status_code == 200
        except Exception as e:
            logger.warning(f"Alerta Rio radar health check failed: {e}")
            return False

    @property
    def is_mock(self) -> bool:
        """Alerta Rio provider is never mock - it's always real data."""
        return False
