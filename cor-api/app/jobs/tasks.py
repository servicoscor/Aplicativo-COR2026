"""Celery tasks for data refresh."""

import asyncio
from typing import Any

from app.core.config import settings
from app.core.logging import get_logger, setup_logging
from app.jobs.celery_app import celery_app
from app.providers.incidents_provider import IncidentsProvider
from app.providers.radar_provider import RadarProvider
from app.providers.rain_gauge_provider import RainGaugeProvider
from app.providers.weather_provider import WeatherProvider
from app.services.cache_service import CacheService

# Setup logging for tasks
setup_logging(settings.log_level)
logger = get_logger(__name__)


def run_async(coro: Any) -> Any:
    """Run async function in sync context."""
    loop = asyncio.get_event_loop()
    if loop.is_running():
        # Create new loop if current is already running
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
    return loop.run_until_complete(coro)


async def _refresh_weather_now() -> dict[str, Any]:
    """Async implementation of weather refresh."""
    cache = CacheService()
    provider = WeatherProvider()

    try:
        await cache.connect()

        logger.info("Refreshing current weather data")
        result = await provider.fetch_current()

        if result.success and result.data:
            await cache.set(
                "weather",
                "now",
                result.data,
                ttl_seconds=settings.cache_ttl_weather_now * 2,
            )
            logger.info(
                f"Weather data refreshed successfully (latency: {result.latency_ms:.2f}ms)"
            )
            return {"success": True, "latency_ms": result.latency_ms}
        else:
            logger.warning(f"Weather refresh failed: {result.error}")
            return {"success": False, "error": result.error}

    except Exception as e:
        logger.error(f"Weather refresh error: {e}")
        return {"success": False, "error": str(e)}

    finally:
        await cache.disconnect()
        await provider.close()


@celery_app.task(bind=True, max_retries=3, default_retry_delay=30)
def refresh_weather_now(self: Any) -> dict[str, Any]:
    """
    Refresh current weather data.

    Fetches current weather from provider and updates cache.
    Runs every 60 seconds via beat schedule.
    """
    try:
        return run_async(_refresh_weather_now())
    except Exception as e:
        logger.error(f"Weather refresh task failed: {e}")
        raise self.retry(exc=e)


async def _refresh_weather_forecast() -> dict[str, Any]:
    """Async implementation of forecast refresh."""
    cache = CacheService()
    provider = WeatherProvider()

    try:
        await cache.connect()

        logger.info("Refreshing weather forecast data")
        result = await provider.fetch_forecast(hours=48)

        if result.success and result.data:
            await cache.set(
                "weather",
                "forecast:48",
                result.data,
                ttl_seconds=settings.cache_ttl_weather_forecast * 2,
            )
            logger.info(
                f"Weather forecast refreshed successfully (latency: {result.latency_ms:.2f}ms)"
            )
            return {"success": True, "latency_ms": result.latency_ms}
        else:
            logger.warning(f"Weather forecast refresh failed: {result.error}")
            return {"success": False, "error": result.error}

    except Exception as e:
        logger.error(f"Weather forecast refresh error: {e}")
        return {"success": False, "error": str(e)}

    finally:
        await cache.disconnect()
        await provider.close()


@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)
def refresh_weather_forecast(self: Any) -> dict[str, Any]:
    """
    Refresh weather forecast data.

    Fetches 48-hour forecast from provider and updates cache.
    Runs every 10 minutes via beat schedule.
    """
    try:
        return run_async(_refresh_weather_forecast())
    except Exception as e:
        logger.error(f"Weather forecast refresh task failed: {e}")
        raise self.retry(exc=e)


async def _refresh_radar_latest() -> dict[str, Any]:
    """Async implementation of radar refresh."""
    cache = CacheService()
    provider = RadarProvider()

    try:
        await cache.connect()

        logger.info("Refreshing radar data")
        result = await provider.fetch_latest()

        if result.success and result.data:
            # Serialize for caching
            from app.schemas.radar import RadarMetadata, RadarSnapshot

            cache_data = {
                "latest": (
                    result.data["latest"].model_dump()
                    if isinstance(result.data["latest"], RadarSnapshot)
                    else result.data["latest"]
                ),
                "metadata": (
                    result.data["metadata"].model_dump()
                    if isinstance(result.data["metadata"], RadarMetadata)
                    else result.data["metadata"]
                ),
                "previous": [
                    p.model_dump() if isinstance(p, RadarSnapshot) else p
                    for p in result.data.get("previous", [])
                ],
            }

            await cache.set(
                "radar",
                "latest",
                cache_data,
                ttl_seconds=settings.cache_ttl_radar * 2,
            )
            logger.info(
                f"Radar data refreshed successfully (latency: {result.latency_ms:.2f}ms)"
            )
            return {"success": True, "latency_ms": result.latency_ms}
        else:
            logger.warning(f"Radar refresh failed: {result.error}")
            return {"success": False, "error": result.error}

    except Exception as e:
        logger.error(f"Radar refresh error: {e}")
        return {"success": False, "error": str(e)}

    finally:
        await cache.disconnect()
        await provider.close()


