"""
Liveness/readiness endpoints. `/health` is intentionally dependency-free
(just confirms the process is up); `/health/ready` additionally checks the
database connection so orchestrators (Docker/K8s) can distinguish "process
running" from "actually able to serve traffic".
"""
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.database import get_db

router = APIRouter()


@router.get("/health")
async def health_check() -> dict:
    return {"status": "ok", "app": settings.APP_NAME, "env": settings.APP_ENV}


@router.get("/health/ready")
async def readiness_check(db: AsyncSession = Depends(get_db)) -> dict:
    await db.execute(text("SELECT 1"))
    return {"status": "ready", "database": "connected"}
