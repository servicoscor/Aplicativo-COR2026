#!/usr/bin/env python3
"""Script to reset admin password."""

import asyncio
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.core.security import hash_password
from app.models.admin_user import AdminUserModel


async def reset_password(email: str, new_password: str):
    """Reset password for an admin user."""
    database_url = os.environ.get(
        "DATABASE_URL",
        "postgresql+asyncpg://cor:cor123@localhost:5432/cor_db"
    )

    engine = create_async_engine(database_url, echo=True)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # Find user
        stmt = select(AdminUserModel).where(
            func.lower(AdminUserModel.email) == email.lower()
        )
        result = await session.execute(stmt)
        user = result.scalar_one_or_none()

        if not user:
            print(f"User not found: {email}")
            return False

        # Update password
        user.password_hash = hash_password(new_password)
        await session.commit()

        print(f"Password updated for {email}")
        return True


if __name__ == "__main__":
    email = sys.argv[1] if len(sys.argv) > 1 else "admin@cor.rio.gov.br"
    password = sys.argv[2] if len(sys.argv) > 2 else "Admin123!"

    print(f"Resetting password for: {email}")
    asyncio.run(reset_password(email, password))
