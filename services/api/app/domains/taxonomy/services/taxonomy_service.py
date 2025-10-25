"""
Taxonomy Service
================
Business logic layer for taxonomy operations with proper validation and error handling.
"""

from typing import Optional, Dict, Any, Tuple, List
from sqlalchemy.ext.asyncio import AsyncSession
import logging
from datetime import datetime
import uuid

from ..schemas.taxonomy_schemas import (
    CategoryCreate, CategoryUpdate, CategoryResponse, CategorySearchRequest,
    CategorySearchResponse, CategoryStats, CategoryType, CategoryStatus
)
from ..repositories.taxonomy_repository import TaxonomyRepository
from ..models.category import Category

logger = logging.getLogger(__name__)


class TaxonomyService:
    """Service layer for taxonomy business logic."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repository = TaxonomyRepository(db)
    
    async def create_category(self, category_data: CategoryCreate) -> Tuple[bool, Optional[CategoryResponse], Optional[str]]:
        """
        Create a new category with comprehensive validation.
        
        Args:
            category_data: Category creation data
            
        Returns:
            Tuple of (success, category_response, error_message)
        """
        try:
            # Check if category name already exists
            existing_category = await self.repository.get_category_by_name(category_data.name)
            if existing_category:
                return False, None, "Category name already exists"
            
            # Validate parent category if provided
            if category_data.parent_id:
                parent_category = await self.repository.get_category_by_id(category_data.parent_id)
                if not parent_category:
                    return False, None, "Parent category not found"
                
                # Check if parent category is of the same type
                if parent_category.category_type != category_data.category_type:
                    return False, None, "Parent category must be of the same type"
            
            # Create category
            category_dict = category_data.model_dump()
            category_dict["id"] = str(uuid.uuid4())
            category_dict["status"] = CategoryStatus.ACTIVE.value
            category_dict["created_at"] = datetime.utcnow()
            category_dict["updated_at"] = datetime.utcnow()
            
            category = await self.repository.create(category_dict)
            category_response = CategoryResponse.model_validate(category)
            
            logger.info(f"Category created successfully: {category.name}")
            return True, category_response, None
            
        except ValueError as e:
            return False, None, str(e)
        except Exception as e:
            logger.error(f"Category creation failed: {e}")
            return False, None, "Failed to create category"
    
    async def get_category(self, category_id: str) -> Tuple[bool, Optional[CategoryResponse], Optional[str]]:
        """
        Get a specific category by ID.
        
        Args:
            category_id: Category UUID string
            
        Returns:
            Tuple of (success, category_response, error_message)
        """
        try:
            category = await self.repository.get_by_id(category_id)
            if not category:
                return False, None, "Category not found"
            
            category_response = CategoryResponse.model_validate(category)
            return True, category_response, None
            
        except Exception as e:
            logger.error(f"Error getting category {category_id}: {e}")
            return False, None, "Failed to get category"
    
    async def update_category(self, category_id: str, update_data: CategoryUpdate) -> Tuple[bool, Optional[CategoryResponse], Optional[str]]:
        """
        Update a category with validation.
        
        Args:
            category_id: Category UUID string
            update_data: Update data
            
        Returns:
            Tuple of (success, updated_category_response, error_message)
        """
        try:
            # Get existing category
            category = await self.repository.get_by_id(category_id)
            if not category:
                return False, None, "Category not found"
            
            # Check if new name conflicts with existing categories
            if update_data.name and update_data.name != category.name:
                existing_category = await self.repository.get_category_by_name(update_data.name)
                if existing_category and existing_category.id != category_id:
                    return False, None, "Category name already exists"
            
            # Validate parent category if provided
            if update_data.parent_id:
                if update_data.parent_id == category_id:
                    return False, None, "Category cannot be its own parent"
                
                parent_category = await self.repository.get_category_by_id(update_data.parent_id)
                if not parent_category:
                    return False, None, "Parent category not found"
                
                # Check if parent category is of the same type
                if parent_category.category_type != category.category_type:
                    return False, None, "Parent category must be of the same type"
            
            # Update category
            update_dict = update_data.model_dump(exclude_unset=True)
            update_dict["updated_at"] = datetime.utcnow()
            
            updated_category = await self.repository.update(category_id, update_dict)
            if not updated_category:
                return False, None, "Failed to update category"
            
            category_response = CategoryResponse.model_validate(updated_category)
            
            logger.info(f"Category updated successfully: {category_id}")
            return True, category_response, None
            
        except Exception as e:
            logger.error(f"Error updating category {category_id}: {e}")
            return False, None, "Failed to update category"
    
    async def delete_category(self, category_id: str) -> Tuple[bool, Optional[str]]:
        """
        Delete a category.
        
        Args:
            category_id: Category UUID string
            
        Returns:
            Tuple of (success, error_message)
        """
        try:
            # Check if category has children
            children = await self.repository.get_category_children(category_id)
            if children:
                return False, "Cannot delete category with child categories"
            
            # Check if category is used in reports
            usage_count = await self.repository.get_category_usage_count(category_id)
            if usage_count > 0:
                return False, f"Cannot delete category used in {usage_count} reports"
            
            # Delete category
            success = await self.repository.delete(category_id)
            if not success:
                return False, "Category not found"
            
            logger.info(f"Category deleted successfully: {category_id}")
            return True, None
            
        except Exception as e:
            logger.error(f"Error deleting category {category_id}: {e}")
            return False, "Failed to delete category"
    
    async def search_categories(self, search_request: CategorySearchRequest) -> Tuple[bool, Optional[CategorySearchResponse], Optional[str]]:
        """
        Search categories with pagination and filters.
        
        Args:
            search_request: Search parameters
            
        Returns:
            Tuple of (success, search_response, error_message)
        """
        try:
            categories, total = await self.repository.search_categories(search_request)
            
            # Convert to CategoryResponse schemas
            category_responses = []
            for category in categories:
                category_response = CategoryResponse.model_validate(category)
                category_responses.append(category_response)
            
            search_response = CategorySearchResponse(
                categories=category_responses,
                total=total,
                page=search_request.page,
                page_size=search_request.page_size,
                has_next=total > (search_request.page * search_request.page_size),
                has_prev=search_request.page > 1
            )
            
            return True, search_response, None
            
        except Exception as e:
            logger.error(f"Error searching categories: {e}")
            return False, None, "Failed to search categories"
    
    async def get_category_statistics(self) -> Tuple[bool, Optional[CategoryStats], Optional[str]]:
        """
        Get comprehensive category statistics.
        
        Returns:
            Tuple of (success, category_stats, error_message)
        """
        try:
            stats_data = await self.repository.get_category_statistics()
            if not stats_data:
                return False, None, "Failed to get category statistics"
            
            stats = CategoryStats(**stats_data)
            return True, stats, None
            
        except Exception as e:
            logger.error(f"Error getting category statistics: {e}")
            return False, None, "Failed to get category statistics"
    
    async def get_category_tree(self, category_type: Optional[CategoryType] = None) -> Tuple[bool, List[Dict[str, Any]], Optional[str]]:
        """
        Get hierarchical category tree.
        
        Args:
            category_type: Optional category type filter
            
        Returns:
            Tuple of (success, category_tree, error_message)
        """
        try:
            tree = await self.repository.get_category_tree(category_type)
            return True, tree, None
            
        except Exception as e:
            logger.error(f"Error getting category tree: {e}")
            return False, [], "Failed to get category tree"
    
    async def get_category_children(self, category_id: str) -> Tuple[bool, List[CategoryResponse], Optional[str]]:
        """
        Get direct children of a category.
        
        Args:
            category_id: Parent category UUID string
            
        Returns:
            Tuple of (success, children_list, error_message)
        """
        try:
            children = await self.repository.get_category_children(category_id)
            
            # Convert to CategoryResponse schemas
            children_responses = []
            for child in children:
                child_response = CategoryResponse.model_validate(child)
                children_responses.append(child_response)
            
            return True, children_responses, None
            
        except Exception as e:
            logger.error(f"Error getting category children {category_id}: {e}")
            return False, [], "Failed to get category children"
    
    async def get_category_parents(self, category_id: str) -> Tuple[bool, List[CategoryResponse], Optional[str]]:
        """
        Get all parent categories up to the root.
        
        Args:
            category_id: Category UUID string
            
        Returns:
            Tuple of (success, parents_list, error_message)
        """
        try:
            parents = await self.repository.get_category_parents(category_id)
            
            # Convert to CategoryResponse schemas
            parents_responses = []
            for parent in parents:
                parent_response = CategoryResponse.model_validate(parent)
                parents_responses.append(parent_response)
            
            return True, parents_responses, None
            
        except Exception as e:
            logger.error(f"Error getting category parents {category_id}: {e}")
            return False, [], "Failed to get category parents"
    
    async def update_category_status(self, category_id: str, status: CategoryStatus) -> Tuple[bool, Optional[str]]:
        """
        Update category status.
        
        Args:
            category_id: Category UUID string
            status: New category status
            
        Returns:
            Tuple of (success, error_message)
        """
        try:
            success = await self.repository.update_category_status(category_id, status)
            if not success:
                return False, "Category not found"
            
            logger.info(f"Category status updated: {category_id} -> {status.value}")
            return True, None
            
        except Exception as e:
            logger.error(f"Error updating category status {category_id}: {e}")
            return False, "Failed to update category status"
    
    async def get_categories_by_type(self, category_type: CategoryType) -> Tuple[bool, List[CategoryResponse], Optional[str]]:
        """
        Get all categories of a specific type.
        
        Args:
            category_type: Category type filter
            
        Returns:
            Tuple of (success, categories_list, error_message)
        """
        try:
            categories = await self.repository.get_categories_by_type(category_type)
            
            # Convert to CategoryResponse schemas
            category_responses = []
            for category in categories:
                category_response = CategoryResponse.model_validate(category)
                category_responses.append(category_response)
            
            return True, category_responses, None
            
        except Exception as e:
            logger.error(f"Error getting categories by type {category_type}: {e}")
            return False, [], "Failed to get categories by type"
    
    async def get_root_categories(self, category_type: Optional[CategoryType] = None) -> Tuple[bool, List[CategoryResponse], Optional[str]]:
        """
        Get all root categories (categories without parents).
        
        Args:
            category_type: Optional category type filter
            
        Returns:
            Tuple of (success, root_categories_list, error_message)
        """
        try:
            root_categories = await self.repository.get_root_categories(category_type)
            
            # Convert to CategoryResponse schemas
            root_responses = []
            for category in root_categories:
                category_response = CategoryResponse.model_validate(category)
                root_responses.append(category_response)
            
            return True, root_responses, None
            
        except Exception as e:
            logger.error(f"Error getting root categories: {e}")
            return False, [], "Failed to get root categories"
    
    async def move_category(self, category_id: str, new_parent_id: Optional[str]) -> Tuple[bool, Optional[str]]:
        """
        Move a category to a new parent.
        
        Args:
            category_id: Category UUID string
            new_parent_id: New parent category UUID string (None for root)
            
        Returns:
            Tuple of (success, error_message)
        """
        try:
            # Get category
            category = await self.repository.get_by_id(category_id)
            if not category:
                return False, "Category not found"
            
            # Validate new parent
            if new_parent_id:
                parent_category = await self.repository.get_category_by_id(new_parent_id)
                if not parent_category:
                    return False, "Parent category not found"
                
                # Check if parent category is of the same type
                if parent_category.category_type != category.category_type:
                    return False, "Parent category must be of the same type"
                
                # Check for circular reference
                if new_parent_id == category_id:
                    return False, "Category cannot be its own parent"
                
                # Check if new parent is a descendant of current category
                descendants = await self.repository.get_category_descendants(category_id)
                if any(desc.id == new_parent_id for desc in descendants):
                    return False, "Cannot move category to its own descendant"
            
            # Update parent
            update_data = CategoryUpdate(parent_id=new_parent_id)
            success = await self.repository.update(category_id, update_data.model_dump(exclude_unset=True))
            
            if not success:
                return False, "Failed to move category"
            
            logger.info(f"Category moved successfully: {category_id} -> {new_parent_id}")
            return True, None
            
        except Exception as e:
            logger.error(f"Error moving category {category_id}: {e}")
            return False, "Failed to move category"
