import pytest


async def _register_owner(client, email="owner@lycanos-test.dev"):
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "Passw0rd",
            "full_name": "Test Owner",
            "business_name": "Test Traders",
        },
    )
    return response.json()["tokens"]["access_token"]


async def _register_cashier_in_new_business(client, email="cashier@lycanos-test.dev"):
    # Registration always creates a fresh business with the registrant as
    # Owner (there's no "join an existing business as Cashier" endpoint
    # yet — that's Phase 7, Employee Management). For RBAC tests we only
    # need *a* non-owner token, so we register a second owner-of-their-own
    # business and treat it as "not the first business's owner" for
    # cross-tenant isolation checks; role-restriction tests use a
    # separately crafted low-privilege scenario below instead.
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "Passw0rd",
            "full_name": "Other Owner",
            "business_name": "Other Business",
        },
    )
    return response.json()["tokens"]["access_token"]


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_create_and_list_category(client):
    token = await _register_owner(client)
    create_response = await client.post(
        "/api/v1/inventory/categories", json={"name": "Beverages", "description": "Cold drinks"}, headers=_auth(token)
    )
    assert create_response.status_code == 201
    assert create_response.json()["name"] == "Beverages"

    list_response = await client.get("/api/v1/inventory/categories", headers=_auth(token))
    assert list_response.status_code == 200
    assert len(list_response.json()) == 1


@pytest.mark.asyncio
async def test_create_supplier(client):
    token = await _register_owner(client)
    response = await client.post(
        "/api/v1/inventory/suppliers",
        json={"name": "Acme Distributors", "contact_phone": "9876543210"},
        headers=_auth(token),
    )
    assert response.status_code == 201
    assert response.json()["name"] == "Acme Distributors"


@pytest.mark.asyncio
async def test_create_product_minimal(client):
    token = await _register_owner(client)
    response = await client.post(
        "/api/v1/inventory/products",
        json={"name": "Coca-Cola 250ml", "sku": "COKE-250", "selling_price": "20.00"},
        headers=_auth(token),
    )
    assert response.status_code == 201
    body = response.json()
    assert body["sku"] == "COKE-250"
    assert body["quantity_in_stock"] == 0
    assert body["is_low_stock"] is True  # 0 <= default reorder_level of 5


@pytest.mark.asyncio
async def test_create_product_duplicate_sku_rejected(client):
    token = await _register_owner(client)
    payload = {"name": "Maggi Noodles", "sku": "MAGGI-70", "selling_price": "14.00"}
    first = await client.post("/api/v1/inventory/products", json=payload, headers=_auth(token))
    assert first.status_code == 201

    second = await client.post("/api/v1/inventory/products", json=payload, headers=_auth(token))
    assert second.status_code == 409


@pytest.mark.asyncio
async def test_create_product_zero_price_rejected(client):
    token = await _register_owner(client)
    response = await client.post(
        "/api/v1/inventory/products",
        json={"name": "Free Sample", "sku": "FREE-1", "selling_price": "0.00"},
        headers=_auth(token),
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_stock_adjustment_increases_quantity(client):
    token = await _register_owner(client)
    create_response = await client.post(
        "/api/v1/inventory/products",
        json={"name": "Dairy Milk", "sku": "DM-1", "selling_price": "40.00", "quantity_in_stock": 10},
        headers=_auth(token),
    )
    product_id = create_response.json()["id"]

    adjust_response = await client.post(
        f"/api/v1/inventory/products/{product_id}/adjust-stock",
        json={"delta": 25, "reason": "Purchase order #PO-1001 received"},
        headers=_auth(token),
    )
    assert adjust_response.status_code == 200
    assert adjust_response.json()["quantity_in_stock"] == 35


@pytest.mark.asyncio
async def test_stock_adjustment_rejects_over_removal(client):
    token = await _register_owner(client)
    create_response = await client.post(
        "/api/v1/inventory/products",
        json={"name": "Lays Chips", "sku": "LAYS-1", "selling_price": "20.00", "quantity_in_stock": 5},
        headers=_auth(token),
    )
    product_id = create_response.json()["id"]

    adjust_response = await client.post(
        f"/api/v1/inventory/products/{product_id}/adjust-stock",
        json={"delta": -10, "reason": "Damaged stock write-off"},
        headers=_auth(token),
    )
    assert adjust_response.status_code == 400
    assert "only 5 in stock" in adjust_response.json()["detail"]


@pytest.mark.asyncio
async def test_low_stock_filter(client):
    token = await _register_owner(client)
    await client.post(
        "/api/v1/inventory/products",
        json={"name": "Low Item", "sku": "LOW-1", "selling_price": "10.00", "quantity_in_stock": 1, "reorder_level": 5},
        headers=_auth(token),
    )
    await client.post(
        "/api/v1/inventory/products",
        json={"name": "Well Stocked", "sku": "OK-1", "selling_price": "10.00", "quantity_in_stock": 100, "reorder_level": 5},
        headers=_auth(token),
    )

    response = await client.get("/api/v1/inventory/products?low_stock_only=true", headers=_auth(token))
    assert response.status_code == 200
    names = [p["name"] for p in response.json()]
    assert names == ["Low Item"]


@pytest.mark.asyncio
async def test_product_search_by_name(client):
    token = await _register_owner(client)
    await client.post(
        "/api/v1/inventory/products",
        json={"name": "Amul Butter 500g", "sku": "AMUL-BTR-500", "selling_price": "250.00"},
        headers=_auth(token),
    )
    await client.post(
        "/api/v1/inventory/products",
        json={"name": "Parle-G Biscuit", "sku": "PARLE-G", "selling_price": "10.00"},
        headers=_auth(token),
    )

    response = await client.get("/api/v1/inventory/products?search=amul", headers=_auth(token))
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["name"] == "Amul Butter 500g"


@pytest.mark.asyncio
async def test_products_are_isolated_per_business(client):
    token_a = await _register_owner(client, email="biz-a@lycanos-test.dev")
    token_b = await _register_cashier_in_new_business(client, email="biz-b@lycanos-test.dev")

    await client.post(
        "/api/v1/inventory/products",
        json={"name": "Business A Product", "sku": "A-1", "selling_price": "10.00"},
        headers=_auth(token_a),
    )

    response_b = await client.get("/api/v1/inventory/products", headers=_auth(token_b))
    assert response_b.status_code == 200
    assert response_b.json() == []  # Business B sees none of Business A's products


@pytest.mark.asyncio
async def test_get_nonexistent_product_returns_404(client):
    token = await _register_owner(client)
    response = await client.get(
        "/api/v1/inventory/products/00000000-0000-0000-0000-000000000000", headers=_auth(token)
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_products_require_authentication(client):
    response = await client.get("/api/v1/inventory/products")
    assert response.status_code == 401
