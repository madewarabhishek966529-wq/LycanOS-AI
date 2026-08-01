import uuid
from decimal import Decimal

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.customer import Customer


class CustomerRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, business_id: uuid.UUID, **fields) -> Customer:
        customer = Customer(business_id=business_id, **fields)
        self.db.add(customer)
        await self.db.commit()
        await self.db.refresh(customer)
        return customer

    async def get_by_id(self, business_id: uuid.UUID, customer_id: uuid.UUID) -> Customer | None:
        result = await self.db.execute(
            select(Customer).where(Customer.id == customer_id, Customer.business_id == business_id)
        )
        return result.scalar_one_or_none()

    async def list_for_business(self, business_id: uuid.UUID, *, search: str | None = None) -> list[Customer]:
        query = select(Customer).where(Customer.business_id == business_id)
        if search:
            like = f"%{search.lower()}%"
            query = query.where(
                or_(Customer.name.ilike(like), Customer.phone.ilike(like), Customer.email.ilike(like))
            )
        query = query.order_by(Customer.name)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def update(self, customer: Customer, **fields) -> Customer:
        for key, value in fields.items():
            if value is not None:
                setattr(customer, key, value)
        await self.db.commit()
        await self.db.refresh(customer)
        return customer

    async def delete(self, customer: Customer) -> None:
        await self.db.delete(customer)
        await self.db.commit()

    async def add_loyalty_points(self, customer: Customer, points: int) -> Customer:
        customer.loyalty_points += points
        await self.db.commit()
        await self.db.refresh(customer)
        return customer

    async def adjust_credit_balance(self, customer: Customer, delta: Decimal) -> Customer:
        customer.credit_balance += delta
        await self.db.commit()
        await self.db.refresh(customer)
        return customer
