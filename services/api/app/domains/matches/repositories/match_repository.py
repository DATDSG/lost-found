"""
Match Repository
================
Repository layer for match data access with proper abstraction and error handling.
"""

from typing import Optional, List, Dict, Any, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func, and_, or_, desc
from sqlalchemy.orm import selectinload
from sqlalchemy.exc import IntegrityError, NoResultFound
import logging
from datetime import datetime, timedelta
import uuid

from ..models.match import Match
from ..schemas.match_schemas import (
    MatchCreate, MatchUpdate, MatchSearchRequest, MatchStatus, MatchType
)

logger = logging.getLogger(__name__)


class MatchRepository:
    """Repository for match data access operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create(self, match_dict: Dict[str, Any]) -> Match:
        """
        Create a new match.
        
        Args:
            match_dict: Match data dictionary
            
        Returns:
            Created match instance
            
        Raises:
            IntegrityError: If constraint violation occurs
            ValueError: If validation fails
        """
        try:
            match = Match(**match_dict)
            self.db.add(match)
            await self.db.commit()
            await self.db.refresh(match)
            
            logger.info(f"Match created successfully: {match.id}")
            return match
            
        except IntegrityError as e:
            await self.db.rollback()
            logger.error(f"Match creation failed - constraint violation: {e}")
            raise ValueError("Match creation failed due to constraint violation")
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Match creation failed: {e}")
            raise
    
    async def get_by_id(self, match_id: str) -> Optional[Match]:
        """
        Get match by ID with relationships loaded.
        
        Args:
            match_id: Match UUID string
            
        Returns:
            Match instance or None if not found
        """
        try:
            query = (
                select(Match)
                .options(
                    selectinload(Match.source_report),
                    selectinload(Match.candidate_report)
                )
                .where(Match.id == match_id)
            )
            result = await self.db.execute(query)
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Error getting match by ID {match_id}: {e}")
            return None
    
    async def update(self, match_id: str, update_dict: Dict[str, Any]) -> Optional[Match]:
        """
        Update match with validation and error handling.
        
        Args:
            match_id: Match UUID string
            update_dict: Update data dictionary
            
        Returns:
            Updated match instance or None if not found
        """
        try:
            # Get existing match
            match = await self.get_by_id(match_id)
            if not match:
                return None
            
            # Update fields
            for field, value in update_dict.items():
                if hasattr(match, field):
                    setattr(match, field, value)
            
            await self.db.commit()
            await self.db.refresh(match)
            
            logger.info(f"Match updated successfully: {match_id}")
            return match
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Match update failed for {match_id}: {e}")
            raise
    
    async def delete(self, match_id: str) -> bool:
        """
        Delete match permanently.
        
        Args:
            match_id: Match UUID string
            
        Returns:
            True if successful, False if not found
        """
        try:
            query = delete(Match).where(Match.id == match_id)
            result = await self.db.execute(query)
            await self.db.commit()
            
            if result.rowcount > 0:
                logger.info(f"Match deleted successfully: {match_id}")
                return True
            return False
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Match deletion failed for {match_id}: {e}")
            return False
    
    async def search_matches(self, search_request: MatchSearchRequest) -> Tuple[List[Match], int]:
        """
        Search matches with pagination and filters.
        
        Args:
            search_request: Search parameters
            
        Returns:
            Tuple of (matches list, total count)
        """
        try:
            # Base query with relationships
            base_query = (
                select(Match)
                .options(
                    selectinload(Match.source_report),
                    selectinload(Match.candidate_report)
                )
            )
            
            # Apply filters
            conditions = []
            
            if search_request.status:
                conditions.append(Match.status == search_request.status)
            
            if search_request.match_type:
                conditions.append(Match.match_type == search_request.match_type)
            
            if search_request.min_score:
                conditions.append(Match.score >= search_request.min_score)
            
            if search_request.max_score:
                conditions.append(Match.score <= search_request.max_score)
            
            if search_request.source_report_id:
                conditions.append(Match.source_report_id == search_request.source_report_id)
            
            if search_request.candidate_report_id:
                conditions.append(Match.candidate_report_id == search_request.candidate_report_id)
            
            if search_request.created_after:
                conditions.append(Match.created_at >= search_request.created_after)
            
            if search_request.created_before:
                conditions.append(Match.created_at <= search_request.created_before)
            
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
            matches_query = (
                search_query
                .offset(search_request.offset)
                .limit(search_request.limit)
                .order_by(desc(Match.score), desc(Match.created_at))
            )
            
            result = await self.db.execute(matches_query)
            matches = result.scalars().all()
            
            return list(matches), total
            
        except Exception as e:
            logger.error(f"Match search failed: {e}")
            return [], 0
    
    async def get_match_by_reports(self, source_report_id: str, candidate_report_id: str) -> Optional[Match]:
        """
        Get match between two specific reports.
        
        Args:
            source_report_id: Source report UUID string
            candidate_report_id: Candidate report UUID string
            
        Returns:
            Match instance or None if not found
        """
        try:
            query = (
                select(Match)
                .where(
                    and_(
                        Match.source_report_id == source_report_id,
                        Match.candidate_report_id == candidate_report_id
                    )
                )
            )
            result = await self.db.execute(query)
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Error getting match by reports: {e}")
            return None
    
    async def check_report_exists(self, report_id: str) -> bool:
        """
        Check if a report exists.
        
        Args:
            report_id: Report UUID string
            
        Returns:
            True if report exists, False otherwise
        """
        try:
            from app.domains.reports.models.report import Report
            
            query = select(func.count(Report.id)).where(Report.id == report_id)
            result = await self.db.execute(query)
            count = result.scalar()
            return count > 0
        except Exception as e:
            logger.error(f"Error checking report existence {report_id}: {e}")
            return False
    
    async def update_match_status(self, match_id: str, status: MatchStatus) -> bool:
        """
        Update match status.
        
        Args:
            match_id: Match UUID string
            status: New match status
            
        Returns:
            True if successful, False otherwise
        """
        try:
            query = (
                update(Match)
                .where(Match.id == match_id)
                .values(
                    status=status.value,
                    updated_at=datetime.utcnow()
                )
            )
            
            result = await self.db.execute(query)
            await self.db.commit()
            
            if result.rowcount > 0:
                logger.info(f"Match status updated: {match_id} -> {status.value}")
                return True
            return False
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Match status update failed for {match_id}: {e}")
            return False
    
    async def get_matches_for_report(self, report_id: str, status: Optional[MatchStatus] = None) -> List[Match]:
        """
        Get all matches for a specific report.
        
        Args:
            report_id: Report UUID string
            status: Optional status filter
            
        Returns:
            List of match instances
        """
        try:
            query = (
                select(Match)
                .options(
                    selectinload(Match.source_report),
                    selectinload(Match.candidate_report)
                )
                .where(
                    or_(
                        Match.source_report_id == report_id,
                        Match.candidate_report_id == report_id
                    )
                )
            )
            
            if status:
                query = query.where(Match.status == status)
            
            query = query.order_by(desc(Match.score), desc(Match.created_at))
            
            result = await self.db.execute(query)
            return list(result.scalars().all())
            
        except Exception as e:
            logger.error(f"Error getting matches for report {report_id}: {e}")
            return []
    
    async def get_match_statistics(self) -> Optional[Dict[str, Any]]:
        """
        Get comprehensive match statistics.
        
        Returns:
            Match statistics dictionary
        """
        try:
            # Total matches
            total_matches_query = select(func.count(Match.id))
            total_matches = await self.db.scalar(total_matches_query) or 0
            
            # Matches by status
            pending_matches_query = select(func.count(Match.id)).where(Match.status == MatchStatus.PENDING)
            pending_matches = await self.db.scalar(pending_matches_query) or 0
            
            promoted_matches_query = select(func.count(Match.id)).where(Match.status == MatchStatus.PROMOTED)
            promoted_matches = await self.db.scalar(promoted_matches_query) or 0
            
            dismissed_matches_query = select(func.count(Match.id)).where(Match.status == MatchStatus.DISMISSED)
            dismissed_matches = await self.db.scalar(dismissed_matches_query) or 0
            
            # Matches by type
            lost_found_matches_query = select(func.count(Match.id)).where(Match.match_type == MatchType.LOST_FOUND)
            lost_found_matches = await self.db.scalar(lost_found_matches_query) or 0
            
            found_lost_matches_query = select(func.count(Match.id)).where(Match.match_type == MatchType.FOUND_LOST)
            found_lost_matches = await self.db.scalar(found_lost_matches_query) or 0
            
            # Average score
            avg_score_query = select(func.avg(Match.score))
            avg_score = await self.db.scalar(avg_score_query) or 0.0
            
            # High confidence matches (score > 0.8)
            high_confidence_query = select(func.count(Match.id)).where(Match.score > 0.8)
            high_confidence_matches = await self.db.scalar(high_confidence_query) or 0
            
            # Recent matches (last 7 days)
            week_ago = datetime.utcnow() - timedelta(days=7)
            recent_matches_query = select(func.count(Match.id)).where(Match.created_at >= week_ago)
            recent_matches = await self.db.scalar(recent_matches_query) or 0
            
            # Calculate success rate
            success_rate = 0.0
            if total_matches > 0:
                success_rate = round((promoted_matches / total_matches) * 100, 1)
            
            return {
                "total_matches": total_matches,
                "by_status": {
                    "pending": pending_matches,
                    "promoted": promoted_matches,
                    "dismissed": dismissed_matches
                },
                "by_type": {
                    "lost_found": lost_found_matches,
                    "found_lost": found_lost_matches
                },
                "score_analysis": {
                    "average_score": round(avg_score, 3),
                    "high_confidence_matches": high_confidence_matches,
                    "high_confidence_percentage": round((high_confidence_matches / total_matches) * 100, 1) if total_matches > 0 else 0
                },
                "activity": {
                    "recent_matches_7_days": recent_matches,
                    "success_rate_percentage": success_rate
                }
            }
            
        except Exception as e:
            logger.error(f"Error getting match statistics: {e}")
            return None
    
    async def get_pending_matches(self, limit: int = 50) -> List[Match]:
        """
        Get pending matches that need review.
        
        Args:
            limit: Maximum number of matches to return
            
        Returns:
            List of pending match instances
        """
        try:
            query = (
                select(Match)
                .options(
                    selectinload(Match.source_report),
                    selectinload(Match.candidate_report)
                )
                .where(Match.status == MatchStatus.PENDING)
                .order_by(desc(Match.score), desc(Match.created_at))
                .limit(limit)
            )
            
            result = await self.db.execute(query)
            return list(result.scalars().all())
            
        except Exception as e:
            logger.error(f"Error getting pending matches: {e}")
            return []
    
    async def get_high_score_matches(self, min_score: float = 0.8, limit: int = 20) -> List[Match]:
        """
        Get high-score matches.
        
        Args:
            min_score: Minimum score threshold
            limit: Maximum number of matches to return
            
        Returns:
            List of high-score match instances
        """
        try:
            query = (
                select(Match)
                .options(
                    selectinload(Match.source_report),
                    selectinload(Match.candidate_report)
                )
                .where(Match.score >= min_score)
                .order_by(desc(Match.score), desc(Match.created_at))
                .limit(limit)
            )
            
            result = await self.db.execute(query)
            return list(result.scalars().all())
            
        except Exception as e:
            logger.error(f"Error getting high-score matches: {e}")
            return []
    
    async def get_matches_by_date_range(self, start_date: datetime, end_date: datetime) -> List[Match]:
        """
        Get matches created within a date range.
        
        Args:
            start_date: Start date
            end_date: End date
            
        Returns:
            List of match instances
        """
        try:
            query = (
                select(Match)
                .options(
                    selectinload(Match.source_report),
                    selectinload(Match.candidate_report)
                )
                .where(
                    and_(
                        Match.created_at >= start_date,
                        Match.created_at <= end_date
                    )
                )
                .order_by(desc(Match.created_at))
            )
            
            result = await self.db.execute(query)
            return list(result.scalars().all())
            
        except Exception as e:
            logger.error(f"Error getting matches by date range: {e}")
            return []
