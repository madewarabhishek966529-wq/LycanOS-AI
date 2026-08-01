import uuid
from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class BestSellingProduct(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    product_id: uuid.UUID
    product_name: str
    quantity_sold: int
    revenue: Decimal


class LowStockProduct(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    product_id: uuid.UUID
    product_name: str
    quantity_in_stock: int
    reorder_level: int


class DashboardSummary(BaseModel):
    today_sales_total: Decimal
    today_sales_count: int
    today_gst_collected: Decimal
    month_revenue_total: Decimal
    month_sales_count: int
    low_stock_count: int
    low_stock_products: list[LowStockProduct]
    best_selling_products: list[BestSellingProduct]


class RevenuePoint(BaseModel):
    day: date
    revenue: Decimal
    invoice_count: int


class RevenueSeries(BaseModel):
    points: list[RevenuePoint]
