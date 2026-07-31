import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentUser, require_role
from app.core.security import UserRole
from app.db.database import get_db
from app.repositories.inventory_repository import CategoryRepository, ProductRepository, SupplierRepository
from app.schemas.inventory import (
    CategoryCreate,
    CategoryResponse,
    CategoryUpdate,
    SupplierCreate,
    SupplierResponse,
    SupplierUpdate,
)
from app.schemas.product import ProductCreate, ProductResponse, ProductUpdate, StockAdjustment
from app.services.inventory_service import InventoryError, InventoryService

router = APIRouter(prefix="/inventory")

# Owner + Manager can create/edit/delete catalog data; every authenticated
# role (including Cashier/Employee) can read it — a cashier needs to see
# products to sell them, just not to redefine pricing.
CanManageInventory = Depends(require_role(UserRole.OWNER, UserRole.MANAGER))


def get_inventory_service(db: AsyncSession = Depends(get_db)) -> InventoryService:
    return InventoryService(CategoryRepository(db), SupplierRepository(db), ProductRepository(db))


def _raise(error: InventoryError):
    raise HTTPException(status_code=error.status_code, detail=error.message)


# --- Categories -------------------------------------------------------


@router.post("/categories", response_model=CategoryResponse, status_code=201, dependencies=[CanManageInventory])
async def create_category(
    payload: CategoryCreate, current_user: CurrentUser, service: InventoryService = Depends(get_inventory_service)
):
    return await service.create_category(current_user.business_id, payload.name, payload.description)


@router.get("/categories", response_model=list[CategoryResponse])
async def list_categories(current_user: CurrentUser, service: InventoryService = Depends(get_inventory_service)):
    return await service.list_categories(current_user.business_id)


@router.patch("/categories/{category_id}", response_model=CategoryResponse, dependencies=[CanManageInventory])
async def update_category(
    category_id: uuid.UUID,
    payload: CategoryUpdate,
    current_user: CurrentUser,
    service: InventoryService = Depends(get_inventory_service),
):
    try:
        category = await service.get_category_or_404(current_user.business_id, category_id)
        return await service.category_repo.update(category, **payload.model_dump(exclude_unset=True))
    except InventoryError as e:
        _raise(e)


@router.delete("/categories/{category_id}", status_code=204, dependencies=[CanManageInventory])
async def delete_category(
    category_id: uuid.UUID, current_user: CurrentUser, service: InventoryService = Depends(get_inventory_service)
):
    try:
        await service.delete_category(current_user.business_id, category_id)
    except InventoryError as e:
        _raise(e)


# --- Suppliers ----------------------------------------------------------


@router.post("/suppliers", response_model=SupplierResponse, status_code=201, dependencies=[CanManageInventory])
async def create_supplier(
    payload: SupplierCreate, current_user: CurrentUser, service: InventoryService = Depends(get_inventory_service)
):
    return await service.create_supplier(current_user.business_id, **payload.model_dump())


@router.get("/suppliers", response_model=list[SupplierResponse])
async def list_suppliers(current_user: CurrentUser, service: InventoryService = Depends(get_inventory_service)):
    return await service.list_suppliers(current_user.business_id)


@router.patch("/suppliers/{supplier_id}", response_model=SupplierResponse, dependencies=[CanManageInventory])
async def update_supplier(
    supplier_id: uuid.UUID,
    payload: SupplierUpdate,
    current_user: CurrentUser,
    service: InventoryService = Depends(get_inventory_service),
):
    try:
        supplier = await service.get_supplier_or_404(current_user.business_id, supplier_id)
        return await service.supplier_repo.update(supplier, **payload.model_dump(exclude_unset=True))
    except InventoryError as e:
        _raise(e)


@router.delete("/suppliers/{supplier_id}", status_code=204, dependencies=[CanManageInventory])
async def delete_supplier(
    supplier_id: uuid.UUID, current_user: CurrentUser, service: InventoryService = Depends(get_inventory_service)
):
    try:
        await service.delete_supplier(current_user.business_id, supplier_id)
    except InventoryError as e:
        _raise(e)


# --- Products -------------------------------------------------------------


@router.post("/products", response_model=ProductResponse, status_code=201, dependencies=[CanManageInventory])
async def create_product(
    payload: ProductCreate, current_user: CurrentUser, service: InventoryService = Depends(get_inventory_service)
):
    try:
        return await service.create_product(current_user.business_id, **payload.model_dump())
    except InventoryError as e:
        _raise(e)


@router.get("/products", response_model=list[ProductResponse])
async def list_products(
    current_user: CurrentUser,
    service: InventoryService = Depends(get_inventory_service),
    search: str | None = Query(default=None),
    category_id: uuid.UUID | None = Query(default=None),
    low_stock_only: bool = Query(default=False),
):
    return await service.list_products(
        current_user.business_id, search=search, category_id=category_id, low_stock_only=low_stock_only
    )


@router.get("/products/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: uuid.UUID, current_user: CurrentUser, service: InventoryService = Depends(get_inventory_service)
):
    try:
        return await service.get_product_or_404(current_user.business_id, product_id)
    except InventoryError as e:
        _raise(e)


@router.patch("/products/{product_id}", response_model=ProductResponse, dependencies=[CanManageInventory])
async def update_product(
    product_id: uuid.UUID,
    payload: ProductUpdate,
    current_user: CurrentUser,
    service: InventoryService = Depends(get_inventory_service),
):
    try:
        return await service.update_product(
            current_user.business_id, product_id, **payload.model_dump(exclude_unset=True)
        )
    except InventoryError as e:
        _raise(e)


@router.post("/products/{product_id}/adjust-stock", response_model=ProductResponse, dependencies=[CanManageInventory])
async def adjust_stock(
    product_id: uuid.UUID,
    payload: StockAdjustment,
    current_user: CurrentUser,
    service: InventoryService = Depends(get_inventory_service),
):
    try:
        return await service.adjust_stock(current_user.business_id, product_id, payload.delta, payload.reason)
    except InventoryError as e:
        _raise(e)


@router.delete("/products/{product_id}", status_code=204, dependencies=[CanManageInventory])
async def delete_product(
    product_id: uuid.UUID, current_user: CurrentUser, service: InventoryService = Depends(get_inventory_service)
):
    try:
        await service.delete_product(current_user.business_id, product_id)
    except InventoryError as e:
        _raise(e)
