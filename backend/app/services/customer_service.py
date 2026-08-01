import uuid
from decimal import Decimal

from app.models.customer import Customer
from app.repositories.customer_repository import CustomerRepository

# 1 loyalty point per ₹100 spent — a simple, transparent default. Making
# this configurable per business is a Settings-phase feature; hardcoding
# an honest, documented rule now beats a fake "customizable" toggle that
# doesn't actually persist anywhere yet.
LOYALTY_POINTS_PER_RUPEE_SPENT = Decimal("100")


class CustomerError(Exception):
    def __init__(self, message: str, status_code: int = 400):
        self.message = message
        self.status_code = status_code
        super().__init__(message)


class CustomerService:
    def __init__(self, customer_repo: CustomerRepository):
        self.customer_repo = customer_repo

    async def create_customer(self, business_id: uuid.UUID, **fields) -> Customer:
        return await self.customer_repo.create(business_id, **fields)

    async def get_customer_or_404(self, business_id: uuid.UUID, customer_id: uuid.UUID) -> Customer:
        customer = await self.customer_repo.get_by_id(business_id, customer_id)
        if customer is None:
            raise CustomerError("Customer not found", status_code=404)
        return customer

    async def list_customers(self, business_id: uuid.UUID, *, search: str | None = None) -> list[Customer]:
        return await self.customer_repo.list_for_business(business_id, search=search)

    async def update_customer(self, business_id: uuid.UUID, customer_id: uuid.UUID, **fields) -> Customer:
        customer = await self.get_customer_or_404(business_id, customer_id)
        return await self.customer_repo.update(customer, **fields)

    async def delete_customer(self, business_id: uuid.UUID, customer_id: uuid.UUID) -> None:
        customer = await self.get_customer_or_404(business_id, customer_id)
        await self.customer_repo.delete(customer)

    async def repay_credit(self, business_id: uuid.UUID, customer_id: uuid.UUID, amount: Decimal) -> Customer:
        customer = await self.get_customer_or_404(business_id, customer_id)
        if amount > customer.credit_balance:
            raise CustomerError(
                f"Repayment of ₹{amount} exceeds the outstanding balance of ₹{customer.credit_balance}"
            )
        return await self.customer_repo.adjust_credit_balance(customer, -amount)

    def calculate_loyalty_points(self, sale_total: Decimal) -> int:
        return int(sale_total // LOYALTY_POINTS_PER_RUPEE_SPENT)
