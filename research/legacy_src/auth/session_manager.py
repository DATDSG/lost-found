"""
Enhanced Session Management System
Implements secure session handling with Redis-based storage, device tracking, and security features
"""

import json
import uuid
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
from fastapi import HTTPException, status, Request
from sqlalchemy.orm import Session
import redis
import jwt
import hashlib
import logging
from user_agents import parse

from ..core.config import settings
from ..models.user import User
from ..database import get_db

logger = logging.getLogger(__name__)

@dataclass
class SessionData:
    """Session data structure"""
    user_id: int
    email: str
    role: str
    device_id: str
    device_info: Dict[str, Any]
    ip_address: str
    created_at: datetime
    last_activity: datetime
    expires_at: datetime
    is_2fa_verified: bool = False
    trusted_device: bool = False
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization"""
        data = asdict(self)
        # Convert datetime objects to ISO strings
        data['created_at'] = self.created_at.isoformat()
        data['last_activity'] = self.last_activity.isoformat()
        data['expires_at'] = self.expires_at.isoformat()
        return data
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'SessionData':
        """Create from dictionary"""
        # Convert ISO strings back to datetime objects
        data['created_at'] = datetime.fromisoformat(data['created_at'])
        data['last_activity'] = datetime.fromisoformat(data['last_activity'])
        data['expires_at'] = datetime.fromisoformat(data['expires_at'])
        return cls(**data)

@dataclass
class DeviceInfo:
    """Device information structure"""
    device_type: str  # mobile, desktop, tablet
    browser: str
    os: str
    ip_address: str
    user_agent: str
    fingerprint: str
    
    @classmethod
    def from_request(cls, request: Request) -> 'DeviceInfo':
        """Extract device info from request"""
        user_agent = request.headers.get('user-agent', '')
        parsed_ua = parse(user_agent)
        
        # Get client IP (considering proxies)
        ip_address = (
            request.headers.get('x-forwarded-for', '').split(',')[0].strip() or
            request.headers.get('x-real-ip', '') or
            request.client.host if request.client else 'unknown'
        )
        
        # Generate device fingerprint
        fingerprint_data = f"{parsed_ua.browser.family}{parsed_ua.os.family}{ip_address}"
        fingerprint = hashlib.sha256(fingerprint_data.encode()).hexdigest()[:16]
        
        return cls(
            device_type=cls._get_device_type(parsed_ua),
            browser=f"{parsed_ua.browser.family} {parsed_ua.browser.version_string}",
            os=f"{parsed_ua.os.family} {parsed_ua.os.version_string}",
            ip_address=ip_address,
            user_agent=user_agent,
            fingerprint=fingerprint
        )
    
    @staticmethod
    def _get_device_type(parsed_ua) -> str:
        """Determine device type from user agent"""
        if parsed_ua.is_mobile:
            return 'mobile'
        elif parsed_ua.is_tablet:
            return 'tablet'
        else:
            return 'desktop'

class SessionManager:
    """Enhanced session management with Redis backend"""
    
    def __init__(self):
        self.redis_client = redis.Redis(
            host=settings.REDIS_HOST,
            port=settings.REDIS_PORT,
            password=settings.REDIS_PASSWORD,
            db=settings.REDIS_SESSION_DB,
            decode_responses=True
        )
        self.session_prefix = "session:"
        self.user_sessions_prefix = "user_sessions:"
        self.device_sessions_prefix = "device_sessions:"
        
    def create_session(
        self, 
        user: User, 
        request: Request,
        remember_me: bool = False,
        is_2fa_verified: bool = False
    ) -> str:
        """Create new session for user"""
        # Generate session ID
        session_id = str(uuid.uuid4())
        
        # Extract device information
        device_info = DeviceInfo.from_request(request)
        device_id = self._get_or_create_device_id(user.id, device_info)
        
        # Check for concurrent session limits
        self._enforce_session_limits(user.id)
        
        # Calculate expiry
        if remember_me:
            expires_in = timedelta(days=settings.SESSION_REMEMBER_DAYS)
        else:
            expires_in = timedelta(hours=settings.SESSION_EXPIRE_HOURS)
        
        now = datetime.utcnow()
        expires_at = now + expires_in
        
        # Create session data
        session_data = SessionData(
            user_id=user.id,
            email=user.email,
            role=user.role.value,
            device_id=device_id,
            device_info=asdict(device_info),
            ip_address=device_info.ip_address,
            created_at=now,
            last_activity=now,
            expires_at=expires_at,
            is_2fa_verified=is_2fa_verified,
            trusted_device=self._is_trusted_device(user.id, device_info)
        )
        
        # Store session in Redis
        session_key = f"{self.session_prefix}{session_id}"
        self.redis_client.setex(
            session_key,
            int(expires_in.total_seconds()),
            json.dumps(session_data.to_dict())
        )
        
        # Add to user's active sessions
        self._add_to_user_sessions(user.id, session_id, expires_at)
        
        # Add to device sessions
        self._add_to_device_sessions(device_id, session_id)
        
        # Log session creation
        logger.info(
            f"Session created for user {user.id} from {device_info.ip_address} "
            f"({device_info.device_type}, {device_info.browser})"
        )
        
        return session_id
    
    def get_session(self, session_id: str) -> Optional[SessionData]:
        """Get session data by ID"""
        session_key = f"{self.session_prefix}{session_id}"
        session_json = self.redis_client.get(session_key)
        
        if not session_json:
            return None
        
        try:
            session_dict = json.loads(session_json)
            return SessionData.from_dict(session_dict)
        except (json.JSONDecodeError, KeyError, ValueError) as e:
            logger.error(f"Failed to parse session data: {e}")
            return None
    
    def update_session_activity(self, session_id: str) -> bool:
        """Update last activity timestamp for session"""
        session_data = self.get_session(session_id)
        if not session_data:
            return False
        
        # Update last activity
        session_data.last_activity = datetime.utcnow()
        
        # Extend session if needed
        time_until_expiry = session_data.expires_at - datetime.utcnow()
        if time_until_expiry.total_seconds() > 0:
            session_key = f"{self.session_prefix}{session_id}"
            self.redis_client.setex(
                session_key,
                int(time_until_expiry.total_seconds()),
                json.dumps(session_data.to_dict())
            )
            return True
        
        return False
    
    def invalidate_session(self, session_id: str) -> bool:
        """Invalidate a specific session"""
        session_data = self.get_session(session_id)
        if not session_data:
            return False
        
        # Remove from Redis
        session_key = f"{self.session_prefix}{session_id}"
        self.redis_client.delete(session_key)
        
        # Remove from user sessions
        self._remove_from_user_sessions(session_data.user_id, session_id)
        
        # Remove from device sessions
        self._remove_from_device_sessions(session_data.device_id, session_id)
        
        logger.info(f"Session {session_id} invalidated for user {session_data.user_id}")
        return True
    
    def invalidate_all_user_sessions(self, user_id: int, except_session: Optional[str] = None) -> int:
        """Invalidate all sessions for a user"""
        user_sessions = self._get_user_sessions(user_id)
        invalidated_count = 0
        
        for session_id in user_sessions:
            if session_id != except_session:
                if self.invalidate_session(session_id):
                    invalidated_count += 1
        
        logger.info(f"Invalidated {invalidated_count} sessions for user {user_id}")
        return invalidated_count
    
    def invalidate_device_sessions(self, device_id: str, except_session: Optional[str] = None) -> int:
        """Invalidate all sessions for a device"""
        device_sessions = self._get_device_sessions(device_id)
        invalidated_count = 0
        
        for session_id in device_sessions:
            if session_id != except_session:
                if self.invalidate_session(session_id):
                    invalidated_count += 1
        
        return invalidated_count
    
    def get_user_sessions(self, user_id: int) -> List[Dict[str, Any]]:
        """Get all active sessions for a user"""
        session_ids = self._get_user_sessions(user_id)
        sessions = []
        
        for session_id in session_ids:
            session_data = self.get_session(session_id)
            if session_data:
                sessions.append({
                    'session_id': session_id,
                    'device_type': session_data.device_info.get('device_type'),
                    'browser': session_data.device_info.get('browser'),
                    'os': session_data.device_info.get('os'),
                    'ip_address': session_data.ip_address,
                    'created_at': session_data.created_at,
                    'last_activity': session_data.last_activity,
                    'is_current': False  # Will be set by caller
                })
        
        return sessions
    
    def cleanup_expired_sessions(self) -> int:
        """Clean up expired sessions (called by background task)"""
        # Redis automatically expires keys, but we need to clean up references
        cleaned_count = 0
        
        # Get all user session keys
        user_session_keys = self.redis_client.keys(f"{self.user_sessions_prefix}*")
        
        for key in user_session_keys:
            user_id = key.split(':')[-1]
            session_ids = self._get_user_sessions(int(user_id))
            
            # Check each session
            for session_id in session_ids[:]:  # Copy list to modify during iteration
                if not self.get_session(session_id):
                    # Session expired, remove from references
                    self._remove_from_user_sessions(int(user_id), session_id)
                    cleaned_count += 1
        
        if cleaned_count > 0:
            logger.info(f"Cleaned up {cleaned_count} expired session references")
        
        return cleaned_count
    
    def detect_suspicious_activity(self, session_id: str, request: Request) -> List[str]:
        """Detect suspicious session activity"""
        session_data = self.get_session(session_id)
        if not session_data:
            return ['Invalid session']
        
        warnings = []
        current_device_info = DeviceInfo.from_request(request)
        
        # Check IP address change
        if session_data.ip_address != current_device_info.ip_address:
            warnings.append('IP address changed')
        
        # Check user agent change
        if session_data.device_info.get('user_agent') != current_device_info.user_agent:
            warnings.append('User agent changed')
        
        # Check for session hijacking indicators
        if (session_data.device_info.get('fingerprint') != 
            current_device_info.fingerprint):
            warnings.append('Device fingerprint mismatch')
        
        # Check for unusual activity patterns
        time_since_last_activity = datetime.utcnow() - session_data.last_activity
        if time_since_last_activity > timedelta(hours=24):
            warnings.append('Long period of inactivity')
        
        return warnings
    
    def _get_or_create_device_id(self, user_id: int, device_info: DeviceInfo) -> str:
        """Get or create device ID for user and device combination"""
        # Use fingerprint as device identifier
        device_id = f"{user_id}:{device_info.fingerprint}"
        
        # Store device info if new
        device_key = f"device_info:{device_id}"
        if not self.redis_client.exists(device_key):
            self.redis_client.setex(
                device_key,
                60 * 60 * 24 * 90,  # 90 days
                json.dumps(asdict(device_info))
            )
        
        return device_id
    
    def _enforce_session_limits(self, user_id: int):
        """Enforce maximum concurrent sessions per user"""
        user_sessions = self._get_user_sessions(user_id)
        
        if len(user_sessions) >= settings.MAX_CONCURRENT_SESSIONS:
            # Remove oldest sessions
            sessions_to_remove = len(user_sessions) - settings.MAX_CONCURRENT_SESSIONS + 1
            
            # Get session data to find oldest
            session_data_list = []
            for session_id in user_sessions:
                session_data = self.get_session(session_id)
                if session_data:
                    session_data_list.append((session_id, session_data.created_at))
            
            # Sort by creation time and remove oldest
            session_data_list.sort(key=lambda x: x[1])
            for i in range(sessions_to_remove):
                self.invalidate_session(session_data_list[i][0])
    
    def _is_trusted_device(self, user_id: int, device_info: DeviceInfo) -> bool:
        """Check if device is trusted for the user"""
        # Simple implementation - could be enhanced with ML-based detection
        device_key = f"trusted_device:{user_id}:{device_info.fingerprint}"
        return self.redis_client.exists(device_key)
    
    def _add_to_user_sessions(self, user_id: int, session_id: str, expires_at: datetime):
        """Add session to user's active sessions list"""
        key = f"{self.user_sessions_prefix}{user_id}"
        self.redis_client.sadd(key, session_id)
        
        # Set expiry for the set itself
        ttl = int((expires_at - datetime.utcnow()).total_seconds())
        if ttl > 0:
            self.redis_client.expire(key, ttl)
    
    def _remove_from_user_sessions(self, user_id: int, session_id: str):
        """Remove session from user's active sessions list"""
        key = f"{self.user_sessions_prefix}{user_id}"
        self.redis_client.srem(key, session_id)
    
    def _get_user_sessions(self, user_id: int) -> List[str]:
        """Get all session IDs for a user"""
        key = f"{self.user_sessions_prefix}{user_id}"
        return list(self.redis_client.smembers(key))
    
    def _add_to_device_sessions(self, device_id: str, session_id: str):
        """Add session to device's active sessions list"""
        key = f"{self.device_sessions_prefix}{device_id}"
        self.redis_client.sadd(key, session_id)
        self.redis_client.expire(key, 60 * 60 * 24 * 30)  # 30 days
    
    def _remove_from_device_sessions(self, device_id: str, session_id: str):
        """Remove session from device's active sessions list"""
        key = f"{self.device_sessions_prefix}{device_id}"
        self.redis_client.srem(key, session_id)
    
    def _get_device_sessions(self, device_id: str) -> List[str]:
        """Get all session IDs for a device"""
        key = f"{self.device_sessions_prefix}{device_id}"
        return list(self.redis_client.smembers(key))

