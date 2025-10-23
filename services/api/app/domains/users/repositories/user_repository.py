"""
User Repository
===============
Repository layer for user data access with proper abstraction and error handling.
"""

from typing import Optional, List, Dict, Any, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func, and_, or_
from sqlalchemy.orm import selectinload
from sqlalchemy.exc import IntegrityError, NoResultFound
import logging
from datetime import datetime, timedelta
import uuid

from app.models import User
from ..schemas.user_schemas import (
    UserCreate, UserUpdate, UserProfile, UserStats, 
    PrivacySettings, UserSearch, UserRole, UserStatus
)

logger = logging.getLogger(__name__)


class UserRepository:
    """Repository for user data access operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create_user(self, user_data: UserCreate, hashed_password: str) -> User:
        """
        Create a new user with proper validation and error handling.
        
        Args:
            user_data: User creation data
            hashed_password: Pre-hashed password
            
        Returns:
            Created user instance
            
        Raises:
            IntegrityError: If email already exists
            ValueError: If validation fails
        """
        try:
            user = User(
                email=user_data.email,
                password=hashed_password,
                display_name=user_data.display_name,
                phone_number=user_data.phone_number,
                avatar_url=user_data.avatar_url,
                role=UserRole.USER.value,
                status=UserStatus.ACTIVE.value,
                is_active=True
            )
            
            self.db.add(user)
            await self.db.commit()
            await self.db.refresh(user)
            
            logger.info(f"User created successfully: {user.email}")
            return user
            
        except IntegrityError as e:
            await self.db.rollback()
            logger.error(f"User creation failed - email already exists: {user_data.email}")
            raise ValueError("Email already exists")
        except Exception as e:
            await self.db.rollback()
            logger.error(f"User creation failed: {e}")
            raise
    
    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        """
        Get user by ID with proper error handling.
        
        Args:
            user_id: User UUID string
            
        Returns:
            User instance or None if not found
        """
        try:
            query = select(User).where(User.id == user_id)
            result = await self.db.execute(query)
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Error getting user by ID {user_id}: {e}")
            return None
    
    async def get_user_by_email(self, email: str) -> Optional[User]:
        """
        Get user by email address.
        
        Args:
            email: User email address
            
        Returns:
            User instance or None if not found
        """
        try:
            query = select(User).where(User.email == email)
            result = await self.db.execute(query)
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Error getting user by email {email}: {e}")
            return None
    
    async def update_user(self, user_id: str, update_data: UserUpdate) -> Optional[User]:
        """
        Update user profile with validation and error handling.
        
        Args:
            user_id: User UUID string
            update_data: Update data
            
        Returns:
            Updated user instance or None if not found
        """
        try:
            # Get existing user
            user = await self.get_user_by_id(user_id)
            if not user:
                return None
            
            # Update fields
            update_dict = update_data.model_dump(exclude_unset=True)
            if not update_dict:
                return user
            
            # Update user fields
            for field, value in update_dict.items():
                setattr(user, field, value)
            
            user.updated_at = datetime.utcnow()
            
            await self.db.commit()
            await self.db.refresh(user)
            
            logger.info(f"User updated successfully: {user.email}")
            return user
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"User update failed for {user_id}: {e}")
            raise
    
    async def update_password(self, user_id: str, hashed_password: str) -> bool:
        """
        Update user password.
        
        Args:
            user_id: User UUID string
            hashed_password: New hashed password
            
        Returns:
            True if successful, False otherwise
        """
        try:
            query = (
                update(User)
                .where(User.id == user_id)
                .values(password=hashed_password, updated_at=datetime.utcnow())
            )
            
            result = await self.db.execute(query)
            await self.db.commit()
            
            if result.rowcount > 0:
                logger.info(f"Password updated for user: {user_id}")
                return True
            return False
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Password update failed for {user_id}: {e}")
            return False
    
    async def update_last_login(self, user_id: str) -> bool:
        """
        Update user's last login timestamp.
        
        Args:
            user_id: User UUID string
            
        Returns:
            True if successful, False otherwise
        """
        try:
            query = (
                update(User)
                .where(User.id == user_id)
                .values(updated_at=datetime.utcnow())
            )
            
            await self.db.execute(query)
            await self.db.commit()
            return True
            
        except Exception as e:
            logger.error(f"Last login update failed for {user_id}: {e}")
            return False
    
    async def deactivate_user(self, user_id: str) -> bool:
        """
        Deactivate user account.
        
        Args:
            user_id: User UUID string
            
        Returns:
            True if successful, False otherwise
        """
        try:
            query = (
                update(User)
                .where(User.id == user_id)
                .values(
                    is_active=False,
                    status=UserStatus.INACTIVE.value,
                    updated_at=datetime.utcnow()
                )
            )
            
            result = await self.db.execute(query)
            await self.db.commit()
            
            if result.rowcount > 0:
                logger.info(f"User deactivated: {user_id}")
                return True
            return False
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"User deactivation failed for {user_id}: {e}")
            return False
    
    async def delete_user(self, user_id: str) -> bool:
        """
        Permanently delete user account.
        
        Args:
            user_id: User UUID string
            
        Returns:
            True if successful, False otherwise
        """
        try:
            query = delete(User).where(User.id == user_id)
            result = await self.db.execute(query)
            await self.db.commit()
            
            if result.rowcount > 0:
                logger.info(f"User deleted permanently: {user_id}")
                return True
            return False
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"User deletion failed for {user_id}: {e}")
            return False
    
    async def search_users(self, search_query: UserSearch) -> Tuple[List[User], int]:
        """
        Search users with pagination.
        
        Args:
            search_query: Search parameters
            
        Returns:
            Tuple of (users list, total count)
        """
        try:
            # Base query
            base_query = select(User).where(User.is_active == True)
            
            # Search conditions
            search_conditions = []
            query_lower = search_query.query.lower()
            
            search_conditions.append(
                or_(
                    User.display_name.ilike(f"%{query_lower}%"),
                    User.email.ilike(f"%{query_lower}%")
                )
            )
            
            # Apply search conditions
            search_query_obj = base_query.where(and_(*search_conditions))
            
            # Get total count
            count_query = select(func.count()).select_from(search_query_obj.subquery())
            total_result = await self.db.execute(count_query)
            total = total_result.scalar()
            
            # Get paginated results
            users_query = (
                search_query_obj
                .offset(search_query.offset)
                .limit(search_query.limit)
                .order_by(User.display_name.asc())
            )
            
            result = await self.db.execute(users_query)
            users = result.scalars().all()
            
            return list(users), total
            
        except Exception as e:
            logger.error(f"User search failed: {e}")
            return [], 0
    
    async def get_user_stats(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get comprehensive user statistics.
        
        Args:
            user_id: User UUID string
            
        Returns:
            User statistics dictionary
        """
        try:
            from app.domains.reports.models.report import Report, ReportStatus
            from app.domains.matches.models.match import Match, MatchStatus
            
            # Report statistics
            total_reports_query = select(func.count(Report.id)).where(Report.owner_id == user_id)
            total_reports = await self.db.scalar(total_reports_query) or 0
            
            active_reports_query = select(func.count(Report.id)).where(
                and_(
                    Report.owner_id == user_id,
                    Report.status == ReportStatus.APPROVED
                )
            )
            active_reports = await self.db.scalar(active_reports_query) or 0
            
            draft_reports_query = select(func.count(Report.id)).where(
                and_(
                    Report.owner_id == user_id,
                    Report.status == ReportStatus.PENDING
                )
            )
            draft_reports = await self.db.scalar(draft_reports_query) or 0
            
            resolved_reports_query = select(func.count(Report.id)).where(
                and_(
                    Report.owner_id == user_id,
                    Report.is_resolved == True
                )
            )
            resolved_reports = await self.db.scalar(resolved_reports_query) or 0
            
            # Match statistics
            total_matches_query = select(func.count(Match.id)).where(
                or_(
                    Match.source_report.has(Report.owner_id == user_id),
                    Match.candidate_report.has(Report.owner_id == user_id)
                )
            )
            total_matches = await self.db.scalar(total_matches_query) or 0
            
            successful_matches_query = select(func.count(Match.id)).where(
                and_(
                    or_(
                        Match.source_report.has(Report.owner_id == user_id),
                        Match.candidate_report.has(Report.owner_id == user_id)
                    ),
                    Match.status == MatchStatus.PROMOTED
                )
            )
            successful_matches = await self.db.scalar(successful_matches_query) or 0
            
            # Calculate success rate
            success_rate = 0.0
            if total_matches > 0:
                success_rate = round((successful_matches / total_matches) * 100, 1)
            
            return {
                "reports": {
                    "total": total_reports,
                    "active": active_reports,
                    "resolved": resolved_reports,
                    "draft": draft_reports
                },
                "matches": {
                    "total": total_matches,
                    "successful": successful_matches,
                    "success_rate": success_rate
                },
                "activity": {
                    "last_activity": datetime.utcnow().isoformat(),
                    "account_age_days": 0  # Will be calculated from created_at
                }
            }
            
        except Exception as e:
            logger.error(f"Error getting user stats for {user_id}: {e}")
            return None
    
    async def get_users_by_ids(self, user_ids: List[str]) -> List[User]:
        """
        Get multiple users by their IDs.
        
        Args:
            user_ids: List of user UUID strings
            
        Returns:
            List of user instances
        """
        try:
            query = select(User).where(User.id.in_(user_ids))
            result = await self.db.execute(query)
            return list(result.scalars().all())
        except Exception as e:
            logger.error(f"Error getting users by IDs: {e}")
            return []
    
    async def get_active_users_count(self) -> int:
        """
        Get count of active users.
        
        Returns:
            Number of active users
        """
        try:
            query = select(func.count(User.id)).where(User.is_active == True)
            result = await self.db.execute(query)
            return result.scalar() or 0
        except Exception as e:
            logger.error(f"Error getting active users count: {e}")
            return 0
    
    async def get_recent_users(self, limit: int = 10) -> List[User]:
        """
        Get recently created users.
        
        Args:
            limit: Maximum number of users to return
            
        Returns:
            List of recent user instances
        """
        try:
            query = (
                select(User)
                .where(User.is_active == True)
                .order_by(User.created_at.desc())
                .limit(limit)
            )
            result = await self.db.execute(query)
            return list(result.scalars().all())
        except Exception as e:
            logger.error(f"Error getting recent users: {e}")
            return []
