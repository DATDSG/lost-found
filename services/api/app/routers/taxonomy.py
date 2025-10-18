"""Taxonomy routes for categories and colors."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..models import Category, Color
from ..schemas import CategoryResponse, ColorResponse

router = APIRouter()


@router.get("/categories", response_model=List[CategoryResponse])
def list_categories(
    db: Session = Depends(get_db),
    active_only: bool = True
):
    """List all categories."""
    query = db.query(Category)
    if active_only:
        query = query.filter(Category.is_active == True)
    
    categories = query.order_by(Category.sort_order).all()
    return categories


@router.get("/categories/{category_id}", response_model=CategoryResponse)
def get_category(
    category_id: str,
    db: Session = Depends(get_db)
):
    """Get a specific category by ID."""
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Category '{category_id}' not found"
        )
    return category


@router.get("/colors", response_model=List[ColorResponse])
def list_colors(
    db: Session = Depends(get_db),
    active_only: bool = True
):
    """List all colors."""
    query = db.query(Color)
    if active_only:
        query = query.filter(Color.is_active == True)
    
    colors = query.order_by(Color.sort_order).all()
    return colors


@router.get("/colors/{color_id}", response_model=ColorResponse)
def get_color(
    color_id: str,
    db: Session = Depends(get_db)
):
    """Get a specific color by ID."""
    color = db.query(Color).filter(Color.id == color_id).first()
    if not color:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Color '{color_id}' not found"
        )
    return color
