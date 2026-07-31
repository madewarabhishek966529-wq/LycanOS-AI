import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.inventory import CategoryResponse, SupplierResponse


class ProductCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    sku: str = Field(min_length=1, max_length=80)
    barcode: str | None = Field(default=None, max_length=80)
    unit: str = Field(default="pcs", max_length=20)
    category_id: uuid.UUID | None = None
    supplier_id: uuid.UUID | None = None
    cost_price: Decimal = Field(default=Decimal("0"), ge=0)
    selling_price: Decimal = Field(ge=0)
    gst_rate: Decimal = Field(default=Decimal("0"), ge=0, le=100)
    quantity_in_stock: int = Field(default=0, ge=0)
    reorder_level: int = Field(default=5, ge=0)
    batch_number: str | None = Field(default=None, max_length=80)
    expiry_date: date | None = None

    @field_validator("selling_price")
    @classmethod
    def selling_price_must_be_positive(cls, value: Decimal) -> Decimal:
        if value <= 0:
            raise ValueError("Selling price must be greater than zero")
        return value


class ProductUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    barcode: str | None = None
    unit: str | None = None
    category_id: uuid.UUID | None = None
    supplier_id: uuid.UUID | None = None
    cost_price: Decimal | None = Field(default=None, ge=0)
    selling_price: Decimal | None = Field(default=None, gt=0)
    gst_rate: Decimal | None = Field(default=None, ge=0, le=100)
    reorder_level: int | None = Field(default=None, ge=0)
    batch_number: str | None = None
    expiry_date: date | None = None
    is_active: bool | None = None


class StockAdjustment(BaseModel):
    """Positive `delta` receives stock (purchase order received), negative
    `delta` removes it (damage, manual correction — sales-driven decrements
    go through the POS endpoint in Phase 5, not this one)."""

    delta: int = Field(description="Positive to add stock, negative to remove")
    reason: str = Field(min_length=1, max_length=255)

    @field_validator("delta")
    @classmethod
    def delta_not_zero(cls, value: int) -> int:
        if value == 0:
            raise ValueError("delta must not be zero")
        return value


class ProductResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    sku: str
    barcode: str | None
    unit: str
    category: CategoryResponse | None
    supplier: SupplierResponse | None
    cost_price: Decimal
    selling_price: Decimal
    gst_rate: Decimal
    quantity_in_stock: int
    reorder_level: int
    batch_number: str | None
    expiry_date: date | None
    is_active: bool
    is_low_stock: bool
    created_at: datetime
    updated_at: datetime
