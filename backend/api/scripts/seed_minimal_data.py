"""Seed minimal development data for the Lost & Found API service.

This script is intentionally idempotent: it will not duplicate existing core records.

It seeds:
- One admin user
- One regular user
- A couple of sample items (lost + found) tied to those users

Usage (inside running api container):
    docker-compose exec api python scripts/seed_minimal_data.py

Or from host (Windows PowerShell):
    docker-compose exec api python scripts/seed_minimal_data.py

Environment requirements:
    DATABASE_URL must point to the Postgres instance (already set in container)
"""
from __future__ import annotations
import os
from datetime import datetime, timedelta, timezone
import sys
from pathlib import Path

# Ensure project root (containing app package) is on PYTHONPATH when executed directly
ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from app.db.session import SessionLocal
from app.db import models

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ADMIN_EMAIL = "admin@example.com"
USER_EMAIL = "user@example.com"


def get_db() -> Session:
    return SessionLocal()


def get_or_create_user(db: Session, email: str, is_superuser: bool = False) -> models.User:
    user = db.query(models.User).filter(models.User.email == email).one_or_none()
    if user:
        return user
    user = models.User(
        email=email,
        hashed_password=pwd_context.hash("password123"),
        full_name="Admin User" if is_superuser else "Regular User",
        is_superuser=is_superuser,
        is_active=True,
        preferred_language="en",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def get_or_create_item(db: Session, owner: models.User, title: str, status: str, category: str, **extra) -> models.Item:
    existing = db.query(models.Item).filter(
        models.Item.owner_id == owner.id,
        models.Item.title == title,
        models.Item.status == status,
    ).one_or_none()
    if existing:
        return existing

    item = models.Item(
        title=title,
        description=extra.get("description", f"Seed item {title}"),
        language="en",
        status=status,
        category=category,
        subcategory=extra.get("subcategory"),
        brand=extra.get("brand"),
        model=extra.get("model"),
        color=extra.get("color"),
        unique_marks=extra.get("unique_marks"),
        evidence_hash=extra.get("evidence_hash"),
        location_name=extra.get("location_name"),
        lost_found_at=datetime.now(timezone.utc) - timedelta(hours=extra.get("age_hours", 12)),
        owner_id=owner.id,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def main():
    db = get_db()
    try:
        admin = get_or_create_user(db, ADMIN_EMAIL, is_superuser=True)
        user = get_or_create_user(db, USER_EMAIL, is_superuser=False)

        get_or_create_item(db, admin, title="Black Backpack", status="lost", category="bags", color="black", description="Contains laptop and notebooks")
        get_or_create_item(db, user, title="Silver Phone", status="found", category="electronics", subcategory="phone", brand="Generic", description="Found near bus stop")

        print("Seed complete:")
        print(f"  Admin: {admin.email} (password: password123)")
        print(f"  User : {user.email} (password: password123)")
    finally:
        db.close()

if __name__ == "__main__":
    main()
