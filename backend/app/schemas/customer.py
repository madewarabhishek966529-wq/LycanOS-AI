import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class CustomerCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    phone: str | None = Field(default=None, max_length=20)
    email: EmailStr | None = None
    address: str | None = None
    notes: str | None = None


class CustomerUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    phone: str | None = None
    email: EmailStr | None = None
    address: str | None = None
    notes: str | None = None


class CreditRepayment(BaseModel):
    amount: Decimal = Field(gt=0)


class CustomerResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    phone: str | None
    email: str | None
    address: str | None
    notes: str | None
    loyalty_points: int
    credit_balance: Decimal
    created_at: datetime
