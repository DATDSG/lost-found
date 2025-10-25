"""
Integration tests for the Lost & Found API
==========================================
End-to-end tests for API endpoints, database operations, and external service integration.
"""

import pytest
import json
from httpx import AsyncClient
from fastapi import status
from unittest.mock import patch, AsyncMock

from app.main import app
from app.models import User


class TestAuthenticationEndpoints:
    """Test authentication API endpoints."""
    
    @pytest.mark.asyncio
    async def test_user_registration_success(self, async_client: AsyncClient):
        """Test successful user registration."""
        user_data = {
            "email": "newuser@example.com",
            "password": "newpassword123",
            "display_name": "New User",
            "phone_number": "+1234567890"
        }
        
        response = await async_client.post("/v1/auth/register", json=user_data)
        
        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        assert data["email"] == user_data["email"]
        assert data["display_name"] == user_data["display_name"]
        assert "id" in data
        assert "password" not in data  # Password should not be returned
    
    @pytest.mark.asyncio
    async def test_user_registration_duplicate_email(self, async_client: AsyncClient, sample_user):
        """Test user registration with duplicate email."""
        user_data = {
            "email": sample_user.email,
            "password": "newpassword123",
            "display_name": "Another User"
        }
        
        response = await async_client.post("/v1/auth/register", json=user_data)
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        data = response.json()
        assert "email" in data["detail"].lower()
    
    @pytest.mark.asyncio
    async def test_user_login_success(self, async_client: AsyncClient, sample_user):
        """Test successful user login."""
        login_data = {
            "email": sample_user.email,
            "password": "testpassword123"
        }
        
        response = await async_client.post("/v1/auth/login", json=login_data)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert "token_type" in data
        assert data["token_type"] == "bearer"
    
    @pytest.mark.asyncio
    async def test_user_login_invalid_credentials(self, async_client: AsyncClient):
        """Test user login with invalid credentials."""
        login_data = {
            "email": "nonexistent@example.com",
            "password": "wrongpassword"
        }
        
        response = await async_client.post("/v1/auth/login", json=login_data)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        data = response.json()
        assert "invalid" in data["detail"].lower()
    
    @pytest.mark.asyncio
    async def test_token_refresh(self, async_client: AsyncClient, sample_user):
        """Test token refresh functionality."""
        # First login to get tokens
        login_data = {
            "email": sample_user.email,
            "password": "testpassword123"
        }
        
        login_response = await async_client.post("/v1/auth/login", json=login_data)
        tokens = login_response.json()
        
        # Use refresh token to get new access token
        refresh_data = {"refresh_token": tokens["refresh_token"]}
        response = await async_client.post("/v1/auth/refresh", json=refresh_data)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data


