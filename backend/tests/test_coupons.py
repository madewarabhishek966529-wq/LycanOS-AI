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
    payload = {"name": "Item", "sku": "ITEM-1", "selling_price": "100.00", "gst_rate": "0", "quantity_in_stock": 100}
    payload.update(overrides)
    response = await client.post("/api/v1/inventory/products", json=payload, headers=_auth(token))
    assert response.status_code == 201
    return response.json()


@pytest.mark.asyncio
async def test_create_and_list_coupon(client):
    token = await _register_owner(client)
    response = await client.post(
        "/api/v1/pos/coupons",
        json={"code": "welcome10", "discount_type": "percentage", "discount_value": "10"},
        headers=_auth(token),
    )
    assert response.status_code == 201
    assert response.json()["code"] == "WELCOME10"  # normalized to uppercase

    list_response = await client.get("/api/v1/pos/coupons", headers=_auth(token))
    assert len(list_response.json()) == 1


@pytest.mark.asyncio
async def test_duplicate_coupon_code_rejected(client):
    token = await _register_owner(client)
    payload = {"code": "SAVE20", "discount_type": "flat", "discount_value": "20"}
    await client.post("/api/v1/pos/coupons", json=payload, headers=_auth(token))
    second = await client.post("/api/v1/pos/coupons", json=payload, headers=_auth(token))
    assert second.status_code == 409


@pytest.mark.asyncio
async def test_percentage_over_100_rejected(client):
    token = await _register_owner(client)
    response = await client.post(
        "/api/v1/pos/coupons",
        json={"code": "TOOMUCH", "discount_type": "percentage", "discount_value": "150"},
        headers=_auth(token),
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_checkout_with_percentage_coupon(client):
    token = await _register_owner(client)
    product = await _create_product(client, token, selling_price="100.00")
    await client.post(
        "/api/v1/pos/coupons",
        json={"code": "TEN", "discount_type": "percentage", "discount_value": "10"},
        headers=_auth(token),
    )

    response = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 2}],
            "coupon_code": "ten",  # lowercase input, should still resolve
            "payment_method": "cash",
        },
        headers=_auth(token),
    )
    assert response.status_code == 201
    body = response.json()
    # 2 x 100 = 200 subtotal, 10% off = 20 discount, total = 180
    assert body["subtotal"] == "200.00"
    assert body["total_amount"] == "180.00"


@pytest.mark.asyncio
async def test_checkout_coupon_capped_by_max_discount(client):
    token = await _register_owner(client)
    product = await _create_product(client, token, selling_price="1000.00")
    await client.post(
        "/api/v1/pos/coupons",
        json={
            "code": "BIGSAVE",
            "discount_type": "percentage",
            "discount_value": "50",
            "max_discount_amount": "100.00",
        },
        headers=_auth(token),
    )

    response = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "coupon_code": "BIGSAVE",
            "payment_method": "cash",
        },
        headers=_auth(token),
    )
    assert response.status_code == 201
    # 50% of 1000 = 500, but capped at max_discount_amount of 100
    assert response.json()["total_amount"] == "900.00"


@pytest.mark.asyncio
async def test_checkout_coupon_below_minimum_purchase_rejected(client):
    token = await _register_owner(client)
    product = await _create_product(client, token, selling_price="10.00")
    await client.post(
        "/api/v1/pos/coupons",
        json={"code": "BIGORDER", "discount_type": "flat", "discount_value": "5", "min_purchase_amount": "500.00"},
        headers=_auth(token),
    )

    response = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "coupon_code": "BIGORDER",
            "payment_method": "cash",
        },
        headers=_auth(token),
    )
    assert response.status_code == 400
    assert "minimum purchase" in response.json()["detail"]


@pytest.mark.asyncio
async def test_checkout_expired_coupon_rejected(client):
    token = await _register_owner(client)
    product = await _create_product(client, token)
    await client.post(
        "/api/v1/pos/coupons",
        json={"code": "OLDCODE", "discount_type": "flat", "discount_value": "5", "valid_until": "2020-01-01"},
        headers=_auth(token),
    )

    response = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "coupon_code": "OLDCODE",
            "payment_method": "cash",
        },
        headers=_auth(token),
    )
    assert response.status_code == 400
    assert "expired" in response.json()["detail"]


@pytest.mark.asyncio
async def test_checkout_unknown_coupon_rejected(client):
    token = await _register_owner(client)
    product = await _create_product(client, token)

    response = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "coupon_code": "DOESNOTEXIST",
            "payment_method": "cash",
        },
        headers=_auth(token),
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_checkout_rejects_coupon_and_manual_discount_together(client):
    token = await _register_owner(client)
    product = await _create_product(client, token)
    await client.post(
        "/api/v1/pos/coupons",
        json={"code": "STACK", "discount_type": "flat", "discount_value": "5"},
        headers=_auth(token),
    )

    response = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "coupon_code": "STACK",
            "invoice_discount_amount": "10.00",
            "payment_method": "cash",
        },
        headers=_auth(token),
    )
    assert response.status_code == 400
    assert "not both" in response.json()["detail"]


@pytest.mark.asyncio
async def test_deactivated_coupon_cannot_be_applied(client):
    token = await _register_owner(client)
    product = await _create_product(client, token)
    await client.post(
        "/api/v1/pos/coupons",
        json={"code": "GONE", "discount_type": "flat", "discount_value": "5"},
        headers=_auth(token),
    )
    await client.post("/api/v1/pos/coupons/GONE/deactivate", headers=_auth(token))

    response = await client.post(
        "/api/v1/pos/checkout",
        json={
            "items": [{"product_id": product["id"], "quantity": 1}],
            "coupon_code": "GONE",
            "payment_method": "cash",
        },
        headers=_auth(token),
    )
    assert response.status_code == 404
