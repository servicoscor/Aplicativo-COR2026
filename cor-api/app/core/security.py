"""Security utilities - API key validation, rate limiting, and JWT authentication."""

import time
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from typing import Annotated, Callable, Dict, List, Optional

import bcrypt
import jwt
from fastapi import Depends, Header, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.errors import RateLimitExceeded, UnauthorizedError
from app.core.logging import get_logger

logger = get_logger(__name__)


# In-memory rate limiter storage
# TODO: Replace with Redis-based rate limiting for distributed deployments
_rate_limit_store: Dict[str, List[float]] = defaultdict(list)


def verify_api_key(
    x_api_key: Annotated[Optional[str], Header()] = None,
) -> bool:
    """
    Verify API key if authentication is enabled.

    Args:
        x_api_key: API key from request header

    Returns:
        True if authenticated or auth is disabled

    Raises:
        UnauthorizedError: If API key is invalid or missing when required
    """
    if not settings.api_key_enabled:
        return True

    if not x_api_key:
        logger.warning("Missing API key in request")
        raise UnauthorizedError(
            message="API key is required",
            details={"header": "X-API-Key"},
        )

    if x_api_key != settings.api_key:
        logger.warning("Invalid API key attempt")
        raise UnauthorizedError(
            message="Invalid API key",
        )

    return True


def check_rate_limit(request: Request) -> bool:
    """
    Check if request is within rate limits.

    Uses a sliding window algorithm with in-memory storage.

    TODO: Implement Redis-based rate limiting for production:
    - Use Redis sorted sets with timestamps
    - Key: f"rate_limit:{client_ip}"
    - ZADD with timestamp, ZREMRANGEBYSCORE to clean old entries
    - ZCARD to count requests in window

    Args:
        request: FastAPI request object

    Returns:
        True if within rate limits

    Raises:
        RateLimitExceeded: If rate limit is exceeded
    """
    # Get client identifier (IP address)
    client_ip = _get_client_ip(request)

    # Current timestamp
    now = time.time()

    # Window duration (1 minute)
    window_seconds = 60

    # Clean old entries
    cutoff = now - window_seconds
    _rate_limit_store[client_ip] = [
        ts for ts in _rate_limit_store[client_ip] if ts > cutoff
    ]

    # Check current count
    current_count = len(_rate_limit_store[client_ip])

    if current_count >= settings.rate_limit_per_minute:
        # Calculate retry-after
        oldest_request = min(_rate_limit_store[client_ip])
        retry_after = int(oldest_request + window_seconds - now) + 1

        logger.warning(
            "Rate limit exceeded",
            extra={
                "client_ip": client_ip,
                "count": current_count,
                "limit": settings.rate_limit_per_minute,
            },
        )

        raise RateLimitExceeded(
            message=f"Rate limit exceeded. Maximum {settings.rate_limit_per_minute} requests per minute.",
            retry_after=retry_after,
        )

    # Record this request
    _rate_limit_store[client_ip].append(now)

    return True


def _get_client_ip(request: Request) -> str:
    """
    Extract client IP address from request.

    Handles X-Forwarded-For header for proxied requests.

    Args:
        request: FastAPI request object

    Returns:
        Client IP address
    """
    # Check for forwarded header (behind proxy/load balancer)
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        # Take the first IP (original client)
        return forwarded_for.split(",")[0].strip()

    # Fall back to direct connection
    if request.client:
        return request.client.host

    return "unknown"


# Dependency for API key verification
ApiKeyDep = Annotated[bool, Depends(verify_api_key)]

# Dependency for rate limiting
RateLimitDep = Annotated[bool, Depends(check_rate_limit)]


# ============================================================================
# Password Hashing
# ============================================================================


