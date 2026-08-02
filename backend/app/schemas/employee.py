import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.core.security import UserRole


class EmployeeCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    full_name: str = Field(min_length=1, max_length=255)
    role: UserRole
    phone: str | None = None
    salary: Decimal | None = Field(default=None, ge=0)
    hire_date: date | None = None
    notes: str | None = None

    @field_validator("password")
    @classmethod
    def password_strength(cls, value: str) -> str:
        if not any(c.isdigit() for c in value) or not any(c.isalpha() for c in value):
            raise ValueError("Password must contain at least one letter and one number")
        return value

    @field_validator("role")
    @classmethod
    def role_not_owner(cls, value: UserRole) -> UserRole:
        if value == UserRole.OWNER:
            raise ValueError("Owner accounts can only be created via registration, not employee creation")
        return value


class EmployeeUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=1, max_length=255)
    role: UserRole | None = None
    is_active: bool | None = None
    phone: str | None = None
    salary: Decimal | None = Field(default=None, ge=0)
    hire_date: date | None = None
    notes: str | None = None

    @field_validator("role")
    @classmethod
    def role_not_owner(cls, value: UserRole | None) -> UserRole | None:
        if value == UserRole.OWNER:
            raise ValueError("Role cannot be changed to Owner")
        return value


class EmployeeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: str
    full_name: str
    role: UserRole
    is_active: bool
    phone: str | None = None
    salary: Decimal | None = None
    hire_date: date | None = None
    notes: str | None = None
    created_at: datetime


class AttendanceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    date: date
    check_in_at: datetime | None
    check_out_at: datetime | None
    status: str


class SalesPerformance(BaseModel):
    employee_id: uuid.UUID
    employee_name: str
    invoice_count: int
    total_sales: Decimal


class ActivityLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    actor_user_id: uuid.UUID
    action: str
    description: str
    created_at: datetime
