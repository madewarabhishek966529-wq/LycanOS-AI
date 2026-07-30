"""
Aggregates all v1 endpoint routers under a single `api_router`, mounted
at settings.API_V1_PREFIX in app/main.py. Feature endpoint modules
(auth, dashboard, inventory, pos, ...) are added here as each phase lands.
"""
from fastapi import APIRouter

from app.api.v1.endpoints import health

api_router = APIRouter()
api_router.include_router(health.router, tags=["health"])
