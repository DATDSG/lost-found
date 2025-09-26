from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.db import models
from app.core.security import get_password_hash

def init() -> None:
    db: Session = SessionLocal()
    if not db.query(models.User).filter(models.User.email == "admin@example.com").first():
        u = models.User(
            email="admin@example.com",
            full_name="Admin",
            hashed_password=get_password_hash("admin123"),
            is_superuser=True,
        )
    db.add(u)
    db.commit()
    db.close()

if __name__ == "__main__":
    init()