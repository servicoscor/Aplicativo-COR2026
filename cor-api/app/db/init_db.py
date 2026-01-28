"""Database initialization."""

from sqlalchemy import text

from app.core.logging import get_logger
from app.db.session import engine
from app.models.base import Base

logger = get_logger(__name__)


async def init_db() -> None:
    """
    Initialize the database.

    Creates all tables and ensures PostGIS extension is enabled.
    """
    async with engine.begin() as conn:
        # Enable PostGIS extension
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        logger.info("PostGIS extension enabled")

        # Create all tables
        await conn.run_sync(Base.metadata.create_all)
        logger.info("Database tables created")


async def check_db_connection() -> bool:
    """Check database connection."""
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        return True
    except Exception as e:
        logger.error(f"Database connection check failed: {e}")
        return False
