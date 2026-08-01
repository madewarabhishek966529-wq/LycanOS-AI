import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.invoice import Invoice, InvoiceLineItem, InvoiceStatus, PaymentSplit


class InvoiceRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    def _with_relations(self):
        return select(Invoice).options(
            selectinload(Invoice.line_items), selectinload(Invoice.payment_splits)
        )

    async def next_invoice_number(self, business_id: uuid.UUID) -> str:
        """Generates a human-readable, per-business invoice number:
        `INV-YYYYMMDD-XXXX`. Not a true atomic sequence (two concurrent
        checkouts on the same day could theoretically compute the same
        count-based suffix) — acceptable for a receipt number that's
        cosmetic; the `id` UUID (not this) is the real primary key
        everything else references."""
        today = datetime.now(timezone.utc).strftime("%Y%m%d")
        result = await self.db.execute(
            select(Invoice).where(
                Invoice.business_id == business_id, Invoice.invoice_number.like(f"INV-{today}-%")
            )
        )
        count_today = len(result.scalars().all())
        return f"INV-{today}-{count_today + 1:04d}"

    async def create(
        self,
        *,
        business_id: uuid.UUID,
        cashier_id: uuid.UUID,
        invoice_number: str,
        subtotal,
        discount_amount,
        gst_amount,
        total_amount,
        payment_method,
        is_split_payment: bool,
        line_items: list[dict],
        payment_splits: list[dict] | None = None,
    ) -> Invoice:
        invoice = Invoice(
            business_id=business_id,
            cashier_id=cashier_id,
            invoice_number=invoice_number,
            subtotal=subtotal,
            discount_amount=discount_amount,
            gst_amount=gst_amount,
            total_amount=total_amount,
            payment_method=payment_method,
            is_split_payment=is_split_payment,
            status=InvoiceStatus.COMPLETED,
        )
        invoice.line_items = [InvoiceLineItem(**item) for item in line_items]
        if payment_splits:
            invoice.payment_splits = [PaymentSplit(**split) for split in payment_splits]

        self.db.add(invoice)
        # Flush (not commit) — assigns invoice.id without ending the
        # transaction, since PosService needs the stock decrements to land
        # in the same unit of work as this insert.
        await self.db.flush()
        return invoice

    async def get_by_id(self, business_id: uuid.UUID, invoice_id: uuid.UUID) -> Invoice | None:
        result = await self.db.execute(
            self._with_relations().where(Invoice.id == invoice_id, Invoice.business_id == business_id)
        )
        return result.scalar_one_or_none()

    async def list_for_business(self, business_id: uuid.UUID, *, limit: int = 50, offset: int = 0) -> list[Invoice]:
        query = (
            self._with_relations()
            .where(Invoice.business_id == business_id)
            .order_by(Invoice.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def reload_with_relations(self, invoice: Invoice) -> Invoice:
        result = await self.db.execute(self._with_relations().where(Invoice.id == invoice.id))
        return result.scalar_one()
