"""
Request/response schemas for the auth endpoints. Kept separate from ORM
models (app/models/user.py) so the API contract can evolve independently
of the DB schema — e.g. we never want `hashed_password` serialized in a
response, which a shared model would risk.
"""
import uuid
from datetime import datetime

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.core.security import UserRole


class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str = Field(min_length=1, max_length=255)
    business_name: str = Field(min_length=1, max_length=255)

    @field_validator("password")
    @classmethod
    def password_complexity(cls, value: str) -> str:
        if not any(c.isdigit() for c in value):
            raise ValueError("Password must contain at least one digit")
        if not any(c.isalpha() for c in value):
            raise ValueError("Password must contain at least one letter")
        return value


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    reset_token: str
    new_password: str = Field(min_length=8, max_length=128)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: uuid.UUID
    email: EmailStr
    full_name: str
    role: UserRole
    business_id: uuid.UUID
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class AuthResponse(BaseModel):
    user: UserResponse
    tokens: TokenResponse