class SessionSecurity:
    """Additional security features for sessions"""
    
    def __init__(self, session_manager: SessionManager):
        self.session_manager = session_manager
        self.redis_client = session_manager.redis_client
    
    def log_security_event(
        self, 
        user_id: int, 
        event_type: str, 
        details: Dict[str, Any],
        session_id: Optional[str] = None
    ):
        """Log security events"""
        event = {
            'user_id': user_id,
            'session_id': session_id,
            'event_type': event_type,
            'details': details,
            'timestamp': datetime.utcnow().isoformat(),
            'ip_address': details.get('ip_address')
        }
        
        # Store in Redis with expiry
        event_key = f"security_event:{user_id}:{datetime.utcnow().timestamp()}"
        self.redis_client.setex(
            event_key,
            60 * 60 * 24 * 30,  # 30 days
            json.dumps(event)
        )
        
        logger.warning(f"Security event: {event_type} for user {user_id}")
    
    def check_brute_force_protection(self, ip_address: str, user_id: Optional[int] = None) -> bool:
        """Check if IP or user is rate limited due to failed attempts"""
        # Check IP-based rate limiting
        ip_key = f"failed_attempts:ip:{ip_address}"
        ip_attempts = self.redis_client.get(ip_key) or 0
        
        if int(ip_attempts) >= settings.MAX_LOGIN_ATTEMPTS_PER_IP:
            return False
        
        # Check user-based rate limiting if user_id provided
        if user_id:
            user_key = f"failed_attempts:user:{user_id}"
            user_attempts = self.redis_client.get(user_key) or 0
            
            if int(user_attempts) >= settings.MAX_LOGIN_ATTEMPTS_PER_USER:
                return False
        
        return True
    
    def record_failed_attempt(self, ip_address: str, user_id: Optional[int] = None):
        """Record failed login attempt"""
        # Record IP-based attempt
        ip_key = f"failed_attempts:ip:{ip_address}"
        self.redis_client.incr(ip_key)
        self.redis_client.expire(ip_key, settings.LOGIN_ATTEMPT_WINDOW_MINUTES * 60)
        
        # Record user-based attempt if user_id provided
        if user_id:
            user_key = f"failed_attempts:user:{user_id}"
            self.redis_client.incr(user_key)
            self.redis_client.expire(user_key, settings.LOGIN_ATTEMPT_WINDOW_MINUTES * 60)
    
    def clear_failed_attempts(self, ip_address: str, user_id: Optional[int] = None):
        """Clear failed login attempts after successful login"""
        ip_key = f"failed_attempts:ip:{ip_address}"
        self.redis_client.delete(ip_key)
        
        if user_id:
            user_key = f"failed_attempts:user:{user_id}"
            self.redis_client.delete(user_key)

# Global session manager instance
session_manager = SessionManager()
session_security = SessionSecurity(session_manager)
