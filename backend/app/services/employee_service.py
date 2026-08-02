"""
Employee management business logic. Employee *creation* is the fix for a
real gap left open since Phase 2: registration (Phase 2) can only ever
create an Owner + a brand-new business — there was no way to add a
Manager/Cashier/Employee to an existing business until this phase.
"""
import uuid
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import UserRole, hash_password
from app.models.attendance import Attendance, AttendanceStatus
from app.models.employee_profile import EmployeeProfile
from app.models.invoice import Invoice, InvoiceStatus
from app.models.user import User
from app.repositories.employee_repository import ActivityLogRepository, AttendanceRepository, EmployeeProfileRepository
from app.repositories.user_repository import UserRepository


class EmployeeError(Exception):
    def __init__(self, message: str, status_code: int = 400):
        self.message = message
        self.status_code = status_code
        super().__init__(message)


def _to_employee_response_dict(user: User, profile: EmployeeProfile | None) -> dict:
    return {
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "role": user.role,
        "is_active": user.is_active,
        "phone": profile.phone if profile else None,
        "salary": profile.salary if profile else None,
        "hire_date": profile.hire_date if profile else None,
        "notes": profile.notes if profile else None,
        "created_at": user.created_at,
    }


class EmployeeService:
    def __init__(
        self,
        db: AsyncSession,
        user_repo: UserRepository,
        profile_repo: EmployeeProfileRepository,
        attendance_repo: AttendanceRepository,
        activity_repo: ActivityLogRepository,
    ):
        self.db = db
        self.user_repo = user_repo
        self.profile_repo = profile_repo
        self.attendance_repo = attendance_repo
        self.activity_repo = activity_repo

    async def create_employee(
        self,
        *,
        business_id: uuid.UUID,
        actor: User,
        email: str,
        password: str,
        full_name: str,
        role: UserRole,
        phone: str | None,
        salary: Decimal | None,
        hire_date: date | None,
        notes: str | None,
    ) -> dict:
        # Only an Owner can create another Manager — a Manager creating
        # peers/superiors of themselves would be a privilege-escalation
        # hole, not a real business need.
        if role == UserRole.MANAGER and actor.role != UserRole.OWNER:
            raise EmployeeError("Only an Owner can create a Manager account", status_code=403)

        existing = await self.user_repo.get_by_email(email)
        if existing is not None:
            raise EmployeeError("An account with this email already exists", status_code=409)

        user = User(
            id=uuid.uuid4(),
            email=email,
            hashed_password=hash_password(password),
            full_name=full_name,
            role=role,
            business_id=business_id,
        )
        user = await self.user_repo.create(user)

        profile = await self.profile_repo.create(
            business_id, user.id, phone=phone, salary=salary, hire_date=hire_date, notes=notes
        )

        await self.activity_repo.log(
            business_id, actor.id, "employee.created", f"Created {role.value} account for {full_name}"
        )
        await self.db.commit()
        await self.db.refresh(user)
        await self.db.refresh(profile)
        return _to_employee_response_dict(user, profile)

    async def get_employee_or_404(self, business_id: uuid.UUID, user_id: uuid.UUID) -> dict:
        user = await self.user_repo.get_by_id_in_business(business_id, user_id)
        if user is None:
            raise EmployeeError("Employee not found", status_code=404)
        profile = await self.profile_repo.get_by_user_id(business_id, user_id)
        return _to_employee_response_dict(user, profile)

    async def list_employees(self, business_id: uuid.UUID) -> list[dict]:
        users = await self.user_repo.list_for_business(business_id)
        results = []
        for user in users:
            profile = await self.profile_repo.get_by_user_id(business_id, user.id)
            results.append(_to_employee_response_dict(user, profile))
        return results

    async def update_employee(
        self, *, business_id: uuid.UUID, actor: User, user_id: uuid.UUID, **fields
    ) -> dict:
        user = await self.user_repo.get_by_id_in_business(business_id, user_id)
        if user is None:
            raise EmployeeError("Employee not found", status_code=404)

        new_role = fields.pop("role", None)
        is_active = fields.pop("is_active", None)

        if new_role == UserRole.MANAGER and actor.role != UserRole.OWNER:
            raise EmployeeError("Only an Owner can promote someone to Manager", status_code=403)

        if is_active is False and user.role == UserRole.OWNER:
            active_owners = await self.user_repo.count_active_owners(business_id)
            if active_owners <= 1:
                raise EmployeeError("Cannot deactivate the business's only active Owner", status_code=400)

        if new_role is not None:
            user.role = new_role
        if is_active is not None:
            user.is_active = is_active

        profile_fields = {
            k: v for k, v in fields.items() if k in {"phone", "salary", "hire_date", "notes"} and v is not None
        }
        if "full_name" in fields and fields["full_name"] is not None:
            user.full_name = fields["full_name"]

        profile = await self.profile_repo.get_by_user_id(business_id, user_id)
        if profile is None and profile_fields:
            profile = await self.profile_repo.create(business_id, user_id, **profile_fields)
        elif profile is not None and profile_fields:
            profile = await self.profile_repo.update(profile, **profile_fields)

        await self.activity_repo.log(business_id, actor.id, "employee.updated", f"Updated {user.full_name}'s profile")
        await self.db.commit()
        await self.db.refresh(user)
        if profile is not None:
            await self.db.refresh(profile)
        return _to_employee_response_dict(user, profile)

    # --- Attendance -----------------------------------------------------

    async def check_in(self, business_id: uuid.UUID, user: User) -> Attendance:
        today = datetime.now(timezone.utc).date()
        existing = await self.attendance_repo.get_for_date(business_id, user.id, today)
        if existing is not None and existing.check_in_at is not None:
            raise EmployeeError("Already checked in today", status_code=409)

        if existing is not None:
            return await self.attendance_repo.update(existing, check_in_at=datetime.now(timezone.utc))

        return await self.attendance_repo.create(
            business_id, user.id, date=today, check_in_at=datetime.now(timezone.utc), status=AttendanceStatus.PRESENT
        )

    async def check_out(self, business_id: uuid.UUID, user: User) -> Attendance:
        today = datetime.now(timezone.utc).date()
        existing = await self.attendance_repo.get_for_date(business_id, user.id, today)
        if existing is None or existing.check_in_at is None:
            raise EmployeeError("Must check in before checking out", status_code=400)
        if existing.check_out_at is not None:
            raise EmployeeError("Already checked out today", status_code=409)

        return await self.attendance_repo.update(existing, check_out_at=datetime.now(timezone.utc))

    async def get_attendance_history(
        self, business_id: uuid.UUID, user_id: uuid.UUID, *, since_days: int = 30
    ) -> list[Attendance]:
        return await self.attendance_repo.list_for_user(business_id, user_id, since_days=since_days)

    # --- Sales performance ------------------------------------------------

    async def get_sales_performance(self, business_id: uuid.UUID, *, since_days: int = 30) -> list[dict]:
        since = datetime.now(timezone.utc) - timedelta(days=since_days)
        result = await self.db.execute(
            select(
                Invoice.cashier_id,
                func.count(Invoice.id).label("invoice_count"),
                func.coalesce(func.sum(Invoice.total_amount), 0).label("total_sales"),
            )
            .where(
                Invoice.business_id == business_id,
                Invoice.status == InvoiceStatus.COMPLETED,
                Invoice.created_at >= since,
            )
            .group_by(Invoice.cashier_id)
            .order_by(func.sum(Invoice.total_amount).desc())
        )
        rows = result.all()

        performance = []
        for row in rows:
            user = await self.user_repo.get_by_id(row.cashier_id)
            performance.append(
                {
                    "employee_id": row.cashier_id,
                    "employee_name": user.full_name if user else "Unknown",
                    "invoice_count": row.invoice_count,
                    "total_sales": Decimal(str(row.total_sales)),
                }
            )
        return performance

    async def get_activity_log(self, business_id: uuid.UUID, *, limit: int = 100):
        return await self.activity_repo.list_for_business(business_id, limit=limit)
