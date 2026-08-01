import pytest


async def _register_owner(client, email="owner@lycanos-test.dev"):
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Passw0rd", "full_name": "Owner", "business_name": "Test Traders"},
    )
    return response.json()["tokens"]["access_token"]


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


async def _create_customer(client, token, **overrides):
    payload = {"name": "Ravi Kumar", "phone": "9876543210"}
    payload.update(overrides)
    response = await client.post("/api/v1/customers", json=payload, headers=_auth(token))
    assert response.status_code == 201
    return response.json()


async def _create_product(client, token, **overrides):
    payload = {"name": "Item", "sku": "ITEM-1", "selling_price": "100.00", "gst_rate": "0", "quantity_in_stock": 100}
    payload.update(overrides)
    response = await client.post("/api/v1/inventory/products", json=payload, headers=_auth(token))
    assert response.status_code == 201
    return response.json()


@pytest.mark.asyncio
async def test_create_and_get_customer(client):
    token = await _register_owner(client)
    customer = await _create_customer(client, token)

    response = await client.get(f"/api/v1/customers/{customer['id']}", headers=_auth(token))
    assert response.status_code == 200
    assert response.json()["name"] == "Ravi Kumar"
    assert response.json()["loyalty_points"] == 0
    assert response.json()["credit_balance"] == "0.00"


@pytest.mark.asyncio
async def test_search_customers_by_phone(client):
    token = await _register_owner(client)
    await _create_customer(client, token, name="Ravi", phone="9876543210")
    await _create_customer(client, token, name="Priya", phone="9111111111")

    response = await client.get("/api/v1/customers?search=9876", headers=_auth(token))
    assert len(response.json()) == 1
    assert response.json()[0]["name"] == "Ravi"


@pytest.mark.asyncio
async def test_update_customer(client):
    token = await _register_owner(client)
    customer = await _create_customer(client, token)

    response = await client.patch(
        f"/api/v1/customers/{customer['id']}", json={"notes": "VIP customer"}, headers=_auth(token)
    )
    assert response.status_code == 200
    assert response.json()["notes"] == "VIP customer"
    assert response.json()["name"] == "Ravi Kumar"


@pytest.mark.asyncio
async def test_delete_customer(client):
    token = await _register_owner(client)
    customer = await _create_customer(client, token)

    delete_response = await client.delete(f"/api/v1/customers/{customer['id']}", headers=_auth(token))
    assert delete_response.status_code == 204

    get_response = await client.get(f"/api/v1/customers/{customer['id']}", headers=_auth(token))
    assert get_response.status_code == 404


@pytest.mark.asyncio
async def test_checkout_with_customer_awards_loyalty_points(client):
    token = await _register_owner(client)
    customer = await _create_customer(client, token)
    product = await _create_product(client, token, selling_price="250.00")

    checkout = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "customer_id": customer["id"],
            "payment_method": "cash",
        },
        headers=_auth(token),
    )
    assert checkout.status_code == 201
    assert checkout.json()["customer_id"] == customer["id"]

    updated_customer = await client.get(f"/api/v1/customers/{customer['id']}", headers=_auth(token))
    assert updated_customer.json()["loyalty_points"] == 2


@pytest.mark.asyncio
async def test_checkout_without_customer_earns_no_points(client):
    token = await _register_owner(client)
    product = await _create_product(client, token, selling_price="1000.00")

    response = await client.post(
        "/api/v1/pos/checkout",
        json={"items": [{"product_id": product["id"], "quantity": 1}], "payment_method": "cash"},
        headers=_auth(token),
    )
    assert response.status_code == 201
    assert response.json()["customer_id"] is None


@pytest.mark.asyncio
async def test_credit_sale_requires_a_customer(client):
    token = await _register_owner(client)
    product = await _create_product(client, token)

    response = await client.post(
        "/api/v1/pos/checkout",
        json={"items": [{"product_id": product["id"], "quantity": 1}], "payment_method": "credit"},
        headers=_auth(token),
    )
    assert response.status_code == 400
    assert "customer must be attached" in response.json()["detail"]


