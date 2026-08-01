"""
Read-only aggregation queries for the dashboard. Deliberately has no
repository layer of its own — these are one-shot aggregate SELECTs, not
CRUD on an entity, so a thin service wrapping SQLAlchemy directly is more
honest than routing through a repository abstraction that would just
forward the same query.

Note on "Pending Orders": the original spec lists this as a dashboard
metric, but this system has no held/pending-invoice concept — POS
checkout (Phase 4) is immediate, completed-or-rejected, there's no
intermediate "pending" state for a sale. Rather than fabricate a number,
that metric is omitted here; it would need a real feature (e.g. held
carts, or online order intake) behind it first.
"""
import uuid
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.invoice import Invoice, InvoiceLineItem, InvoiceStatus
from app.models.product import Product
from app.schemas.dashboard import BestSellingProduct, DashboardSummary, LowStockProduct, RevenuePoint, RevenueSeries


def _start_of_today_utc() -> datetime:
    now = datetime.now(timezone.utc)
    return now.replace(hour=0, minute=0, second=0, microsecond=0)


def _start_of_month_utc() -> datetime:
    return _start_of_today_utc().replace(day=1)


class DashboardService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_summary(self, business_id: uuid.UUID, *, best_sellers_days: int = 30) -> DashboardSummary:
        today_start = _start_of_today_utc()
        month_start = _start_of_month_utc()

        today_totals = await self._sales_totals(business_id, since=today_start)
        month_totals = await self._sales_totals(business_id, since=month_start)

        low_stock_products = await self._low_stock_products(business_id)
        best_sellers = await self._best_selling_products(business_id, since_days=best_sellers_days)

        return DashboardSummary(
            today_sales_total=today_totals["revenue"],
            today_sales_count=today_totals["count"],
            today_gst_collected=today_totals["gst"],
            month_revenue_total=month_totals["revenue"],
            month_sales_count=month_totals["count"],
            low_stock_count=len(low_stock_products),
            low_stock_products=low_stock_products,
            best_selling_products=best_sellers,
        )

    async def get_revenue_series(self, business_id: uuid.UUID, *, days: int = 7) -> RevenueSeries:
        since = _start_of_today_utc() - timedelta(days=days - 1)

        result = await self.db.execute(
            select(
                func.date(Invoice.created_at).label("day"),
                func.coalesce(func.sum(Invoice.total_amount), 0).label("revenue"),
                func.count(Invoice.id).label("invoice_count"),
            )
            .where(
                Invoice.business_id == business_id,
                Invoice.status == InvoiceStatus.COMPLETED,
                Invoice.created_at >= since,
            )
            .group_by(func.date(Invoice.created_at))
            .order_by(func.date(Invoice.created_at))
        )
        rows = {row.day: row for row in result.all()}

        # Fill in zero-revenue days so the chart doesn't have gaps — a day
        # with no sales is a data point, not missing data.
        points = []
        for offset in range(days):
            day = (since + timedelta(days=offset)).date()
            row = rows.get(day) or rows.get(day.isoformat())
            points.append(
                RevenuePoint(
                    day=day,
                    revenue=Decimal(str(row.revenue)) if row else Decimal("0"),
                    invoice_count=row.invoice_count if row else 0,
                )
            )
        return RevenueSeries(points=points)

    async def _sales_totals(self, business_id: uuid.UUID, *, since: datetime) -> dict:
        result = await self.db.execute(
            select(
                func.coalesce(func.sum(Invoice.total_amount), 0),
                func.count(Invoice.id),
                func.coalesce(func.sum(Invoice.gst_amount), 0),
            ).where(
                Invoice.business_id == business_id,
                Invoice.status == InvoiceStatus.COMPLETED,
                Invoice.created_at >= since,
            )
        )
        revenue, count, gst = result.one()
        return {"revenue": Decimal(str(revenue)), "count": count, "gst": Decimal(str(gst))}

    async def _low_stock_products(self, business_id: uuid.UUID) -> list[LowStockProduct]:
        result = await self.db.execute(
            select(Product)
            .where(
                Product.business_id == business_id,
                Product.is_active.is_(True),
                Product.quantity_in_stock <= Product.reorder_level,
            )
            .order_by(Product.quantity_in_stock)
        )
        products = result.scalars().all()
        return [
            LowStockProduct(
                product_id=p.id,
                product_name=p.name,
                quantity_in_stock=p.quantity_in_stock,
                reorder_level=p.reorder_level,
            )
            for p in products
        ]

    async def _best_selling_products(
        self, business_id: uuid.UUID, *, since_days: int
    ) -> list[BestSellingProduct]:
        since = _start_of_today_utc() - timedelta(days=since_days)

        result = await self.db.execute(
            select(
                InvoiceLineItem.product_id,
                InvoiceLineItem.product_name,
                func.sum(InvoiceLineItem.quantity).label("quantity_sold"),
                func.sum(InvoiceLineItem.line_total).label("revenue"),
            )
            .join(Invoice, Invoice.id == InvoiceLineItem.invoice_id)
            .where(
                Invoice.business_id == business_id,
                Invoice.status == InvoiceStatus.COMPLETED,
                Invoice.created_at >= since,
            )
            .group_by(InvoiceLineItem.product_id, InvoiceLineItem.product_name)
            .order_by(func.sum(InvoiceLineItem.quantity).desc())
            .limit(5)
        )
        return [
            BestSellingProduct(
                product_id=row.product_id,
                product_name=row.product_name,
                quantity_sold=row.quantity_sold,
                revenue=Decimal(str(row.revenue)),
            )
            for row in result.all()
        ]
