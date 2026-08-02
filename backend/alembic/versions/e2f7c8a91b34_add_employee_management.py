"""add employee_profiles, attendance, activity_logs

Revision ID: e2f7c8a91b34
Revises: d1a6e5b3f420
Create Date: Phase 7 — Employee Management
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "e2f7c8a91b34"
down_revision = "d1a6e5b3f420"
branch_labels = None
depends_on = None

attendance_status_enum = postgresql.ENUM(
    "present", "absent", "leave", "half_day", name="attendance_status", create_type=False
)


def upgrade() -> None:
    attendance_status_enum_create = postgresql.ENUM(
        "present", "absent", "leave", "half_day", name="attendance_status"
    )
    attendance_status_enum_create.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "employee_profiles",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=True),
        sa.Column("salary", sa.Numeric(12, 2), nullable=True),
        sa.Column("hire_date", sa.Date(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["business_id"], ["businesses.id"]),
        sa.UniqueConstraint("user_id", name="uq_employee_profiles_user_id"),
    )
    op.create_index("ix_employee_profiles_user_id", "employee_profiles", ["user_id"])
    op.create_index("ix_employee_profiles_business_id", "employee_profiles", ["business_id"])

    op.create_table(
        "attendance",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("check_in_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("check_out_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", attendance_status_enum, nullable=False, server_default="present"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["business_id"], ["businesses.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
    )
    op.create_index("ix_attendance_business_id", "attendance", ["business_id"])
    op.create_index("ix_attendance_user_id", "attendance", ["user_id"])
    op.create_index("ix_attendance_date", "attendance", ["date"])

    op.create_table(
        "activity_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("actor_user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("action", sa.String(length=80), nullable=False),
        sa.Column("description", sa.String(length=500), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["business_id"], ["businesses.id"]),
        sa.ForeignKeyConstraint(["actor_user_id"], ["users.id"]),
    )
    op.create_index("ix_activity_logs_business_id", "activity_logs", ["business_id"])
    op.create_index("ix_activity_logs_actor_user_id", "activity_logs", ["actor_user_id"])


def downgrade() -> None:
    op.drop_index("ix_activity_logs_actor_user_id", table_name="activity_logs")
    op.drop_index("ix_activity_logs_business_id", table_name="activity_logs")
    op.drop_table("activity_logs")

    op.drop_index("ix_attendance_date", table_name="attendance")
    op.drop_index("ix_attendance_user_id", table_name="attendance")
    op.drop_index("ix_attendance_business_id", table_name="attendance")
    op.drop_table("attendance")

    op.drop_index("ix_employee_profiles_business_id", table_name="employee_profiles")
    op.drop_index("ix_employee_profiles_user_id", table_name="employee_profiles")
    op.drop_table("employee_profiles")

    attendance_status_enum.drop(op.get_bind(), checkfirst=True)
