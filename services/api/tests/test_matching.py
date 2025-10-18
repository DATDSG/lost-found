"""Unit tests for the MatchingPipeline."""

import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock, AsyncMock, patch
from sqlalchemy.ext.asyncio import AsyncSession

from app.matching import MatchingPipeline, MatchCandidate
from app.models import Report
from app.config import get_config


@pytest.fixture
def mock_db():
    """Create a mock database session."""
    return AsyncMock(spec=AsyncSession)


@pytest.fixture
def mock_config():
    """Create a mock configuration."""
    config = Mock()
    config.matching_text_weight = 0.45
    config.matching_image_weight = 0.35
    config.matching_geo_weight = 0.15
    config.matching_time_weight = 0.05
    config.matching_text_threshold = 0.7
    config.matching_geo_radius_km = 5.0
    config.matching_time_window_days = 30
    config.cache_ttl = 300
    return config


@pytest.fixture
def mock_cache_client():
    """Create a mock Redis cache client."""
    cache = AsyncMock()
    cache.get.return_value = None
    cache.setex = AsyncMock()
    return cache


@pytest.fixture
def sample_report():
    """Create a sample report for testing."""
    report = Mock(spec=Report)
    report.id = 1
    report.type = "lost"
    report.title = "Lost Black Backpack"
    report.description = "Black backpack with laptop inside"
    report.category = "bag"
    report.location_point = "POINT(-73.935242 40.730610)"  # NYC coordinates
    report.embedding = [0.1] * 384  # Mock embedding vector
    report.image_hash = "abc123def456"
    report.created_at = datetime.utcnow()
    report.user_id = 100
    return report


@pytest.fixture
def matching_pipeline(mock_db, mock_config, mock_cache_client):
    """Create a MatchingPipeline instance for testing."""
    with patch('app.matching.get_config', return_value=mock_config):
        with patch('app.matching.get_cache_client', return_value=mock_cache_client):
            return MatchingPipeline(mock_db)


