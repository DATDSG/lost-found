from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core import security
from app.core.deps import get_db, get_current_user
from app.db import models
from app.schemas.auth import Token, UserCreate, UserPublic, LoginRequest
from app.core.config import settings


router = APIRouter()


@router.post("/register", response_model=UserPublic, status_code=201)
def register(payload: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(models.User).filter(models.User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    user = models.User(
        email=payload.email,
        hashed_password=security.get_password_hash(payload.password),
        full_name=payload.full_name,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return UserPublic.model_validate(user)


@router.post("/login", response_model=Token)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    if payload.email == settings.ADMIN_EMAIL:
        user = db.query(models.User).filter(models.User.email == payload.email).first()
        if not user:
            user = models.User(
                email=settings.ADMIN_EMAIL,
                hashed_password=security.get_password_hash(settings.ADMIN_PASSWORD),
                full_name="Admin",
                is_superuser=True,
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        if not security.verify_password(payload.password, user.hashed_password):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    else:
        user = db.query(models.User).filter(models.User.email == payload.email).first()
        if not user or not security.verify_password(payload.password, user.hashed_password):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if not user or not security.verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    access_token_expires = timedelta(minutes=security.settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    token = security.create_access_token({"sub": str(user.id), "is_superuser": str(user.is_superuser)}, expires_delta=access_token_expires)
    return Token(access_token=token, token_type="bearer")


@router.get("/me", response_model=UserPublic)
def me(user: models.User = Depends(get_current_user)):
    return UserPublic.model_validate(user)