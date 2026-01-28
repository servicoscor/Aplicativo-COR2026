"""FastAPI application entry point."""

import time
import uuid
from contextlib import asynccontextmanager
from typing import Any, AsyncGenerator

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app import __version__
from app.api.v1 import api_router
from app.core.config import settings
from app.core.errors import AppException
from app.core.logging import get_logger, set_request_id, setup_logging
from app.db.init_db import check_db_connection, init_db
from app.services.cache_service import get_cache_service

# Setup logging
setup_logging(settings.log_level)
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """
    Application lifespan handler.

    Handles startup and shutdown events.
    """
    # Startup
    logger.info(f"Starting COR API v{__version__}")
    logger.info(f"Environment: {settings.environment}")

    # Initialize database
    try:
        if await check_db_connection():
            await init_db()
            logger.info("Database initialized successfully")
        else:
            logger.warning("Database connection not available")
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")

    # Initialize cache
    try:
        cache = await get_cache_service()
        if await cache.health_check():
            logger.info("Redis cache connected")
        else:
            logger.warning("Redis cache not available")
    except Exception as e:
        logger.error(f"Redis initialization failed: {e}")

    logger.info("COR API startup complete")

    yield

    # Shutdown
    logger.info("Shutting down COR API")

    # Cleanup cache connection
    try:
        cache = await get_cache_service()
        await cache.disconnect()
    except Exception:
        pass

    logger.info("COR API shutdown complete")


# Create FastAPI application
app = FastAPI(
    title=settings.app_name,
    description="API unificada do Centro de Operações Rio (COR) para dados de cidade: meteorologia, radar, pluviometria e ocorrências.",
    version=__version__,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def request_middleware(request: Request, call_next: Any) -> Response:
    """
    Middleware for request processing.

    Adds request ID, measures latency, and handles errors.
    """
    # Generate request ID
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
    set_request_id(request_id)

    # Start timing
    start_time = time.perf_counter()

    try:
        response = await call_next(request)

        # Calculate latency
        latency_ms = (time.perf_counter() - start_time) * 1000

        # Add headers
        response.headers["X-Request-ID"] = request_id
        response.headers["X-Response-Time-Ms"] = f"{latency_ms:.2f}"

        # Log request
        logger.info(
            f"{request.method} {request.url.path} - {response.status_code} ({latency_ms:.2f}ms)",
            extra={
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "latency_ms": latency_ms,
            },
        )

        return response

    except Exception as e:
        # Calculate latency
        latency_ms = (time.perf_counter() - start_time) * 1000

        logger.error(
            f"Unhandled error: {e}",
            extra={
                "method": request.method,
                "path": request.url.path,
                "latency_ms": latency_ms,
            },
        )
        raise


@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
    """Handle application exceptions."""
    return JSONResponse(
        status_code=exc.status_code,
        content=exc.to_dict(),
        headers={"X-Request-ID": request.headers.get("X-Request-ID", "")},
    )


@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Handle unexpected exceptions."""
    logger.error(f"Unexpected error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": {
                "code": "INTERNAL_ERROR",
                "message": "An unexpected error occurred",
                "details": {} if settings.is_production else {"error": str(exc)},
            }
        },
        headers={"X-Request-ID": request.headers.get("X-Request-ID", "")},
    )


# Include API routes
app.include_router(api_router, prefix="/v1")


@app.get("/", include_in_schema=False)
async def root() -> dict[str, str]:
    """Root endpoint - API info."""
    return {
        "name": settings.app_name,
        "version": __version__,
        "docs": "/docs",
        "health": "/v1/health",
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.is_development,
        log_level=settings.log_level.lower(),
    )
