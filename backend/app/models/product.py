import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, Numeric, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class Product(Base):
    __tablename__ = "products"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("businesses.id"), nullable=False, index=True
    )
    category_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("categories.id"), nullable=True, index=True
    )
    supplier_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("suppliers.id"), nullable=True, index=True
    )

    name: Mapped[str] = mapped_column(String(200), nullable=False)
    sku: Mapped[str] = mapped_column(String(80), nullable=False)
    barcode: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    unit: Mapped[str] = mapped_column(String(20), default="pcs", nullable=False)

    cost_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0, nullable=False)
    selling_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    gst_rate: Mapped[Decimal] = mapped_column(Numeric(5, 2), default=0, nullable=False)

    quantity_in_stock: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    reorder_level: Mapped[int] = mapped_column(Integer, default=5, nullable=False)

    batch_number: Mapped[str | None] = mapped_column(String(80), nullable=True)
    expiry_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    category: Mapped["Category | None"] = relationship(back_populates="products")
    supplier: Mapped["Supplier | None"] = relationship(back_populates="products")

    @property
    def is_low_stock(self) -> bool:
        return self.quantity_in_stock <= self.reorder_level

    def __repr__(self) -> str:
        return f"<Product {self.name} ({self.sku})>"
