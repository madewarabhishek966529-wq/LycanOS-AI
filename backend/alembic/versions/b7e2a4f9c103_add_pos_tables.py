"""add pos tables — invoices, invoice_line_items, payment_splits

Revision ID: b7e2a4f9c103
Revises: a3f1c9d2e551
Create Date: Phase 4 — POS Billing
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "b7e2a4f9c103"
down_revision = "a3f1c9d2e551"
branch_labels = None
depends_on = None

payment_method_enum = postgresql.ENUM(
    "cash", "card", "upi", "wallet", "credit", name="payment_method", create_type=False
)
invoice_status_enum = postgresql.ENUM("completed", "voided", name="invoice_status", create_type=False)


def upgrade() -> None:
    payment_method_enum_create = postgresql.ENUM(
        "cash", "card", "upi", "wallet", "credit", name="payment_method"
    )
    invoice_status_enum_create = postgresql.ENUM("completed", "voided", name="invoice_status")
    payment_method_enum_create.create(op.get_bind(), checkfirst=True)
    invoice_status_enum_create.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "invoices",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("cashier_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("invoice_number", sa.String(length=30), nullable=False),
        sa.Column("subtotal", sa.Numeric(12, 2), nullable=False),
        sa.Column("discount_amount", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("gst_amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("total_amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("payment_method", payment_method_enum, nullable=False),
        sa.Column("is_split_payment", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("status", invoice_status_enum, nullable=False, server_default="completed"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["business_id"], ["businesses.id"]),
        sa.ForeignKeyConstraint(["cashier_id"], ["users.id"]),
    )
    op.create_index("ix_invoices_business_id", "invoices", ["business_id"])
    op.create_index("ix_invoices_cashier_id", "invoices", ["cashier_id"])
    op.create_index("ix_invoices_invoice_number", "invoices", ["invoice_number"])

    op.create_table(
        "invoice_line_items",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("invoice_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("product_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("product_name", sa.String(length=200), nullable=False),
        sa.Column("unit_price", sa.Numeric(12, 2), nullable=False),
        sa.Column("gst_rate", sa.Numeric(5, 2), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("line_discount_amount", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("line_total", sa.Numeric(12, 2), nullable=False),
        sa.ForeignKeyConstraint(["invoice_id"], ["invoices.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["product_id"], ["products.id"]),
    )
    op.create_index("ix_invoice_line_items_invoice_id", "invoice_line_items", ["invoice_id"])
    op.create_index("ix_invoice_line_items_product_id", "invoice_line_items", ["product_id"])

    op.create_table(
        "payment_splits",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("invoice_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("method", payment_method_enum, nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.ForeignKeyConstraint(["invoice_id"], ["invoices.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_payment_splits_invoice_id", "payment_splits", ["invoice_id"])


def downgrade() -> None:
    op.drop_index("ix_payment_splits_invoice_id", table_name="payment_splits")
    op.drop_table("payment_splits")

    op.drop_index("ix_invoice_line_items_product_id", table_name="invoice_line_items")
    op.drop_index("ix_invoice_line_items_invoice_id", table_name="invoice_line_items")
    op.drop_table("invoice_line_items")

    op.drop_index("ix_invoices_invoice_number", table_name="invoices")
    op.drop_index("ix_invoices_cashier_id", table_name="invoices")
    op.drop_index("ix_invoices_business_id", table_name="invoices")
    op.drop_table("invoices")

    payment_method_enum.drop(op.get_bind(), checkfirst=True)
    invoice_status_enum.drop(op.get_bind(), checkfirst=True)
