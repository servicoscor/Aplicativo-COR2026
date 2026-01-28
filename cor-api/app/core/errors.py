"""Custom exceptions for the application."""

from typing import Any, Dict, Optional


class AppException(Exception):
    """Base exception for application errors."""

    def __init__(
        self,
        message: str,
        code: str = "INTERNAL_ERROR",
        status_code: int = 500,
        details: Optional[Dict[str, Any]] = None,
    ) -> None:
        self.message = message
        self.code = code
        self.status_code = status_code
        self.details = details or {}
        super().__init__(message)

    def to_dict(self) -> Dict[str, Any]:
        """Convert exception to dictionary."""
        return {
            "error": {
                "code": self.code,
                "message": self.message,
                "details": self.details,
            }
        }


class ProviderException(AppException):
    """Exception raised when a provider fails."""

    def __init__(
        self,
        message: str,
        provider: str,
        code: str = "PROVIDER_ERROR",
        status_code: int = 502,
        details: Optional[Dict[str, Any]] = None,
    ) -> None:
        details = details or {}
        details["provider"] = provider
        super().__init__(message, code, status_code, details)
        self.provider = provider


class CacheException(AppException):
    """Exception raised when cache operations fail."""

    def __init__(
        self,
        message: str,
        operation: str = "unknown",
        code: str = "CACHE_ERROR",
        status_code: int = 500,
        details: Optional[Dict[str, Any]] = None,
    ) -> None:
        details = details or {}
        details["operation"] = operation
        super().__init__(message, code, status_code, details)
        self.operation = operation


class ValidationException(AppException):
    """Exception raised when validation fails."""

    def __init__(
        self,
        message: str,
        field: Optional[str] = None,
        code: str = "VALIDATION_ERROR",
        status_code: int = 422,
        details: Optional[Dict[str, Any]] = None,
    ) -> None:
        details = details or {}
        if field:
            details["field"] = field
        super().__init__(message, code, status_code, details)
        self.field = field


class NotFoundError(AppException):
    """Exception raised when a resource is not found."""

    def __init__(
        self,
        message: str = "Resource not found",
        resource: Optional[str] = None,
        code: str = "NOT_FOUND",
        status_code: int = 404,
        details: Optional[Dict[str, Any]] = None,
    ) -> None:
        details = details or {}
        if resource:
            details["resource"] = resource
        super().__init__(message, code, status_code, details)
        self.resource = resource


class RateLimitExceeded(AppException):
    """Exception raised when rate limit is exceeded."""

    def __init__(
        self,
        message: str = "Rate limit exceeded",
        retry_after: int = 60,
        code: str = "RATE_LIMIT_EXCEEDED",
        status_code: int = 429,
        details: Optional[Dict[str, Any]] = None,
    ) -> None:
        details = details or {}
        details["retry_after"] = retry_after
        super().__init__(message, code, status_code, details)
        self.retry_after = retry_after


class UnauthorizedError(AppException):
    """Exception raised when authentication fails."""

    def __init__(
        self,
        message: str = "Unauthorized",
        code: str = "UNAUTHORIZED",
        status_code: int = 401,
        details: Optional[Dict[str, Any]] = None,
    ) -> None:
        super().__init__(message, code, status_code, details)


class ValidationError(AppException):
    """Exception raised when validation fails (alias for ValidationException)."""

    def __init__(
        self,
        message: str,
        field: Optional[str] = None,
        code: str = "VALIDATION_ERROR",
        status_code: int = 422,
        details: Optional[Dict[str, Any]] = None,
    ) -> None:
        details = details or {}
        if field:
            details["field"] = field
        super().__init__(message, code, status_code, details)
        self.field = field