def hash_password(password: str) -> str:
    """
    Hash a password using bcrypt.

    Args:
        password: Plain text password

    Returns:
        Hashed password string
    """
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a password against its hash.

    Args:
        plain_password: Plain text password to verify
        hashed_password: Bcrypt hash to verify against

    Returns:
        True if password matches, False otherwise
    """
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8"),
            hashed_password.encode("utf-8"),
        )
    except Exception as e:
        logger.error(f"Password verification error: {e}")
        return False


# ============================================================================
# JWT Token Operations
# ============================================================================


def create_access_token(
    user_id: str,
    email: str,
    role: str,
    expires_delta: Optional[timedelta] = None,
) -> tuple[str, datetime]:
    """
    Create a JWT access token.

    Args:
        user_id: User ID (subject)
        email: User email
        role: User role
        expires_delta: Optional custom expiration time

    Returns:
        Tuple of (token string, expiration datetime)
    """
    now = datetime.now(timezone.utc)
    expire = now + (expires_delta or timedelta(minutes=settings.jwt_access_token_expire_minutes))

    payload = {
        "sub": user_id,
        "email": email,
        "role": role,
        "iat": now,
        "exp": expire,
    }

    token = jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)
    return token, expire


def decode_access_token(token: str) -> dict:
    """
    Decode and validate a JWT access token.

    Args:
        token: JWT token string

    Returns:
        Decoded token payload

    Raises:
        UnauthorizedError: If token is invalid or expired
    """
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise UnauthorizedError(message="Token has expired")
    except jwt.InvalidTokenError as e:
        raise UnauthorizedError(message=f"Invalid token: {str(e)}")


# ============================================================================
# JWT Authentication Dependencies
# ============================================================================


async def get_current_admin_user(
    authorization: Annotated[Optional[str], Header()] = None,
):
    """
    Get current authenticated admin user from JWT token.

    This dependency extracts and validates the JWT token from the Authorization header.
    It returns the user data from the token payload.

    Note: This is a lightweight dependency that doesn't hit the database.
    For full user validation, use get_current_admin_user_from_db.

    Args:
        authorization: Authorization header value

    Returns:
        AdminUser schema instance

    Raises:
        UnauthorizedError: If token is missing, invalid, or expired
    """
    from app.schemas.admin_user import AdminRole, AdminUser

    if not authorization:
        raise UnauthorizedError(message="Authorization header is required")

    if not authorization.startswith("Bearer "):
        raise UnauthorizedError(message="Invalid authorization scheme. Use 'Bearer <token>'")

    token = authorization[7:]  # Remove "Bearer " prefix

    payload = decode_access_token(token)

    # Build user from token payload (lightweight, no DB hit)
    return AdminUser(
        id=payload["sub"],
        email=payload["email"],
        name=payload.get("name", payload["email"]),  # Fallback to email if name not in token
        role=AdminRole(payload["role"]),
        is_active=True,  # Assumed true if token is valid
        created_at=datetime.fromtimestamp(payload["iat"], tz=timezone.utc),
        updated_at=datetime.fromtimestamp(payload["iat"], tz=timezone.utc),
        last_login_at=None,
    )


async def get_current_admin_user_from_db(
    authorization: Annotated[Optional[str], Header()] = None,
    db: AsyncSession = None,
):
    """
    Get current authenticated admin user from database.

    This dependency validates the JWT and then loads the full user from the database.
    Use this when you need the latest user data or to verify the user still exists/is active.

    Args:
        authorization: Authorization header value
        db: Database session

    Returns:
        AdminUser schema instance with full data

    Raises:
        UnauthorizedError: If token is invalid, expired, or user not found/inactive
    """
    from app.models.admin_user import AdminUserModel
    from app.schemas.admin_user import AdminRole, AdminUser

    if not authorization:
        raise UnauthorizedError(message="Authorization header is required")

    if not authorization.startswith("Bearer "):
        raise UnauthorizedError(message="Invalid authorization scheme. Use 'Bearer <token>'")

    token = authorization[7:]
    payload = decode_access_token(token)

    # Load user from database
    stmt = select(AdminUserModel).where(AdminUserModel.id == payload["sub"])
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user:
        raise UnauthorizedError(message="User not found")

    if not user.is_active:
        raise UnauthorizedError(message="User account is disabled")

    return AdminUser(
        id=user.id,
        email=user.email,
        name=user.name,
        role=AdminRole(user.role),
        is_active=user.is_active,
        created_at=user.created_at,
        updated_at=user.updated_at,
        last_login_at=user.last_login_at,
    )


def require_role(allowed_roles: list) -> Callable:
    """
    Dependency factory for role-based access control.

    Creates a dependency that checks if the current user has one of the allowed roles.

    Args:
        allowed_roles: List of AdminRole values that are allowed

    Returns:
        Dependency function that validates user role

    Example:
        @router.post("/alerts")
        async def create_alert(
            current_user: Annotated[AdminUser, Depends(require_role([AdminRole.ADMIN, AdminRole.COMUNICACAO]))]
        ):
            ...
    """
    from app.schemas.admin_user import AdminUser

    async def role_checker(
        current_user: AdminUser = Depends(get_current_admin_user),
    ) -> AdminUser:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role '{current_user.role.value}' is not authorized for this action. Required: {[r.value for r in allowed_roles]}",
            )
        return current_user

    return role_checker


# Type alias for current admin user dependency
CurrentAdminUser = Annotated["AdminUser", Depends(get_current_admin_user)]
