"""Structured JSON logging configuration."""

import logging
import sys
from contextvars import ContextVar
from typing import Any, Dict, Optional

from pythonjsonlogger import jsonlogger

# Context variable for request ID
request_id_ctx: ContextVar[Optional[str]] = ContextVar("request_id", default=None)


class RequestIdFilter(logging.Filter):
    """Filter that adds request_id to log records."""

    def filter(self, record: logging.LogRecord) -> bool:
        """Add request_id to the log record."""
        record.request_id = request_id_ctx.get()
        return True


class CustomJsonFormatter(jsonlogger.JsonFormatter):
    """Custom JSON formatter with additional fields."""

    def add_fields(
        self,
        log_record: Dict[str, Any],
        record: logging.LogRecord,
        message_dict: Dict[str, Any],
    ) -> None:
        """Add custom fields to log record."""
        super().add_fields(log_record, record, message_dict)

        # Add timestamp
        log_record["timestamp"] = self.formatTime(record)

        # Add log level
        log_record["level"] = record.levelname

        # Add logger name
        log_record["logger"] = record.name

        # Add request_id if present
        if hasattr(record, "request_id") and record.request_id:
            log_record["request_id"] = record.request_id

        # Add source location
        log_record["source"] = {
            "file": record.filename,
            "line": record.lineno,
            "function": record.funcName,
        }


def setup_logging(level: str = "INFO") -> None:
    """Configure structured JSON logging."""
    root_logger = logging.getLogger()
    root_logger.setLevel(level.upper())

    # Remove existing handlers
    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)

    # Create console handler with JSON formatter
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level.upper())

    # Use JSON formatter
    formatter = CustomJsonFormatter(
        fmt="%(timestamp)s %(level)s %(name)s %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S%z",
    )
    console_handler.setFormatter(formatter)

    # Add request ID filter
    console_handler.addFilter(RequestIdFilter())

    root_logger.addHandler(console_handler)

    # Reduce noise from third-party libraries
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    """Get a logger with the given name."""
    return logging.getLogger(name)


def set_request_id(request_id: Optional[str]) -> None:
    """Set the request ID in context."""
    request_id_ctx.set(request_id)


def get_request_id() -> Optional[str]:
    """Get the current request ID from context."""
    return request_id_ctx.get()
