import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.coupon import Coupon


class CouponRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, business_id: uuid.UUID, **fields) -> Coupon:
        coupon = Coupon(business_id=business_id, **fields)
        self.db.add(coupon)
        await self.db.commit()
        await self.db.refresh(coupon)
        return coupon

    async def list_for_business(self, business_id: uuid.UUID) -> list[Coupon]:
        result = await self.db.execute(
            select(Coupon).where(Coupon.business_id == business_id).order_by(Coupon.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_by_code(self, business_id: uuid.UUID, code: str) -> Coupon | None:
        result = await self.db.execute(
            select(Coupon).where(Coupon.business_id == business_id, Coupon.code == code.upper())
        )
        return result.scalar_one_or_none()

    async def deactivate(self, coupon: Coupon) -> Coupon:
        coupon.is_active = False
        await self.db.commit()
        await self.db.refresh(coupon)
        return coupon
