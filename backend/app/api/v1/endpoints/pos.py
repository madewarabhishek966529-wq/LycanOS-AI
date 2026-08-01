import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentUser, require_role
from app.core.security import UserRole
from app.db.database import get_db
from app.repositories.coupon_repository import CouponRepository
from app.repositories.inventory_repository import ProductRepository
from app.repositories.invoice_repository import InvoiceRepository
from app.schemas.coupon import CouponCreate, CouponResponse
from app.schemas.pos import CheckoutRequest, InvoiceResponse
from app.services.pos_service import PosError, PosService

router = APIRouter(prefix="/pos")

# Billing is a Cashier-and-above responsibility — a generic Employee
# account (e.g. a stock clerk) isn't assumed to run the register.
CanBill = Depends(require_role(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER))
CanManageCoupons = Depends(require_role(UserRole.OWNER, UserRole.MANAGER))


def get_pos_service(db: AsyncSession = Depends(get_db)) -> PosService:
    return PosService(db, ProductRepository(db), InvoiceRepository(db), CouponRepository(db))


def get_coupon_repository(db: AsyncSession = Depends(get_db)) -> CouponRepository:
    return CouponRepository(db)


@router.post("/checkout", response_model=InvoiceResponse, status_code=201, dependencies=[CanBill])
async def checkout(
    payload: CheckoutRequest, current_user: CurrentUser, service: PosService = Depends(get_pos_service)
):
    try:
        return await service.checkout(
            business_id=current_user.business_id, cashier_id=current_user.id, request=payload
        )
    except PosError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get("/invoices", response_model=list[InvoiceResponse], dependencies=[CanBill])
async def list_invoices(
    current_user: CurrentUser,
    service: PosService = Depends(get_pos_service),
    limit: int = Query(default=50, le=200),
    offset: int = Query(default=0, ge=0),
):
    return await service.list_invoices(current_user.business_id, limit=limit, offset=offset)


@router.get("/invoices/{invoice_id}", response_model=InvoiceResponse, dependencies=[CanBill])
async def get_invoice(
    invoice_id: uuid.UUID, current_user: CurrentUser, service: PosService = Depends(get_pos_service)
):
    try:
        return await service.get_invoice_or_404(current_user.business_id, invoice_id)
    except PosError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get("/invoices/{invoice_id}/receipt", dependencies=[CanBill])
async def get_receipt(
    invoice_id: uuid.UUID, current_user: CurrentUser, service: PosService = Depends(get_pos_service)
):
    try:
        pdf_bytes = await service.get_receipt_pdf(current_user.business_id, invoice_id)
    except PosError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f"inline; filename=receipt-{invoice_id}.pdf"},
    )


# --- Coupons -----------------------------------------------------------
# Owner/Manager create and deactivate coupons; any billing-capable role
# (Cashier included) can list them, since a cashier needs to know which
# codes are currently valid to apply one at checkout.


@router.post("/coupons", response_model=CouponResponse, status_code=201, dependencies=[CanManageCoupons])
async def create_coupon(
    payload: CouponCreate, current_user: CurrentUser, repo: CouponRepository = Depends(get_coupon_repository)
):
    existing = await repo.get_by_code(current_user.business_id, payload.code)
    if existing is not None:
        raise HTTPException(status_code=409, detail=f"Coupon code '{payload.code}' already exists")
    return await repo.create(current_user.business_id, **payload.model_dump())


@router.get("/coupons", response_model=list[CouponResponse], dependencies=[CanBill])
async def list_coupons(current_user: CurrentUser, repo: CouponRepository = Depends(get_coupon_repository)):
    return await repo.list_for_business(current_user.business_id)


@router.post("/coupons/{code}/deactivate", response_model=CouponResponse, dependencies=[CanManageCoupons])
async def deactivate_coupon(
    code: str, current_user: CurrentUser, repo: CouponRepository = Depends(get_coupon_repository)
):
    coupon = await repo.get_by_code(current_user.business_id, code)
    if coupon is None:
        raise HTTPException(status_code=404, detail="Coupon not found")
    return await repo.deactivate(coupon)
