"""
Data-access layer for User. AuthService (business logic, password
hashing, token issuing) depends on this repository rather than touching
`AsyncSession` queries directly, so the query logic is unit-testable and
reusable from other services later (e.g. Employee Management in Phase 7
will read Users through this same repository).
"""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.business import Business
from app.models.user import User


class UserRepository:
    def __init__(self, db: AsyncSession):
        self._db = db

    async def get_by_email(self, email: str) -> User | None:
        result = await self._db.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def get_by_id(self, user_id: uuid.UUID) -> User | None:
        result = await self._db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_by_id_in_business(self, business_id: uuid.UUID, user_id: uuid.UUID) -> User | None:
        result = await self._db.execute(
            select(User).where(User.id == user_id, User.business_id == business_id)
        )
        return result.scalar_one_or_none()

    async def list_for_business(self, business_id: uuid.UUID) -> list[User]:
        result = await self._db.execute(
            select(User).where(User.business_id == business_id).order_by(User.full_name)
        )
        return list(result.scalars().all())

    async def count_active_owners(self, business_id: uuid.UUID) -> int:
        from app.core.security import UserRole

        result = await self._db.execute(
            select(User).where(
                User.business_id == business_id, User.role == UserRole.OWNER, User.is_active.is_(True)
            )
        )
        return len(result.scalars().all())

    async def get_by_reset_token(self, reset_token: str) -> User | None:
        result = await self._db.execute(select(User).where(User.reset_token == reset_token))
        return result.scalar_one_or_none()

    async def create(self, user: User) -> User:
        self._db.add(user)
        await self._db.flush()
        await self._db.refresh(user)
        return user

    async def update(self, user: User) -> User:
        await self._db.flush()
        await self._db.refresh(user)
        return user


class BusinessRepository:
    def __init__(self, db: AsyncSession):
        self._db = db

    async def create(self, business: Business) -> Business:
        self._db.add(business)
        await self._db.flush()
        await self._db.refresh(business)
        return business