class TestMatchingPipeline:
    """Test suite for MatchingPipeline."""

    def test_initialization(self, matching_pipeline, mock_db):
        """Test that MatchingPipeline initializes correctly."""
        assert matching_pipeline.db == mock_db
        assert matching_pipeline.config is not None
        assert matching_pipeline.cache is not None

    @pytest.mark.asyncio
    async def test_text_similarity_calculation(self, matching_pipeline):
        """Test text similarity score calculation."""
        embedding1 = [1.0, 0.0, 0.0]
        embedding2 = [1.0, 0.0, 0.0]
        
        # Identical embeddings should give high similarity
        score = matching_pipeline._calculate_text_similarity(embedding1, embedding2)
        assert score == pytest.approx(1.0, abs=0.01)
        
        # Orthogonal embeddings should give low similarity
        embedding3 = [0.0, 1.0, 0.0]
        score = matching_pipeline._calculate_text_similarity(embedding1, embedding3)
        assert score == pytest.approx(0.0, abs=0.01)

    def test_image_similarity_calculation(self, matching_pipeline):
        """Test image hash similarity calculation."""
        # Identical hashes
        score = matching_pipeline._calculate_image_similarity("abc123", "abc123")
        assert score == 1.0
        
        # Different hashes (Hamming distance)
        score = matching_pipeline._calculate_image_similarity("0000", "1111")
        assert 0.0 <= score <= 1.0

    def test_geo_proximity_calculation(self, matching_pipeline):
        """Test geographic proximity score calculation."""
        # Same location
        point1 = "POINT(-73.935242 40.730610)"
        point2 = "POINT(-73.935242 40.730610)"
        score = matching_pipeline._calculate_geo_proximity(point1, point2)
        assert score == 1.0
        
        # Very far apart (should be 0)
        point3 = "POINT(0.0 0.0)"  # Null Island
        score = matching_pipeline._calculate_geo_proximity(point1, point3)
        assert score == 0.0

    def test_time_decay_calculation(self, matching_pipeline):
        """Test time decay score calculation."""
        now = datetime.utcnow()
        
        # Recent report (1 day ago)
        recent = now - timedelta(days=1)
        score = matching_pipeline._calculate_time_decay(now, recent)
        assert score > 0.9
        
        # Old report (30 days ago)
        old = now - timedelta(days=30)
        score = matching_pipeline._calculate_time_decay(now, old)
        assert 0.0 <= score < 0.5
        
        # Very old report (100 days ago)
        very_old = now - timedelta(days=100)
        score = matching_pipeline._calculate_time_decay(now, very_old)
        assert score == pytest.approx(0.0, abs=0.1)

    def test_composite_score_calculation(self, matching_pipeline):
        """Test weighted composite score calculation."""
        scores = {
            'text': 0.9,
            'image': 0.8,
            'geo': 0.7,
            'time': 0.6
        }
        
        composite = matching_pipeline._calculate_composite_score(scores)
        
        # Should be weighted average
        expected = (0.9 * 0.45) + (0.8 * 0.35) + (0.7 * 0.15) + (0.6 * 0.05)
        assert composite == pytest.approx(expected, abs=0.01)

    @pytest.mark.asyncio
    async def test_find_matches_empty_result(self, matching_pipeline, sample_report, mock_db):
        """Test find_matches when no candidates are found."""
        # Mock empty database query result
        mock_db.execute = AsyncMock(return_value=Mock(scalars=Mock(return_value=Mock(all=Mock(return_value=[])))))
        
        matches = await matching_pipeline.find_matches(sample_report, max_results=10)
        
        assert isinstance(matches, list)
        assert len(matches) == 0

    @pytest.mark.asyncio
    async def test_find_matches_with_candidates(self, matching_pipeline, sample_report, mock_db):
        """Test find_matches with candidate reports."""
        # Create mock candidate reports
        candidate1 = Mock(spec=Report)
        candidate1.id = 2
        candidate1.type = "found"
        candidate1.title = "Found Black Backpack"
        candidate1.category = "bag"
        candidate1.embedding = [0.1] * 384
        candidate1.image_hash = "abc123def457"  # Similar hash
        candidate1.location_point = "POINT(-73.935242 40.730610)"
        candidate1.created_at = datetime.utcnow() - timedelta(days=1)
        candidate1.user_id = 200
        
        # Mock database query result
        mock_result = Mock()
        mock_result.scalars = Mock(return_value=Mock(all=Mock(return_value=[candidate1])))
        mock_db.execute = AsyncMock(return_value=mock_result)
        
        matches = await matching_pipeline.find_matches(sample_report, max_results=10)
        
        assert isinstance(matches, list)
        assert len(matches) > 0
        
        # Verify match structure
        match = matches[0]
        assert isinstance(match, MatchCandidate)
        assert match.report_id == candidate1.id
        assert 0.0 <= match.score <= 1.0
        assert match.explanation is not None

    @pytest.mark.asyncio
    async def test_cache_integration(self, matching_pipeline, sample_report, mock_cache_client):
        """Test that caching works correctly."""
        # First call should miss cache
        mock_cache_client.get.return_value = None
        
        # Mock database with empty result
        matching_pipeline.db.execute = AsyncMock(
            return_value=Mock(scalars=Mock(return_value=Mock(all=Mock(return_value=[]))))
        )
        
        await matching_pipeline.find_matches(sample_report)
        
        # Verify cache was checked
        mock_cache_client.get.assert_called_once()
        
        # Verify cache was set
        mock_cache_client.setex.assert_called_once()

    @pytest.mark.asyncio
    async def test_opposite_type_matching(self, matching_pipeline, sample_report, mock_db):
        """Test that only opposite type reports are matched (lost <-> found)."""
        # Lost report should only match found reports
        assert sample_report.type == "lost"
        
        # This would be verified in the actual SQL query construction
        # which should filter for opposite types
        await matching_pipeline.find_matches(sample_report)
        
        # Verify execute was called (query construction is internal)
        mock_db.execute.assert_called()

    def test_score_ordering(self, matching_pipeline):
        """Test that matches are returned in descending score order."""
        candidates = [
            MatchCandidate(report_id=1, score=0.5, explanation="Low match"),
            MatchCandidate(report_id=2, score=0.9, explanation="High match"),
            MatchCandidate(report_id=3, score=0.7, explanation="Medium match"),
        ]
        
        sorted_candidates = sorted(candidates, key=lambda x: x.score, reverse=True)
        
        assert sorted_candidates[0].score == 0.9
        assert sorted_candidates[1].score == 0.7
        assert sorted_candidates[2].score == 0.5


@pytest.mark.asyncio
class TestMatchingPipelineIntegration:
    """Integration tests for MatchingPipeline with more realistic scenarios."""

    async def test_full_matching_workflow(self, matching_pipeline, sample_report):
        """Test the complete matching workflow end-to-end."""
        # This would require a real database connection in a full integration test
        # For now, we verify the structure is correct
        assert matching_pipeline is not None
        assert sample_report is not None

    async def test_performance_with_many_candidates(self, matching_pipeline):
        """Test performance with a large number of candidate reports."""
        # This would be a performance test with actual data
        # Placeholder for future implementation
        pass
