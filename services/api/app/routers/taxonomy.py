"""Taxonomy routes for categories and colors."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List

from ..database import get_db
from ..models import Category, Color
from ..schemas import CategoryResponse, ColorResponse

router = APIRouter()


@router.get("/categories", response_model=List[CategoryResponse])
async def list_categories(
    db: AsyncSession = Depends(get_db),
    active_only: bool = True
):
    """List all categories."""
    query = select(Category)
    if active_only:
        query = query.where(Category.is_active == True)
    
    query = query.order_by(Category.sort_order)
    result = await db.execute(query)
    categories = result.scalars().all()
    return categories


@router.get("/categories/{category_id}", response_model=CategoryResponse)
async def get_category(
    category_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Get a specific category by ID."""
    result = await db.execute(
        select(Category).where(Category.id == category_id)
    )
    category = result.scalar_one_or_none()
    
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Category '{category_id}' not found"
        )
    return category


@router.get("/colors", response_model=List[ColorResponse])
async def list_colors(
    db: AsyncSession = Depends(get_db),
    active_only: bool = True
):
    """List all colors."""
    query = select(Color)
    if active_only:
        query = query.where(Color.is_active == True)
    
    query = query.order_by(Color.sort_order)
    result = await db.execute(query)
    colors = result.scalars().all()
    return colors


@router.get("/colors/{color_id}", response_model=ColorResponse)
async def get_color(
    color_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Get a specific color by ID."""
    result = await db.execute(
        select(Color).where(Color.id == color_id)
    )
    color = result.scalar_one_or_none()
    
    if not color:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Color '{color_id}' not found"
        )
    return color
