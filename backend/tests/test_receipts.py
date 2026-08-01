import pytest


async def _register_owner(client, email="owner@lycanos-test.dev"):
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Passw0rd", "full_name": "Owner", "business_name": "Test Traders"},
    )
    return response.json()["tokens"]["access_token"]


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_receipt_returns_a_valid_pdf(client):
    token = await _register_owner(client)
    product_response = await client.post(
        "/api/v1/inventory/products",
        json={"name": "Parle-G", "sku": "PARLE-1", "selling_price": "10.00", "gst_rate": "5", "quantity_in_stock": 50},
        headers=_auth(token),
    )
    product = product_response.json()

    checkout_response = await client.post(
        "/api/v1/pos/checkout",
        json={"items": [{"product_id": product["id"], "quantity": 3}], "payment_method": "cash"},
        headers=_auth(token),
    )
    invoice_id = checkout_response.json()["id"]

    receipt_response = await client.get(f"/api/v1/pos/invoices/{invoice_id}/receipt", headers=_auth(token))
    assert receipt_response.status_code == 200
    assert receipt_response.headers["content-type"] == "application/pdf"
    # A real PDF starts with the %PDF- magic bytes — this confirms fpdf2
    # actually produced a valid file, not just any bytes.
    assert receipt_response.content.startswith(b"%PDF-")
    assert len(receipt_response.content) > 500


@pytest.mark.asyncio
async def test_receipt_for_nonexistent_invoice_returns_404(client):
    token = await _register_owner(client)
    response = await client.get(
        "/api/v1/pos/invoices/00000000-0000-0000-0000-000000000000/receipt", headers=_auth(token)
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_receipt_requires_authentication(client):
    response = await client.get("/api/v1/pos/invoices/00000000-0000-0000-0000-000000000000/receipt")
    assert response.status_code == 401
