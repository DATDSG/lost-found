"""
Match Service
=============
Business logic layer for match operations with proper validation and error handling.
"""

from typing import Optional, Dict, Any, Tuple, List
from sqlalchemy.ext.asyncio import AsyncSession
import logging
from datetime import datetime, timedelta
import uuid

from ..schemas.match_schemas import (
    MatchCreate, MatchUpdate, MatchResponse, MatchSearchRequest,
    MatchSearchResponse, MatchStats, MatchScoreBreakdown,
    BulkMatchRequest, BulkMatchResponse, MatchStatus, MatchType
)
from ..repositories.match_repository import MatchRepository
from ..models.match import Match

logger = logging.getLogger(__name__)


class MatchService:
    """Service layer for match business logic."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repository = MatchRepository(db)
    
    async def create_match(self, match_data: MatchCreate) -> Tuple[bool, Optional[MatchResponse], Optional[str]]:
        """
        Create a new match with comprehensive validation.
        
        Args:
            match_data: Match creation data
            
        Returns:
            Tuple of (success, match_response, error_message)
        """
        try:
            # Validate source and candidate reports exist
            source_exists = await self.repository.check_report_exists(match_data.source_report_id)
            if not source_exists:
                return False, None, "Source report not found"
            
            candidate_exists = await self.repository.check_report_exists(match_data.candidate_report_id)
            if not candidate_exists:
                return False, None, "Candidate report not found"
            
            # Check if match already exists
            existing_match = await self.repository.get_match_by_reports(
                match_data.source_report_id, 
                match_data.candidate_report_id
            )
            if existing_match:
                return False, None, "Match already exists between these reports"
            
            # Create match
            match_dict = match_data.model_dump()
            match_dict["id"] = str(uuid.uuid4())
            match_dict["created_at"] = datetime.utcnow()
            match_dict["updated_at"] = datetime.utcnow()
            
            match = await self.repository.create(match_dict)
            match_response = MatchResponse.model_validate(match)
            
            logger.info(f"Match created successfully: {match.id}")
            return True, match_response, None
            
        except ValueError as e:
            return False, None, str(e)
        except Exception as e:
            logger.error(f"Match creation failed: {e}")
            return False, None, "Failed to create match"
    
    async def get_match(self, match_id: str) -> Tuple[bool, Optional[MatchResponse], Optional[str]]:
        """
        Get a specific match by ID.
        
        Args:
            match_id: Match UUID string
            
        Returns:
            Tuple of (success, match_response, error_message)
        """
        try:
            match = await self.repository.get_by_id(match_id)
            if not match:
                return False, None, "Match not found"
            
            match_response = MatchResponse.model_validate(match)
            return True, match_response, None
            
        except Exception as e:
            logger.error(f"Error getting match {match_id}: {e}")
            return False, None, "Failed to get match"
    
    async def update_match(self, match_id: str, update_data: MatchUpdate) -> Tuple[bool, Optional[MatchResponse], Optional[str]]:
        """
        Update a match with validation.
        
        Args:
            match_id: Match UUID string
            update_data: Update data
            
        Returns:
            Tuple of (success, updated_match_response, error_message)
        """
        try:
            # Get existing match
            match = await self.repository.get_by_id(match_id)
            if not match:
                return False, None, "Match not found"
            
            # Update match
            update_dict = update_data.model_dump(exclude_unset=True)
            update_dict["updated_at"] = datetime.utcnow()
            
            updated_match = await self.repository.update(match_id, update_dict)
            if not updated_match:
                return False, None, "Failed to update match"
            
            match_response = MatchResponse.model_validate(updated_match)
            
            logger.info(f"Match updated successfully: {match_id}")
            return True, match_response, None
            
        except Exception as e:
            logger.error(f"Error updating match {match_id}: {e}")
            return False, None, "Failed to update match"
    
    async def delete_match(self, match_id: str) -> Tuple[bool, Optional[str]]:
        """
        Delete a match.
        
        Args:
            match_id: Match UUID string
            
        Returns:
            Tuple of (success, error_message)
        """
        try:
            success = await self.repository.delete(match_id)
            if not success:
                return False, "Match not found"
            
            logger.info(f"Match deleted successfully: {match_id}")
            return True, None
            
        except Exception as e:
            logger.error(f"Error deleting match {match_id}: {e}")
            return False, "Failed to delete match"
    
    async def search_matches(self, search_request: MatchSearchRequest) -> Tuple[bool, Optional[MatchSearchResponse], Optional[str]]:
        """
        Search matches with pagination and filters.
        
        Args:
            search_request: Search parameters
            
        Returns:
            Tuple of (success, search_response, error_message)
        """
        try:
            matches, total = await self.repository.search_matches(search_request)
            
            # Convert to MatchResponse schemas
            match_responses = []
            for match in matches:
                match_response = MatchResponse.model_validate(match)
                match_responses.append(match_response)
            
            search_response = MatchSearchResponse(
                matches=match_responses,
                total=total,
                page=search_request.page,
                page_size=search_request.page_size,
                has_next=total > (search_request.page * search_request.page_size),
                has_prev=search_request.page > 1
            )
            
            return True, search_response, None
            
        except Exception as e:
            logger.error(f"Error searching matches: {e}")
            return False, None, "Failed to search matches"
    
    async def get_match_statistics(self) -> Tuple[bool, Optional[MatchStats], Optional[str]]:
        """
        Get comprehensive match statistics.
        
        Returns:
            Tuple of (success, match_stats, error_message)
        """
        try:
            stats_data = await self.repository.get_match_statistics()
            if not stats_data:
                return False, None, "Failed to get match statistics"
            
            stats = MatchStats(**stats_data)
            return True, stats, None
            
        except Exception as e:
            logger.error(f"Error getting match statistics: {e}")
            return False, None, "Failed to get match statistics"
    
    async def promote_match(self, match_id: str) -> Tuple[bool, Optional[str]]:
        """
        Promote a match to confirmed status.
        
        Args:
            match_id: Match UUID string
            
        Returns:
            Tuple of (success, error_message)
        """
        try:
            # Get match
            match = await self.repository.get_by_id(match_id)
            if not match:
                return False, "Match not found"
            
            # Update status to promoted
            update_data = MatchUpdate(status=MatchStatus.PROMOTED)
            success = await self.repository.update_match_status(match_id, MatchStatus.PROMOTED)
            
            if not success:
                return False, "Failed to promote match"
            
            logger.info(f"Match promoted successfully: {match_id}")
            return True, None
            
        except Exception as e:
            logger.error(f"Error promoting match {match_id}: {e}")
            return False, "Failed to promote match"
    
    async def dismiss_match(self, match_id: str) -> Tuple[bool, Optional[str]]:
        """
        Dismiss a match.
        
        Args:
            match_id: Match UUID string
            
        Returns:
            Tuple of (success, error_message)
        """
        try:
            # Get match
            match = await self.repository.get_by_id(match_id)
            if not match:
                return False, "Match not found"
            
            # Update status to dismissed
            success = await self.repository.update_match_status(match_id, MatchStatus.DISMISSED)
            
            if not success:
                return False, "Failed to dismiss match"
            
            logger.info(f"Match dismissed successfully: {match_id}")
            return True, None
            
        except Exception as e:
            logger.error(f"Error dismissing match {match_id}: {e}")
            return False, "Failed to dismiss match"
    
    async def get_matches_for_report(self, report_id: str, status: Optional[MatchStatus] = None) -> Tuple[bool, List[MatchResponse], Optional[str]]:
        """
        Get all matches for a specific report.
        
        Args:
            report_id: Report UUID string
            status: Optional status filter
            
        Returns:
            Tuple of (success, matches_list, error_message)
        """
        try:
            matches = await self.repository.get_matches_for_report(report_id, status)
            
            # Convert to MatchResponse schemas
            match_responses = []
            for match in matches:
                match_response = MatchResponse.model_validate(match)
                match_responses.append(match_response)
            
            return True, match_responses, None
            
        except Exception as e:
            logger.error(f"Error getting matches for report {report_id}: {e}")
            return False, [], "Failed to get matches for report"
    
    async def bulk_create_matches(self, bulk_request: BulkMatchRequest) -> Tuple[bool, Optional[BulkMatchResponse], Optional[str]]:
        """
        Create multiple matches in bulk.
        
        Args:
            bulk_request: Bulk match creation request
            
        Returns:
            Tuple of (success, bulk_response, error_message)
        """
        try:
            created_matches = []
            errors = []
            
            for match_data in bulk_request.matches:
                success, match_response, error = await self.create_match(match_data)
                if success:
                    created_matches.append(match_response)
                else:
                    errors.append({
                        "match_data": match_data.model_dump(),
                        "error": error
                    })
            
            bulk_response = BulkMatchResponse(
                created_matches=created_matches,
                total_created=len(created_matches),
                total_failed=len(errors),
                errors=errors
            )
            
            logger.info(f"Bulk match creation completed: {len(created_matches)} created, {len(errors)} failed")
            return True, bulk_response, None
            
        except Exception as e:
            logger.error(f"Error in bulk match creation: {e}")
            return False, None, "Failed to create matches in bulk"
    
    async def get_pending_matches(self, limit: int = 50) -> Tuple[bool, List[MatchResponse], Optional[str]]:
        """
        Get pending matches that need review.
        
        Args:
            limit: Maximum number of matches to return
            
        Returns:
            Tuple of (success, matches_list, error_message)
        """
        try:
            matches = await self.repository.get_pending_matches(limit)
            
            # Convert to MatchResponse schemas
            match_responses = []
            for match in matches:
                match_response = MatchResponse.model_validate(match)
                match_responses.append(match_response)
            
            return True, match_responses, None
            
        except Exception as e:
            logger.error(f"Error getting pending matches: {e}")
            return False, [], "Failed to get pending matches"
    
    async def calculate_match_score(self, source_report_id: str, candidate_report_id: str) -> Tuple[bool, Optional[MatchScoreBreakdown], Optional[str]]:
        """
        Calculate match score between two reports.
        
        Args:
            source_report_id: Source report UUID string
            candidate_report_id: Candidate report UUID string
            
        Returns:
            Tuple of (success, score_breakdown, error_message)
        """
        try:
            # This would typically involve complex matching algorithms
            # For now, return a basic score calculation
            score_breakdown = MatchScoreBreakdown(
                overall_score=0.75,
                description_similarity=0.8,
                location_proximity=0.7,
                image_similarity=0.6,
                category_match=1.0,
                timestamp_proximity=0.5,
                factors={
                    "description_match": 0.8,
                    "location_distance_km": 2.5,
                    "image_similarity": 0.6,
                    "category_exact_match": True,
                    "time_difference_hours": 24
                }
            )
            
            return True, score_breakdown, None
            
        except Exception as e:
            logger.error(f"Error calculating match score: {e}")
            return False, None, "Failed to calculate match score"
