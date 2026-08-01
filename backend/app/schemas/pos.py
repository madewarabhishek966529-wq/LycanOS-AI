import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.invoice import PaymentMethod


class CheckoutLineItem(BaseModel):
    product_id: uuid.UUID
    quantity: int = Field(gt=0)
    line_discount_amount: Decimal = Field(default=Decimal("0"), ge=0)


class PaymentSplitInput(BaseModel):
    method: PaymentMethod
    amount: Decimal = Field(gt=0)


class CheckoutRequest(BaseModel):
    items: list[CheckoutLineItem] = Field(min_length=1)
    invoice_discount_amount: Decimal = Field(default=Decimal("0"), ge=0)
    coupon_code: str | None = None
    payment_method: PaymentMethod | None = None
    payment_splits: list[PaymentSplitInput] | None = None

    @field_validator("items")
    @classmethod
    def no_duplicate_products(cls, items: list[CheckoutLineItem]) -> list[CheckoutLineItem]:
        product_ids = [item.product_id for item in items]
        if len(product_ids) != len(set(product_ids)):
            raise ValueError("Each product should appear once — combine quantities instead of repeating a line")
        return items


class InvoiceLineItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    product_id: uuid.UUID
    product_name: str
    unit_price: Decimal
    gst_rate: Decimal
    quantity: int
    line_discount_amount: Decimal
    line_total: Decimal


class PaymentSplitResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    method: PaymentMethod
    amount: Decimal


class InvoiceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    invoice_number: str
    subtotal: Decimal
    discount_amount: Decimal
    gst_amount: Decimal
    total_amount: Decimal
    payment_method: PaymentMethod
    is_split_payment: bool
    status: str
    line_items: list[InvoiceLineItemResponse]
    payment_splits: list[PaymentSplitResponse]
    created_at: datetime
