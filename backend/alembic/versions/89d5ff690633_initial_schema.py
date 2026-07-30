"""initial schema — businesses and users

Revision ID: 89d5ff690633
Revises:
Create Date: Phase 2 — Authentication
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "89d5ff690633"
down_revision = None
branch_labels = None
depends_on = None

user_role_enum = postgresql.ENUM(
    "owner", "manager", "cashier", "employee", name="user_role"
)


def upgrade() -> None:
    user_role_enum.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "businesses",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("hashed_password", sa.String(length=255), nullable=False),
        sa.Column("full_name", sa.String(length=255), nullable=False),
        sa.Column("role", user_role_enum, nullable=False, server_default="employee"),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("reset_token", sa.String(length=255), nullable=True),
        sa.Column("reset_token_expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            onupdate=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["business_id"], ["businesses.id"]),
        sa.UniqueConstraint("email"),
    )
    op.create_index("ix_users_email", "users", ["email"])
    op.create_index("ix_users_business_id", "users", ["business_id"])


def downgrade() -> None:
    op.drop_index("ix_users_business_id", table_name="users")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
    op.drop_table("businesses")
    user_role_enum.drop(op.get_bind(), checkfirst=True)
