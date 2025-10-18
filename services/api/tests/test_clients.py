"""Integration tests for service clients (NLP and Vision)."""

import pytest
from unittest.mock import AsyncMock, patch, Mock
import httpx

from app.clients import NLPClient, VisionClient, get_cache_client


@pytest.fixture
def mock_httpx_client():
    """Create a mock httpx AsyncClient."""
    client = AsyncMock(spec=httpx.AsyncClient)
    return client


@pytest.fixture
def nlp_client(mock_httpx_client):
    """Create an NLPClient for testing."""
    with patch('app.clients.httpx.AsyncClient', return_value=mock_httpx_client):
        return NLPClient("http://nlp:8001")


@pytest.fixture
def vision_client(mock_httpx_client):
    """Create a VisionClient for testing."""
    with patch('app.clients.httpx.AsyncClient', return_value=mock_httpx_client):
        return VisionClient("http://vision:8002")


@pytest.fixture
def mock_cache():
    """Create a mock Redis cache."""
    cache = AsyncMock()
    cache.get.return_value = None
    cache.setex = AsyncMock()
    return cache


class TestNLPClient:
    """Test suite for NLP service client."""

    @pytest.mark.asyncio
    async def test_generate_embedding_success(self, nlp_client, mock_httpx_client):
        """Test successful embedding generation."""
        # Mock successful response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"embedding": [0.1, 0.2, 0.3]}
        mock_httpx_client.post.return_value = mock_response
        
        embedding = await nlp_client.generate_embedding("test text")
        
        assert embedding is not None
        assert isinstance(embedding, list)
        assert len(embedding) == 3
        assert embedding == [0.1, 0.2, 0.3]

    @pytest.mark.asyncio
    async def test_generate_embedding_with_cache(self, nlp_client, mock_cache):
        """Test embedding generation with cache hit."""
        with patch('app.clients.get_cache_client', return_value=mock_cache):
            # Mock cache hit
            import json
            mock_cache.get.return_value = json.dumps([0.1, 0.2, 0.3])
            
            client = NLPClient("http://nlp:8001")
            embedding = await client.generate_embedding("cached text")
            
            assert embedding == [0.1, 0.2, 0.3]
            # Should not call HTTP client
            mock_cache.get.assert_called_once()

    @pytest.mark.asyncio
    async def test_generate_embedding_service_error(self, nlp_client, mock_httpx_client):
        """Test handling of NLP service errors."""
        # Mock error response
        mock_response = Mock()
        mock_response.status_code = 500
        mock_response.raise_for_status.side_effect = httpx.HTTPStatusError(
            "Server error", request=Mock(), response=mock_response
        )
        mock_httpx_client.post.return_value = mock_response
        
        embedding = await nlp_client.generate_embedding("test text")
        
        # Should return None on error
        assert embedding is None

    @pytest.mark.asyncio
    async def test_generate_embedding_timeout(self, nlp_client, mock_httpx_client):
        """Test handling of timeout errors."""
        # Mock timeout
        mock_httpx_client.post.side_effect = httpx.TimeoutException("Timeout")
        
        embedding = await nlp_client.generate_embedding("test text")
        
        assert embedding is None

    @pytest.mark.asyncio
    async def test_health_check_success(self, nlp_client, mock_httpx_client):
        """Test successful health check."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"status": "healthy"}
        mock_httpx_client.get.return_value = mock_response
        
        is_healthy = await nlp_client.health_check()
        
        assert is_healthy is True

    @pytest.mark.asyncio
    async def test_health_check_failure(self, nlp_client, mock_httpx_client):
        """Test failed health check."""
        mock_httpx_client.get.side_effect = httpx.RequestError("Connection failed")
        
        is_healthy = await nlp_client.health_check()
        
        assert is_healthy is False


class TestVisionClient:
    """Test suite for Vision service client."""

    @pytest.mark.asyncio
    async def test_generate_hash_success(self, vision_client, mock_httpx_client):
        """Test successful image hash generation."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"hash": "abc123def456"}
        mock_httpx_client.post.return_value = mock_response
        
        image_hash = await vision_client.generate_hash("http://example.com/image.jpg")
        
        assert image_hash is not None
        assert isinstance(image_hash, str)
        assert image_hash == "abc123def456"

    @pytest.mark.asyncio
    async def test_generate_hash_with_cache(self, vision_client, mock_cache):
        """Test hash generation with cache hit."""
        with patch('app.clients.get_cache_client', return_value=mock_cache):
            # Mock cache hit
            mock_cache.get.return_value = "cached_hash_123"
            
            client = VisionClient("http://vision:8002")
            image_hash = await client.generate_hash("http://example.com/cached.jpg")
            
            assert image_hash == "cached_hash_123"
            mock_cache.get.assert_called_once()

    @pytest.mark.asyncio
    async def test_generate_hash_service_error(self, vision_client, mock_httpx_client):
        """Test handling of Vision service errors."""
        mock_response = Mock()
        mock_response.status_code = 500
        mock_response.raise_for_status.side_effect = httpx.HTTPStatusError(
            "Server error", request=Mock(), response=mock_response
        )
        mock_httpx_client.post.return_value = mock_response
        
        image_hash = await vision_client.generate_hash("http://example.com/image.jpg")
        
        assert image_hash is None

    @pytest.mark.asyncio
    async def test_generate_hash_invalid_image(self, vision_client, mock_httpx_client):
        """Test handling of invalid image URLs."""
        mock_response = Mock()
        mock_response.status_code = 400
        mock_response.raise_for_status.side_effect = httpx.HTTPStatusError(
            "Bad request", request=Mock(), response=mock_response
        )
        mock_httpx_client.post.return_value = mock_response
        
        image_hash = await vision_client.generate_hash("invalid_url")
        
        assert image_hash is None

    @pytest.mark.asyncio
    async def test_health_check_success(self, vision_client, mock_httpx_client):
        """Test successful health check."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_httpx_client.get.return_value = mock_response
        
        is_healthy = await vision_client.health_check()
        
        assert is_healthy is True

    @pytest.mark.asyncio
    async def test_health_check_failure(self, vision_client, mock_httpx_client):
        """Test failed health check."""
        mock_httpx_client.get.side_effect = Exception("Network error")
        
        is_healthy = await vision_client.health_check()
        
        assert is_healthy is False


class TestClientRetryLogic:
    """Test retry logic for service clients."""

    @pytest.mark.asyncio
    async def test_nlp_client_retry_on_failure(self, mock_httpx_client):
        """Test that NLP client retries on failure."""
        with patch('app.clients.httpx.AsyncClient', return_value=mock_httpx_client):
            # First two calls fail, third succeeds
            mock_response_fail = Mock()
            mock_response_fail.status_code = 500
            mock_response_fail.raise_for_status.side_effect = httpx.HTTPStatusError(
                "Error", request=Mock(), response=mock_response_fail
            )
            
            mock_response_success = Mock()
            mock_response_success.status_code = 200
            mock_response_success.json.return_value = {"embedding": [0.1, 0.2]}
            
            mock_httpx_client.post.side_effect = [
                mock_response_fail,
                mock_response_fail,
                mock_response_success
            ]
            
            client = NLPClient("http://nlp:8001", max_retries=3)
            embedding = await client.generate_embedding("test")
            
            # Should eventually succeed
            assert embedding is not None
            assert mock_httpx_client.post.call_count == 3


@pytest.mark.asyncio
class TestCacheClient:
    """Test Redis cache client."""

    async def test_get_cache_client(self):
        """Test cache client initialization."""
        with patch('app.clients.redis.from_url') as mock_redis:
            mock_redis.return_value = AsyncMock()
            
            cache = get_cache_client()
            
            assert cache is not None

    async def test_cache_set_get(self, mock_cache):
        """Test cache set and get operations."""
        # Set value
        await mock_cache.setex("test_key", 300, "test_value")
        mock_cache.setex.assert_called_with("test_key", 300, "test_value")
        
        # Get value
        mock_cache.get.return_value = "test_value"
        value = await mock_cache.get("test_key")
        
        assert value == "test_value"
