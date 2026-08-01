"""add customers table and invoices.customer_id

Revision ID: d1a6e5b3f420
Revises: c9d4f1a8b217
Create Date: Phase 6 — Customer Management
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "d1a6e5b3f420"
down_revision = "c9d4f1a8b217"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "customers",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=True),
        sa.Column("email", sa.String(length=255), nullable=True),
        sa.Column("address", sa.String(length=500), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("loyalty_points", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("credit_balance", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["business_id"], ["businesses.id"]),
    )
    op.create_index("ix_customers_business_id", "customers", ["business_id"])
    op.create_index("ix_customers_phone", "customers", ["phone"])

    op.add_column("invoices", sa.Column("customer_id", postgresql.UUID(as_uuid=True), nullable=True))
    op.create_foreign_key("fk_invoices_customer_id", "invoices", "customers", ["customer_id"], ["id"])
    op.create_index("ix_invoices_customer_id", "invoices", ["customer_id"])


def downgrade() -> None:
    op.drop_index("ix_invoices_customer_id", table_name="invoices")
    op.drop_constraint("fk_invoices_customer_id", "invoices", type_="foreignkey")
    op.drop_column("invoices", "customer_id")

    op.drop_index("ix_customers_phone", table_name="customers")
    op.drop_index("ix_customers_business_id", table_name="customers")
    op.drop_table("customers")
