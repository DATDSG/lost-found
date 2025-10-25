"""
Test configuration and fixtures for the Lost & Found API
=======================================================
Comprehensive test setup with database, Redis, and external service mocking.
"""

import asyncio
import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, MagicMock
import os
import tempfile
import shutil
from typing import AsyncGenerator, Generator

# Import application components
from app.main import app
from app.config import optimized_config
from app.infrastructure.database.base import Base
from app.infrastructure.database.session import get_async_db
from app.models import User

# Test database URL
TEST_DATABASE_URL = "postgresql+asyncpg://postgres:postgres@localhost:5432/lostfound_test"

@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest_asyncio.fixture(scope="function")
async def test_db():
    """Create a test database session."""
    # Create test database engine
    engine = create_async_engine(
        TEST_DATABASE_URL,
        echo=False,
        pool_pre_ping=True,
        pool_recycle=300,
    )
    
    # Create all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Create session factory
    async_session = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    # Create session
    async with async_session() as session:
        yield session
    
    # Clean up
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    
    await engine.dispose()

@pytest.fixture
def test_client(test_db):
    """Create a test client with database dependency override."""
    def override_get_db():
        return test_db
    
    app.dependency_overrides[get_async_db] = override_get_db
    
    with TestClient(app) as client:
        yield client
    
    app.dependency_overrides.clear()

@pytest_asyncio.fixture
async def async_client(test_db):
    """Create an async test client."""
    def override_get_db():
        return test_db
    
    app.dependency_overrides[get_async_db] = override_get_db
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client
    
    app.dependency_overrides.clear()

@pytest.fixture
def mock_redis():
    """Mock Redis client."""
    mock_redis = AsyncMock()
    mock_redis.get.return_value = None
    mock_redis.set.return_value = True
    mock_redis.delete.return_value = True
    mock_redis.exists.return_value = False
    mock_redis.expire.return_value = True
    mock_redis.health_check.return_value = {
        "status": "healthy",
        "version": "7.0.0",
        "memory_used": "1MB"
    }
    return mock_redis

@pytest.fixture
def mock_minio():
    """Mock MinIO client."""
    mock_minio = MagicMock()
    mock_minio.health_check.return_value = {
        "status": "healthy",
        "endpoint": "http://localhost:9000",
        "bucket_count": 1
    }
    mock_minio.put_object.return_value = True
    mock_minio.get_object.return_value = b"test data"
    mock_minio.remove_object.return_value = True
    return mock_minio

@pytest.fixture
def mock_nlp_client():
    """Mock NLP service client."""
    mock_client = AsyncMock()
    mock_client.health_check.return_value = {"status": "healthy"}
    mock_client.calculate_similarity.return_value = {
        "similarity_score": 0.85,
        "confidence": 0.9,
        "method": "cosine_similarity"
    }
    return mock_client

@pytest.fixture
def mock_vision_client():
    """Mock Vision service client."""
    mock_client = AsyncMock()
    mock_client.health_check.return_value = {"status": "healthy"}
    mock_client.calculate_similarity.return_value = {
        "similarity_score": 0.78,
        "confidence": 0.85,
        "method": "perceptual_hash"
    }
    return mock_client

@pytest.fixture
def sample_user_data():
    """Sample user data for testing."""
    return {
        "email": "test@example.com",
        "password": "testpassword123",
        "display_name": "Test User",
        "phone_number": "+1234567890"
    }

@pytest_asyncio.fixture
async def sample_user(test_db, sample_user_data):
    """Create a sample user in the test database."""
    user = User(
        email=sample_user_data["email"],
        password=sample_user_data["password"],
        display_name=sample_user_data["display_name"],
        phone_number=sample_user_data["phone_number"]
    )
    test_db.add(user)
    await test_db.commit()
    await test_db.refresh(user)
    return user

@pytest.fixture
def sample_report_data():
    """Sample report data for testing."""
    return {
        "report_type": "lost",
        "title": "Lost iPhone",
        "description": "Black iPhone 13 Pro Max lost in downtown area",
        "category": "electronics",
        "location_description": "Downtown area near Central Park",
        "date_lost": "2024-01-15T10:00:00Z"
    }

@pytest_asyncio.fixture
async def sample_report(test_db, sample_user, sample_report_data):
    """Create a sample report in the test database."""
    report = Report(
        user_id=sample_user.id,
        report_type=sample_report_data["report_type"],
        title=sample_report_data["title"],
        description=sample_report_data["description"],
        category=sample_report_data["category"],
        location_description=sample_report_data["location_description"],
        date_lost=sample_report_data["date_lost"]
    )
    test_db.add(report)
    await test_db.commit()
    await test_db.refresh(report)
    return report

@pytest.fixture
def auth_headers(sample_user):
    """Generate authentication headers for testing."""
    # In a real implementation, you would generate a JWT token here
    return {"Authorization": f"Bearer test_token_{sample_user.id}"}

@pytest.fixture
def temp_media_dir():
    """Create a temporary directory for media testing."""
    temp_dir = tempfile.mkdtemp()
    yield temp_dir
    shutil.rmtree(temp_dir)

@pytest.fixture
def sample_image_file(temp_media_dir):
    """Create a sample image file for testing."""
    import io
    from PIL import Image
    
    # Create a simple test image
    img = Image.new('RGB', (100, 100), color='red')
    img_path = os.path.join(temp_media_dir, 'test_image.jpg')
    img.save(img_path, 'JPEG')
    
    return img_path

# Test markers
pytestmark = pytest.mark.asyncio
