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
    payload = {
        "name": "Coca-Cola 250ml",
        "sku": "COKE-250",
        "selling_price": "20.00",
        "gst_rate": "12.00",
        "quantity_in_stock": 100,
    }
    payload.update(overrides)
    response = await client.post("/api/v1/inventory/products", json=payload, headers=_auth(token))
    assert response.status_code == 201
    return response.json()


@pytest.mark.asyncio
async def test_checkout_happy_path_computes_gst_correctly(client):
    token = await _register_owner(client)
    product = await _create_product(client, token)

    response = await client.post(
        "/api/v1/pos/checkout",
        json={"items": [{"product_id": product["id"], "quantity": 3}], "payment_method": "cash"},
        headers=_auth(token),
    )
    assert response.status_code == 201
    body = response.json()

    # 3 x 20.00 = 60.00 subtotal, 12% GST = 7.20, total = 67.20
    assert body["subtotal"] == "60.00"
    assert body["gst_amount"] == "7.20"
    assert body["total_amount"] == "67.20"
    assert body["line_items"][0]["quantity"] == 3
    assert body["invoice_number"].startswith("INV-")


@pytest.mark.asyncio
async def test_checkout_decrements_stock(client):
    token = await _register_owner(client)
    product = await _create_product(client, token, quantity_in_stock=10)

    await client.post(
        "/api/v1/pos/checkout",
        json={"items": [{"product_id": product["id"], "quantity": 4}], "payment_method": "cash"},
        headers=_auth(token),
    )

    updated = await client.get(f"/api/v1/inventory/products/{product['id']}", headers=_auth(token))
    assert updated.json()["quantity_in_stock"] == 6


@pytest.mark.asyncio
async def test_checkout_rejects_insufficient_stock_without_decrementing(client):
    token = await _register_owner(client)
    product = await _create_product(client, token, quantity_in_stock=5)

    response = await client.post(
        "/api/v1/pos/checkout",
        json={"items": [{"product_id": product["id"], "quantity": 100}], "payment_method": "cash"},
        headers=_auth(token),
    )
    assert response.status_code == 400
    assert "Not enough stock" in response.json()["detail"]

    # Stock must be untouched after a rejected checkout.
    unchanged = await client.get(f"/api/v1/inventory/products/{product['id']}", headers=_auth(token))
    assert unchanged.json()["quantity_in_stock"] == 5


@pytest.mark.asyncio
async def test_checkout_atomic_across_multiple_items(client):
    """If item 2 in a multi-item cart fails validation, item 1's stock
    must NOT have been decremented — this is the core atomicity guarantee
    the whole PosService module exists for."""
    token = await _register_owner(client)
    product_ok = await _create_product(client, token, sku="OK-1", quantity_in_stock=10)
    product_short = await _create_product(client, token, sku="SHORT-1", quantity_in_stock=2)

    response = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [
                {"product_id": product_ok["id"], "quantity": 5},
                {"product_id": product_short["id"], "quantity": 50},
            ],
            "payment_method": "cash",
        },
        headers=_auth(token),
    )
    assert response.status_code == 400

    ok_after = await client.get(f"/api/v1/inventory/products/{product_ok['id']}", headers=_auth(token))
    assert ok_after.json()["quantity_in_stock"] == 10  # untouched


@pytest.mark.asyncio
async def test_checkout_with_line_and_invoice_discount(client):
    token = await _register_owner(client)
    product = await _create_product(client, token, selling_price="100.00", gst_rate="0")

    response = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 2, "line_discount_amount": "10.00"}],
            "invoice_discount_amount": "20.00",
            "payment_method": "cash",
        },
        headers=_auth(token),
    )
    assert response.status_code == 201
    body = response.json()

    # 2 x 100 = 200 gross, -10 line discount = 190 subtotal.
    # -20 invoice discount, 0% GST => total 170.
    assert body["subtotal"] == "190.00"
    assert body["total_amount"] == "170.00"
    assert body["discount_amount"] == "30.00"  # 10 line + 20 invoice


@pytest.mark.asyncio
async def test_checkout_rejects_invoice_discount_exceeding_subtotal(client):
    token = await _register_owner(client)
    product = await _create_product(client, token, selling_price="10.00")

    response = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "invoice_discount_amount": "999.00",
            "payment_method": "cash",
        },
        headers=_auth(token),
    )
    assert response.status_code == 400
    assert "exceed" in response.json()["detail"]


@pytest.mark.asyncio
async def test_checkout_split_payment_must_match_total(client):
    token = await _register_owner(client)
    product = await _create_product(client, token, selling_price="50.00", gst_rate="0")

    mismatched = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "payment_splits": [{"method": "cash", "amount": "20.00"}, {"method": "card", "amount": "20.00"}],
        },
        headers=_auth(token),
    )
    assert mismatched.status_code == 400
    assert "does not match" in mismatched.json()["detail"]

    matched = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "payment_splits": [{"method": "cash", "amount": "20.00"}, {"method": "card", "amount": "30.00"}],
        },
        headers=_auth(token),
    )
    assert matched.status_code == 201
    assert matched.json()["is_split_payment"] is True


@pytest.mark.asyncio
async def test_checkout_rejects_duplicate_product_lines(client):
    token = await _register_owner(client)
    product = await _create_product(client, token)

    response = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [
                {"product_id": product["id"], "quantity": 1},
                {"product_id": product["id"], "quantity": 2},
            ],
            "payment_method": "cash",
        },
        headers=_auth(token),
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_checkout_requires_a_payment_method(client):
    token = await _register_owner(client)
    product = await _create_product(client, token)

    response = await client.post(
        "/api/v1/pos/checkout",
        json={"items": [{"product_id": product["id"], "quantity": 1}]},
        headers=_auth(token),
    )
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_get_and_list_invoices(client):
    token = await _register_owner(client)
    product = await _create_product(client, token)

    checkout_response = await client.post(
        "/api/v1/pos/checkout",
        json={"items": [{"product_id": product["id"], "quantity": 1}], "payment_method": "upi"},
        headers=_auth(token),
    )
    invoice_id = checkout_response.json()["id"]

    get_response = await client.get(f"/api/v1/pos/invoices/{invoice_id}", headers=_auth(token))
    assert get_response.status_code == 200
    assert get_response.json()["payment_method"] == "upi"

    list_response = await client.get("/api/v1/pos/invoices", headers=_auth(token))
    assert list_response.status_code == 200
    assert len(list_response.json()) == 1


@pytest.mark.asyncio
async def test_checkout_requires_authentication(client):
    response = await client.post("/api/v1/pos/checkout", json={"items": [], "payment_method": "cash"})
    assert response.status_code == 401