@pytest.mark.asyncio
async def test_credit_sale_increases_customer_credit_balance(client):
    token = await _register_owner(client)
    customer = await _create_customer(client, token)
    product = await _create_product(client, token, selling_price="500.00")

    checkout = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "customer_id": customer["id"],
            "payment_method": "credit",
        },
        headers=_auth(token),
    )
    assert checkout.status_code == 201

    updated = await client.get(f"/api/v1/customers/{customer['id']}", headers=_auth(token))
    assert updated.json()["credit_balance"] == "500.00"


@pytest.mark.asyncio
async def test_partial_credit_split_payment_only_adds_credit_portion(client):
    token = await _register_owner(client)
    customer = await _create_customer(client, token)
    product = await _create_product(client, token, selling_price="1000.00")

    checkout = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "customer_id": customer["id"],
            "payment_splits": [{"method": "cash", "amount": "600.00"}, {"method": "credit", "amount": "400.00"}],
        },
        headers=_auth(token),
    )
    assert checkout.status_code == 201

    updated = await client.get(f"/api/v1/customers/{customer['id']}", headers=_auth(token))
    assert updated.json()["credit_balance"] == "400.00"


@pytest.mark.asyncio
async def test_repay_credit_reduces_balance(client):
    token = await _register_owner(client)
    customer = await _create_customer(client, token)
    product = await _create_product(client, token, selling_price="500.00")

    await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "customer_id": customer["id"],
            "payment_method": "credit",
        },
        headers=_auth(token),
    )

    repay = await client.post(
        f"/api/v1/customers/{customer['id']}/repay-credit", json={"amount": "200.00"}, headers=_auth(token)
    )
    assert repay.status_code == 200
    assert repay.json()["credit_balance"] == "300.00"


@pytest.mark.asyncio
async def test_repay_credit_rejects_overpayment(client):
    token = await _register_owner(client)
    customer = await _create_customer(client, token)
    product = await _create_product(client, token, selling_price="100.00")

    await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "customer_id": customer["id"],
            "payment_method": "credit",
        },
        headers=_auth(token),
    )

    repay = await client.post(
        f"/api/v1/customers/{customer['id']}/repay-credit", json={"amount": "999.00"}, headers=_auth(token)
    )
    assert repay.status_code == 400
    assert "exceeds" in repay.json()["detail"]


@pytest.mark.asyncio
async def test_purchase_history_lists_customers_invoices(client):
    token = await _register_owner(client)
    customer = await _create_customer(client, token)
    product = await _create_product(client, token, selling_price="50.00")

    await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "customer_id": customer["id"],
            "payment_method": "cash",
        },
        headers=_auth(token),
    )

    history = await client.get(f"/api/v1/customers/{customer['id']}/purchases", headers=_auth(token))
    assert history.status_code == 200
    assert len(history.json()) == 1
    assert history.json()[0]["total_amount"] == "50.00"


@pytest.mark.asyncio
async def test_checkout_rejects_unknown_customer(client):
    token = await _register_owner(client)
    product = await _create_product(client, token)

    response = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "customer_id": "00000000-0000-0000-0000-000000000000",
            "payment_method": "cash",
        },
        headers=_auth(token),
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_customers_isolated_per_business(client):
    token_a = await _register_owner(client, email="biz-a@lycanos-test.dev")
    token_b = await _register_owner(client, email="biz-b@lycanos-test.dev")

    await _create_customer(client, token_a, name="Business A Customer")

    response_b = await client.get("/api/v1/customers", headers=_auth(token_b))
    assert response_b.json() == []


@pytest.mark.asyncio
async def test_customers_require_authentication(client):
    response = await client.get("/api/v1/customers")
    assert response.status_code == 401
