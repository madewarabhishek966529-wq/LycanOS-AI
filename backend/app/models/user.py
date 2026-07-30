"""
User ORM model — the first real table in the schema. Every other model
added from Phase 4 onward (Product, Invoice, Customer, ...) will carry a
`business_id` foreign key following the same pattern established here,
since LycanOS AI is multi-tenant per business from day one.
"""
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.security import UserRole
from app.db.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)

    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)

    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role"), nullable=False, default=UserRole.EMPLOYEE
    )

    # Every user belongs to exactly one business. The business that owns
    # the very first registered account is created implicitly by
    # AuthService.register — see app/services/auth_service.py.
    business_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("businesses.id"), nullable=False, index=True
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Set when a forgot-password flow issues a reset token; cleared once
    # used or expired. Kept simple (single active token) for Phase 2 —
    # a dedicated PasswordResetToken table can replace this if multiple
    # concurrent reset flows ever become a real requirement.
    reset_token: Mapped[str | None] = mapped_column(String(255), nullable=True)
    reset_token_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    def __repr__(self) -> str:
        return f"<User {self.email} ({self.role})>"
