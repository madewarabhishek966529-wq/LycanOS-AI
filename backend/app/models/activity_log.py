"""
A scoped activity log, not a comprehensive audit system: it records the
actions this phase's own endpoints perform (employee create/update/
deactivate, attendance check-in/out) rather than retrofitting logging
into every endpoint across every prior phase. Extending coverage to
inventory/POS/customer actions is straightforward (call `log_activity`
from those services too) but wasn't done here to avoid touching four
already-tested phases' services just to add logging as a side effect —
that's a follow-up, not a Phase 7 requirement.
"""
import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base


class ActivityLog(Base):
    __tablename__ = "activity_logs"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("businesses.id"), nullable=False, index=True
    )
    actor_user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )

    action: Mapped[str] = mapped_column(String(80), nullable=False)
    description: Mapped[str] = mapped_column(String(500), nullable=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self) -> str:
        return f"<ActivityLog {self.action}>"
