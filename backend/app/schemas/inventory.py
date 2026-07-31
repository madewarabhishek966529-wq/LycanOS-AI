import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class CategoryCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    description: str | None = None


class CategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    description: str | None = None


class CategoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    description: str | None
    created_at: datetime


class SupplierCreate(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    contact_phone: str | None = None
    contact_email: EmailStr | None = None
    address: str | None = None


class SupplierUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=150)
    contact_phone: str | None = None
    contact_email: EmailStr | None = None
    address: str | None = None


class SupplierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    contact_phone: str | None
    contact_email: str | None
    address: str | None
    created_at: datetime
