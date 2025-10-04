"""
OAuth2 Social Login Providers
Implements Google, Facebook, and other social authentication options
"""

import os
import json
import httpx
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from fastapi import HTTPException, status
from pydantic import BaseModel, Field
import jwt
from passlib.context import CryptContext

from ..core.config import settings
from ..models.user import User, UserRole
from ..database import get_db

class OAuthProvider(BaseModel):
    """Base OAuth provider configuration"""
    name: str
    client_id: str
    client_secret: str
    redirect_uri: str
    scope: str
    auth_url: str
    token_url: str
    user_info_url: str

class OAuthUserInfo(BaseModel):
    """Standardized user info from OAuth providers"""
    provider: str
    provider_id: str
    email: str
    full_name: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    avatar_url: Optional[str] = None
    verified_email: bool = False

class GoogleOAuthProvider:
    """Google OAuth2 implementation"""
    
    def __init__(self):
        self.client_id = settings.GOOGLE_CLIENT_ID
        self.client_secret = settings.GOOGLE_CLIENT_SECRET
        self.redirect_uri = settings.GOOGLE_REDIRECT_URI
        self.scope = "openid email profile"
        self.auth_url = "https://accounts.google.com/o/oauth2/v2/auth"
        self.token_url = "https://oauth2.googleapis.com/token"
        self.user_info_url = "https://www.googleapis.com/oauth2/v2/userinfo"
    
    def get_auth_url(self, state: str) -> str:
        """Generate Google OAuth authorization URL"""
        params = {
            "client_id": self.client_id,
            "redirect_uri": self.redirect_uri,
            "scope": self.scope,
            "response_type": "code",
            "state": state,
            "access_type": "offline",
            "prompt": "consent"
        }
        
        query_string = "&".join([f"{k}={v}" for k, v in params.items()])
        return f"{self.auth_url}?{query_string}"
    
    async def exchange_code_for_token(self, code: str) -> Dict[str, Any]:
        """Exchange authorization code for access token"""
        data = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": self.redirect_uri
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(self.token_url, data=data)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Failed to exchange code for token"
                )
            
            return response.json()
    
    async def get_user_info(self, access_token: str) -> OAuthUserInfo:
        """Get user information from Google"""
        headers = {"Authorization": f"Bearer {access_token}"}
        
        async with httpx.AsyncClient() as client:
            response = await client.get(self.user_info_url, headers=headers)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Failed to get user info from Google"
                )
            
            user_data = response.json()
            
            return OAuthUserInfo(
                provider="google",
                provider_id=user_data["id"],
                email=user_data["email"],
                full_name=user_data["name"],
                first_name=user_data.get("given_name"),
                last_name=user_data.get("family_name"),
                avatar_url=user_data.get("picture"),
                verified_email=user_data.get("verified_email", False)
            )

class FacebookOAuthProvider:
    """Facebook OAuth2 implementation"""
    
    def __init__(self):
        self.client_id = settings.FACEBOOK_CLIENT_ID
        self.client_secret = settings.FACEBOOK_CLIENT_SECRET
        self.redirect_uri = settings.FACEBOOK_REDIRECT_URI
        self.scope = "email,public_profile"
        self.auth_url = "https://www.facebook.com/v18.0/dialog/oauth"
        self.token_url = "https://graph.facebook.com/v18.0/oauth/access_token"
        self.user_info_url = "https://graph.facebook.com/v18.0/me"
    
    def get_auth_url(self, state: str) -> str:
        """Generate Facebook OAuth authorization URL"""
        params = {
            "client_id": self.client_id,
            "redirect_uri": self.redirect_uri,
            "scope": self.scope,
            "response_type": "code",
            "state": state
        }
        
        query_string = "&".join([f"{k}={v}" for k, v in params.items()])
        return f"{self.auth_url}?{query_string}"
    
    async def exchange_code_for_token(self, code: str) -> Dict[str, Any]:
        """Exchange authorization code for access token"""
        params = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "code": code,
            "redirect_uri": self.redirect_uri
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(self.token_url, params=params)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Failed to exchange code for token"
                )
            
            return response.json()
    
    async def get_user_info(self, access_token: str) -> OAuthUserInfo:
        """Get user information from Facebook"""
        params = {
            "access_token": access_token,
            "fields": "id,name,email,first_name,last_name,picture"
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(self.user_info_url, params=params)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Failed to get user info from Facebook"
                )
            
            user_data = response.json()
            
            return OAuthUserInfo(
                provider="facebook",
                provider_id=user_data["id"],
                email=user_data.get("email", ""),
                full_name=user_data["name"],
                first_name=user_data.get("first_name"),
                last_name=user_data.get("last_name"),
                avatar_url=user_data.get("picture", {}).get("data", {}).get("url"),
                verified_email=True  # Facebook emails are generally verified
            )

