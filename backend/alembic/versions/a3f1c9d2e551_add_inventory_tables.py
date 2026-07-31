"""add inventory tables — categories, suppliers, products

Revision ID: a3f1c9d2e551
Revises: 89d5ff690633
Create Date: Phase 3 — Inventory
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "a3f1c9d2e551"
down_revision = "89d5ff690633"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "categories",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["business_id"], ["businesses.id"]),
    )
    op.create_index("ix_categories_business_id", "categories", ["business_id"])

    op.create_table(
        "suppliers",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=150), nullable=False),
        sa.Column("contact_phone", sa.String(length=20), nullable=True),
        sa.Column("contact_email", sa.String(length=255), nullable=True),
        sa.Column("address", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["business_id"], ["businesses.id"]),
    )
    op.create_index("ix_suppliers_business_id", "suppliers", ["business_id"])

    op.create_table(
        "products",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("category_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("supplier_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("sku", sa.String(length=80), nullable=False),
        sa.Column("barcode", sa.String(length=80), nullable=True),
        sa.Column("unit", sa.String(length=20), nullable=False, server_default="pcs"),
        sa.Column("cost_price", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("selling_price", sa.Numeric(12, 2), nullable=False),
        sa.Column("gst_rate", sa.Numeric(5, 2), nullable=False, server_default="0"),
        sa.Column("quantity_in_stock", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("reorder_level", sa.Integer(), nullable=False, server_default="5"),
        sa.Column("batch_number", sa.String(length=80), nullable=True),
        sa.Column("expiry_date", sa.Date(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            onupdate=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["business_id"], ["businesses.id"]),
        sa.ForeignKeyConstraint(["category_id"], ["categories.id"]),
        sa.ForeignKeyConstraint(["supplier_id"], ["suppliers.id"]),
    )
    op.create_index("ix_products_business_id", "products", ["business_id"])
    op.create_index("ix_products_category_id", "products", ["category_id"])
    op.create_index("ix_products_supplier_id", "products", ["supplier_id"])
    op.create_index("ix_products_barcode", "products", ["barcode"])


def downgrade() -> None:
    op.drop_index("ix_products_barcode", table_name="products")
    op.drop_index("ix_products_supplier_id", table_name="products")
    op.drop_index("ix_products_category_id", table_name="products")
    op.drop_index("ix_products_business_id", table_name="products")
    op.drop_table("products")

    op.drop_index("ix_suppliers_business_id", table_name="suppliers")
    op.drop_table("suppliers")

    op.drop_index("ix_categories_business_id", table_name="categories")
    op.drop_table("categories")