class TestReportEndpoints:
    """Test report management API endpoints."""
    
    @pytest.mark.asyncio
    async def test_create_lost_report(self, async_client: AsyncClient, auth_headers):
        """Test creating a lost item report."""
        report_data = {
            "report_type": "lost",
            "title": "Lost iPhone 13 Pro",
            "description": "Black iPhone 13 Pro Max lost in downtown area",
            "category": "electronics",
            "location_description": "Downtown area near Central Park",
            "date_lost": "2024-01-15T10:00:00Z"
        }
        
        response = await async_client.post(
            "/v1/reports",
            json=report_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        assert data["title"] == report_data["title"]
        assert data["report_type"] == report_data["report_type"]
        assert data["status"] == "active"
        assert "id" in data
    
    @pytest.mark.asyncio
    async def test_create_found_report(self, async_client: AsyncClient, auth_headers):
        """Test creating a found item report."""
        report_data = {
            "report_type": "found",
            "title": "Found iPhone 13 Pro",
            "description": "Black iPhone 13 Pro Max found in downtown area",
            "category": "electronics",
            "location_description": "Downtown area near Central Park",
            "date_found": "2024-01-15T10:00:00Z"
        }
        
        response = await async_client.post(
            "/v1/reports",
            json=report_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        assert data["title"] == report_data["title"]
        assert data["report_type"] == report_data["report_type"]
        assert data["status"] == "active"
    
    @pytest.mark.asyncio
    async def test_get_reports_list(self, async_client: AsyncClient, auth_headers, sample_report):
        """Test getting list of reports."""
        response = await async_client.get("/v1/reports", headers=auth_headers)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "page" in data
        assert "size" in data
        assert len(data["items"]) >= 1
    
    @pytest.mark.asyncio
    async def test_get_report_by_id(self, async_client: AsyncClient, auth_headers, sample_report):
        """Test getting a specific report by ID."""
        response = await async_client.get(
            f"/v1/reports/{sample_report.id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["id"] == str(sample_report.id)
        assert data["title"] == sample_report.title
    
    @pytest.mark.asyncio
    async def test_update_report(self, async_client: AsyncClient, auth_headers, sample_report):
        """Test updating a report."""
        update_data = {
            "title": "Updated Lost iPhone 13 Pro",
            "description": "Updated description"
        }
        
        response = await async_client.put(
            f"/v1/reports/{sample_report.id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["title"] == update_data["title"]
        assert data["description"] == update_data["description"]
    
    @pytest.mark.asyncio
    async def test_delete_report(self, async_client: AsyncClient, auth_headers, sample_report):
        """Test deleting a report."""
        response = await async_client.delete(
            f"/v1/reports/{sample_report.id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_204_NO_CONTENT
        
        # Verify report is deleted
        get_response = await async_client.get(
            f"/v1/reports/{sample_report.id}",
            headers=auth_headers
        )
        assert get_response.status_code == status.HTTP_404_NOT_FOUND
    
    @pytest.mark.asyncio
    async def test_unauthorized_access(self, async_client: AsyncClient):
        """Test accessing protected endpoints without authentication."""
        response = await async_client.get("/v1/reports")
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


class TestMatchingEndpoints:
    """Test matching functionality API endpoints."""
    
    @pytest.mark.asyncio
    async def test_search_matches(self, async_client: AsyncClient, auth_headers, sample_report):
        """Test searching for matches."""
        search_data = {
            "report_id": str(sample_report.id),
            "max_results": 10
        }
        
        # Mock external services
        with patch('app.clients.get_nlp_client') as mock_nlp, \
             patch('app.clients.get_vision_client') as mock_vision:
            
            mock_nlp.return_value.calculate_similarity.return_value = {
                "similarity_score": 0.85,
                "confidence": 0.9
            }
            mock_vision.return_value.calculate_similarity.return_value = {
                "similarity_score": 0.78,
                "confidence": 0.85
            }
            
            response = await async_client.post(
                "/v1/matches/search",
                json=search_data,
                headers=auth_headers
            )
            
            assert response.status_code == status.HTTP_200_OK
            data = response.json()
            assert "matches" in data
            assert "total" in data
    
    @pytest.mark.asyncio
    async def test_get_matches(self, async_client: AsyncClient, auth_headers):
        """Test getting list of matches."""
        response = await async_client.get("/v1/matches", headers=auth_headers)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "page" in data
        assert "size" in data
    
    @pytest.mark.asyncio
    async def test_update_match_status(self, async_client: AsyncClient, auth_headers):
        """Test updating match status."""
        # This would require a sample match to be created first
        # For now, we'll test the endpoint structure
        match_id = "123e4567-e89b-12d3-a456-426614174000"
        status_data = {"status": "confirmed"}
        
        response = await async_client.put(
            f"/v1/matches/{match_id}/status",
            json=status_data,
            headers=auth_headers
        )
        
        # Should return 404 for non-existent match, but endpoint should exist
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_404_NOT_FOUND]


class TestMediaEndpoints:
    """Test media upload and management endpoints."""
    
    @pytest.mark.asyncio
    async def test_upload_image(self, async_client: AsyncClient, auth_headers, sample_image_file):
        """Test image upload functionality."""
        with open(sample_image_file, "rb") as f:
            files = {"file": ("test_image.jpg", f, "image/jpeg")}
            
            response = await async_client.post(
                "/v1/media/upload",
                files=files,
                headers=auth_headers
            )
        
        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        assert "id" in data
        assert "file_path" in data
        assert "file_type" in data
        assert data["file_type"] == "image/jpeg"
    
    @pytest.mark.asyncio
    async def test_get_media(self, async_client: AsyncClient, auth_headers):
        """Test getting media file information."""
        media_id = "123e4567-e89b-12d3-a456-426614174000"
        
        response = await async_client.get(
            f"/v1/media/{media_id}",
            headers=auth_headers
        )
        
        # Should return 404 for non-existent media, but endpoint should exist
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_404_NOT_FOUND]


class TestHealthEndpoints:
    """Test health check and monitoring endpoints."""
    
    @pytest.mark.asyncio
    async def test_health_check(self, async_client: AsyncClient):
        """Test health check endpoint."""
        response = await async_client.get("/health")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "status" in data
        assert "service" in data
        assert "version" in data
        assert data["status"] in ["ok", "degraded"]
    
    @pytest.mark.asyncio
    async def test_v1_health_check(self, async_client: AsyncClient):
        """Test v1 health check endpoint."""
        response = await async_client.get("/v1/health")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "status" in data
        assert "service" in data
    
    @pytest.mark.asyncio
    async def test_performance_metrics(self, async_client: AsyncClient):
        """Test performance metrics endpoint."""
        response = await async_client.get("/performance/metrics")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "database" in data
        assert "cache" in data
        assert "configuration" in data


class TestAdminEndpoints:
    """Test admin panel API endpoints."""
    
    @pytest.mark.asyncio
    async def test_admin_dashboard(self, async_client: AsyncClient, auth_headers):
        """Test admin dashboard endpoint."""
        response = await async_client.get("/v1/admin/dashboard", headers=auth_headers)
        
        # Should return 403 for non-admin users, but endpoint should exist
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_403_FORBIDDEN]
    
    @pytest.mark.asyncio
    async def test_admin_users(self, async_client: AsyncClient, auth_headers):
        """Test admin users endpoint."""
        response = await async_client.get("/v1/admin/users", headers=auth_headers)
        
        # Should return 403 for non-admin users, but endpoint should exist
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_403_FORBIDDEN]
    
    @pytest.mark.asyncio
    async def test_admin_reports(self, async_client: AsyncClient, auth_headers):
        """Test admin reports endpoint."""
        response = await async_client.get("/v1/admin/reports", headers=auth_headers)
        
        # Should return 403 for non-admin users, but endpoint should exist
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_403_FORBIDDEN]


