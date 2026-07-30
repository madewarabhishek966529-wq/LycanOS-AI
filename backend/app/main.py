"""
LycanOS AI backend — FastAPI entrypoint.

Run locally with:
    uvicorn app.main:app --reload --port 8000
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: nothing beyond settings validation is required yet.
    # Later phases hook Redis connection warmup and Chroma client init here.
    yield
    # Shutdown: connection pools are closed automatically by SQLAlchemy's
    # engine disposal — nothing else to release in Phase 1.


app = FastAPI(
    title=settings.APP_NAME,
    description="AI-powered Business Operating System for SMBs",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_PREFIX)


@app.get("/")
async def root() -> dict:
    return {"message": f"{settings.APP_NAME} API", "docs": "/docs"}
