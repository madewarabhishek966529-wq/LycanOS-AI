from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentUser, require_role
from app.core.security import UserRole
from app.db.database import get_db
from app.schemas.dashboard import DashboardSummary, RevenueSeries
from app.services.dashboard_service import DashboardService

router = APIRouter(prefix="/dashboard")

# Business-wide financials are Owner/Manager territory — a Cashier sees
# their own register (POS invoices they created) but not the whole
# business's revenue picture, and a generic Employee sees neither.
CanViewDashboard = Depends(require_role(UserRole.OWNER, UserRole.MANAGER))


def get_dashboard_service(db: AsyncSession = Depends(get_db)) -> DashboardService:
    return DashboardService(db)


@router.get("/summary", response_model=DashboardSummary, dependencies=[CanViewDashboard])
async def get_summary(
    current_user: CurrentUser,
    service: DashboardService = Depends(get_dashboard_service),
    best_sellers_days: int = Query(default=30, ge=1, le=365),
):
    return await service.get_summary(current_user.business_id, best_sellers_days=best_sellers_days)


@router.get("/revenue-series", response_model=RevenueSeries, dependencies=[CanViewDashboard])
async def get_revenue_series(
    current_user: CurrentUser,
    service: DashboardService = Depends(get_dashboard_service),
    days: int = Query(default=7, ge=1, le=90),
):
    return await service.get_revenue_series(current_user.business_id, days=days)
