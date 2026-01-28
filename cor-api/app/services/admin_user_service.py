"""Admin user service for authentication and user management."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, List, Optional, Tuple
from uuid import uuid4

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError, UnauthorizedError, ValidationError
from app.core.logging import get_logger
from app.core.security import create_access_token, hash_password, verify_password
from app.models.admin_user import AdminUserModel
from app.schemas.admin_user import (
    AdminRole,
    AdminUser,
    AdminUserCreate,
    AdminUserUpdate,
    LoginRequest,
    TokenResponse,
)

logger = get_logger(__name__)


class AdminUserService:
    """Service for admin user operations."""

    def __init__(self, db: AsyncSession):
        """Initialize service with database session."""
        self.db = db

    async def authenticate(self, data: LoginRequest) -> TokenResponse:
        """
        Authenticate user and return JWT token.

        Args:
            data: Login credentials

        Returns:
            TokenResponse with access token and user details

        Raises:
            UnauthorizedError: If credentials are invalid
        """
        # Find user by email
        stmt = select(AdminUserModel).where(
            func.lower(AdminUserModel.email) == data.email.lower()
        )
        result = await self.db.execute(stmt)
        user = result.scalar_one_or_none()

        if not user:
            logger.warning(f"Login attempt with unknown email: {data.email}")
            raise UnauthorizedError(message="Invalid email or password")

        if not user.is_active:
            logger.warning(f"Login attempt for disabled user: {data.email}")
            raise UnauthorizedError(message="Account is disabled")

        # Verify password
        if not verify_password(data.password, user.password_hash):
            logger.warning(f"Invalid password for user: {data.email}")
            raise UnauthorizedError(message="Invalid email or password")

        # Update last login
        user.last_login_at = datetime.now(timezone.utc)
        await self.db.commit()

        # Create access token
        from app.core.config import settings

        access_token, expires = create_access_token(
            user_id=user.id,
            email=user.email,
            role=user.role,
        )

        # Calculate expires_in seconds
        expires_in = int((expires - datetime.now(timezone.utc)).total_seconds())

        logger.info(f"User logged in: {user.email}")

        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            expires_in=expires_in,
            user=AdminUser(
                id=user.id,
                email=user.email,
                name=user.name,
                role=AdminRole(user.role),
                is_active=user.is_active,
                created_at=user.created_at,
                updated_at=user.updated_at,
                last_login_at=user.last_login_at,
            ),
        )

    async def create_user(self, data: AdminUserCreate) -> AdminUser:
        """
        Create a new admin user.

        Args:
            data: User creation data

        Returns:
            Created user

        Raises:
            ValidationError: If email already exists
        """
        # Check if email exists
        stmt = select(AdminUserModel).where(
            func.lower(AdminUserModel.email) == data.email.lower()
        )
        result = await self.db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            raise ValidationError(
                message="Email already registered",
                field="email",
            )

        # Create user
        user = AdminUserModel(
            id=str(uuid4()),
            email=data.email.lower(),
            name=data.name,
            password_hash=hash_password(data.password),
            role=data.role.value,
            is_active=True,
        )

        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)

        logger.info(f"Admin user created: {user.email} (role: {user.role})")

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

    async def get_user(self, user_id: str) -> AdminUser:
        """
        Get user by ID.

        Args:
            user_id: User ID

        Returns:
            User data

        Raises:
            NotFoundError: If user not found
        """
        stmt = select(AdminUserModel).where(AdminUserModel.id == user_id)
        result = await self.db.execute(stmt)
        user = result.scalar_one_or_none()

        if not user:
            raise NotFoundError(
                message="User not found",
                resource="AdminUser",
                resource_id=user_id,
            )

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

    async def get_user_by_email(self, email: str) -> Optional[AdminUser]:
        """
        Get user by email.

        Args:
            email: User email

        Returns:
            User data or None if not found
        """
        stmt = select(AdminUserModel).where(
            func.lower(AdminUserModel.email) == email.lower()
        )
        result = await self.db.execute(stmt)
        user = result.scalar_one_or_none()

        if not user:
            return None

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

    async def list_users(
        self,
        limit: int = 50,
        offset: int = 0,
        role: Optional[AdminRole] = None,
        is_active: Optional[bool] = None,
    ) -> Tuple[List[AdminUser], int]:
        """
        List admin users with optional filtering.

        Args:
            limit: Maximum number of users to return
            offset: Number of users to skip
            role: Filter by role
            is_active: Filter by active status

        Returns:
            Tuple of (users list, total count)
        """
        # Base query
        stmt = select(AdminUserModel)

        # Apply filters
        if role is not None:
            stmt = stmt.where(AdminUserModel.role == role.value)
        if is_active is not None:
            stmt = stmt.where(AdminUserModel.is_active == is_active)

        # Count total
        count_stmt = select(func.count()).select_from(stmt.subquery())
        count_result = await self.db.execute(count_stmt)
        total = count_result.scalar() or 0

        # Apply pagination and ordering
        stmt = stmt.order_by(AdminUserModel.created_at.desc())
        stmt = stmt.offset(offset).limit(limit)

        result = await self.db.execute(stmt)
        users = result.scalars().all()

        return (
            [
                AdminUser(
                    id=u.id,
                    email=u.email,
                    name=u.name,
                    role=AdminRole(u.role),
                    is_active=u.is_active,
                    created_at=u.created_at,
                    updated_at=u.updated_at,
                    last_login_at=u.last_login_at,
                )
                for u in users
            ],
            total,
        )

    async def update_user(self, user_id: str, data: AdminUserUpdate) -> AdminUser:
        """
        Update an admin user.

        Args:
            user_id: User ID
            data: Update data

        Returns:
            Updated user

        Raises:
            NotFoundError: If user not found
        """
        stmt = select(AdminUserModel).where(AdminUserModel.id == user_id)
        result = await self.db.execute(stmt)
        user = result.scalar_one_or_none()

        if not user:
            raise NotFoundError(
                message="User not found",
                resource="AdminUser",
                resource_id=user_id,
            )

        # Update fields
        if data.name is not None:
            user.name = data.name
        if data.role is not None:
            user.role = data.role.value
        if data.is_active is not None:
            user.is_active = data.is_active
        if data.password is not None:
            user.password_hash = hash_password(data.password)

        await self.db.commit()
        await self.db.refresh(user)

        logger.info(f"Admin user updated: {user.email}")

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

    async def delete_user(self, user_id: str) -> None:
        """
        Delete an admin user.

        Args:
            user_id: User ID

        Raises:
            NotFoundError: If user not found
        """
        stmt = select(AdminUserModel).where(AdminUserModel.id == user_id)
        result = await self.db.execute(stmt)
        user = result.scalar_one_or_none()

        if not user:
            raise NotFoundError(
                message="User not found",
                resource="AdminUser",
                resource_id=user_id,
            )

        await self.db.delete(user)
        await self.db.commit()

        logger.info(f"Admin user deleted: {user.email}")
