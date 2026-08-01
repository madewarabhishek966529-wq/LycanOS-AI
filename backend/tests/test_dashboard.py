import pytest


async def _register_owner(client, email="owner@lycanos-test.dev"):
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Passw0rd", "full_name": "Owner", "business_name": "Test Traders"},
    )
    return response.json()["tokens"]["access_token"]


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


async def _create_product(client, token, **overrides):
    payload = {"name": "Item", "sku": "ITEM-1", "selling_price": "100.00", "gst_rate": "10", "quantity_in_stock": 100}
    payload.update(overrides)
    response = await client.post("/api/v1/inventory/products", json=payload, headers=_auth(token))
    assert response.status_code == 201
    return response.json()


async def _checkout(client, token, product_id, quantity=1, payment_method="cash"):
    response = await client.post(
        "/api/v1/pos/checkout",
        json={"items": [{"product_id": product_id, "quantity": quantity}], "payment_method": payment_method},
        headers=_auth(token),
    )
    assert response.status_code == 201
    return response.json()


@pytest.mark.asyncio
async def test_summary_reflects_todays_sales(client):
    token = await _register_owner(client)
    product = await _create_product(client, token, selling_price="100.00", gst_rate="10")
    await _checkout(client, token, product["id"], quantity=2)  # 200 subtotal, 20 gst, 220 total

    response = await client.get("/api/v1/dashboard/summary", headers=_auth(token))
    assert response.status_code == 200
    body = response.json()

    assert body["today_sales_total"] == "220.00"
    assert body["today_sales_count"] == 1
    assert body["today_gst_collected"] == "20.00"
    assert body["month_revenue_total"] == "220.00"
    assert body["month_sales_count"] == 1


@pytest.mark.asyncio
async def test_summary_accumulates_multiple_sales(client):
    token = await _register_owner(client)
    product = await _create_product(client, token, selling_price="50.00", gst_rate="0")
    await _checkout(client, token, product["id"], quantity=1)  # 50
    await _checkout(client, token, product["id"], quantity=1)  # 50

    response = await client.get("/api/v1/dashboard/summary", headers=_auth(token))
    body = response.json()
    assert body["today_sales_total"] == "100.00"
    assert body["today_sales_count"] == 2


@pytest.mark.asyncio
async def test_summary_shows_low_stock_products(client):
    token = await _register_owner(client)
    await _create_product(client, token, name="Low Item", sku="LOW-1", quantity_in_stock=2, reorder_level=5)
    await _create_product(client, token, name="OK Item", sku="OK-1", quantity_in_stock=100, reorder_level=5)

    response = await client.get("/api/v1/dashboard/summary", headers=_auth(token))
    body = response.json()
    assert body["low_stock_count"] == 1
    assert body["low_stock_products"][0]["product_name"] == "Low Item"


@pytest.mark.asyncio
async def test_summary_best_selling_products_ranked_by_quantity(client):
    token = await _register_owner(client)
    popular = await _create_product(client, token, name="Popular", sku="POP-1", selling_price="10.00")
    rare = await _create_product(client, token, name="Rare", sku="RARE-1", selling_price="10.00")

    await _checkout(client, token, popular["id"], quantity=10)
    await _checkout(client, token, rare["id"], quantity=1)

    response = await client.get("/api/v1/dashboard/summary", headers=_auth(token))
    best_sellers = response.json()["best_selling_products"]
    assert best_sellers[0]["product_name"] == "Popular"
    assert best_sellers[0]["quantity_sold"] == 10


@pytest.mark.asyncio
async def test_summary_excludes_other_businesses_data(client):
    token_a = await _register_owner(client, email="biz-a@lycanos-test.dev")
    token_b = await _register_owner(client, email="biz-b@lycanos-test.dev")

    product_a = await _create_product(client, token_a, sku="A-ITEM")
    await _checkout(client, token_a, product_a["id"], quantity=5)

    response_b = await client.get("/api/v1/dashboard/summary", headers=_auth(token_b))
    assert response_b.json()["today_sales_count"] == 0


@pytest.mark.asyncio
async def test_revenue_series_fills_zero_days(client):
    token = await _register_owner(client)
    product = await _create_product(client, token, selling_price="10.00", gst_rate="0")
    await _checkout(client, token, product["id"], quantity=1)

    response = await client.get("/api/v1/dashboard/revenue-series?days=7", headers=_auth(token))
    assert response.status_code == 200
    points = response.json()["points"]
    assert len(points) == 7
    non_zero_days = [p for p in points if float(p["revenue"]) > 0]
    assert len(non_zero_days) == 1
    assert non_zero_days[0]["revenue"] == "10.00"


@pytest.mark.asyncio
async def test_dashboard_accessible_to_owner(client):
    token = await _register_owner(client)
    response = await client.get("/api/v1/dashboard/summary", headers=_auth(token))
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_dashboard_requires_authentication(client):
    response = await client.get("/api/v1/dashboard/summary")
    assert response.status_code == 401
