from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.core.deps import get_db
from app.db.session import Base

engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base.metadata.create_all(bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)

def auth_headers():
    client.post("/auth/register", json={"email": "c@d.com", "password": "pw"})
    token = client.post("/auth/login", json={"email": "c@d.com", "password": "pw"}).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

def test_crud_items():
    h = auth_headers()
    r = client.post("/items/", json={"title": "Wallet", "description": "Black", "status": "lost"}, headers=h)
    assert r.status_code == 201
    item_id = r.json()["id"]

    r = client.get("/items/", headers=h)
    assert r.status_code == 200
    assert len(r.json()) == 1

    r = client.patch(f"/items/{item_id}", json={"status": "found"}, headers=h)
    assert r.status_code == 200
    assert r.json()["status"] == "found"

    r = client.delete(f"/items/{item_id}", headers=h)
    assert r.status_code == 204

    r = client.get("/items/", headers=h)
    assert r.status_code == 200
    assert r.json() == []