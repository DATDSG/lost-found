"""
Unit tests for authentication functionality
==========================================
Tests for user authentication, JWT tokens, and authorization.
"""

import pytest
from unittest.mock import patch, AsyncMock
from fastapi import HTTPException
from datetime import datetime, timedelta
import jwt

from app.auth import (
    create_access_token,
    get_password_hash,
    verify_password,
    decode_token
)
from app.models import User


class TestPasswordHashing:
    """Test password hashing functionality."""
    
    def test_hash_password(self):
        """Test password hashing."""
        password = "testpassword123"
        hashed = get_password_hash(password)
        
        assert hashed != password
        assert len(hashed) > 50  # Argon2 hashes are long
        assert hashed.startswith("$argon2id$")
    
    def test_verify_password_correct(self):
        """Test password verification with correct password."""
        password = "testpassword123"
        hashed = get_password_hash(password)
        
        assert verify_password(password, hashed) is True
    
    def test_verify_password_incorrect(self):
        """Test password verification with incorrect password."""
        password = "testpassword123"
        wrong_password = "wrongpassword"
        hashed = get_password_hash(password)
        
        assert verify_password(wrong_password, hashed) is False


class TestTokenCreation:
    """Test JWT token creation."""
    
    def test_create_access_token(self):
        """Test access token creation."""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        token = create_access_token({"sub": user_id})
        
        assert isinstance(token, str)
        assert len(token) > 100  # JWT tokens are long
        
        # Decode token to verify contents
        decoded = decode_token(token)
        assert decoded is not None
        assert decoded["sub"] == user_id
    
    def test_token_expiration(self):
        """Test token expiration."""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        
        # Create token with short expiration
        with patch('app.auth.ACCESS_TOKEN_EXPIRE_MINUTES', 1):
            token = create_access_token({"sub": user_id})
        
        # Token should be valid initially
        decoded = decode_token(token)
        assert decoded is not None
        assert decoded["sub"] == user_id


class TestTokenVerification:
    """Test JWT token verification."""
    
    def test_verify_valid_token(self):
        """Test verification of valid token."""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        token = create_access_token({"sub": user_id})
        
        decoded = decode_token(token)
        assert decoded is not None
        assert decoded["sub"] == user_id
    
    def test_verify_invalid_token(self):
        """Test verification of invalid token."""
        invalid_token = "invalid.token.here"
        
        decoded = decode_token(invalid_token)
        assert decoded is None


class TestUserModel:
    """Test User model functionality."""
    
    def test_user_creation(self):
        """Test User model creation."""
        user = User(
            email="test@example.com",
            password="hashed_password",
            display_name="Test User",
            role="user",
            is_active=True  # Explicitly set is_active
        )
        
        assert user.email == "test@example.com"
        assert user.display_name == "Test User"
        assert user.role == "user"
        assert user.is_active is True
    
    def test_user_repr(self):
        """Test User model string representation."""
        user = User(
            email="test@example.com",
            password="hashed_password",
            display_name="Test User",
            role="admin"
        )
        
        repr_str = repr(user)
        assert "test@example.com" in repr_str
        assert "admin" in repr_str


class TestAuthenticationIntegration:
    """Test authentication integration."""
    
    @pytest.mark.asyncio
    async def test_password_hash_and_verify(self):
        """Test password hashing and verification integration."""
        password = "testpassword123"
        
        # Hash password
        hashed = get_password_hash(password)
        
        # Verify password
        is_valid = verify_password(password, hashed)
        assert is_valid is True
        
        # Test with wrong password
        is_invalid = verify_password("wrongpassword", hashed)
        assert is_invalid is False
    
    def test_token_creation_and_verification(self):
        """Test token creation and verification integration."""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        
        # Create token
        token = create_access_token({"sub": user_id})
        
        # Verify token
        decoded = decode_token(token)
        assert decoded is not None
        assert decoded["sub"] == user_id
    
    def test_user_registration_flow(self):
        """Test user registration flow."""
        # Simulate user registration data
        email = "newuser@example.com"
        password = "newpassword123"
        display_name = "New User"
        
        # Hash password
        hashed_password = get_password_hash(password)
        
        # Create user
        user = User(
            email=email,
            password=hashed_password,
            display_name=display_name,
            role="user",
            is_active=True
        )
        
        # Verify user creation
        assert user.email == email
        assert user.display_name == display_name
        assert user.password == hashed_password
        assert user.is_active is True
        
        # Verify password
        assert verify_password(password, user.password) is True
    
    def test_user_login_flow(self):
        """Test user login flow."""
        # Simulate existing user
        email = "existing@example.com"
        password = "existingpassword123"
        hashed_password = get_password_hash(password)
        
        user = User(
            email=email,
            password=hashed_password,
            display_name="Existing User"
        )
        
        # Simulate login attempt
        login_password = "existingpassword123"
        is_valid = verify_password(login_password, user.password)
        
        assert is_valid is True
        
        # Create access token for valid user
        token = create_access_token({"sub": str(user.id)})
        
        # Verify token
        decoded = decode_token(token)
        assert decoded is not None
        assert decoded["sub"] == str(user.id)


class TestSecurityFeatures:
    """Test security features."""
    
    def test_password_strength(self):
        """Test password hashing with different password strengths."""
        passwords = [
            "simple",
            "password123",
            "VeryStrongPassword123!@#",
            "a" * 100  # Very long password
        ]
        
        for password in passwords:
            hashed = get_password_hash(password)
            assert verify_password(password, hashed) is True
            assert verify_password(password + "x", hashed) is False
    
    def test_token_security(self):
        """Test token security features."""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        
        # Create token
        token = create_access_token({"sub": user_id})
        
        # Add longer delay to ensure different timestamps
        import time
        time.sleep(1)  # 1 second delay
        
        # Token should be different each time (due to timestamp)
        token2 = create_access_token({"sub": user_id})
        assert token != token2
        
        # Both tokens should be valid
        decoded1 = decode_token(token)
        decoded2 = decode_token(token2)
        
        assert decoded1 is not None
        assert decoded2 is not None
        assert decoded1["sub"] == decoded2["sub"] == user_id
    
    def test_user_role_security(self):
        """Test user role-based security."""
        # Regular user
        user = User(
            email="user@example.com",
            password="hashed_password",
            role="user"
        )
        
        assert user.role == "user"
        
        # Admin user
        admin = User(
            email="admin@example.com",
            password="hashed_password",
            role="admin"
        )
        
        assert admin.role == "admin"
        
        # Create tokens for both
        user_token = create_access_token({"sub": str(user.id), "role": user.role})
        admin_token = create_access_token({"sub": str(admin.id), "role": admin.role})
        
        # Verify tokens
        user_decoded = decode_token(user_token)
        admin_decoded = decode_token(admin_token)
        
        assert user_decoded["role"] == "user"
        assert admin_decoded["role"] == "admin"