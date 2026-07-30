import pytest


async def _register(client, email="owner@lycanos-test.dev", password="Passw0rd", business_name="Test Traders"):
    return await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": password,
            "full_name": "Test Owner",
            "business_name": business_name,
        },
    )


@pytest.mark.asyncio
async def test_register_creates_owner_and_business(client):
    response = await _register(client)
    assert response.status_code == 201
    body = response.json()
    assert body["user"]["role"] == "owner"
    assert body["user"]["email"] == "owner@lycanos-test.dev"
    assert "access_token" in body["tokens"]
    assert "refresh_token" in body["tokens"]


@pytest.mark.asyncio
async def test_register_duplicate_email_rejected(client):
    await _register(client)
    response = await _register(client)
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_register_weak_password_rejected(client):
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "weak@lycanos-test.dev",
            "password": "allletters",  # no digit
            "full_name": "Weak Pw",
            "business_name": "X",
        },
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_login_success(client):
    await _register(client, email="login@lycanos-test.dev")
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "login@lycanos-test.dev", "password": "Passw0rd"},
    )
    assert response.status_code == 200
    assert "access_token" in response.json()["tokens"]


@pytest.mark.asyncio
async def test_login_wrong_password_rejected(client):
    await _register(client, email="wrongpw@lycanos-test.dev")
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "wrongpw@lycanos-test.dev", "password": "wrongpassword1"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_me_requires_authentication(client):
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_me_returns_current_user(client):
    register_response = await _register(client, email="me@lycanos-test.dev")
    access_token = register_response.json()["tokens"]["access_token"]

    response = await client.get(
        "/api/v1/auth/me", headers={"Authorization": f"Bearer {access_token}"}
    )
    assert response.status_code == 200
    assert response.json()["email"] == "me@lycanos-test.dev"


@pytest.mark.asyncio
async def test_refresh_issues_new_token_pair(client):
    register_response = await _register(client, email="refresh@lycanos-test.dev")
    refresh_token = register_response.json()["tokens"]["refresh_token"]

    response = await client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert response.status_code == 200
    assert "access_token" in response.json()


@pytest.mark.asyncio
async def test_refresh_rejects_access_token(client):
    register_response = await _register(client, email="badrefresh@lycanos-test.dev")
    access_token = register_response.json()["tokens"]["access_token"]

    # Using an access token where a refresh token is expected must fail —
    # this is the whole point of tagging tokens with a "type" claim.
    response = await client.post("/api/v1/auth/refresh", json={"refresh_token": access_token})
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_forgot_password_never_reveals_account_existence(client):
    await _register(client, email="reset@lycanos-test.dev")

    exists_response = await client.post("/api/v1/auth/forgot-password", json={"email": "reset@lycanos-test.dev"})
    not_exists_response = await client.post(
        "/api/v1/auth/forgot-password", json={"email": "nobody@lycanos-test.dev"}
    )

    assert exists_response.status_code == 202
    assert not_exists_response.status_code == 202
    assert exists_response.json() == not_exists_response.json()


@pytest.mark.asyncio
async def test_invalid_token_rejected_on_protected_route(client):
    response = await client.get("/api/v1/auth/me", headers={"Authorization": "Bearer not-a-real-token"})
    assert response.status_code == 401
