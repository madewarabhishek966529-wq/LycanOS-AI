"""
Minimal Business record. Registering the first user of a business (the
Owner) creates this row implicitly — see AuthService.register. Business
profile fields (GST settings, invoice customization, currency, etc.) are
added to this table in the Settings phase; keeping it minimal now avoids
a migration full of nullable placeholder columns.
"""
import uuid
from datetime import datetime

from sqlalchemy import DateTime, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base


class Business(Base):
    __tablename__ = "businesses"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self) -> str:
        return f"<Business {self.name}>"
