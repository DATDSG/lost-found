"""
User Service
============
Business logic layer for user operations with proper validation and error handling.
"""

from typing import Optional, Dict, Any, Tuple, List
from sqlalchemy.ext.asyncio import AsyncSession
import logging
from datetime import datetime, timedelta
import hashlib
import secrets
import uuid
from passlib.context import CryptContext

from ..schemas.user_schemas import (
    UserCreate, UserUpdate, UserProfile, UserStats, 
    PrivacySettings, PasswordChange, UserSearch,
    UserRole, UserStatus, PrivacyLevel
)
from ..repositories.user_repository import UserRepository
from app.models import User

logger = logging.getLogger(__name__)

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class UserService:
    """Service layer for user business logic."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repository = UserRepository(db)
    
    def _hash_password(self, password: str) -> str:
        """Hash password using bcrypt."""
        return pwd_context.hash(password)
    
    def _verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify password against hash."""
        return pwd_context.verify(plain_password, hashed_password)
    
    def _generate_api_key(self) -> str:
        """Generate a secure API key."""
        return secrets.token_urlsafe(32)
    
    async def create_user(self, user_data: UserCreate) -> Tuple[bool, Optional[User], Optional[str]]:
        """
        Create a new user with comprehensive validation.
        
        Args:
            user_data: User creation data
            
        Returns:
            Tuple of (success, user_instance, error_message)
        """
        try:
            # Check if email already exists
            existing_user = await self.repository.get_user_by_email(user_data.email)
            if existing_user:
                return False, None, "Email already exists"
            
            # Hash password
            hashed_password = self._hash_password(user_data.password)
            
            # Create user
            user = await self.repository.create_user(user_data, hashed_password)
            
            logger.info(f"User created successfully: {user.email}")
            return True, user, None
            
        except ValueError as e:
            return False, None, str(e)
        except Exception as e:
            logger.error(f"User creation failed: {e}")
            return False, None, "Failed to create user"
    
    async def get_user_profile(self, user_id: str) -> Tuple[bool, Optional[UserProfile], Optional[str]]:
        """
        Get user profile with proper formatting.
        
        Args:
            user_id: User UUID string
            
        Returns:
            Tuple of (success, user_profile, error_message)
        """
        try:
            user = await self.repository.get_user_by_id(user_id)
            if not user:
                return False, None, "User not found"
            
            # Convert to UserProfile schema
            profile = UserProfile(
                id=str(user.id),
                email=user.email,
                display_name=user.display_name,
                phone_number=user.phone_number,
                avatar_url=user.avatar_url,
                bio=getattr(user, 'bio', None),
                location=getattr(user, 'location', None),
                gender=getattr(user, 'gender', None),
                date_of_birth=getattr(user, 'date_of_birth', None),
                role=UserRole(user.role),
                status=UserStatus(user.status),
                created_at=user.created_at,
                updated_at=user.updated_at,
                last_login=None  # This would need to be tracked separately
            )
            
            return True, profile, None
            
        except Exception as e:
            logger.error(f"Error getting user profile {user_id}: {e}")
            return False, None, "Failed to get user profile"
    
    async def update_user_profile(self, user_id: str, update_data: UserUpdate) -> Tuple[bool, Optional[UserProfile], Optional[str]]:
        """
        Update user profile with validation.
        
        Args:
            user_id: User UUID string
            update_data: Update data
            
        Returns:
            Tuple of (success, updated_profile, error_message)
        """
        try:
            # Update user
            updated_user = await self.repository.update_user(user_id, update_data)
            if not updated_user:
                return False, None, "User not found"
            
            # Convert to UserProfile schema
            profile = UserProfile(
                id=str(updated_user.id),
                email=updated_user.email,
                display_name=updated_user.display_name,
                phone_number=updated_user.phone_number,
                avatar_url=updated_user.avatar_url,
                bio=getattr(updated_user, 'bio', None),
                location=getattr(updated_user, 'location', None),
                gender=getattr(updated_user, 'gender', None),
                date_of_birth=getattr(updated_user, 'date_of_birth', None),
                role=UserRole(updated_user.role),
                status=UserStatus(updated_user.status),
                created_at=updated_user.created_at,
                updated_at=updated_user.updated_at,
                last_login=None
            )
            
            logger.info(f"User profile updated: {updated_user.email}")
            return True, profile, None
            
        except Exception as e:
            logger.error(f"Error updating user profile {user_id}: {e}")
            return False, None, "Failed to update user profile"
    
    async def change_password(self, user_id: str, password_data: PasswordChange) -> Tuple[bool, Optional[str]]:
        """
        Change user password with proper validation.
        
        Args:
            user_id: User UUID string
            password_data: Password change data
            
        Returns:
            Tuple of (success, error_message)
        """
        try:
            # Get user
            user = await self.repository.get_user_by_id(user_id)
            if not user:
                return False, "User not found"
            
            # Verify current password
            if not self._verify_password(password_data.current_password, user.password):
                return False, "Current password is incorrect"
            
            # Hash new password
            hashed_password = self._hash_password(password_data.new_password)
            
            # Update password
            success = await self.repository.update_password(user_id, hashed_password)
            if not success:
                return False, "Failed to update password"
            
            logger.info(f"Password changed for user: {user.email}")
            return True, None
            
        except Exception as e:
            logger.error(f"Error changing password for {user_id}: {e}")
            return False, "Failed to change password"
    
    async def get_user_statistics(self, user_id: str) -> Tuple[bool, Optional[UserStats], Optional[str]]:
        """
        Get comprehensive user statistics.
        
        Args:
            user_id: User UUID string
            
        Returns:
            Tuple of (success, user_stats, error_message)
        """
        try:
            # Get user
            user = await self.repository.get_user_by_id(user_id)
            if not user:
                return False, None, "User not found"
            
            # Get statistics
            stats_data = await self.repository.get_user_stats(user_id)
            if not stats_data:
                return False, None, "Failed to get user statistics"
            
            # Calculate account age
            account_age_days = (datetime.utcnow() - user.created_at).days
            stats_data["activity"]["account_age_days"] = account_age_days
            
            # Convert to UserStats schema
            stats = UserStats(**stats_data)
            
            return True, stats, None
            
        except Exception as e:
            logger.error(f"Error getting user statistics {user_id}: {e}")
            return False, None, "Failed to get user statistics"
    
    async def search_users(self, search_query: UserSearch) -> Tuple[bool, List[UserProfile], int, Optional[str]]:
        """
        Search users with pagination.
        
        Args:
            search_query: Search parameters
            
        Returns:
            Tuple of (success, users_list, total_count, error_message)
        """
        try:
            # Search users
            users, total = await self.repository.search_users(search_query)
            
            # Convert to UserProfile schemas
            profiles = []
            for user in users:
                profile = UserProfile(
                    id=str(user.id),
                    email=user.email,
                    display_name=user.display_name,
                    phone_number=user.phone_number,
                    avatar_url=user.avatar_url,
                    role=UserRole(user.role),
                    status=UserStatus(user.status),
                    created_at=user.created_at,
                    updated_at=user.updated_at,
                    last_login=None
                )
                profiles.append(profile)
            
            return True, profiles, total, None
            
        except Exception as e:
            logger.error(f"Error searching users: {e}")
            return False, [], 0, "Failed to search users"
    
    async def deactivate_user_account(self, user_id: str) -> Tuple[bool, Optional[str]]:
        """
        Deactivate user account.
        
        Args:
            user_id: User UUID string
            
        Returns:
            Tuple of (success, error_message)
        """
        try:
            # Get user
            user = await self.repository.get_user_by_id(user_id)
            if not user:
                return False, "User not found"
            
            # Deactivate user
            success = await self.repository.deactivate_user(user_id)
            if not success:
                return False, "Failed to deactivate user account"
            
            logger.info(f"User account deactivated: {user.email}")
            return True, None
            
        except Exception as e:
            logger.error(f"Error deactivating user account {user_id}: {e}")
            return False, "Failed to deactivate user account"
    
    async def delete_user_account(self, user_id: str) -> Tuple[bool, Optional[str]]:
        """
        Permanently delete user account.
        
        Args:
            user_id: User UUID string
            
        Returns:
            Tuple of (success, error_message)
        """
        try:
            # Get user
            user = await self.repository.get_user_by_id(user_id)
            if not user:
                return False, "User not found"
            
            # Delete user
            success = await self.repository.delete_user(user_id)
            if not success:
                return False, "Failed to delete user account"
            
            logger.info(f"User account deleted permanently: {user.email}")
            return True, None
            
        except Exception as e:
            logger.error(f"Error deleting user account {user_id}: {e}")
            return False, "Failed to delete user account"
    
    async def verify_user_credentials(self, email: str, password: str) -> Tuple[bool, Optional[User], Optional[str]]:
        """
        Verify user credentials for authentication.
        
        Args:
            email: User email
            password: Plain text password
            
        Returns:
            Tuple of (success, user_instance, error_message)
        """
        try:
            # Get user by email
            user = await self.repository.get_user_by_email(email)
            if not user:
                return False, None, "Invalid credentials"
            
            # Check if user is active
            if not user.is_active:
                return False, None, "Account is deactivated"
            
            # Verify password
            if not self._verify_password(password, user.password):
                return False, None, "Invalid credentials"
            
            # Update last login
            await self.repository.update_last_login(str(user.id))
            
            return True, user, None
            
        except Exception as e:
            logger.error(f"Error verifying credentials for {email}: {e}")
            return False, None, "Authentication failed"
    
    async def get_user_by_email(self, email: str) -> Tuple[bool, Optional[User], Optional[str]]:
        """
        Get user by email address.
        
        Args:
            email: User email address
            
        Returns:
            Tuple of (success, user_instance, error_message)
        """
        try:
            user = await self.repository.get_user_by_email(email)
            if not user:
                return False, None, "User not found"
            
            return True, user, None
            
        except Exception as e:
            logger.error(f"Error getting user by email {email}: {e}")
            return False, None, "Failed to get user"
    
    async def update_user_status(self, user_id: str, status: UserStatus) -> Tuple[bool, Optional[str]]:
        """
        Update user status.
        
        Args:
            user_id: User UUID string
            status: New user status
            
        Returns:
            Tuple of (success, error_message)
        """
        try:
            # Get user
            user = await self.repository.get_user_by_id(user_id)
            if not user:
                return False, "User not found"
            
            # Update status
            update_data = UserUpdate()
            update_data.status = status.value
            
            updated_user = await self.repository.update_user(user_id, update_data)
            if not updated_user:
                return False, "Failed to update user status"
            
            logger.info(f"User status updated: {user.email} -> {status.value}")
            return True, None
            
        except Exception as e:
            logger.error(f"Error updating user status {user_id}: {e}")
            return False, "Failed to update user status"
    
    async def get_user_activity_summary(self, user_id: str, days: int = 30) -> Dict[str, Any]:
        """
        Get user activity summary for the last N days.
        
        Args:
            user_id: User UUID string
            days: Number of days to look back
            
        Returns:
            Activity summary dictionary
        """
        try:
            # This would typically involve querying activity logs
            # For now, return basic information
            user = await self.repository.get_user_by_id(user_id)
            if not user:
                return {}
            
            return {
                "user_id": str(user.id),
                "last_login": user.updated_at.isoformat() if user.updated_at else None,
                "account_age_days": (datetime.utcnow() - user.created_at).days,
                "status": user.status,
                "is_active": user.is_active
            }
            
        except Exception as e:
            logger.error(f"Error getting user activity summary {user_id}: {e}")
            return {}