class OAuthService:
    """OAuth service for managing social logins"""
    
    def __init__(self):
        self.providers = {
            "google": GoogleOAuthProvider(),
            "facebook": FacebookOAuthProvider()
        }
        self.pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    
    def get_provider(self, provider_name: str) -> Optional[Any]:
        """Get OAuth provider by name"""
        return self.providers.get(provider_name)
    
    async def authenticate_with_oauth(
        self, 
        provider_name: str, 
        code: str,
        db_session
    ) -> Dict[str, Any]:
        """Authenticate user with OAuth provider"""
        provider = self.get_provider(provider_name)
        if not provider:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported OAuth provider: {provider_name}"
            )
        
        # Exchange code for token
        token_data = await provider.exchange_code_for_token(code)
        access_token = token_data["access_token"]
        
        # Get user info
        oauth_user = await provider.get_user_info(access_token)
        
        # Find or create user
        user = await self._find_or_create_oauth_user(oauth_user, db_session)
        
        # Generate JWT token
        jwt_token = self._generate_jwt_token(user)
        
        return {
            "access_token": jwt_token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "email": user.email,
                "full_name": user.full_name,
                "role": user.role.value,
                "avatar_url": user.avatar_url,
                "oauth_provider": oauth_user.provider
            }
        }
    
    async def _find_or_create_oauth_user(
        self, 
        oauth_user: OAuthUserInfo, 
        db_session
    ) -> User:
        """Find existing user or create new one from OAuth data"""
        # Try to find user by OAuth provider ID
        user = db_session.query(User).filter(
            User.oauth_provider == oauth_user.provider,
            User.oauth_provider_id == oauth_user.provider_id
        ).first()
        
        if user:
            # Update user info if needed
            user.full_name = oauth_user.full_name
            user.avatar_url = oauth_user.avatar_url
            user.last_login = datetime.utcnow()
            db_session.commit()
            return user
        
        # Try to find user by email
        user = db_session.query(User).filter(User.email == oauth_user.email).first()
        
        if user:
            # Link OAuth account to existing user
            user.oauth_provider = oauth_user.provider
            user.oauth_provider_id = oauth_user.provider_id
            user.avatar_url = oauth_user.avatar_url
            user.last_login = datetime.utcnow()
            db_session.commit()
            return user
        
        # Create new user
        user = User(
            email=oauth_user.email,
            full_name=oauth_user.full_name,
            phone="",  # Will be updated later if needed
            password_hash="",  # OAuth users don't have passwords
            role=UserRole.USER,
            is_active=True,
            email_verified=oauth_user.verified_email,
            oauth_provider=oauth_user.provider,
            oauth_provider_id=oauth_user.provider_id,
            avatar_url=oauth_user.avatar_url,
            created_at=datetime.utcnow(),
            last_login=datetime.utcnow()
        )
        
        db_session.add(user)
        db_session.commit()
        db_session.refresh(user)
        
        return user
    
    def _generate_jwt_token(self, user: User) -> str:
        """Generate JWT token for user"""
        payload = {
            "sub": str(user.id),
            "email": user.email,
            "role": user.role.value,
            "iat": datetime.utcnow(),
            "exp": datetime.utcnow() + timedelta(days=settings.JWT_EXPIRY_DAYS)
        }
        
        return jwt.encode(
            payload, 
            settings.JWT_SECRET, 
            algorithm=settings.JWT_ALGORITHM
        )

# Global OAuth service instance
oauth_service = OAuthService()
