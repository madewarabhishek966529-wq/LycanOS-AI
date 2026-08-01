"""
POS models: Invoice (a completed or voided sale) and InvoiceLineItem (one
product line within it). Stock is decremented atomically at checkout time
in the same DB transaction that creates these rows — see
app/services/pos_service.py.
"""
import enum
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, Numeric, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class PaymentMethod(str, enum.Enum):
    CASH = "cash"
    CARD = "card"
    UPI = "upi"
    WALLET = "wallet"
    CREDIT = "credit"  # goes on the customer's credit balance (Phase 6)


class InvoiceStatus(str, enum.Enum):
    COMPLETED = "completed"
    VOIDED = "voided"


class Invoice(Base):
    __tablename__ = "invoices"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("businesses.id"), nullable=False, index=True
    )
    cashier_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    # Nullable — most POS sales are walk-in/anonymous. Only set when a
    # cashier explicitly attaches a customer at checkout (Phase 6), which
    # is also what makes loyalty points and credit-balance sales possible.
    customer_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("customers.id"), nullable=True, index=True
    )

    invoice_number: Mapped[str] = mapped_column(String(30), nullable=False, index=True)

    subtotal: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    discount_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0, nullable=False)
    gst_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    total_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)

    payment_method: Mapped[PaymentMethod] = mapped_column(
        Enum(PaymentMethod, name="payment_method"), nullable=False
    )
    # Split payments (Phase 4 spec item): if present, a JSON-ish breakdown
    # is stored as separate PaymentSplit rows rather than a single method —
    # see `payment_splits` relationship below. `payment_method` stays as
    # the *primary* method for simple single-tender sales and reporting.
    is_split_payment: Mapped[bool] = mapped_column(default=False, nullable=False)

    status: Mapped[InvoiceStatus] = mapped_column(
        Enum(InvoiceStatus, name="invoice_status"), default=InvoiceStatus.COMPLETED, nullable=False
    )

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    line_items: Mapped[list["InvoiceLineItem"]] = relationship(
        back_populates="invoice", cascade="all, delete-orphan"
    )
    payment_splits: Mapped[list["PaymentSplit"]] = relationship(
        back_populates="invoice", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<Invoice {self.invoice_number} ({self.status.value})>"


class InvoiceLineItem(Base):
    __tablename__ = "invoice_line_items"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    invoice_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("invoices.id"), nullable=False, index=True
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("products.id"), nullable=False, index=True
    )

    # Snapshotted at sale time — if the product's name/price changes later,
    # historical invoices must still show what was actually sold and for
    # how much, not today's catalog values.
    product_name: Mapped[str] = mapped_column(String(200), nullable=False)
    unit_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    gst_rate: Mapped[Decimal] = mapped_column(Numeric(5, 2), nullable=False)

    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    line_discount_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0, nullable=False)
    line_total: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)

    invoice: Mapped["Invoice"] = relationship(back_populates="line_items")

    def __repr__(self) -> str:
        return f"<InvoiceLineItem {self.product_name} x{self.quantity}>"


class PaymentSplit(Base):
    __tablename__ = "payment_splits"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    invoice_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("invoices.id"), nullable=False, index=True
    )
    method: Mapped[PaymentMethod] = mapped_column(Enum(PaymentMethod, name="payment_method"), nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)

    invoice: Mapped["Invoice"] = relationship(back_populates="payment_splits")
