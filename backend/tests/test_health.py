"""
Phase 1 smoke tests: confirms the app object builds correctly (settings
load, CORS middleware attaches, router mounts) and the dependency-free
/health endpoint responds. DB-backed endpoints (/health/ready and every
feature endpoint from Phase 2 onward) are covered by tests that spin up a
test Postgres instance, added alongside those phases.
"""
import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.mark.asyncio
async def test_root_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()


@pytest.mark.asyncio
async def test_health_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["app"] == "LycanOS AI"


@pytest.mark.asyncio
async def test_docs_available():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/docs")
    assert response.status_code == 200
