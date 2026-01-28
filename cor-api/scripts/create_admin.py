#!/usr/bin/env python3
"""Script to create initial admin user.

Usage:
    python scripts/create_admin.py

Or with custom credentials:
    python scripts/create_admin.py --email admin@cor.rio.gov.br --password MySecurePass123 --name "Admin User"

Environment variables can also be used:
    ADMIN_SEED_EMAIL=admin@cor.rio.gov.br
    ADMIN_SEED_PASSWORD=MySecurePass123
"""

import argparse
import asyncio
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

from app.core.config import settings
from app.core.security import hash_password
from app.models.admin_user import AdminUserModel
from app.models.base import Base


async def create_admin_user(
    email: str,
    password: str,
    name: str = "Admin",
    role: str = "admin",
) -> bool:
    """
    Create an admin user in the database.

    Args:
        email: Admin email
        password: Admin password
        name: Admin name
        role: Admin role (admin, comunicacao, viewer)

    Returns:
        True if user was created, False if already exists
    """
    # Create async engine
    engine = create_async_engine(
        settings.database_url,
        echo=False,
    )

    # Create session factory
    async_session = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )

    async with async_session() as session:
        # Check if user already exists
        stmt = select(AdminUserModel).where(
            func.lower(AdminUserModel.email) == email.lower()
        )
        result = await session.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            print(f"User with email '{email}' already exists.")
            return False

        # Create user
        from uuid import uuid4

        user = AdminUserModel(
            id=str(uuid4()),
            email=email.lower(),
            name=name,
            password_hash=hash_password(password),
            role=role,
            is_active=True,
        )

        session.add(user)
        await session.commit()

        print(f"Admin user created successfully!")
        print(f"  Email: {email}")
        print(f"  Name: {name}")
        print(f"  Role: {role}")
        print(f"  ID: {user.id}")

        return True

    await engine.dispose()


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Create initial admin user for COR Admin panel.",
    )
    parser.add_argument(
        "--email",
        default=settings.admin_seed_email or "admin@cor.rio.gov.br",
        help="Admin email address",
    )
    parser.add_argument(
        "--password",
        default=settings.admin_seed_password,
        help="Admin password (min 8 chars, must include uppercase, lowercase, and digit)",
    )
    parser.add_argument(
        "--name",
        default="Administrador COR",
        help="Admin full name",
    )
    parser.add_argument(
        "--role",
        default="admin",
        choices=["admin", "comunicacao", "viewer"],
        help="Admin role",
    )

    args = parser.parse_args()

    # Validate password
    if not args.password:
        print("Error: Password is required.")
        print("Use --password argument or set ADMIN_SEED_PASSWORD environment variable.")
        sys.exit(1)

    if len(args.password) < 8:
        print("Error: Password must be at least 8 characters.")
        sys.exit(1)

    if not any(c.isupper() for c in args.password):
        print("Error: Password must contain at least one uppercase letter.")
        sys.exit(1)

    if not any(c.islower() for c in args.password):
        print("Error: Password must contain at least one lowercase letter.")
        sys.exit(1)

    if not any(c.isdigit() for c in args.password):
        print("Error: Password must contain at least one digit.")
        sys.exit(1)

    # Run async function
    try:
        asyncio.run(
            create_admin_user(
                email=args.email,
                password=args.password,
                name=args.name,
                role=args.role,
            )
        )
    except Exception as e:
        print(f"Error creating admin user: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
