"""add coupons table

Revision ID: c9d4f1a8b217
Revises: b7e2a4f9c103
Create Date: Phase 4 — POS Billing (coupons)
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "c9d4f1a8b217"
down_revision = "b7e2a4f9c103"
branch_labels = None
depends_on = None

discount_type_enum = postgresql.ENUM("percentage", "flat", name="discount_type", create_type=False)


def upgrade() -> None:
    discount_type_enum_create = postgresql.ENUM("percentage", "flat", name="discount_type")
    discount_type_enum_create.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "coupons",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("code", sa.String(length=30), nullable=False),
        sa.Column("discount_type", discount_type_enum, nullable=False),
        sa.Column("discount_value", sa.Numeric(12, 2), nullable=False),
        sa.Column("min_purchase_amount", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("max_discount_amount", sa.Numeric(12, 2), nullable=True),
        sa.Column("valid_until", sa.Date(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["business_id"], ["businesses.id"]),
    )
    op.create_index("ix_coupons_business_id", "coupons", ["business_id"])
    op.create_unique_constraint("uq_coupons_business_id_code", "coupons", ["business_id", "code"])


def downgrade() -> None:
    op.drop_constraint("uq_coupons_business_id_code", "coupons", type_="unique")
    op.drop_index("ix_coupons_business_id", table_name="coupons")
    op.drop_table("coupons")
    discount_type_enum.drop(op.get_bind(), checkfirst=True)
