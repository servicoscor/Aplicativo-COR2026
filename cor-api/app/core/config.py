"""Application configuration using Pydantic Settings."""

from functools import lru_cache
from typing import Literal, Optional

from pydantic import Field, PostgresDsn, RedisDsn
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Application
    app_name: str = "COR API"
    app_version: str = "1.0.0"
    environment: Literal["development", "staging", "production"] = "development"
    debug: bool = Field(default=False)
    log_level: str = Field(default="INFO")

    # Database
    database_url: str = Field(
        default="postgresql+asyncpg://cor:cor123@localhost:5432/cor_db"
    )
    database_url_sync: str = Field(
        default="postgresql://cor:cor123@localhost:5432/cor_db"
    )
    db_pool_size: int = Field(default=5)
    db_max_overflow: int = Field(default=10)

    # Redis
    redis_url: str = Field(default="redis://localhost:6379/0")

    # Celery
    celery_broker_url: str = Field(default="redis://localhost:6379/1")
    celery_result_backend: str = Field(default="redis://localhost:6379/1")

    # Security
    api_key_enabled: bool = Field(default=False)
    api_key: str = Field(default="your-secret-api-key")

    # JWT Configuration
    jwt_secret_key: str = Field(
        default="change-this-in-production-use-secrets-token-hex-32",
        description="Secret key for JWT encoding (use a strong 32+ byte key in production)",
    )
    jwt_algorithm: str = Field(
        default="HS256",
        description="Algorithm for JWT encoding",
    )
    jwt_access_token_expire_minutes: int = Field(
        default=480,  # 8 hours
        description="Access token expiration in minutes",
    )

    # Admin seed user (for initial setup)
    admin_seed_email: Optional[str] = Field(
        default=None,
        description="Email for initial admin user (set on first run)",
    )
    admin_seed_password: Optional[str] = Field(
        default=None,
        description="Password for initial admin user (set on first run)",
    )

    # Rate Limiting
    rate_limit_per_minute: int = Field(default=100)

    # Provider URLs (to be configured with real endpoints)
    weather_provider_url: Optional[str] = Field(default=None)
    weather_provider_api_key: Optional[str] = Field(default=None)

    # Radar Provider Configuration
    radar_provider_url: Optional[str] = Field(default=None)
    radar_provider_api_key: Optional[str] = Field(default=None)
    radar_provider_timeout: float = Field(default=15.0)  # Radar images can be large
    radar_provider_auth_header: str = Field(default="Authorization")  # Header name for auth
    radar_provider_auth_scheme: str = Field(default="Bearer")  # Auth scheme (Bearer, Token, etc)

    rain_gauge_provider_url: Optional[str] = Field(default=None)
    rain_gauge_provider_api_key: Optional[str] = Field(default=None)
    incidents_provider_url: Optional[str] = Field(default=None)
    incidents_provider_api_key: Optional[str] = Field(default=None)

    # Alerta Rio Provider Configuration
    alertario_provider_url: Optional[str] = Field(
        default=None,
        description="Override URL for Alerta Rio (uses default public URL if not set)"
    )
    alertario_provider_timeout: float = Field(
        default=5.0,
        description="Timeout for Alerta Rio requests in seconds"
    )

    # FCM (Firebase Cloud Messaging) Configuration
    fcm_credentials_path: Optional[str] = Field(
        default=None,
        description="Path to Firebase service account JSON file"
    )
    fcm_credentials_json: Optional[str] = Field(
        default=None,
        description="Firebase service account JSON as string (alternative to file path)"
    )
    fcm_project_id: Optional[str] = Field(
        default=None,
        description="Firebase project ID (optional, read from credentials)"
    )
    fcm_dry_run: bool = Field(
        default=False,
        description="If true, FCM validates but doesn't send messages"
    )
    push_batch_size: int = Field(
        default=500,
        description="Max notifications per FCM batch (FCM limit is 500)"
    )
    push_batch_delay_ms: int = Field(
        default=100,
        description="Delay between batches in milliseconds"
    )

    # Provider timeouts (seconds)
    provider_timeout: float = Field(default=10.0)
    provider_retry_attempts: int = Field(default=3)

    # Cache TTLs (seconds)
    cache_ttl_weather_now: int = Field(default=60)
    cache_ttl_weather_forecast: int = Field(default=600)  # 10 minutes
    cache_ttl_radar: int = Field(default=180)  # 3 minutes
    cache_ttl_rain_gauges: int = Field(default=120)  # 2 minutes
    cache_ttl_incidents: int = Field(default=45)
    cache_ttl_alertario: int = Field(default=300)  # 5 minutes (short-term forecast)
    cache_ttl_alertario_extended: int = Field(default=600)  # 10 minutes (extended forecast)

    @property
    def is_development(self) -> bool:
        """Check if running in development mode."""
        return self.environment == "development"

    @property
    def is_production(self) -> bool:
        """Check if running in production mode."""
        return self.environment == "production"


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


settings = get_settings()
