"""
Role-Based Access Control (RBAC) System
Implements comprehensive permission management for the Lost & Found system
"""

from enum import Enum
from typing import List, Set, Dict, Optional
from functools import wraps
from fastapi import HTTPException, status, Depends
from sqlalchemy.orm import Session
import logging

from ..models.user import User, UserRole
from ..database import get_db
from .jwt_handler import get_current_user

logger = logging.getLogger(__name__)

class Permission(Enum):
    """System permissions"""
    # Item permissions
    CREATE_ITEM = "create_item"
    READ_ITEM = "read_item"
    UPDATE_ITEM = "update_item"
    DELETE_ITEM = "delete_item"
    READ_ALL_ITEMS = "read_all_items"
    
    # Match permissions
    VIEW_MATCHES = "view_matches"
    CREATE_MATCH = "create_match"
    UPDATE_MATCH = "update_match"
    
    # Claim permissions
    CREATE_CLAIM = "create_claim"
    VIEW_CLAIM = "view_claim"
    APPROVE_CLAIM = "approve_claim"
    REJECT_CLAIM = "reject_claim"
    VIEW_ALL_CLAIMS = "view_all_claims"
    
    # User permissions
    READ_USER_PROFILE = "read_user_profile"
    UPDATE_USER_PROFILE = "update_user_profile"
    VIEW_ALL_USERS = "view_all_users"
    MANAGE_USERS = "manage_users"
    
    # Admin permissions
    MANAGE_SYSTEM = "manage_system"
    VIEW_ANALYTICS = "view_analytics"
    MANAGE_ROLES = "manage_roles"
    EXPORT_DATA = "export_data"
    
    # Moderation permissions
    MODERATE_CONTENT = "moderate_content"
    BAN_USER = "ban_user"
    DELETE_ANY_ITEM = "delete_any_item"
    
    # ML permissions
    MANAGE_ML_SERVICES = "manage_ml_services"
    VIEW_ML_METRICS = "view_ml_metrics"

class RolePermissions:
    """Define permissions for each role"""
    
    PERMISSIONS = {
        UserRole.USER: {
            Permission.CREATE_ITEM,
            Permission.READ_ITEM,
            Permission.UPDATE_ITEM,
            Permission.DELETE_ITEM,
            Permission.VIEW_MATCHES,
            Permission.CREATE_CLAIM,
            Permission.VIEW_CLAIM,
            Permission.READ_USER_PROFILE,
            Permission.UPDATE_USER_PROFILE,
        },
        
        UserRole.MODERATOR: {
            # All user permissions
            Permission.CREATE_ITEM,
            Permission.READ_ITEM,
            Permission.UPDATE_ITEM,
            Permission.DELETE_ITEM,
            Permission.VIEW_MATCHES,
            Permission.CREATE_MATCH,
            Permission.UPDATE_MATCH,
            Permission.CREATE_CLAIM,
            Permission.VIEW_CLAIM,
            Permission.READ_USER_PROFILE,
            Permission.UPDATE_USER_PROFILE,
            
            # Additional moderator permissions
            Permission.READ_ALL_ITEMS,
            Permission.VIEW_ALL_CLAIMS,
            Permission.APPROVE_CLAIM,
            Permission.REJECT_CLAIM,
            Permission.MODERATE_CONTENT,
            Permission.DELETE_ANY_ITEM,
            Permission.VIEW_ANALYTICS,
        },
        
        UserRole.ADMIN: {
            # All permissions
            *[perm for perm in Permission]
        }
    }
    
    @classmethod
    def get_permissions(cls, role: UserRole) -> Set[Permission]:
        """Get permissions for a role"""
        return cls.PERMISSIONS.get(role, set())
    
    @classmethod
    def has_permission(cls, role: UserRole, permission: Permission) -> bool:
        """Check if role has specific permission"""
        return permission in cls.get_permissions(role)

class PermissionChecker:
    """Permission checking utilities"""
    
    def __init__(self, required_permissions: List[Permission]):
        self.required_permissions = required_permissions
    
    def __call__(
        self, 
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
    ):
        """Check if current user has required permissions"""
        if not current_user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication required"
            )
        
        if not current_user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is inactive"
            )
        
        user_permissions = RolePermissions.get_permissions(current_user.role)
        
        for permission in self.required_permissions:
            if permission not in user_permissions:
                logger.warning(
                    f"User {current_user.id} ({current_user.role.value}) "
                    f"denied access - missing permission: {permission.value}"
                )
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Insufficient permissions: {permission.value}"
                )
        
        return current_user

def require_permissions(*permissions: Permission):
    """Decorator to require specific permissions"""
    return PermissionChecker(list(permissions))

