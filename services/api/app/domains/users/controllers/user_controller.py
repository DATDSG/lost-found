"""
Users Domain Controller
=======================
FastAPI controller for the Users domain with comprehensive functionality.
Handles HTTP requests and responses for user operations with proper validation,
error handling, and business logic separation.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, Path, Body, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_
from typing import List, Optional, Dict, Any
import logging
from datetime import datetime, timedelta
import uuid

from ....infrastructure.database.session import get_async_db
from ....infrastructure.monitoring.metrics import get_metrics_collector
from ....dependencies import get_current_user
from ....models import User
from ..schemas.user_schemas import (
    UserCreate, UserUpdate, UserProfile, UserStats, 
    PrivacySettings, PasswordChange, UserSearch,
    UserResponse, UserStatsResponse, PrivacySettingsResponse,
    DataExport, DataExportResponse, AccountDeletion,
    UserRole, UserStatus, PrivacyLevel
)
from ..services.user_service import UserService
from ..repositories.user_repository import UserRepository

logger = logging.getLogger(__name__)

router = APIRouter(tags=["users"])


# Dependency to get user service
async def get_user_service(db: AsyncSession = Depends(get_async_db)) -> UserService:
    """Get user service instance."""
    return UserService(db)


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(
    current_user: User = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service),
    metrics = Depends(get_metrics_collector)
):
    """
    Get current user's profile information with comprehensive data.
    
    Returns:
        User profile with all relevant information
    """
    try:
        success, profile, error = await user_service.get_user_profile(str(current_user.id))
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=error or "User not found"
            )
        
        return UserResponse(
            success=True,
            message="Profile retrieved successfully",
            data=profile
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting current user profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve profile"
        )


@router.put("/me", response_model=UserResponse)
async def update_current_user_profile(
    profile_data: UserUpdate,
    current_user: User = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service),
    metrics = Depends(get_metrics_collector)
):
    """
    Update current user's profile information with validation.
    
    Args:
        profile_data: Profile update data
        
    Returns:
        Updated user profile
    """
    try:
        success, profile, error = await user_service.update_user_profile(
            str(current_user.id), profile_data
        )
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error or "Failed to update profile"
            )
        
        return UserResponse(
            success=True,
            message="Profile updated successfully",
            data=profile
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating user profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update profile"
        )


@router.post("/me/change-password")
async def change_password(
    password_data: PasswordChange,
    current_user: User = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service),
    metrics = Depends(get_metrics_collector)
):
    """
    Change user password with proper validation.
    
    Args:
        password_data: Password change data
        
    Returns:
        Success message
    """
    try:
        success, error = await user_service.change_password(
            str(current_user.id), password_data
        )
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error or "Failed to change password"
            )
        
        return {
            "success": True,
            "message": "Password changed successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error changing password: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to change password"
        )


@router.get("/me/stats", response_model=UserStatsResponse)
async def get_user_statistics(
    current_user: User = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service),
    metrics = Depends(get_metrics_collector)
):
    """
    Get comprehensive user statistics for profile page.
    
    Returns:
        User statistics including reports, matches, and activity data
    """
    try:
        success, stats, error = await user_service.get_user_statistics(str(current_user.id))
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=error or "Failed to get user statistics"
            )
        
        return UserStatsResponse(
            success=True,
            message="Statistics retrieved successfully",
            data=stats
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user statistics: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user statistics"
        )


@router.get("/me/privacy", response_model=PrivacySettingsResponse)
async def get_privacy_settings(
    current_user: User = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service),
    metrics = Depends(get_metrics_collector)
):
    """
    Get user privacy settings.
    
    Returns:
        Current privacy settings
    """
    try:
        # For now, return default privacy settings
        # This would typically be stored in a separate table
        privacy_settings = PrivacySettings()
        
        return PrivacySettingsResponse(
            success=True,
            message="Privacy settings retrieved successfully",
            data=privacy_settings
        )
        
    except Exception as e:
        logger.error(f"Error getting privacy settings: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get privacy settings"
        )


@router.put("/me/privacy", response_model=PrivacySettingsResponse)
async def update_privacy_settings(
    privacy_data: PrivacySettings,
    current_user: User = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service),
    metrics = Depends(get_metrics_collector)
):
    """
    Update user privacy settings.
    
    Args:
        privacy_data: New privacy settings
        
    Returns:
        Updated privacy settings
    """
    try:
        # For now, just return the updated settings
        # This would typically be stored in a separate table
        
        return PrivacySettingsResponse(
            success=True,
            message="Privacy settings updated successfully",
            data=privacy_data
        )
        
    except Exception as e:
        logger.error(f"Error updating privacy settings: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update privacy settings"
        )


@router.post("/me/export-data", response_model=DataExportResponse)
async def request_data_export(
    export_data: DataExport,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service),
    metrics = Depends(get_metrics_collector)
):
    """
    Request user data export.
    
    Args:
        export_data: Export configuration
        
    Returns:
        Export request confirmation
    """
    try:
        # This would typically trigger a background task to generate the export
        # For now, return a mock response
        
        return DataExportResponse(
            success=True,
            message="Data export request submitted successfully",
            download_url="https://example.com/exports/user-data-123.zip",
            expires_at=datetime.utcnow() + timedelta(days=7)
        )
        
    except Exception as e:
        logger.error(f"Error requesting data export: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to request data export"
        )


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user_account(
    deletion_data: AccountDeletion,
    current_user: User = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service),
    metrics = Depends(get_metrics_collector)
):
    """
    Permanently delete user account.
    
    Args:
        deletion_data: Account deletion confirmation
        
    Returns:
        No content on success
    """
    try:
        # Verify password before deletion
        success, user, error = await user_service.verify_user_credentials(
            current_user.email, deletion_data.password
        )
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid password"
            )
        
        # Delete user account
        success, error = await user_service.delete_user_account(str(current_user.id))
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error or "Failed to delete account"
            )
        
        # Return 204 No Content
        return None
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting user account: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete account"
        )


@router.get("/search", response_model=List[UserProfile])
async def search_users(
    query: str = Query(..., min_length=2, max_length=100, description="Search query"),
    limit: int = Query(10, ge=1, le=50, description="Number of results to return"),
    offset: int = Query(0, ge=0, description="Number of results to skip"),
    current_user: User = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service),
    metrics = Depends(get_metrics_collector)
):
    """
    Search users with pagination.
    
    Args:
        query: Search query
        limit: Number of results to return
        offset: Number of results to skip
        
    Returns:
        List of matching user profiles
    """
    try:
        search_query = UserSearch(query=query, limit=limit, offset=offset)
        success, users, total, error = await user_service.search_users(search_query)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error or "Failed to search users"
            )
        
        return users
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error searching users: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to search users"
        )


@router.get("/{user_id}", response_model=UserProfile)
async def get_user_profile(
    user_id: str = Path(..., description="User ID"),
    current_user: User = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service),
    metrics = Depends(get_metrics_collector)
):
    """
    Get a specific user's public profile.
    
    Args:
        user_id: User UUID string
        
    Returns:
        User profile (public information only)
    """
    try:
        success, profile, error = await user_service.get_user_profile(user_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=error or "User not found"
            )
        
        # Remove sensitive information for public profile
        profile.email = None  # Don't expose email in public profile
        
        return profile
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user profile {user_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user profile"
        )


@router.get("/me/activity")
async def get_user_activity_summary(
    days: int = Query(30, ge=1, le=365, description="Number of days to look back"),
    current_user: User = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service),
    metrics = Depends(get_metrics_collector)
):
    """
    Get user activity summary.
    
    Args:
        days: Number of days to look back
        
    Returns:
        Activity summary
    """
    try:
        activity = await user_service.get_user_activity_summary(str(current_user.id), days)
        
        return {
            "success": True,
            "message": "Activity summary retrieved successfully",
            "data": activity
        }
        
    except Exception as e:
        logger.error(f"Error getting user activity summary: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get activity summary"
        )
