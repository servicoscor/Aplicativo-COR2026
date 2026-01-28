from __future__ import annotations
"""Cache service for Redis operations with fallback support."""

import json
from datetime import datetime, timezone
from typing import Any, TypeVar

import redis.asyncio as redis
from pydantic import BaseModel

from app.core.config import settings
from app.core.errors import CacheException
from app.core.logging import get_logger
from app.schemas.common import CacheInfo

logger = get_logger(__name__)

T = TypeVar("T", bound=BaseModel)


class CacheService:
    """
    Redis cache service with fallback support.

    Stores the "last good data" for each endpoint and returns it
    when providers fail, along with staleness information.
    """

    def __init__(self, redis_url: str | None = None):
        """Initialize cache service."""
        self.redis_url = redis_url or settings.redis_url
        self._client: redis.Redis | None = None
        self._connected = False

    async def connect(self) -> None:
        """Connect to Redis."""
        if self._client is not None:
            return

        try:
            self._client = redis.from_url(
                self.redis_url,
                encoding="utf-8",
                decode_responses=True,
            )
            # Test connection
            await self._client.ping()
            self._connected = True
            logger.info("Connected to Redis")
        except Exception as e:
            logger.error(f"Failed to connect to Redis: {e}")
            self._connected = False
            raise CacheException(
                message=f"Failed to connect to Redis: {e}",
                operation="connect",
            )

    async def disconnect(self) -> None:
        """Disconnect from Redis."""
        if self._client:
            await self._client.close()
            self._client = None
            self._connected = False
            logger.info("Disconnected from Redis")

    @property
    def is_connected(self) -> bool:
        """Check if connected to Redis."""
        return self._connected and self._client is not None

    async def _ensure_connected(self) -> None:
        """Ensure connection to Redis."""
        if not self.is_connected:
            await self.connect()

    def _make_key(self, namespace: str, key: str) -> str:
        """Create a namespaced cache key."""
        return f"cor:{namespace}:{key}"

    def _make_timestamp_key(self, namespace: str, key: str) -> str:
        """Create a timestamp key for tracking cache age."""
        return f"cor:{namespace}:{key}:timestamp"

    async def set(
        self,
        namespace: str,
        key: str,
        data: BaseModel | dict[str, Any] | list[Any],
        ttl_seconds: int | None = None,
    ) -> None:
        """
        Store data in cache.

        Args:
            namespace: Cache namespace (e.g., "weather", "radar")
            key: Cache key within namespace
            data: Data to cache (Pydantic model or dict)
            ttl_seconds: TTL in seconds (None for no expiry)
        """
        await self._ensure_connected()

        cache_key = self._make_key(namespace, key)
        timestamp_key = self._make_timestamp_key(namespace, key)

        try:
            # Serialize data
            if isinstance(data, BaseModel):
                json_data = data.model_dump_json()
            else:
                json_data = json.dumps(data, default=str)

            # Store data and timestamp
            now = datetime.now(timezone.utc).isoformat()

            if ttl_seconds:
                await self._client.setex(cache_key, ttl_seconds, json_data)
                await self._client.setex(timestamp_key, ttl_seconds, now)
            else:
                await self._client.set(cache_key, json_data)
                await self._client.set(timestamp_key, now)

            logger.debug(f"Cached data for {cache_key}")

        except Exception as e:
            logger.error(f"Failed to set cache {cache_key}: {e}")
            raise CacheException(
                message=f"Failed to set cache: {e}",
                operation="set",
            )

    async def get(
        self,
        namespace: str,
        key: str,
        model_class: type[T] | None = None,
    ) -> tuple[T | dict[str, Any] | None, CacheInfo | None]:
        """
        Get data from cache with cache info.

        Args:
            namespace: Cache namespace
            key: Cache key within namespace
            model_class: Optional Pydantic model class for deserialization

        Returns:
            Tuple of (data, cache_info) or (None, None) if not found
        """
        await self._ensure_connected()

        cache_key = self._make_key(namespace, key)
        timestamp_key = self._make_timestamp_key(namespace, key)

        try:
            # Get data and timestamp
            json_data = await self._client.get(cache_key)
            timestamp_str = await self._client.get(timestamp_key)

            if json_data is None:
                return None, None

            # Parse data
            if model_class:
                data = model_class.model_validate_json(json_data)
            else:
                data = json.loads(json_data)

            # Calculate age
            cached_at = None
            age_seconds = None
            if timestamp_str:
                cached_at = datetime.fromisoformat(timestamp_str)
                age_seconds = int(
                    (datetime.now(timezone.utc) - cached_at).total_seconds()
                )

            cache_info = CacheInfo(
                stale=False,  # Will be set by service if serving fallback
                age_seconds=age_seconds,
                cached_at=cached_at,
            )

            return data, cache_info

        except Exception as e:
            logger.error(f"Failed to get cache {cache_key}: {e}")
            return None, None

    async def get_fallback(
        self,
        namespace: str,
        key: str,
        model_class: type[T] | None = None,
    ) -> tuple[T | dict[str, Any] | None, CacheInfo | None]:
        """
        Get stale/fallback data from cache.

        Same as get(), but marks cache_info.stale = True.
        """
        data, cache_info = await self.get(namespace, key, model_class)

        if data and cache_info:
            cache_info.stale = True

        return data, cache_info

    async def delete(self, namespace: str, key: str) -> None:
        """Delete data from cache."""
        await self._ensure_connected()

        cache_key = self._make_key(namespace, key)
        timestamp_key = self._make_timestamp_key(namespace, key)

        try:
            await self._client.delete(cache_key, timestamp_key)
            logger.debug(f"Deleted cache for {cache_key}")
        except Exception as e:
            logger.error(f"Failed to delete cache {cache_key}: {e}")

    async def get_cache_age(self, namespace: str, key: str) -> int | None:
        """Get age of cached data in seconds."""
        await self._ensure_connected()

        timestamp_key = self._make_timestamp_key(namespace, key)

        try:
            timestamp_str = await self._client.get(timestamp_key)
            if timestamp_str:
                cached_at = datetime.fromisoformat(timestamp_str)
                return int((datetime.now(timezone.utc) - cached_at).total_seconds())
        except Exception:
            pass

        return None

    async def health_check(self) -> bool:
        """Check Redis health."""
        try:
            if self._client:
                await self._client.ping()
                return True
        except Exception:
            pass
        return False


# Singleton instance
_cache_service: CacheService | None = None


async def get_cache_service() -> CacheService:
    """Get or create the cache service singleton."""
    global _cache_service
    if _cache_service is None:
        _cache_service = CacheService()
        await _cache_service.connect()
    return _cache_service
