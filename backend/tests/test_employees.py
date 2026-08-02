import pytest


async def _register_owner(client, email="owner@lycanos-test.dev"):
    response = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "Passw0rd", "full_name": "Owner", "business_name": "Test Traders"},
    )
    return response.json()["tokens"]["access_token"]


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


async def _create_employee(client, owner_token, **overrides):
    payload = {
        "email": "cashier@lycanos-test.dev",
        "password": "Passw0rd",
        "full_name": "Cash Ier",
        "role": "cashier",
    }
    payload.update(overrides)
    response = await client.post("/api/v1/employees", json=payload, headers=_auth(owner_token))
    return response


@pytest.mark.asyncio
async def test_owner_can_create_cashier(client):
    owner_token = await _register_owner(client)
    response = await _create_employee(client, owner_token)
    assert response.status_code == 201
    body = response.json()
    assert body["role"] == "cashier"
    assert body["email"] == "cashier@lycanos-test.dev"
    assert body["is_active"] is True


@pytest.mark.asyncio
async def test_created_employee_can_log_in(client):
    owner_token = await _register_owner(client)
    await _create_employee(client, owner_token, email="newcashier@lycanos-test.dev")

    login = await client.post(
        "/api/v1/auth/login", json={"email": "newcashier@lycanos-test.dev", "password": "Passw0rd"}
    )
    assert login.status_code == 200
    assert login.json()["user"]["role"] == "cashier"


@pytest.mark.asyncio
async def test_cannot_create_owner_via_employee_endpoint(client):
    owner_token = await _register_owner(client)
    response = await _create_employee(client, owner_token, role="owner")
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_employee_creation_rejects_weak_password(client):
    owner_token = await _register_owner(client)
    response = await _create_employee(client, owner_token, password="allletters")
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_duplicate_employee_email_rejected(client):
    owner_token = await _register_owner(client)
    await _create_employee(client, owner_token)
    second = await _create_employee(client, owner_token)
    assert second.status_code == 409


