"""
Employee-specific data lives here rather than directly on `User`, because
`User` is the auth/identity model (used by every phase since Phase 2) and
salary/hire-date are business-operational data that doesn't belong mixed
into it. A `User` created via Phase 7's create-employee flow always gets
exactly one `EmployeeProfile`; the Owner created at registration (Phase 2)
does not get one automatically, since nothing about "salary" applies to a
business's founder by default — one can be added for them via the same
endpoints if needed.
"""
import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Date, DateTime, ForeignKey, Numeric, String, Text, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base


class EmployeeProfile(Base):
    __tablename__ = "employee_profiles"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id"), nullable=False, unique=True, index=True
    )
    business_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("businesses.id"), nullable=False, index=True
    )

    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    salary: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    hire_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self) -> str:
        return f"<EmployeeProfile user_id={self.user_id}>"
