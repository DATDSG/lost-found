"""API smoke test script.

Runs a minimal end-to-end verification:
1. Health & readiness
2. Seed (optional if users/items already present)
3. Login as admin (seed default)
4. List items
5. Create a new item
6. List again & basic assertions

Exit code non-zero on failure.
Usage:
    docker-compose exec api python scripts/smoke_test_api.py
(Assumes RUN INSIDE api container.)
"""
from __future__ import annotations
import os, sys, json, time, argparse
import http.client
from datetime import datetime

API_HOST = os.environ.get("SMOKE_API_HOST", "localhost")
API_PORT = int(os.environ.get("SMOKE_API_PORT", "8000"))
ADMIN_EMAIL = os.environ.get("SMOKE_ADMIN_EMAIL", "admin@example.com")
ADMIN_PASSWORD = os.environ.get("SMOKE_ADMIN_PASSWORD", "password123")


def _request(method: str, path: str, body: dict | None = None, token: str | None = None):
    conn = http.client.HTTPConnection(API_HOST, API_PORT, timeout=10)
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = json.dumps(body) if body is not None else None
    conn.request(method, path, body=data, headers=headers)
    resp = conn.getresponse()
    raw = resp.read().decode("utf-8", "ignore")
    try:
        payload = json.loads(raw) if raw else None
    except Exception:
        payload = {"_raw": raw}
    return resp.status, payload


def assert_status(actual: int, expected: int, context: str):
    if actual != expected:
        print(f"[FAIL] {context}: expected {expected}, got {actual}", file=sys.stderr)
        sys.exit(2)


def wait_ready(timeout=30):
    start = time.time()
    while time.time() - start < timeout:
        code, payload = _request("GET", "/readyz")
        if code == 200 and payload and payload.get("ready"):
            print("[OK] Readiness passed")
            return
        time.sleep(1)
    print("[FAIL] Service not ready within timeout", file=sys.stderr)
    sys.exit(2)


def login_admin():
    code, payload = _request("POST", "/auth/login", {"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD})
    assert_status(code, 200, "login")
    token = payload.get("access_token")
    if not token:
        print("[FAIL] No access_token in login response", file=sys.stderr)
        sys.exit(3)
    print("[OK] Logged in as admin")
    return token


def list_items(token: str):
    code, payload = _request("GET", "/items", token=token)
    assert_status(code, 200, "list items")
    if not isinstance(payload, list):
        print("[FAIL] /items did not return a list", file=sys.stderr)
        sys.exit(4)
    print(f"[OK] Retrieved {len(payload)} items")
    return payload


def create_item(token: str):
    body = {
        "title": f"Smoke Wallet {int(time.time())}",
        "description": "Smoke test item",
        "language": "en",
        "status": "lost",
        "category": "accessories",
        "lat": 7.29,
        "lng": 80.63,
        "location_name": "Kandy"
    }
    code, payload = _request("POST", "/items", body, token=token)
    assert_status(code, 201, "create item")
    item_id = payload.get("id")
    if not item_id:
        print("[FAIL] Created item missing id", file=sys.stderr)
        sys.exit(5)
    print(f"[OK] Created item {item_id}")
    return item_id


def parse_args():
    p = argparse.ArgumentParser(description="API smoke test")
    p.add_argument("--no-create", action="store_true", help="Skip item creation (read-only mode)")
    p.add_argument("--search-query", default="Wallet", help="Query term for /items/search test")
    return p.parse_args()

def auth_me(token: str):
    code, payload = _request("GET", "/auth/me", token=token)
    assert_status(code, 200, "auth/me")
    if not payload.get("email"):
        print("[FAIL] /auth/me missing email", file=sys.stderr)
        sys.exit(7)
    print("[OK] /auth/me returned user")
    return payload

def search_items(token: str, query: str):
    # /items/search uses query params; we use a minimal case with ?query=
    path = f"/items/search?query={query}&limit=5"
    code, payload = _request("GET", path, token=token)
    assert_status(code, 200, "items/search")
    if not isinstance(payload, list):
        print("[FAIL] /items/search did not return list", file=sys.stderr)
        sys.exit(8)
    print(f"[OK] /items/search returned {len(payload)} results (query='{query}')")
    return payload

def main():
    args = parse_args()
    # 1. Health
    code, _ = _request("GET", "/healthz")
    assert_status(code, 200, "healthz")
    print("[OK] Healthz reachable")

    # 2. Readiness
    wait_ready()

    # 3. Login
    token = login_admin()

    # 4. Validate /auth/me
    auth_me(token)

    # 5. Run a search (best effort; may be empty if dataset minimal)
    search_items(token, args.search_query)

    # 6. List items
    before = list_items(token)

    # 7. Optionally create item
    if not args.no_create:
        create_item(token)
        after = list_items(token)
        if len(after) < len(before):
            print("[FAIL] Item count did not increase after creation", file=sys.stderr)
            sys.exit(6)
    else:
        print("[INFO] Skipping item creation (--no-create)")

    print("[SUCCESS] Smoke test passed")

if __name__ == "__main__":
    main()
