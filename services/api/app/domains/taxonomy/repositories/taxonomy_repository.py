"""
Taxonomy Repository
====================
Repository layer for taxonomy data access with proper abstraction and error handling.
"""

from typing import Optional, List, Dict, Any, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func, and_, or_, desc
from sqlalchemy.orm import selectinload
from sqlalchemy.exc import IntegrityError, NoResultFound
import logging
from datetime import datetime, timedelta
import uuid

from ..models.category import Category
from ..schemas.taxonomy_schemas import (
    CategoryCreate, CategoryUpdate, CategorySearchRequest, CategoryType, CategoryStatus
)

logger = logging.getLogger(__name__)


class TaxonomyRepository:
    """Repository for taxonomy data access operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create(self, category_dict: Dict[str, Any]) -> Category:
        """
        Create a new category.
        
        Args:
            category_dict: Category data dictionary
            
        Returns:
            Created category instance
            
        Raises:
            IntegrityError: If constraint violation occurs
            ValueError: If validation fails
        """
        try:
            category = Category(**category_dict)
            self.db.add(category)
            await self.db.commit()
            await self.db.refresh(category)
            
            logger.info(f"Category created successfully: {category.name}")
            return category
            
        except IntegrityError as e:
            await self.db.rollback()
            logger.error(f"Category creation failed - constraint violation: {e}")
            raise ValueError("Category creation failed due to constraint violation")
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Category creation failed: {e}")
            raise
    
    async def get_by_id(self, category_id: str) -> Optional[Category]:
        """
        Get category by ID.
        
        Args:
            category_id: Category UUID string
            
        Returns:
            Category instance or None if not found
        """
        try:
            query = select(Category).where(Category.id == category_id)
            result = await self.db.execute(query)
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Error getting category by ID {category_id}: {e}")
            return None
    
    async def get_category_by_name(self, name: str) -> Optional[Category]:
        """
        Get category by name.
        
        Args:
            name: Category name
            
        Returns:
            Category instance or None if not found
        """
        try:
            query = select(Category).where(Category.name == name)
            result = await self.db.execute(query)
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Error getting category by name {name}: {e}")
            return None
    
    async def update(self, category_id: str, update_dict: Dict[str, Any]) -> Optional[Category]:
        """
        Update category with validation and error handling.
        
        Args:
            category_id: Category UUID string
            update_dict: Update data dictionary
            
        Returns:
            Updated category instance or None if not found
        """
        try:
            # Get existing category
            category = await self.get_by_id(category_id)
            if not category:
                return None
            
            # Update fields
            for field, value in update_dict.items():
                if hasattr(category, field):
                    setattr(category, field, value)
            
            await self.db.commit()
            await self.db.refresh(category)
            
            logger.info(f"Category updated successfully: {category_id}")
            return category
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Category update failed for {category_id}: {e}")
            raise
    
    async def delete(self, category_id: str) -> bool:
        """
        Delete category permanently.
        
        Args:
            category_id: Category UUID string
            
        Returns:
            True if successful, False if not found
        """
        try:
            query = delete(Category).where(Category.id == category_id)
            result = await self.db.execute(query)
            await self.db.commit()
            
            if result.rowcount > 0:
                logger.info(f"Category deleted successfully: {category_id}")
                return True
            return False
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Category deletion failed for {category_id}: {e}")
            return False
    
    async def search_categories(self, search_request: CategorySearchRequest) -> Tuple[List[Category], int]:
        """
        Search categories with pagination and filters.
        
        Args:
            search_request: Search parameters
            
        Returns:
            Tuple of (categories list, total count)
        """
        try:
            # Base query
            base_query = select(Category)
            
            # Apply filters
            conditions = []
            
            if search_request.category_type:
                conditions.append(Category.category_type == search_request.category_type)
            
            if search_request.status:
                conditions.append(Category.status == search_request.status)
            
            if search_request.parent_id:
                conditions.append(Category.parent_id == search_request.parent_id)
            
            if search_request.query:
                query_lower = search_request.query.lower()
                conditions.append(
                    or_(
                        Category.name.ilike(f"%{query_lower}%"),
                        Category.description.ilike(f"%{query_lower}%")
                    )
                )
            
            if search_request.created_after:
                conditions.append(Category.created_at >= search_request.created_after)
            
            if search_request.created_before:
                conditions.append(Category.created_at <= search_request.created_before)
            
            # Apply conditions
            if conditions:
                search_query = base_query.where(and_(*conditions))
            else:
                search_query = base_query
            
            # Get total count
            count_query = select(func.count()).select_from(search_query.subquery())
            total_result = await self.db.execute(count_query)
            total = total_result.scalar()
            
            # Get paginated results
            categories_query = (
                search_query
                .offset(search_request.offset)
                .limit(search_request.limit)
                .order_by(Category.name.asc())
            )
            
            result = await self.db.execute(categories_query)
            categories = result.scalars().all()
            
            return list(categories), total
            
        except Exception as e:
            logger.error(f"Category search failed: {e}")
            return [], 0
    
    async def get_category_children(self, category_id: str) -> List[Category]:
        """
        Get direct children of a category.
        
        Args:
            category_id: Parent category UUID string
            
        Returns:
            List of child category instances
        """
        try:
            query = (
                select(Category)
                .where(Category.parent_id == category_id)
                .order_by(Category.name.asc())
            )
            result = await self.db.execute(query)
            return list(result.scalars().all())
        except Exception as e:
            logger.error(f"Error getting category children {category_id}: {e}")
            return []
    
    async def get_category_parents(self, category_id: str) -> List[Category]:
        """
        Get all parent categories up to the root.
        
        Args:
            category_id: Category UUID string
            
        Returns:
            List of parent category instances (from immediate parent to root)
        """
        try:
            parents = []
            current_id = category_id
            
            while current_id:
                query = select(Category).where(Category.id == current_id)
                result = await self.db.execute(query)
                category = result.scalar_one_or_none()
                
                if not category or not category.parent_id:
                    break
                
                # Get parent
                parent_query = select(Category).where(Category.id == category.parent_id)
                parent_result = await self.db.execute(parent_query)
                parent = parent_result.scalar_one_or_none()
                
                if parent:
                    parents.append(parent)
                    current_id = parent.parent_id
                else:
                    break
            
            return parents
            
        except Exception as e:
            logger.error(f"Error getting category parents {category_id}: {e}")
            return []
    
    async def get_category_descendants(self, category_id: str) -> List[Category]:
        """
        Get all descendant categories recursively.
        
        Args:
            category_id: Parent category UUID string
            
        Returns:
            List of descendant category instances
        """
        try:
            descendants = []
            
            def get_children_recursive(parent_id: str):
                children = await self.get_category_children(parent_id)
                for child in children:
                    descendants.append(child)
                    get_children_recursive(child.id)
            
            get_children_recursive(category_id)
            return descendants
            
        except Exception as e:
            logger.error(f"Error getting category descendants {category_id}: {e}")
            return []
    
    async def get_category_tree(self, category_type: Optional[CategoryType] = None) -> List[Dict[str, Any]]:
        """
        Get hierarchical category tree.
        
        Args:
            category_type: Optional category type filter
            
        Returns:
            List of category tree nodes with children
        """
        try:
            # Get root categories
            root_query = select(Category).where(Category.parent_id.is_(None))
            if category_type:
                root_query = root_query.where(Category.category_type == category_type)
            
            root_query = root_query.order_by(Category.name.asc())
            result = await self.db.execute(root_query)
            root_categories = list(result.scalars().all())
            
            # Build tree recursively
            def build_tree(categories: List[Category]) -> List[Dict[str, Any]]:
                tree = []
                for category in categories:
                    children = await self.get_category_children(category.id)
                    node = {
                        "id": str(category.id),
                        "name": category.name,
                        "description": category.description,
                        "category_type": category.category_type.value,
                        "status": category.status.value,
                        "parent_id": str(category.parent_id) if category.parent_id else None,
                        "sort_order": category.sort_order,
                        "created_at": category.created_at.isoformat(),
                        "updated_at": category.updated_at.isoformat(),
                        "children": build_tree(children) if children else []
                    }
                    tree.append(node)
                return tree
            
            return build_tree(root_categories)
            
        except Exception as e:
            logger.error(f"Error getting category tree: {e}")
            return []
    
    async def update_category_status(self, category_id: str, status: CategoryStatus) -> bool:
        """
        Update category status.
        
        Args:
            category_id: Category UUID string
            status: New category status
            
        Returns:
            True if successful, False otherwise
        """
        try:
            query = (
                update(Category)
                .where(Category.id == category_id)
                .values(
                    status=status.value,
                    updated_at=datetime.utcnow()
                )
            )
            
            result = await self.db.execute(query)
            await self.db.commit()
            
            if result.rowcount > 0:
                logger.info(f"Category status updated: {category_id} -> {status.value}")
                return True
            return False
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Category status update failed for {category_id}: {e}")
            return False
    
    async def get_categories_by_type(self, category_type: CategoryType) -> List[Category]:
        """
        Get all categories of a specific type.
        
        Args:
            category_type: Category type filter
            
        Returns:
            List of category instances
        """
        try:
            query = (
                select(Category)
                .where(Category.category_type == category_type)
                .order_by(Category.name.asc())
            )
            result = await self.db.execute(query)
            return list(result.scalars().all())
        except Exception as e:
            logger.error(f"Error getting categories by type {category_type}: {e}")
            return []
    
    async def get_root_categories(self, category_type: Optional[CategoryType] = None) -> List[Category]:
        """
        Get all root categories (categories without parents).
        
        Args:
            category_type: Optional category type filter
            
        Returns:
            List of root category instances
        """
        try:
            query = select(Category).where(Category.parent_id.is_(None))
            if category_type:
                query = query.where(Category.category_type == category_type)
            
            query = query.order_by(Category.name.asc())
            result = await self.db.execute(query)
            return list(result.scalars().all())
        except Exception as e:
            logger.error(f"Error getting root categories: {e}")
            return []
    
    async def get_category_usage_count(self, category_id: str) -> int:
        """
        Get count of reports using this category.
        
        Args:
            category_id: Category UUID string
            
        Returns:
            Number of reports using this category
        """
        try:
            from app.domains.reports.models.report import Report
            
            query = select(func.count(Report.id)).where(Report.category == category_id)
            result = await self.db.execute(query)
            return result.scalar() or 0
        except Exception as e:
            logger.error(f"Error getting category usage count {category_id}: {e}")
            return 0
    
    async def get_category_statistics(self) -> Optional[Dict[str, Any]]:
        """
        Get comprehensive category statistics.
        
        Returns:
            Category statistics dictionary
        """
        try:
            # Total categories
            total_categories_query = select(func.count(Category.id))
            total_categories = await self.db.scalar(total_categories_query) or 0
            
            # Categories by status
            active_categories_query = select(func.count(Category.id)).where(Category.status == CategoryStatus.ACTIVE)
            active_categories = await self.db.scalar(active_categories_query) or 0
            
            inactive_categories_query = select(func.count(Category.id)).where(Category.status == CategoryStatus.INACTIVE)
            inactive_categories = await self.db.scalar(inactive_categories_query) or 0
            
            # Categories by type
            item_categories_query = select(func.count(Category.id)).where(Category.category_type == CategoryType.ITEM)
            item_categories = await self.db.scalar(item_categories_query) or 0
            
            location_categories_query = select(func.count(Category.id)).where(Category.category_type == CategoryType.LOCATION)
            location_categories = await self.db.scalar(location_categories_query) or 0
            
            # Root categories
            root_categories_query = select(func.count(Category.id)).where(Category.parent_id.is_(None))
            root_categories = await self.db.scalar(root_categories_query) or 0
            
            # Categories with children
            categories_with_children_query = select(func.count(func.distinct(Category.parent_id))).where(Category.parent_id.isnot(None))
            categories_with_children = await self.db.scalar(categories_with_children_query) or 0
            
            # Recent categories (last 7 days)
            week_ago = datetime.utcnow() - timedelta(days=7)
            recent_categories_query = select(func.count(Category.id)).where(Category.created_at >= week_ago)
            recent_categories = await self.db.scalar(recent_categories_query) or 0
            
            return {
                "total_categories": total_categories,
                "by_status": {
                    "active": active_categories,
                    "inactive": inactive_categories
                },
                "by_type": {
                    "item": item_categories,
                    "location": location_categories
                },
                "hierarchy": {
                    "root_categories": root_categories,
                    "categories_with_children": categories_with_children,
                    "leaf_categories": total_categories - categories_with_children
                },
                "activity": {
                    "recent_categories_7_days": recent_categories
                }
            }
            
        except Exception as e:
            logger.error(f"Error getting category statistics: {e}")
            return None
    
    async def get_recent_categories(self, limit: int = 20) -> List[Category]:
        """
        Get recently created categories.
        
        Args:
            limit: Maximum number of categories to return
            
        Returns:
            List of recent category instances
        """
        try:
            query = (
                select(Category)
                .order_by(desc(Category.created_at))
                .limit(limit)
            )
            result = await self.db.execute(query)
            return list(result.scalars().all())
        except Exception as e:
            logger.error(f"Error getting recent categories: {e}")
            return []
    
    async def get_categories_by_name_pattern(self, pattern: str) -> List[Category]:
        """
        Get categories matching a name pattern.
        
        Args:
            pattern: Name pattern to match
            
        Returns:
            List of matching category instances
        """
        try:
            query = (
                select(Category)
                .where(Category.name.ilike(f"%{pattern}%"))
                .order_by(Category.name.asc())
            )
            result = await self.db.execute(query)
            return list(result.scalars().all())
        except Exception as e:
            logger.error(f"Error getting categories by name pattern {pattern}: {e}")
            return []