@celery_app.task(bind=True, max_retries=3, default_retry_delay=30)
def refresh_radar_latest(self: Any) -> dict[str, Any]:
    """
    Refresh radar data.

    Fetches latest radar snapshot and metadata from provider and updates cache.
    Runs every 3 minutes via beat schedule.
    """
    try:
        return run_async(_refresh_radar_latest())
    except Exception as e:
        logger.error(f"Radar refresh task failed: {e}")
        raise self.retry(exc=e)


async def _refresh_rain_gauges() -> dict[str, Any]:
    """Async implementation of rain gauge refresh."""
    cache = CacheService()
    provider = RainGaugeProvider()

    try:
        await cache.connect()

        logger.info("Refreshing rain gauge data")
        result = await provider.fetch_latest()

        if result.success and result.data:
            # Serialize for caching
            from app.schemas.rain_gauge import RainGauge, RainGaugesSummary

            cache_data = {
                "gauges": [
                    g.model_dump() if isinstance(g, RainGauge) else g
                    for g in result.data["gauges"]
                ],
                "summary": (
                    result.data["summary"].model_dump()
                    if isinstance(result.data["summary"], RainGaugesSummary)
                    else result.data["summary"]
                ),
            }

            await cache.set(
                "rain_gauges",
                "latest",
                cache_data,
                ttl_seconds=settings.cache_ttl_rain_gauges * 2,
            )
            logger.info(
                f"Rain gauge data refreshed successfully (latency: {result.latency_ms:.2f}ms)"
            )
            return {"success": True, "latency_ms": result.latency_ms}
        else:
            logger.warning(f"Rain gauge refresh failed: {result.error}")
            return {"success": False, "error": result.error}

    except Exception as e:
        logger.error(f"Rain gauge refresh error: {e}")
        return {"success": False, "error": str(e)}

    finally:
        await cache.disconnect()
        await provider.close()


@celery_app.task(bind=True, max_retries=3, default_retry_delay=30)
def refresh_rain_gauges(self: Any) -> dict[str, Any]:
    """
    Refresh rain gauge data.

    Fetches latest readings from all rain gauge stations and updates cache.
    Runs every 2 minutes via beat schedule.
    """
    try:
        return run_async(_refresh_rain_gauges())
    except Exception as e:
        logger.error(f"Rain gauge refresh task failed: {e}")
        raise self.retry(exc=e)


async def _refresh_incidents() -> dict[str, Any]:
    """Async implementation of incidents refresh."""
    cache = CacheService()
    provider = IncidentsProvider()

    try:
        await cache.connect()

        logger.info("Refreshing incidents data")
        result = await provider.fetch_incidents()

        if result.success and result.data:
            # Serialize for caching
            from app.schemas.incident import Incident, IncidentsSummary

            cache_data = {
                "incidents": [
                    i.model_dump() if isinstance(i, Incident) else i
                    for i in result.data["incidents"]
                ],
                "summary": (
                    result.data["summary"].model_dump()
                    if isinstance(result.data["summary"], IncidentsSummary)
                    else result.data["summary"]
                ),
            }

            await cache.set(
                "incidents",
                "latest",
                cache_data,
                ttl_seconds=settings.cache_ttl_incidents * 2,
            )
            logger.info(
                f"Incidents data refreshed successfully (latency: {result.latency_ms:.2f}ms)"
            )
            return {"success": True, "latency_ms": result.latency_ms}
        else:
            logger.warning(f"Incidents refresh failed: {result.error}")
            return {"success": False, "error": result.error}

    except Exception as e:
        logger.error(f"Incidents refresh error: {e}")
        return {"success": False, "error": str(e)}

    finally:
        await cache.disconnect()
        await provider.close()