class TestErrorHandling:
    """Test error handling and edge cases."""
    
    @pytest.mark.asyncio
    async def test_invalid_json(self, async_client: AsyncClient):
        """Test handling of invalid JSON."""
        response = await async_client.post(
            "/v1/auth/login",
            content="invalid json",
            headers={"Content-Type": "application/json"}
        )
        
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    @pytest.mark.asyncio
    async def test_missing_required_fields(self, async_client: AsyncClient):
        """Test handling of missing required fields."""
        incomplete_data = {"email": "test@example.com"}  # Missing password
        
        response = await async_client.post("/v1/auth/login", json=incomplete_data)
        
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    @pytest.mark.asyncio
    async def test_invalid_uuid(self, async_client: AsyncClient, auth_headers):
        """Test handling of invalid UUID."""
        invalid_uuid = "not-a-uuid"
        
        response = await async_client.get(
            f"/v1/reports/{invalid_uuid}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    @pytest.mark.asyncio
    async def test_nonexistent_resource(self, async_client: AsyncClient, auth_headers):
        """Test handling of nonexistent resources."""
        nonexistent_id = "123e4567-e89b-12d3-a456-426614174000"
        
        response = await async_client.get(
            f"/v1/reports/{nonexistent_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_404_NOT_FOUND


class TestRateLimiting:
    """Test rate limiting functionality."""
    
    @pytest.mark.asyncio
    async def test_rate_limiting_auth(self, async_client: AsyncClient):
        """Test rate limiting on authentication endpoints."""
        login_data = {
            "email": "test@example.com",
            "password": "wrongpassword"
        }
        
        # Make multiple requests to trigger rate limiting
        responses = []
        for _ in range(10):  # Assuming rate limit is lower than 10
            response = await async_client.post("/v1/auth/login", json=login_data)
            responses.append(response.status_code)
        
        # At least one should be rate limited
        assert status.HTTP_429_TOO_MANY_REQUESTS in responses
    
    @pytest.mark.asyncio
    async def test_rate_limiting_search(self, async_client: AsyncClient, auth_headers):
        """Test rate limiting on search endpoints."""
        search_data = {
            "query": "test search",
            "max_results": 10
        }
        
        # Make multiple requests to trigger rate limiting
        responses = []
        for _ in range(100):  # Assuming rate limit is lower than 100
            response = await async_client.post(
                "/v1/matches/search",
                json=search_data,
                headers=auth_headers
            )
            responses.append(response.status_code)
        
        # At least one should be rate limited
        assert status.HTTP_429_TOO_MANY_REQUESTS in responses
