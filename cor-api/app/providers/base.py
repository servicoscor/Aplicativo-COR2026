from __future__ import annotations
"""Base provider class and common utilities."""

import time
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Generic, TypeVar

import httpx

from app.core.config import settings
from app.core.errors import ProviderException
from app.core.logging import get_logger
from app.schemas.common import SourceStatus

logger = get_logger(__name__)

T = TypeVar("T")


@dataclass
class SourceMetrics:
    """Metrics for a data source."""

    name: str
    status: SourceStatus = SourceStatus.OK
    last_success: datetime | None = None
    last_error: str | None = None
    last_error_time: datetime | None = None
    latency_ms: float = 0.0
    request_count: int = 0
    error_count: int = 0

    def record_success(self, latency_ms: float) -> None:
        """Record a successful request."""
        self.status = SourceStatus.OK
        self.last_success = datetime.now(timezone.utc)
        self.latency_ms = latency_ms
        self.request_count += 1
        # Reset error count on success
        if self.error_count > 0:
            self.error_count = max(0, self.error_count - 1)

    def record_error(self, error_message: str) -> None:
        """Record a failed request."""
        self.last_error = error_message
        self.last_error_time = datetime.now(timezone.utc)
        self.error_count += 1
        self.request_count += 1

        # Update status based on error count
        if self.error_count >= 5:
            self.status = SourceStatus.DOWN
        elif self.error_count >= 2:
            self.status = SourceStatus.DEGRADED


@dataclass
class ProviderResult(Generic[T]):
    """Result wrapper for provider responses."""

    data: T | None = None
    success: bool = True
    error: str | None = None
    latency_ms: float = 0.0
    fetched_at: datetime = field(
        default_factory=lambda: datetime.now(timezone.utc)
    )

    @classmethod
    def ok(cls, data: T, latency_ms: float = 0.0) -> "ProviderResult[T]":
        """Create a successful result."""
        return cls(data=data, success=True, latency_ms=latency_ms)

    @classmethod
    def fail(cls, error: str, latency_ms: float = 0.0) -> "ProviderResult[T]":
        """Create a failed result."""
        return cls(data=None, success=False, error=error, latency_ms=latency_ms)


class BaseProvider(ABC):
    """Base class for all data providers."""

    def __init__(
        self,
        name: str,
        base_url: str | None = None,
        api_key: str | None = None,
        timeout: float | None = None,
    ):
        """
        Initialize the provider.

        Args:
            name: Provider name for logging and metrics
            base_url: Base URL for API requests
            api_key: API key for authentication
            timeout: Request timeout in seconds
        """
        self.name = name
        self.base_url = base_url
        self.api_key = api_key
        self.timeout = timeout or settings.provider_timeout
        self.metrics = SourceMetrics(name=name)
        self._client: httpx.AsyncClient | None = None

    @property
    def is_configured(self) -> bool:
        """Check if the provider has a real URL configured."""
        return self.base_url is not None

    @property
    def is_mock(self) -> bool:
        """Check if provider is using mock data."""
        return not self.is_configured

    async def get_client(self) -> httpx.AsyncClient:
        """Get or create HTTP client."""
        if self._client is None:
            self._client = httpx.AsyncClient(
                timeout=httpx.Timeout(self.timeout),
                headers=self._get_default_headers(),
            )
        return self._client

    async def close(self) -> None:
        """Close the HTTP client."""
        if self._client:
            await self._client.aclose()
            self._client = None

    def _get_default_headers(self) -> dict[str, str]:
        """Get default headers for requests."""
        headers = {
            "Accept": "application/json",
            "User-Agent": f"COR-API/{settings.app_version}",
        }
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        return headers

    async def _make_request(
        self,
        method: str,
        endpoint: str,
        params: dict[str, Any] | None = None,
        data: dict[str, Any] | None = None,
    ) -> httpx.Response:
        """
        Make an HTTP request.

        Args:
            method: HTTP method
            endpoint: API endpoint
            params: Query parameters
            data: Request body

        Returns:
            HTTP response

        Raises:
            ProviderException: If request fails
        """
        if not self.base_url:
            raise ProviderException(
                message="Provider URL not configured",
                provider=self.name,
                code="PROVIDER_NOT_CONFIGURED",
            )

        url = f"{self.base_url.rstrip('/')}/{endpoint.lstrip('/')}"
        client = await self.get_client()

        start_time = time.perf_counter()
        try:
            response = await client.request(
                method=method,
                url=url,
                params=params,
                json=data,
            )
            latency_ms = (time.perf_counter() - start_time) * 1000

            if response.status_code >= 400:
                self.metrics.record_error(
                    f"HTTP {response.status_code}: {response.text[:200]}"
                )
                raise ProviderException(
                    message=f"Provider returned error: {response.status_code}",
                    provider=self.name,
                    code="PROVIDER_HTTP_ERROR",
                    details={"status_code": response.status_code},
                )

            self.metrics.record_success(latency_ms)
            return response

        except httpx.TimeoutException as e:
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_error(f"Timeout: {str(e)}")
            raise ProviderException(
                message="Provider request timed out",
                provider=self.name,
                code="PROVIDER_TIMEOUT",
            ) from e

        except httpx.RequestError as e:
            latency_ms = (time.perf_counter() - start_time) * 1000
            self.metrics.record_error(f"Request error: {str(e)}")
            raise ProviderException(
                message=f"Provider request failed: {str(e)}",
                provider=self.name,
                code="PROVIDER_REQUEST_ERROR",
            ) from e

    @abstractmethod
    async def fetch(self, **kwargs: Any) -> ProviderResult[Any]:
        """
        Fetch data from the provider.

        This method should be implemented by subclasses.
        If the provider is not configured, it should return mock data.
        """
        pass

    def get_metrics(self) -> SourceMetrics:
        """Get current metrics."""
        return self.metrics