@celery_app.task(bind=True, max_retries=3, default_retry_delay=15)
def refresh_incidents(self: Any) -> dict[str, Any]:
    """
    Refresh incidents data.

    Fetches active incidents from provider and updates cache.
    Runs every 45 seconds via beat schedule.
    """
    try:
        return run_async(_refresh_incidents())
    except Exception as e:
        logger.error(f"Incidents refresh task failed: {e}")
        raise self.retry(exc=e)


# ==================== Alert Sending Task ====================


async def _send_alert(alert_id: str) -> dict[str, Any]:
    """Async implementation of alert sending."""
    from datetime import datetime, timezone

    from sqlalchemy import select
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
    from sqlalchemy.orm import selectinload
    from sqlalchemy.pool import NullPool

    from app.models.alert import AlertDeliveryModel, AlertModel
    from app.providers.push_provider import PushNotification, PushProvider

    # Create database connection
    engine = create_async_engine(
        settings.database_url,
        echo=False,
        pool_pre_ping=True,
        poolclass=NullPool,
    )
    AsyncSessionLocal = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False,
        autoflush=False,
    )

    push_provider = PushProvider()
    stats = {
        "alert_id": alert_id,
        "success": 0,
        "failed": 0,
        "total": 0,
        "errors": [],
    }

    try:
        async with AsyncSessionLocal() as db:
            # Load alert with areas
            stmt = (
                select(AlertModel)
                .options(selectinload(AlertModel.areas))
                .where(AlertModel.id == alert_id)
            )
            result = await db.execute(stmt)
            alert = result.scalar_one_or_none()

            if not alert:
                logger.error(f"Alert {alert_id} not found")
                return {"success": False, "error": "Alert not found"}

            if alert.status != "sent":
                logger.warning(f"Alert {alert_id} is not in sent status")
                return {"success": False, "error": "Alert not in sent status"}

            # Import service for device query
            from app.services.alert_service import AlertService

            alert_service = AlertService(db)
            devices = await alert_service.get_targeted_devices(alert)

            logger.info(f"Sending alert {alert_id} to {len(devices)} devices")
            stats["total"] = len(devices)

            if not devices:
                logger.info(f"No devices to send alert {alert_id}")
                return {"success": True, **stats}

            # Prepare notifications
            notifications = []
            for device in devices:
                notifications.append(
                    PushNotification(
                        device_token=device.push_token,
                        title=alert.title,
                        body=alert.body,
                        data={
                            "alert_id": alert.id,
                            "severity": alert.severity,
                            "type": "alert",
                        },
                        platform=device.platform or "android",
                    )
                )

            # Send in batches
            batch_size = 100
            for i in range(0, len(notifications), batch_size):
                batch = notifications[i : i + batch_size]
                batch_devices = devices[i : i + batch_size]

                results = await push_provider.send_batch(batch)

                # Record deliveries
                now = datetime.now(timezone.utc)
                for j, push_result in enumerate(results):
                    device = batch_devices[j]

                    delivery = AlertDeliveryModel(
                        alert_id=alert.id,
                        device_id=device.id,
                        sent_at=now,
                        provider_status="sent" if push_result.success else "failed",
                        error_message=push_result.error,
                    )
                    db.add(delivery)

                    if push_result.success:
                        stats["success"] += 1
                    else:
                        stats["failed"] += 1
                        if push_result.error and len(stats["errors"]) < 10:
                            stats["errors"].append(push_result.error)

                await db.commit()
                logger.info(
                    f"Alert {alert_id}: batch {i // batch_size + 1} - "
                    f"{sum(1 for r in results if r.success)}/{len(results)} sent"
                )

            logger.info(
                f"Alert {alert_id} delivery complete: "
                f"{stats['success']}/{stats['total']} successful"
            )
            return {"success": True, **stats}

    except Exception as e:
        logger.error(f"Alert sending error: {e}")
        return {"success": False, "error": str(e), **stats}

    finally:
        await push_provider.close()
        await engine.dispose()


@celery_app.task(bind=True, max_retries=3, default_retry_delay=30)
def send_alert_task(self: Any, alert_id: str) -> dict[str, Any]:
    """
    Send push notifications for an alert.

    This task:
    1. Loads the alert and its targeting areas
    2. Queries devices matching the targeting criteria
    3. Sends push notifications in batches
    4. Records delivery status for each device

    Args:
        alert_id: ID of the alert to send

    Returns:
        Dict with success status, counts, and any errors
    """
    try:
        return run_async(_send_alert(alert_id))
    except Exception as e:
        logger.error(f"Send alert task failed: {e}")
        raise self.retry(exc=e)
