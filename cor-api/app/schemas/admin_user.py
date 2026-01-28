"""Admin user Pydantic schemas."""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.schemas.common import BaseResponse


class AdminRole(str, Enum):
    """Admin user roles for RBAC."""

    ADMIN = "admin"
    COMUNICACAO = "comunicacao"
    VIEWER = "viewer"


class AdminUserBase(BaseModel):
    """Base admin user fields."""

    model_config = ConfigDict(populate_by_name=True)

    email: EmailStr = Field(..., description="User email (used for login)")
    name: str = Field(..., min_length=1, max_length=200, description="User full name")
    role: AdminRole = Field(default=AdminRole.VIEWER, description="User role for RBAC")


class AdminUserCreate(AdminUserBase):
    """Schema for creating a new admin user."""

    password: str = Field(..., min_length=8, max_length=128, description="Password")

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        """Validate password complexity."""
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not any(c.islower() for c in v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one digit")
        return v


class AdminUserUpdate(BaseModel):
    """Schema for updating an admin user."""

    model_config = ConfigDict(populate_by_name=True)

    name: Optional[str] = Field(default=None, max_length=200, description="User full name")
    role: Optional[AdminRole] = Field(default=None, description="User role")
    is_active: Optional[bool] = Field(default=None, description="Whether user is active")
    password: Optional[str] = Field(default=None, min_length=8, max_length=128, description="New password")

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: Optional[str]) -> Optional[str]:
        """Validate password complexity if provided."""
        if v is None:
            return v
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not any(c.islower() for c in v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one digit")
        return v


class AdminUser(AdminUserBase):
    """Admin user response schema."""

    id: str = Field(..., description="User ID")
    is_active: bool = Field(..., description="Whether user is active")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")
    last_login_at: Optional[datetime] = Field(default=None, description="Last login timestamp")


class AdminUserResponse(BaseResponse):
    """Single admin user response."""

    data: AdminUser


class AdminUserListResponse(BaseResponse):
    """Admin users list response."""

    data: List[AdminUser] = Field(default_factory=list)
    total: int = Field(default=0, description="Total number of users")


# ============================================================================
# Authentication Schemas
# ============================================================================


class LoginRequest(BaseModel):
    """Login request schema."""

    model_config = ConfigDict(populate_by_name=True)

    email: EmailStr = Field(..., description="User email")
    password: str = Field(..., description="Password")


class TokenResponse(BaseModel):
    """JWT token response."""

    model_config = ConfigDict(populate_by_name=True)

    access_token: str = Field(..., description="JWT access token")
    token_type: str = Field(default="bearer", description="Token type")
    expires_in: int = Field(..., description="Token expiration in seconds")
    user: AdminUser = Field(..., description="Authenticated user details")


class TokenPayload(BaseModel):
    """JWT token payload (decoded)."""

    sub: str = Field(..., description="Subject (user ID)")
    email: str = Field(..., description="User email")
    role: AdminRole = Field(..., description="User role")
    exp: datetime = Field(..., description="Expiration timestamp")
    iat: datetime = Field(..., description="Issued at timestamp")
