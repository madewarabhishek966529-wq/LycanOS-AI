import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentUser, require_role
from app.core.security import UserRole
from app.db.database import get_db
from app.repositories.customer_repository import CustomerRepository
from app.repositories.invoice_repository import InvoiceRepository
from app.schemas.customer import CreditRepayment, CustomerCreate, CustomerResponse, CustomerUpdate
from app.schemas.pos import InvoiceResponse
from app.services.customer_service import CustomerError, CustomerService

router = APIRouter(prefix="/customers")

# Owner/Manager manage customer profiles and credit repayments; Cashier
# needs read access to attach a customer at checkout, so reads are open to
# any billing-capable role (matching the CanBill group from Phase 4)
# rather than the stricter management group.
CanManageCustomers = Depends(require_role(UserRole.OWNER, UserRole.MANAGER))
CanViewCustomers = Depends(require_role(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER))


def get_customer_service(db: AsyncSession = Depends(get_db)) -> CustomerService:
    return CustomerService(CustomerRepository(db))


def get_invoice_repository(db: AsyncSession = Depends(get_db)) -> InvoiceRepository:
    return InvoiceRepository(db)


@router.post("", response_model=CustomerResponse, status_code=201, dependencies=[CanManageCustomers])
async def create_customer(
    payload: CustomerCreate, current_user: CurrentUser, service: CustomerService = Depends(get_customer_service)
):
    return await service.create_customer(current_user.business_id, **payload.model_dump())


@router.get("", response_model=list[CustomerResponse], dependencies=[CanViewCustomers])
async def list_customers(
    current_user: CurrentUser,
    service: CustomerService = Depends(get_customer_service),
    search: str | None = Query(default=None),
):
    return await service.list_customers(current_user.business_id, search=search)


@router.get("/{customer_id}", response_model=CustomerResponse, dependencies=[CanViewCustomers])
async def get_customer(
    customer_id: uuid.UUID, current_user: CurrentUser, service: CustomerService = Depends(get_customer_service)
):
    try:
        return await service.get_customer_or_404(current_user.business_id, customer_id)
    except CustomerError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.patch("/{customer_id}", response_model=CustomerResponse, dependencies=[CanManageCustomers])
async def update_customer(
    customer_id: uuid.UUID,
    payload: CustomerUpdate,
    current_user: CurrentUser,
    service: CustomerService = Depends(get_customer_service),
):
    try:
        return await service.update_customer(
            current_user.business_id, customer_id, **payload.model_dump(exclude_unset=True)
        )
    except CustomerError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.delete("/{customer_id}", status_code=204, dependencies=[CanManageCustomers])
async def delete_customer(
    customer_id: uuid.UUID, current_user: CurrentUser, service: CustomerService = Depends(get_customer_service)
):
    try:
        await service.delete_customer(current_user.business_id, customer_id)
    except CustomerError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post("/{customer_id}/repay-credit", response_model=CustomerResponse, dependencies=[CanViewCustomers])
async def repay_credit(
    customer_id: uuid.UUID,
    payload: CreditRepayment,
    current_user: CurrentUser,
    service: CustomerService = Depends(get_customer_service),
):
    try:
        return await service.repay_credit(current_user.business_id, customer_id, payload.amount)
    except CustomerError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get("/{customer_id}/purchases", response_model=list[InvoiceResponse], dependencies=[CanViewCustomers])
async def get_purchase_history(
    customer_id: uuid.UUID,
    current_user: CurrentUser,
    customer_service: CustomerService = Depends(get_customer_service),
    invoice_repo: InvoiceRepository = Depends(get_invoice_repository),
):
    try:
        await customer_service.get_customer_or_404(current_user.business_id, customer_id)
    except CustomerError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)

    return await invoice_repo.list_for_customer(current_user.business_id, customer_id)
