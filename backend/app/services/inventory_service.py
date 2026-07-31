"""
Inventory business logic: SKU-uniqueness enforcement, stock-adjustment
validation, and low-stock queries used by both the Inventory endpoints
directly and (from Phase 3 onward, once reordered ahead of it) the
Dashboard's low-stock widget.
"""
import uuid
from decimal import Decimal

from app.models.category import Category
from app.models.product import Product
from app.models.supplier import Supplier
from app.repositories.inventory_repository import CategoryRepository, ProductRepository, SupplierRepository


class InventoryError(Exception):
    def __init__(self, message: str, status_code: int = 400):
        self.message = message
        self.status_code = status_code
        super().__init__(message)


class InventoryService:
    def __init__(
        self,
        category_repo: CategoryRepository,
        supplier_repo: SupplierRepository,
        product_repo: ProductRepository,
    ):
        self.category_repo = category_repo
        self.supplier_repo = supplier_repo
        self.product_repo = product_repo

    # --- Categories ---------------------------------------------------

    async def create_category(self, business_id: uuid.UUID, name: str, description: str | None) -> Category:
        return await self.category_repo.create(business_id, name, description)

    async def list_categories(self, business_id: uuid.UUID) -> list[Category]:
        return await self.category_repo.list_for_business(business_id)

    async def get_category_or_404(self, business_id: uuid.UUID, category_id: uuid.UUID) -> Category:
        category = await self.category_repo.get_by_id(business_id, category_id)
        if category is None:
            raise InventoryError("Category not found", status_code=404)
        return category

    async def delete_category(self, business_id: uuid.UUID, category_id: uuid.UUID) -> None:
        category = await self.get_category_or_404(business_id, category_id)
        await self.category_repo.delete(category)

    # --- Suppliers ------------------------------------------------------

    async def create_supplier(self, business_id: uuid.UUID, **fields) -> Supplier:
        return await self.supplier_repo.create(business_id, **fields)

    async def list_suppliers(self, business_id: uuid.UUID) -> list[Supplier]:
        return await self.supplier_repo.list_for_business(business_id)

    async def get_supplier_or_404(self, business_id: uuid.UUID, supplier_id: uuid.UUID) -> Supplier:
        supplier = await self.supplier_repo.get_by_id(business_id, supplier_id)
        if supplier is None:
            raise InventoryError("Supplier not found", status_code=404)
        return supplier

    async def delete_supplier(self, business_id: uuid.UUID, supplier_id: uuid.UUID) -> None:
        supplier = await self.get_supplier_or_404(business_id, supplier_id)
        await self.supplier_repo.delete(supplier)

    # --- Products ---------------------------------------------------------

    async def create_product(self, business_id: uuid.UUID, **fields) -> Product:
        existing = await self.product_repo.get_by_sku(business_id, fields["sku"])
        if existing is not None:
            raise InventoryError(f"A product with SKU '{fields['sku']}' already exists", status_code=409)

        if fields.get("category_id") is not None:
            await self.get_category_or_404(business_id, fields["category_id"])
        if fields.get("supplier_id") is not None:
            await self.get_supplier_or_404(business_id, fields["supplier_id"])

        return await self.product_repo.create(business_id, **fields)

    async def get_product_or_404(self, business_id: uuid.UUID, product_id: uuid.UUID) -> Product:
        product = await self.product_repo.get_by_id(business_id, product_id)
        if product is None:
            raise InventoryError("Product not found", status_code=404)
        return product

    async def list_products(
        self,
        business_id: uuid.UUID,
        *,
        search: str | None = None,
        category_id: uuid.UUID | None = None,
        low_stock_only: bool = False,
    ) -> list[Product]:
        return await self.product_repo.list_for_business(
            business_id, search=search, category_id=category_id, low_stock_only=low_stock_only
        )

    async def update_product(self, business_id: uuid.UUID, product_id: uuid.UUID, **fields) -> Product:
        product = await self.get_product_or_404(business_id, product_id)

        if fields.get("category_id") is not None:
            await self.get_category_or_404(business_id, fields["category_id"])
        if fields.get("supplier_id") is not None:
            await self.get_supplier_or_404(business_id, fields["supplier_id"])

        return await self.product_repo.update(product, **fields)

    async def adjust_stock(
        self, business_id: uuid.UUID, product_id: uuid.UUID, delta: int, reason: str
    ) -> Product:
        product = await self.get_product_or_404(business_id, product_id)
        resulting_quantity = product.quantity_in_stock + delta
        if resulting_quantity < 0:
            raise InventoryError(
                f"Cannot remove {abs(delta)} units — only {product.quantity_in_stock} in stock",
                status_code=400,
            )
        return await self.product_repo.adjust_stock(product, delta)

    async def delete_product(self, business_id: uuid.UUID, product_id: uuid.UUID) -> None:
        product = await self.get_product_or_404(business_id, product_id)
        await self.product_repo.delete(product)