@pytest.mark.asyncio
async def test_manager_cannot_create_another_manager(client):
    owner_token = await _register_owner(client)
    await _create_employee(client, owner_token, email="manager@lycanos-test.dev", role="manager")
    manager_login = await client.post(
        "/api/v1/auth/login", json={"email": "manager@lycanos-test.dev", "password": "Passw0rd"}
    )
    manager_token = manager_login.json()["tokens"]["access_token"]

    response = await _create_employee(
        client, manager_token, email="anothermanager@lycanos-test.dev", role="manager"
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_manager_can_create_cashier(client):
    owner_token = await _register_owner(client)
    await _create_employee(client, owner_token, email="manager@lycanos-test.dev", role="manager")
    manager_login = await client.post(
        "/api/v1/auth/login", json={"email": "manager@lycanos-test.dev", "password": "Passw0rd"}
    )
    manager_token = manager_login.json()["tokens"]["access_token"]

    response = await _create_employee(client, manager_token, email="staffmember@lycanos-test.dev")
    assert response.status_code == 201


@pytest.mark.asyncio
async def test_cashier_cannot_create_employees(client):
    owner_token = await _register_owner(client)
    await _create_employee(client, owner_token, email="cashier1@lycanos-test.dev")
    cashier_login = await client.post(
        "/api/v1/auth/login", json={"email": "cashier1@lycanos-test.dev", "password": "Passw0rd"}
    )
    cashier_token = cashier_login.json()["tokens"]["access_token"]

    response = await _create_employee(client, cashier_token, email="cashier2@lycanos-test.dev")
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_list_employees_includes_owner_and_created_staff(client):
    owner_token = await _register_owner(client)
    await _create_employee(client, owner_token)

    response = await client.get("/api/v1/employees", headers=_auth(owner_token))
    assert response.status_code == 200
    assert len(response.json()) == 2


@pytest.mark.asyncio
async def test_update_employee_profile_fields(client):
    owner_token = await _register_owner(client)
    create_response = await _create_employee(client, owner_token)
    employee_id = create_response.json()["id"]

    response = await client.patch(
        f"/api/v1/employees/{employee_id}",
        json={"salary": "25000.00", "phone": "9998887777"},
        headers=_auth(owner_token),
    )
    assert response.status_code == 200
    assert response.json()["salary"] == "25000.00"
    assert response.json()["phone"] == "9998887777"


@pytest.mark.asyncio
async def test_deactivate_employee(client):
    owner_token = await _register_owner(client)
    create_response = await _create_employee(client, owner_token)
    employee_id = create_response.json()["id"]

    response = await client.patch(
        f"/api/v1/employees/{employee_id}", json={"is_active": False}, headers=_auth(owner_token)
    )
    assert response.status_code == 200
    assert response.json()["is_active"] is False


@pytest.mark.asyncio
async def test_cannot_deactivate_the_only_owner(client):
    owner_token = await _register_owner(client)
    me = await client.get("/api/v1/auth/me", headers=_auth(owner_token))
    owner_id = me.json()["id"]

    response = await client.patch(
        f"/api/v1/employees/{owner_id}", json={"is_active": False}, headers=_auth(owner_token)
    )
    assert response.status_code == 400
    assert "only active Owner" in response.json()["detail"]


@pytest.mark.asyncio
async def test_check_in_and_check_out(client):
    owner_token = await _register_owner(client)

    check_in = await client.post("/api/v1/employees/attendance/check-in", headers=_auth(owner_token))
    assert check_in.status_code == 200
    assert check_in.json()["check_in_at"] is not None
    assert check_in.json()["check_out_at"] is None

    check_out = await client.post("/api/v1/employees/attendance/check-out", headers=_auth(owner_token))
    assert check_out.status_code == 200
    assert check_out.json()["check_out_at"] is not None


@pytest.mark.asyncio
async def test_cannot_check_in_twice(client):
    owner_token = await _register_owner(client)
    await client.post("/api/v1/employees/attendance/check-in", headers=_auth(owner_token))

    second = await client.post("/api/v1/employees/attendance/check-in", headers=_auth(owner_token))
    assert second.status_code == 409


@pytest.mark.asyncio
async def test_cannot_check_out_before_checking_in(client):
    owner_token = await _register_owner(client)
    response = await client.post("/api/v1/employees/attendance/check-out", headers=_auth(owner_token))
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_attendance_history_visible_to_self(client):
    owner_token = await _register_owner(client)
    me = await client.get("/api/v1/auth/me", headers=_auth(owner_token))
    owner_id = me.json()["id"]

    await client.post("/api/v1/employees/attendance/check-in", headers=_auth(owner_token))

    response = await client.get(f"/api/v1/employees/{owner_id}/attendance", headers=_auth(owner_token))
    assert response.status_code == 200
    assert len(response.json()) == 1


@pytest.mark.asyncio
async def test_cashier_cannot_view_another_employees_attendance(client):
    owner_token = await _register_owner(client)
    await _create_employee(client, owner_token, email="cashier@lycanos-test.dev")
    cashier_login = await client.post(
        "/api/v1/auth/login", json={"email": "cashier@lycanos-test.dev", "password": "Passw0rd"}
    )
    cashier_token = cashier_login.json()["tokens"]["access_token"]

    me = await client.get("/api/v1/auth/me", headers=_auth(owner_token))
    owner_id = me.json()["id"]

    response = await client.get(f"/api/v1/employees/{owner_id}/attendance", headers=_auth(cashier_token))
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_sales_performance_reflects_cashier_checkouts(client):
    owner_token = await _register_owner(client)

    product_response = await client.post(
        "/api/v1/inventory/products",
        json={"name": "Item", "sku": "ITEM-1", "selling_price": "100.00", "gst_rate": "0", "quantity_in_stock": 50},
        headers=_auth(owner_token),
    )
    product = product_response.json()

    await client.post(
        "/api/v1/pos/checkout",
        json={"items": [{"product_id": product["id"], "quantity": 2}], "payment_method": "cash"},
        headers=_auth(owner_token),
    )

    response = await client.get("/api/v1/employees/performance", headers=_auth(owner_token))
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["total_sales"] == "200.00"
    assert response.json()[0]["invoice_count"] == 1


@pytest.mark.asyncio
async def test_activity_log_records_employee_creation(client):
    owner_token = await _register_owner(client)
    await _create_employee(client, owner_token)

    response = await client.get("/api/v1/employees/activity-log", headers=_auth(owner_token))
    assert response.status_code == 200
    actions = [entry["action"] for entry in response.json()]
    assert "employee.created" in actions


@pytest.mark.asyncio
async def test_employees_isolated_per_business(client):
    owner_a = await _register_owner(client, email="owner-a@lycanos-test.dev")
    owner_b = await _register_owner(client, email="owner-b@lycanos-test.dev")

    await _create_employee(client, owner_a, email="staff-a@lycanos-test.dev")

    response_b = await client.get("/api/v1/employees", headers=_auth(owner_b))
    assert len(response_b.json()) == 1


@pytest.mark.asyncio
async def test_employees_endpoint_requires_authentication(client):
    response = await client.get("/api/v1/employees")
    assert response.status_code == 401
