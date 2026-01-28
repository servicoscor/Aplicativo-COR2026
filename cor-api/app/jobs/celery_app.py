"""Celery application configuration."""

from celery import Celery
from celery.schedules import crontab

from app.core.config import settings

# Create Celery app
celery_app = Celery(
    "cor_worker",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
    include=["app.jobs.tasks"],
)

# Celery configuration
celery_app.conf.update(
    # Task settings
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="America/Sao_Paulo",
    enable_utc=True,

    # Task execution settings
    task_acks_late=True,
    task_reject_on_worker_lost=True,
    task_time_limit=300,  # 5 minutes max
    task_soft_time_limit=240,  # 4 minutes soft limit

    # Worker settings
    worker_prefetch_multiplier=1,
    worker_concurrency=4,

    # Result backend settings
    result_expires=3600,  # Results expire after 1 hour

    # Beat schedule for periodic tasks
    beat_schedule={
        # Weather - every 60 seconds
        "refresh-weather-now": {
            "task": "app.jobs.tasks.refresh_weather_now",
            "schedule": 60.0,
            "options": {"queue": "weather"},
        },
        # Weather forecast - every 10 minutes
        "refresh-weather-forecast": {
            "task": "app.jobs.tasks.refresh_weather_forecast",
            "schedule": 600.0,
            "options": {"queue": "weather"},
        },
        # Radar - every 3 minutes
        "refresh-radar-latest": {
            "task": "app.jobs.tasks.refresh_radar_latest",
            "schedule": 180.0,
            "options": {"queue": "radar"},
        },
        # Rain gauges - every 2 minutes
        "refresh-rain-gauges": {
            "task": "app.jobs.tasks.refresh_rain_gauges",
            "schedule": 120.0,
            "options": {"queue": "sensors"},
        },
        # Incidents - every 45 seconds
        "refresh-incidents": {
            "task": "app.jobs.tasks.refresh_incidents",
            "schedule": 45.0,
            "options": {"queue": "incidents"},
        },
    },

    # Task routing
    task_routes={
        "app.jobs.tasks.refresh_weather_*": {"queue": "weather"},
        "app.jobs.tasks.refresh_radar_*": {"queue": "radar"},
        "app.jobs.tasks.refresh_rain_*": {"queue": "sensors"},
        "app.jobs.tasks.refresh_incidents": {"queue": "incidents"},
    },

    # Default queue
    task_default_queue="default",
)