def require_role(*roles: UserRole):
    """Decorator to require specific roles"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Get current user from kwargs or dependencies
            current_user = kwargs.get('current_user')
            if not current_user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Authentication required"
                )
            
            if current_user.role not in roles:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Role {current_user.role.value} not authorized"
                )
            
            return await func(*args, **kwargs)
        return wrapper
    return decorator

class ResourceOwnershipChecker:
    """Check if user owns or can access specific resources"""
    
    @staticmethod
    def can_access_item(user: User, item_user_id: int) -> bool:
        """Check if user can access an item"""
        # Admins and moderators can access any item
        if user.role in [UserRole.ADMIN, UserRole.MODERATOR]:
            return True
        
        # Users can only access their own items
        return user.id == item_user_id
    
    @staticmethod
    def can_modify_item(user: User, item_user_id: int) -> bool:
        """Check if user can modify an item"""
        # Admins can modify any item
        if user.role == UserRole.ADMIN:
            return True
        
        # Users can only modify their own items
        return user.id == item_user_id
    
    @staticmethod
    def can_delete_item(user: User, item_user_id: int) -> bool:
        """Check if user can delete an item"""
        # Admins and moderators can delete any item
        if user.role in [UserRole.ADMIN, UserRole.MODERATOR]:
            return True
        
        # Users can only delete their own items
        return user.id == item_user_id
    
    @staticmethod
    def can_access_claim(user: User, claim_user_id: int) -> bool:
        """Check if user can access a claim"""
        # Admins and moderators can access any claim
        if user.role in [UserRole.ADMIN, UserRole.MODERATOR]:
            return True
        
        # Users can only access their own claims
        return user.id == claim_user_id
    
    @staticmethod
    def can_approve_claim(user: User) -> bool:
        """Check if user can approve claims"""
        return user.role in [UserRole.ADMIN, UserRole.MODERATOR]

def check_item_ownership(
    item_user_id: int,
    action: str = "access"
):
    """Dependency to check item ownership"""
    def checker(current_user: User = Depends(get_current_user)):
        if action == "access":
            can_perform = ResourceOwnershipChecker.can_access_item(
                current_user, item_user_id
            )
        elif action == "modify":
            can_perform = ResourceOwnershipChecker.can_modify_item(
                current_user, item_user_id
            )
        elif action == "delete":
            can_perform = ResourceOwnershipChecker.can_delete_item(
                current_user, item_user_id
            )
        else:
            can_perform = False
        
        if not can_perform:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Cannot {action} this item"
            )
        
        return current_user
    
    return checker

def check_claim_ownership(claim_user_id: int):
    """Dependency to check claim ownership"""
    def checker(current_user: User = Depends(get_current_user)):
        if not ResourceOwnershipChecker.can_access_claim(
            current_user, claim_user_id
        ):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot access this claim"
            )
        
        return current_user
    
    return checker

class PermissionService:
    """Service for managing permissions and roles"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_user_permissions(self, user: User) -> List[str]:
        """Get all permissions for a user"""
        permissions = RolePermissions.get_permissions(user.role)
        return [perm.value for perm in permissions]
    
    def check_permission(self, user: User, permission: Permission) -> bool:
        """Check if user has specific permission"""
        return RolePermissions.has_permission(user.role, permission)
    
    def get_role_hierarchy(self) -> Dict[str, int]:
        """Get role hierarchy levels"""
        return {
            UserRole.USER.value: 1,
            UserRole.MODERATOR.value: 2,
            UserRole.ADMIN.value: 3
        }
    
    def can_manage_user(self, manager: User, target_user: User) -> bool:
        """Check if manager can manage target user"""
        hierarchy = self.get_role_hierarchy()
        manager_level = hierarchy.get(manager.role.value, 0)
        target_level = hierarchy.get(target_user.role.value, 0)
        
        # Can only manage users with lower hierarchy level
        return manager_level > target_level
    
    def get_accessible_items_filter(self, user: User):
        """Get SQLAlchemy filter for items user can access"""
        if user.role in [UserRole.ADMIN, UserRole.MODERATOR]:
            # Admins and moderators can see all items
            return None
        else:
            # Regular users can only see their own items
            return {"user_id": user.id}
    
    def get_accessible_claims_filter(self, user: User):
        """Get SQLAlchemy filter for claims user can access"""
        if user.role in [UserRole.ADMIN, UserRole.MODERATOR]:
            # Admins and moderators can see all claims
            return None
        else:
            # Regular users can only see their own claims
            return {"claimant_id": user.id}

# Convenience functions for common permission checks
def require_admin():
    """Require admin role"""
    return require_permissions(Permission.MANAGE_SYSTEM)

def require_moderator_or_admin():
    """Require moderator or admin role"""
    return require_permissions(Permission.MODERATE_CONTENT)

def require_authenticated():
    """Require any authenticated user"""
    return require_permissions(Permission.READ_USER_PROFILE)

# Permission dependency instances
RequireAdmin = require_admin()
RequireModerator = require_moderator_or_admin()
RequireAuthenticated = require_authenticated()

# Item-specific permissions
RequireItemCreate = require_permissions(Permission.CREATE_ITEM)
RequireItemRead = require_permissions(Permission.READ_ITEM)
RequireItemUpdate = require_permissions(Permission.UPDATE_ITEM)
RequireItemDelete = require_permissions(Permission.DELETE_ITEM)

# Claim-specific permissions
RequireClaimCreate = require_permissions(Permission.CREATE_CLAIM)
RequireClaimApprove = require_permissions(Permission.APPROVE_CLAIM)
RequireClaimView = require_permissions(Permission.VIEW_CLAIM)

# Analytics and system permissions
RequireAnalytics = require_permissions(Permission.VIEW_ANALYTICS)
RequireMLManagement = require_permissions(Permission.MANAGE_ML_SERVICES)
