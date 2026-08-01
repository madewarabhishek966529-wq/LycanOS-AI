"""
POS checkout logic. The one rule this module exists to enforce: an invoice
and its stock decrements are either both persisted or neither is — a
checkout can never leave stock decremented with no invoice on record, or
vice versa. That's achieved by mutating `Product.quantity_in_stock`
directly on the ORM objects already tracked by the request's session and
committing once, at the end, alongside the new `Invoice` row.
"""
import uuid
from datetime import date
from decimal import ROUND_HALF_UP, Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.business import Business
from app.models.coupon import DiscountType
from app.models.invoice import Invoice
from app.models.product import Product
from app.repositories.coupon_repository import CouponRepository
from app.repositories.inventory_repository import ProductRepository
from app.repositories.invoice_repository import InvoiceRepository
from app.schemas.pos import CheckoutRequest
from app.services.receipt_service import generate_receipt_pdf

TWO_PLACES = Decimal("0.01")


def _round(value: Decimal) -> Decimal:
    return value.quantize(TWO_PLACES, rounding=ROUND_HALF_UP)


class PosError(Exception):
    def __init__(self, message: str, status_code: int = 400):
        self.message = message
        self.status_code = status_code
        super().__init__(message)


class PosService:
    def __init__(
        self,
        db: AsyncSession,
        product_repo: ProductRepository,
        invoice_repo: InvoiceRepository,
        coupon_repo: CouponRepository,
    ):
        self.db = db
        self.product_repo = product_repo
        self.invoice_repo = invoice_repo
        self.coupon_repo = coupon_repo

    async def checkout(
        self, *, business_id: uuid.UUID, cashier_id: uuid.UUID, request: CheckoutRequest
    ) -> Invoice:
        if request.payment_method is None and not request.payment_splits:
            raise PosError("Provide either payment_method or payment_splits")
        if request.payment_method is not None and request.payment_splits:
            raise PosError("Provide payment_method OR payment_splits, not both")

        # --- 1. Load and validate every product up front, before mutating
        # anything — a mid-loop failure must never leave some products
        # decremented and others not. ---
        products: dict[uuid.UUID, Product] = {}
        for item in request.items:
            product = await self.product_repo.get_by_id(business_id, item.product_id)
            if product is None or not product.is_active:
                raise PosError(f"Product {item.product_id} not found", status_code=404)
            if product.quantity_in_stock < item.quantity:
                raise PosError(
                    f"Not enough stock for '{product.name}' — only {product.quantity_in_stock} "
                    f"{product.unit} available, {item.quantity} requested"
                )
            if item.line_discount_amount > product.selling_price * item.quantity:
                raise PosError(f"Discount on '{product.name}' exceeds its line total")
            products[item.product_id] = product

        # --- 2. Compute financials. ---
        line_computations = []
        subtotal = Decimal("0")
        for item in request.items:
            product = products[item.product_id]
            line_gross = product.selling_price * item.quantity
            line_net = line_gross - item.line_discount_amount
            subtotal += line_net
            line_computations.append({"item": item, "product": product, "line_net": line_net})

        # --- Coupon resolution: a coupon computes the invoice-level
        # discount from the catalog, so it's mutually exclusive with a
        # manually supplied invoice_discount_amount — accepting both would
        # let a client silently stack them. ---
        invoice_discount_amount = request.invoice_discount_amount
        if request.coupon_code:
            if request.invoice_discount_amount > 0:
                raise PosError("Provide either a coupon_code or invoice_discount_amount, not both")
            coupon = await self.coupon_repo.get_by_code(business_id, request.coupon_code)
            if coupon is None or not coupon.is_active:
                raise PosError(f"Coupon '{request.coupon_code}' is not valid", status_code=404)
            if coupon.valid_until is not None and coupon.valid_until < date.today():
                raise PosError(f"Coupon '{coupon.code}' has expired")
            if subtotal < coupon.min_purchase_amount:
                raise PosError(
                    f"Coupon '{coupon.code}' requires a minimum purchase of ₹{coupon.min_purchase_amount}"
                )

            if coupon.discount_type == DiscountType.PERCENTAGE:
                invoice_discount_amount = _round(subtotal * coupon.discount_value / 100)
            else:
                invoice_discount_amount = coupon.discount_value

            if coupon.max_discount_amount is not None:
                invoice_discount_amount = min(invoice_discount_amount, coupon.max_discount_amount)
            invoice_discount_amount = min(invoice_discount_amount, subtotal)

        if invoice_discount_amount > subtotal:
            raise PosError("Invoice discount cannot exceed the subtotal")

        discount_ratio = (invoice_discount_amount / subtotal) if subtotal > 0 else Decimal("0")

        line_items_payload = []
        gst_total = Decimal("0")
        for computation in line_computations:
            item = computation["item"]
            product = computation["product"]
            line_net = computation["line_net"]

            line_taxable = _round(line_net * (1 - discount_ratio))
            line_gst = _round(line_taxable * product.gst_rate / 100)
            line_total = line_taxable + line_gst
            gst_total += line_gst

            line_items_payload.append({
                "product_id": product.id,
                "product_name": product.name,
                "unit_price": product.selling_price,
                "gst_rate": product.gst_rate,
                "quantity": item.quantity,
                "line_discount_amount": item.line_discount_amount,
                "line_total": line_total,
            })

        total_discount = sum((c["item"].line_discount_amount for c in line_computations), Decimal("0")) + \
            invoice_discount_amount
        total_amount = _round(subtotal - invoice_discount_amount + gst_total)

        # --- 3. Validate payment covers the total. ---
        payment_splits_payload = None
        if request.payment_splits:
            splits_sum = sum((s.amount for s in request.payment_splits), Decimal("0"))
            if abs(splits_sum - total_amount) > Decimal("0.01"):
                raise PosError(
                    f"Payment splits total ₹{splits_sum} does not match invoice total ₹{total_amount}"
                )
            payment_splits_payload = [{"method": s.method, "amount": s.amount} for s in request.payment_splits]
            primary_method = request.payment_splits[0].method
        else:
            primary_method = request.payment_method

        # --- 4. Decrement stock (in-session mutation, not yet committed). ---
        for item in request.items:
            products[item.product_id].quantity_in_stock -= item.quantity

        # --- 5. Create the invoice (flush, not commit) and commit
        # everything together. ---
        invoice_number = await self.invoice_repo.next_invoice_number(business_id)
        invoice = await self.invoice_repo.create(
            business_id=business_id,
            cashier_id=cashier_id,
            invoice_number=invoice_number,
            subtotal=_round(subtotal),
            discount_amount=_round(total_discount),
            gst_amount=_round(gst_total),
            total_amount=total_amount,
            payment_method=primary_method,
            is_split_payment=bool(request.payment_splits),
            line_items=line_items_payload,
            payment_splits=payment_splits_payload,
        )

        await self.db.commit()
        return await self.invoice_repo.reload_with_relations(invoice)

    async def get_invoice_or_404(self, business_id: uuid.UUID, invoice_id: uuid.UUID) -> Invoice:
        invoice = await self.invoice_repo.get_by_id(business_id, invoice_id)
        if invoice is None:
            raise PosError("Invoice not found", status_code=404)
        return invoice

    async def get_receipt_pdf(self, business_id: uuid.UUID, invoice_id: uuid.UUID) -> bytes:
        invoice = await self.get_invoice_or_404(business_id, invoice_id)
        result = await self.db.execute(select(Business).where(Business.id == business_id))
        business = result.scalar_one()
        return generate_receipt_pdf(invoice, business)

    async def list_invoices(self, business_id: uuid.UUID, *, limit: int = 50, offset: int = 0) -> list[Invoice]:
        return await self.invoice_repo.list_for_business(business_id, limit=limit, offset=offset)
