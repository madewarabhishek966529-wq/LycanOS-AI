import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.coupon import DiscountType


class CouponCreate(BaseModel):
    code: str = Field(min_length=3, max_length=30)
    discount_type: DiscountType
    discount_value: Decimal = Field(gt=0)
    min_purchase_amount: Decimal = Field(default=Decimal("0"), ge=0)
    max_discount_amount: Decimal | None = Field(default=None, gt=0)
    valid_until: date | None = None

    @field_validator("code")
    @classmethod
    def uppercase_code(cls, value: str) -> str:
        return value.strip().upper()

    @field_validator("discount_value")
    @classmethod
    def percentage_within_bounds(cls, value: Decimal, info) -> Decimal:
        discount_type = info.data.get("discount_type")
        if discount_type == DiscountType.PERCENTAGE and value > 100:
            raise ValueError("Percentage discount cannot exceed 100")
        return value


class CouponResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    code: str
    discount_type: DiscountType
    discount_value: Decimal
    min_purchase_amount: Decimal
    max_discount_amount: Decimal | None
    valid_until: date | None
    is_active: bool
    created_at: datetime
