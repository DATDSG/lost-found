from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.deps import get_db, get_current_user
from app.db import models
from app.schemas.items import ItemCreate, ItemUpdate, ItemPublic


router = APIRouter()


@router.post("/", response_model=ItemPublic, status_code=201)
def create_item(payload: ItemCreate, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    item = models.Item(
        title=payload.title,
        description=payload.description,
        status=payload.status,
        lat=payload.lat,
        lng=payload.lng,
        owner_id=user.id,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return ItemPublic.model_validate(item)


@router.get("/", response_model=List[ItemPublic])
def list_items(db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    items = db.query(models.Item).filter(models.Item.owner_id == user.id).order_by(models.Item.id.desc()).all()
    return [ItemPublic.model_validate(i) for i in items]


@router.get("/{item_id}", response_model=ItemPublic)
def get_item(item_id: int, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    item = db.query(models.Item).filter(models.Item.id == item_id, models.Item.owner_id == user.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return ItemPublic.model_validate(item)


@router.patch("/{item_id}", response_model=ItemPublic)
def update_item(item_id: int, payload: ItemUpdate, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    item = db.query(models.Item).filter(models.Item.id == item_id, models.Item.owner_id == user.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(item, k, v)
    db.commit()
    db.refresh(item)
    return ItemPublic.model_validate(item)


@router.delete("/{item_id}", status_code=204)
def delete_item(item_id: int, db: Session = Depends(get_db), user: models.User = Depends(get_current_user)):
    item = db.query(models.Item).filter(models.Item.id == item_id, models.Item.owner_id == user.id).first()
    if not item:
        return # idempotent
    db.delete(item)
    db.commit()