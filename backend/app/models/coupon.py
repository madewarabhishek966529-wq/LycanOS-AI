import enum
import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Boolean, Date, DateTime, Enum, ForeignKey, Numeric, String, UniqueConstraint, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base


class DiscountType(str, enum.Enum):
    PERCENTAGE = "percentage"
    FLAT = "flat"


class Coupon(Base):
    __tablename__ = "coupons"
    __table_args__ = (UniqueConstraint("business_id", "code", name="uq_coupons_business_id_code"),)

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("businesses.id"), nullable=False, index=True
    )

    code: Mapped[str] = mapped_column(String(30), nullable=False)
    discount_type: Mapped[DiscountType] = mapped_column(Enum(DiscountType, name="discount_type"), nullable=False)
    discount_value: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)

    min_purchase_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0, nullable=False)
    max_discount_amount: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    valid_until: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self) -> str:
        return f"<Coupon {self.code}>"
