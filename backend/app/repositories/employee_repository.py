import uuid
from datetime import date, datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.activity_log import ActivityLog
from app.models.attendance import Attendance, AttendanceStatus
from app.models.employee_profile import EmployeeProfile


class EmployeeProfileRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, business_id: uuid.UUID, user_id: uuid.UUID, **fields) -> EmployeeProfile:
        profile = EmployeeProfile(business_id=business_id, user_id=user_id, **fields)
        self.db.add(profile)
        await self.db.flush()
        return profile

    async def get_by_user_id(self, business_id: uuid.UUID, user_id: uuid.UUID) -> EmployeeProfile | None:
        result = await self.db.execute(
            select(EmployeeProfile).where(
                EmployeeProfile.user_id == user_id, EmployeeProfile.business_id == business_id
            )
        )
        return result.scalar_one_or_none()

    async def update(self, profile: EmployeeProfile, **fields) -> EmployeeProfile:
        for key, value in fields.items():
            if value is not None:
                setattr(profile, key, value)
        await self.db.flush()
        return profile


class AttendanceRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_for_date(self, business_id: uuid.UUID, user_id: uuid.UUID, day: date) -> Attendance | None:
        result = await self.db.execute(
            select(Attendance).where(
                Attendance.business_id == business_id, Attendance.user_id == user_id, Attendance.date == day
            )
        )
        return result.scalar_one_or_none()

    async def create(self, business_id: uuid.UUID, user_id: uuid.UUID, **fields) -> Attendance:
        record = Attendance(business_id=business_id, user_id=user_id, **fields)
        self.db.add(record)
        await self.db.commit()
        await self.db.refresh(record)
        return record

    async def update(self, record: Attendance, **fields) -> Attendance:
        for key, value in fields.items():
            if value is not None:
                setattr(record, key, value)
        await self.db.commit()
        await self.db.refresh(record)
        return record

    async def list_for_user(
        self, business_id: uuid.UUID, user_id: uuid.UUID, *, since_days: int = 30
    ) -> list[Attendance]:
        since = (datetime.now(timezone.utc) - timedelta(days=since_days)).date()
        result = await self.db.execute(
            select(Attendance)
            .where(Attendance.business_id == business_id, Attendance.user_id == user_id, Attendance.date >= since)
            .order_by(Attendance.date.desc())
        )
        return list(result.scalars().all())

    async def list_for_business_on_date(self, business_id: uuid.UUID, day: date) -> list[Attendance]:
        result = await self.db.execute(
            select(Attendance).where(Attendance.business_id == business_id, Attendance.date == day)
        )
        return list(result.scalars().all())


class ActivityLogRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def log(self, business_id: uuid.UUID, actor_user_id: uuid.UUID, action: str, description: str) -> None:
        entry = ActivityLog(business_id=business_id, actor_user_id=actor_user_id, action=action, description=description)
        self.db.add(entry)
        await self.db.flush()

    async def list_for_business(self, business_id: uuid.UUID, *, limit: int = 100) -> list[ActivityLog]:
        result = await self.db.execute(
            select(ActivityLog)
            .where(ActivityLog.business_id == business_id)
            .order_by(ActivityLog.created_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())
