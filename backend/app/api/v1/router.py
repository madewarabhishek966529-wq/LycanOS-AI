"""
Aggregates all v1 endpoint routers under a single `api_router`, mounted
at settings.API_V1_PREFIX in app/main.py. Feature endpoint modules
(auth, dashboard, inventory, pos, ...) are added here as each phase lands.
"""
from fastapi import APIRouter

from app.api.v1.endpoints import auth, customers, dashboard, employees, health, inventory, pos

api_router = APIRouter()
api_router.include_router(health.router, tags=["health"])
api_router.include_router(auth.router, tags=["auth"])
api_router.include_router(inventory.router, tags=["inventory"])
api_router.include_router(pos.router, tags=["pos"])
api_router.include_router(dashboard.router, tags=["dashboard"])
api_router.include_router(customers.router, tags=["customers"])
api_router.include_router(employees.router, tags=["employees"])
