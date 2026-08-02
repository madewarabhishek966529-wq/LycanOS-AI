import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentUser, require_role
from app.core.security import UserRole
from app.db.database import get_db
from app.repositories.employee_repository import ActivityLogRepository, AttendanceRepository, EmployeeProfileRepository
from app.repositories.user_repository import UserRepository
from app.schemas.employee import (
    ActivityLogResponse,
    AttendanceResponse,
    EmployeeCreate,
    EmployeeResponse,
    EmployeeUpdate,
    SalesPerformance,
)
from app.services.employee_service import EmployeeError, EmployeeService

router = APIRouter(prefix="/employees")

CanManageEmployees = Depends(require_role(UserRole.OWNER, UserRole.MANAGER))


def get_employee_service(db: AsyncSession = Depends(get_db)) -> EmployeeService:
    return EmployeeService(
        db, UserRepository(db), EmployeeProfileRepository(db), AttendanceRepository(db), ActivityLogRepository(db)
    )


@router.post("", response_model=EmployeeResponse, status_code=201, dependencies=[CanManageEmployees])
async def create_employee(
    payload: EmployeeCreate, current_user: CurrentUser, service: EmployeeService = Depends(get_employee_service)
):
    try:
        return await service.create_employee(
            business_id=current_user.business_id, actor=current_user, **payload.model_dump()
        )
    except EmployeeError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get("", response_model=list[EmployeeResponse], dependencies=[CanManageEmployees])
async def list_employees(current_user: CurrentUser, service: EmployeeService = Depends(get_employee_service)):
    return await service.list_employees(current_user.business_id)


@router.get("/performance", response_model=list[SalesPerformance], dependencies=[CanManageEmployees])
async def get_sales_performance(
    current_user: CurrentUser,
    service: EmployeeService = Depends(get_employee_service),
    since_days: int = Query(default=30, ge=1, le=365),
):
    return await service.get_sales_performance(current_user.business_id, since_days=since_days)


@router.get("/activity-log", response_model=list[ActivityLogResponse], dependencies=[CanManageEmployees])
async def get_activity_log(
    current_user: CurrentUser,
    service: EmployeeService = Depends(get_employee_service),
    limit: int = Query(default=100, le=500),
):
    return await service.get_activity_log(current_user.business_id, limit=limit)


@router.post("/attendance/check-in", response_model=AttendanceResponse)
async def check_in(current_user: CurrentUser, service: EmployeeService = Depends(get_employee_service)):
    try:
        return await service.check_in(current_user.business_id, current_user)
    except EmployeeError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.post("/attendance/check-out", response_model=AttendanceResponse)
async def check_out(current_user: CurrentUser, service: EmployeeService = Depends(get_employee_service)):
    try:
        return await service.check_out(current_user.business_id, current_user)
    except EmployeeError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get("/{employee_id}", response_model=EmployeeResponse)
async def get_employee(
    employee_id: uuid.UUID, current_user: CurrentUser, service: EmployeeService = Depends(get_employee_service)
):
    if employee_id != current_user.id and current_user.role not in (UserRole.OWNER, UserRole.MANAGER):
        raise HTTPException(status_code=403, detail="Not authorized to view this employee")
    try:
        return await service.get_employee_or_404(current_user.business_id, employee_id)
    except EmployeeError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.patch("/{employee_id}", response_model=EmployeeResponse, dependencies=[CanManageEmployees])
async def update_employee(
    employee_id: uuid.UUID,
    payload: EmployeeUpdate,
    current_user: CurrentUser,
    service: EmployeeService = Depends(get_employee_service),
):
    try:
        return await service.update_employee(
            business_id=current_user.business_id,
            actor=current_user,
            user_id=employee_id,
            **payload.model_dump(exclude_unset=True),
        )
    except EmployeeError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


@router.get("/{employee_id}/attendance", response_model=list[AttendanceResponse])
async def get_attendance_history(
    employee_id: uuid.UUID,
    current_user: CurrentUser,
    service: EmployeeService = Depends(get_employee_service),
    since_days: int = Query(default=30, ge=1, le=365),
):
    if employee_id != current_user.id and current_user.role not in (UserRole.OWNER, UserRole.MANAGER):
        raise HTTPException(status_code=403, detail="Not authorized to view this employee's attendance")
    return await service.get_attendance_history(current_user.business_id, employee_id, since_days=since_days)
