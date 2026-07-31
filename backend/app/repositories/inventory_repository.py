"""
Repository layer for inventory. Every query is scoped by `business_id` —
there is no method here that can accidentally leak another business's
data, since the business_id filter is baked into each query rather than
left to callers to remember.
"""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.category import Category
from app.models.product import Product
from app.models.supplier import Supplier


class CategoryRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, business_id: uuid.UUID, name: str, description: str | None) -> Category:
        category = Category(business_id=business_id, name=name, description=description)
        self.db.add(category)
        await self.db.commit()
        await self.db.refresh(category)
        return category

    async def list_for_business(self, business_id: uuid.UUID) -> list[Category]:
        result = await self.db.execute(
            select(Category).where(Category.business_id == business_id).order_by(Category.name)
        )
        return list(result.scalars().all())

    async def get_by_id(self, business_id: uuid.UUID, category_id: uuid.UUID) -> Category | None:
        result = await self.db.execute(
            select(Category).where(Category.id == category_id, Category.business_id == business_id)
        )
        return result.scalar_one_or_none()

    async def update(self, category: Category, **fields) -> Category:
        for key, value in fields.items():
            if value is not None:
                setattr(category, key, value)
        await self.db.commit()
        await self.db.refresh(category)
        return category

    async def delete(self, category: Category) -> None:
        await self.db.delete(category)
        await self.db.commit()


class SupplierRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, business_id: uuid.UUID, **fields) -> Supplier:
        supplier = Supplier(business_id=business_id, **fields)
        self.db.add(supplier)
        await self.db.commit()
        await self.db.refresh(supplier)
        return supplier

    async def list_for_business(self, business_id: uuid.UUID) -> list[Supplier]:
        result = await self.db.execute(
            select(Supplier).where(Supplier.business_id == business_id).order_by(Supplier.name)
        )
        return list(result.scalars().all())

    async def get_by_id(self, business_id: uuid.UUID, supplier_id: uuid.UUID) -> Supplier | None:
        result = await self.db.execute(
            select(Supplier).where(Supplier.id == supplier_id, Supplier.business_id == business_id)
        )
        return result.scalar_one_or_none()

    async def update(self, supplier: Supplier, **fields) -> Supplier:
        for key, value in fields.items():
            if value is not None:
                setattr(supplier, key, value)
        await self.db.commit()
        await self.db.refresh(supplier)
        return supplier

    async def delete(self, supplier: Supplier) -> None:
        await self.db.delete(supplier)
        await self.db.commit()


class ProductRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    def _with_relations(self):
        return select(Product).options(selectinload(Product.category), selectinload(Product.supplier))

    async def _reload_with_relations(self, product: Product) -> Product:
        """Re-fetches the product with category/supplier eagerly loaded.

        `session.refresh(obj, attribute_names=[...])` only reloads the
        named attributes and leaves every other column expired-but-not-
        reloaded, which then triggers an implicit lazy load the next time
        a plain attribute like `updated_at` is accessed — fatal in an
        async context (`MissingGreenlet`). Re-running the eager-loaded
        SELECT avoids that entirely and keeps every column consistent.
        """
        result = await self.db.execute(self._with_relations().where(Product.id == product.id))
        return result.scalar_one()

    async def create(self, business_id: uuid.UUID, **fields) -> Product:
        product = Product(business_id=business_id, **fields)
        self.db.add(product)
        await self.db.commit()
        return await self._reload_with_relations(product)

    async def get_by_id(self, business_id: uuid.UUID, product_id: uuid.UUID) -> Product | None:
        result = await self.db.execute(
            self._with_relations().where(Product.id == product_id, Product.business_id == business_id)
        )
        return result.scalar_one_or_none()

    async def get_by_sku(self, business_id: uuid.UUID, sku: str) -> Product | None:
        result = await self.db.execute(
            select(Product).where(Product.business_id == business_id, Product.sku == sku)
        )
        return result.scalar_one_or_none()

    async def list_for_business(
        self,
        business_id: uuid.UUID,
        *,
        search: str | None = None,
        category_id: uuid.UUID | None = None,
        low_stock_only: bool = False,
        active_only: bool = True,
    ) -> list[Product]:
        query = self._with_relations().where(Product.business_id == business_id)

        if active_only:
            query = query.where(Product.is_active.is_(True))
        if category_id is not None:
            query = query.where(Product.category_id == category_id)
        if search:
            like = f"%{search.lower()}%"
            query = query.where(
                Product.name.ilike(like) | Product.sku.ilike(like) | Product.barcode.ilike(like)
            )
        if low_stock_only:
            query = query.where(Product.quantity_in_stock <= Product.reorder_level)

        query = query.order_by(Product.name)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def update(self, product: Product, **fields) -> Product:
        for key, value in fields.items():
            if value is not None:
                setattr(product, key, value)
        await self.db.commit()
        return await self._reload_with_relations(product)

    async def adjust_stock(self, product: Product, delta: int) -> Product:
        product.quantity_in_stock = product.quantity_in_stock + delta
        await self.db.commit()
        return await self._reload_with_relations(product)

    async def delete(self, product: Product) -> None:
        await self.db.delete(product)
        await self.db.commit()
