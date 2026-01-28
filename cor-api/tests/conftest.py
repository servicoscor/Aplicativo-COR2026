"""Pytest configuration and fixtures."""

import asyncio
from typing import AsyncGenerator, Generator
from unittest.mock import AsyncMock, MagicMock

import pytest
import pytest_asyncio
from fastapi.testclient import TestClient
from httpx import AsyncClient

from app.main import app
from app.services.cache_service import CacheService


@pytest.fixture(scope="session")
def event_loop() -> Generator[asyncio.AbstractEventLoop, None, None]:
    """Create event loop for async tests."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
def client() -> Generator[TestClient, None, None]:
    """Create synchronous test client."""
    with TestClient(app) as test_client:
        yield test_client


@pytest_asyncio.fixture
async def async_client() -> AsyncGenerator[AsyncClient, None]:
    """Create async test client."""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac


@pytest.fixture
def mock_cache() -> MagicMock:
    """Create mock cache service."""
    cache = MagicMock(spec=CacheService)
    cache.connect = AsyncMock()
    cache.disconnect = AsyncMock()
    cache.health_check = AsyncMock(return_value=True)
    cache.set = AsyncMock()
    cache.get = AsyncMock(return_value=(None, None))
    cache.get_fallback = AsyncMock(return_value=(None, None))
    cache.get_cache_age = AsyncMock(return_value=None)
    cache.is_connected = True
    return cache


@pytest.fixture
def mock_redis_connected(monkeypatch: pytest.MonkeyPatch, mock_cache: MagicMock) -> None:
    """Mock Redis as connected."""
    async def get_mock_cache() -> CacheService:
        return mock_cache

    monkeypatch.setattr(
        "app.services.cache_service.get_cache_service",
        get_mock_cache,
    )
    monkeypatch.setattr(
        "app.api.deps.get_cache_service",
        get_mock_cache,
    )
