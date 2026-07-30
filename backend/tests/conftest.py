"""
Test fixtures for Phase 2+.

Uses an in-memory SQLite DB (via aiosqlite) rather than requiring a real
Postgres instance for the test suite to run — every model in this project
uses dialect-agnostic SQLAlchemy types (`Uuid`, generic `Enum`) specifically
so this works. Alembic migrations still target Postgres-specific dialect
features for the real deployment; tests exercise the ORM layer directly via
`Base.metadata.create_all`, not the migration scripts.
"""
import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from app.db.database import Base, get_db
import app.models  # noqa: F401 — register all models on Base.metadata (must precede the next import)
from app.main import app


@pytest_asyncio.fixture
async def db_session():
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_factory = async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)

    async with session_factory() as session:
        yield session

    await engine.dispose()


@pytest_asyncio.fixture
async def client(db_session):
    async def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()
