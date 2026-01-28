"""Admin authentication endpoints."""

from typing import Annotated

from fastapi import APIRouter, Depends, Request

from app.core.security import RateLimitDep, get_current_admin_user
from app.db.session import get_db
from app.schemas.admin_user import (
    AdminUser,
    AdminUserResponse,
    LoginRequest,
    TokenResponse,
)
from app.services.admin_user_service import AdminUserService
from app.services.audit_service import AuditService
from app.schemas.audit_log import AuditAction, AuditResource
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter()

DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[AdminUser, Depends(get_current_admin_user)]


def _get_client_ip(request: Request) -> str:
    """Extract client IP from request."""
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    if request.client:
        return request.client.host
    return "unknown"


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Admin Login",
    description="Authenticate admin user with email and password. Returns JWT access token.",
)
async def login(
    data: LoginRequest,
    request: Request,
    db: DbSession,
    _rate_limit: RateLimitDep = True,
) -> TokenResponse:
    """
    Authenticate admin user and return JWT token.

    - **email**: Admin user email
    - **password**: Admin user password

    Returns access token valid for 8 hours.
    """
    user_service = AdminUserService(db)
    audit_service = AuditService(db)

    try:
        result = await user_service.authenticate(data)

        # Log successful login
        await audit_service.log_action(
            action=AuditAction.LOGIN,
            resource=AuditResource.AUTH,
            user=result.user,
            ip_address=_get_client_ip(request),
            user_agent=request.headers.get("User-Agent"),
            payload_summary={"email": data.email},
        )

        return result

    except Exception as e:
        # Log failed login attempt
        await audit_service.log_action(
            action=AuditAction.LOGIN_FAILED,
            resource=AuditResource.AUTH,
            ip_address=_get_client_ip(request),
            user_agent=request.headers.get("User-Agent"),
            payload_summary={"email": data.email, "error": str(e)},
        )
        raise


@router.get(
    "/me",
    response_model=AdminUserResponse,
    summary="Get Current User",
    description="Get details of the currently authenticated admin user.",
)
async def get_me(
    current_user: CurrentUser,
    db: DbSession,
) -> AdminUserResponse:
    """
    Get current authenticated user details.

    Requires valid JWT token in Authorization header.
    """
    # Refresh user data from database
    user_service = AdminUserService(db)
    user = await user_service.get_user(current_user.id)

    return AdminUserResponse(
        success=True,
        data=user,
    )


@router.post(
    "/refresh",
    response_model=TokenResponse,
    summary="Refresh Token",
    description="Get a new access token using the current valid token.",
)
async def refresh_token(
    current_user: CurrentUser,
    db: DbSession,
) -> TokenResponse:
    """
    Refresh access token.

    Returns a new token with extended expiration.
    Requires valid JWT token in Authorization header.
    """
    from datetime import datetime, timezone
    from app.core.security import create_access_token
    from app.core.config import settings

    # Create new token
    access_token, expires = create_access_token(
        user_id=current_user.id,
        email=current_user.email,
        role=current_user.role.value,
    )

    expires_in = int((expires - datetime.now(timezone.utc)).total_seconds())

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=expires_in,
        user=current_user,
    )
