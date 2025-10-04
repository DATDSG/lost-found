"""
Configuration for Backend Enhancements
Centralized configuration for all backend enhancement features
"""

from pydantic import BaseSettings, Field
from typing import Dict, List, Optional
import os

class AuthenticationConfig(BaseSettings):
    """OAuth2 and 2FA configuration"""
    
    # OAuth2 Settings
    GOOGLE_CLIENT_ID: str = Field(..., env="GOOGLE_CLIENT_ID")
    GOOGLE_CLIENT_SECRET: str = Field(..., env="GOOGLE_CLIENT_SECRET")
    FACEBOOK_APP_ID: str = Field(..., env="FACEBOOK_APP_ID")
    FACEBOOK_APP_SECRET: str = Field(..., env="FACEBOOK_APP_SECRET")
    
    # OAuth2 URLs
    OAUTH_REDIRECT_URI: str = Field(default="http://localhost:8000/auth/callback", env="OAUTH_REDIRECT_URI")
    
    # 2FA Settings
    TOTP_ISSUER: str = Field(default="Lost & Found System", env="TOTP_ISSUER")
    TOTP_ALGORITHM: str = Field(default="SHA1", env="TOTP_ALGORITHM")
    TOTP_DIGITS: int = Field(default=6, env="TOTP_DIGITS")
    TOTP_PERIOD: int = Field(default=30, env="TOTP_PERIOD")
    
    # SMS Settings (Twilio)
    TWILIO_ACCOUNT_SID: Optional[str] = Field(default=None, env="TWILIO_ACCOUNT_SID")
    TWILIO_AUTH_TOKEN: Optional[str] = Field(default=None, env="TWILIO_AUTH_TOKEN")
    TWILIO_PHONE_NUMBER: Optional[str] = Field(default=None, env="TWILIO_PHONE_NUMBER")
    
    # AWS SNS Settings
    AWS_ACCESS_KEY_ID: Optional[str] = Field(default=None, env="AWS_ACCESS_KEY_ID")
    AWS_SECRET_ACCESS_KEY: Optional[str] = Field(default=None, env="AWS_SECRET_ACCESS_KEY")
    AWS_REGION: Optional[str] = Field(default="us-east-1", env="AWS_REGION")
    
    # Email Settings
    SMTP_HOST: Optional[str] = Field(default=None, env="SMTP_HOST")
    SMTP_PORT: int = Field(default=587, env="SMTP_PORT")
    SMTP_USERNAME: Optional[str] = Field(default=None, env="SMTP_USERNAME")
    SMTP_PASSWORD: Optional[str] = Field(default=None, env="SMTP_PASSWORD")
    SMTP_USE_TLS: bool = Field(default=True, env="SMTP_USE_TLS")
    
    class Config:
        env_file = ".env"

class RBACConfig(BaseSettings):
    """Role-Based Access Control configuration"""
    
    # Default role assignments
    DEFAULT_USER_ROLE: str = Field(default="user", env="DEFAULT_USER_ROLE")
    ADMIN_EMAIL_DOMAINS: List[str] = Field(default=[], env="ADMIN_EMAIL_DOMAINS")
    
    # Permission settings
    ENABLE_RESOURCE_OWNERSHIP_CHECK: bool = Field(default=True, env="ENABLE_RESOURCE_OWNERSHIP_CHECK")
    SUPERUSER_BYPASS_PERMISSIONS: bool = Field(default=True, env="SUPERUSER_BYPASS_PERMISSIONS")
    
    # Session settings
    ROLE_CACHE_TTL: int = Field(default=300, env="ROLE_CACHE_TTL")  # 5 minutes
    
    class Config:
        env_file = ".env"

class SessionConfig(BaseSettings):
    """Session management configuration"""
    
    # Redis settings
    REDIS_HOST: str = Field(default="localhost", env="REDIS_HOST")
    REDIS_PORT: int = Field(default=6379, env="REDIS_PORT")
    REDIS_PASSWORD: Optional[str] = Field(default=None, env="REDIS_PASSWORD")
    REDIS_SESSION_DB: int = Field(default=0, env="REDIS_SESSION_DB")
    REDIS_CACHE_DB: int = Field(default=1, env="REDIS_CACHE_DB")
    
    # Session settings
    SESSION_TTL: int = Field(default=86400, env="SESSION_TTL")  # 24 hours
    MAX_CONCURRENT_SESSIONS: int = Field(default=5, env="MAX_CONCURRENT_SESSIONS")
    SESSION_REFRESH_THRESHOLD: int = Field(default=3600, env="SESSION_REFRESH_THRESHOLD")  # 1 hour
    
    # Security settings
    ENABLE_DEVICE_TRACKING: bool = Field(default=True, env="ENABLE_DEVICE_TRACKING")
    ENABLE_SUSPICIOUS_ACTIVITY_DETECTION: bool = Field(default=True, env="ENABLE_SUSPICIOUS_ACTIVITY_DETECTION")
    MAX_LOGIN_ATTEMPTS: int = Field(default=5, env="MAX_LOGIN_ATTEMPTS")
    LOGIN_ATTEMPT_WINDOW: int = Field(default=900, env="LOGIN_ATTEMPT_WINDOW")  # 15 minutes
    LOCKOUT_DURATION: int = Field(default=1800, env="LOCKOUT_DURATION")  # 30 minutes
    
    class Config:
        env_file = ".env"

class DataRetentionConfig(BaseSettings):
    """Data retention and GDPR compliance configuration"""
    
    # Retention periods (in days)
    ITEM_RETENTION_DAYS: int = Field(default=365, env="ITEM_RETENTION_DAYS")
    USER_INACTIVE_RETENTION_DAYS: int = Field(default=1095, env="USER_INACTIVE_RETENTION_DAYS")  # 3 years
    LOG_RETENTION_DAYS: int = Field(default=90, env="LOG_RETENTION_DAYS")
    AUDIT_LOG_RETENTION_DAYS: int = Field(default=2555, env="AUDIT_LOG_RETENTION_DAYS")  # 7 years
    
    # Soft delete settings
    SOFT_DELETE_PERMANENT_CLEANUP_DAYS: int = Field(default=90, env="SOFT_DELETE_PERMANENT_CLEANUP_DAYS")
    
    # GDPR settings
    GDPR_DATA_EXPORT_FORMAT: str = Field(default="json", env="GDPR_DATA_EXPORT_FORMAT")
    GDPR_ANONYMIZATION_ENABLED: bool = Field(default=True, env="GDPR_ANONYMIZATION_ENABLED")
    
    # Cleanup schedule
    RETENTION_CLEANUP_HOUR: int = Field(default=2, env="RETENTION_CLEANUP_HOUR")  # 2 AM
    RETENTION_CLEANUP_ENABLED: bool = Field(default=True, env="RETENTION_CLEANUP_ENABLED")
    
    class Config:
        env_file = ".env"

class BackupConfig(BaseSettings):
    """Backup and recovery configuration"""
    
    # Database backup settings
    DB_BACKUP_ENABLED: bool = Field(default=True, env="DB_BACKUP_ENABLED")
    DB_BACKUP_SCHEDULE: str = Field(default="0 1 * * *", env="DB_BACKUP_SCHEDULE")  # Daily at 1 AM
    DB_BACKUP_RETENTION_DAYS: int = Field(default=30, env="DB_BACKUP_RETENTION_DAYS")
    
    # Incremental backup settings
    INCREMENTAL_BACKUP_ENABLED: bool = Field(default=True, env="INCREMENTAL_BACKUP_ENABLED")
    INCREMENTAL_BACKUP_INTERVAL_HOURS: int = Field(default=6, env="INCREMENTAL_BACKUP_INTERVAL_HOURS")
    
    # S3 settings for backup storage
    BACKUP_S3_BUCKET: Optional[str] = Field(default=None, env="BACKUP_S3_BUCKET")
    BACKUP_S3_PREFIX: str = Field(default="backups/", env="BACKUP_S3_PREFIX")
    BACKUP_S3_REGION: str = Field(default="us-east-1", env="BACKUP_S3_REGION")
    
    # Local backup settings
    LOCAL_BACKUP_PATH: str = Field(default="/var/backups/lost-found", env="LOCAL_BACKUP_PATH")
    LOCAL_BACKUP_RETENTION_COUNT: int = Field(default=7, env="LOCAL_BACKUP_RETENTION_COUNT")
    
    # Media backup settings
    MEDIA_BACKUP_ENABLED: bool = Field(default=True, env="MEDIA_BACKUP_ENABLED")
    MEDIA_BACKUP_SCHEDULE: str = Field(default="0 3 * * 0", env="MEDIA_BACKUP_SCHEDULE")  # Weekly on Sunday at 3 AM
    
    class Config:
        env_file = ".env"

class PerformanceConfig(BaseSettings):
    """Performance optimization configuration"""
    
    # Caching settings
    CACHE_DEFAULT_TTL: int = Field(default=300, env="CACHE_DEFAULT_TTL")  # 5 minutes
    CACHE_ENABLED: bool = Field(default=True, env="CACHE_ENABLED")
    
    # Query optimization
    ENABLE_QUERY_CACHING: bool = Field(default=True, env="ENABLE_QUERY_CACHING")
    SLOW_QUERY_THRESHOLD_MS: int = Field(default=1000, env="SLOW_QUERY_THRESHOLD_MS")
    
    # Pagination settings
    DEFAULT_PAGE_SIZE: int = Field(default=20, env="DEFAULT_PAGE_SIZE")
    MAX_PAGE_SIZE: int = Field(default=100, env="MAX_PAGE_SIZE")
    
    # Geospatial query settings
    DEFAULT_SEARCH_RADIUS_KM: float = Field(default=5.0, env="DEFAULT_SEARCH_RADIUS_KM")
    MAX_SEARCH_RADIUS_KM: float = Field(default=50.0, env="MAX_SEARCH_RADIUS_KM")
    
    # Index management
    AUTO_CREATE_INDEXES: bool = Field(default=True, env="AUTO_CREATE_INDEXES")
    INDEX_CREATION_TIMEOUT_SECONDS: int = Field(default=300, env="INDEX_CREATION_TIMEOUT_SECONDS")
    
    # Performance monitoring
    ENABLE_PERFORMANCE_MONITORING: bool = Field(default=True, env="ENABLE_PERFORMANCE_MONITORING")
    PERFORMANCE_METRICS_RETENTION_DAYS: int = Field(default=30, env="PERFORMANCE_METRICS_RETENTION_DAYS")
    
    class Config:
        env_file = ".env"

class SecurityConfig(BaseSettings):
    """Security configuration"""
    
    # Rate limiting
    RATE_LIMIT_ENABLED: bool = Field(default=True, env="RATE_LIMIT_ENABLED")
    RATE_LIMIT_REQUESTS_PER_MINUTE: int = Field(default=60, env="RATE_LIMIT_REQUESTS_PER_MINUTE")
    
    # IP whitelisting/blacklisting
    IP_WHITELIST: List[str] = Field(default=[], env="IP_WHITELIST")
    IP_BLACKLIST: List[str] = Field(default=[], env="IP_BLACKLIST")
    
    # Security headers
    ENABLE_SECURITY_HEADERS: bool = Field(default=True, env="ENABLE_SECURITY_HEADERS")
    
    # Audit logging
    ENABLE_AUDIT_LOGGING: bool = Field(default=True, env="ENABLE_AUDIT_LOGGING")
    AUDIT_LOG_SENSITIVE_OPERATIONS: bool = Field(default=True, env="AUDIT_LOG_SENSITIVE_OPERATIONS")
    
    class Config:
        env_file = ".env"

class BackendEnhancementsConfig:
    """Main configuration class that combines all enhancement configs"""
    
    def __init__(self):
        self.auth = AuthenticationConfig()
        self.rbac = RBACConfig()
        self.session = SessionConfig()
        self.data_retention = DataRetentionConfig()
        self.backup = BackupConfig()
        self.performance = PerformanceConfig()
        self.security = SecurityConfig()
    
    def get_feature_flags(self) -> Dict[str, bool]:
        """Get feature flags for all enhancements"""
        return {
            # Authentication features
            "oauth2_enabled": bool(self.auth.GOOGLE_CLIENT_ID and self.auth.FACEBOOK_APP_ID),
            "2fa_totp_enabled": True,
            "2fa_sms_enabled": bool(self.auth.TWILIO_ACCOUNT_SID or self.auth.AWS_ACCESS_KEY_ID),
            
            # RBAC features
            "rbac_enabled": True,
            "resource_ownership_check": self.rbac.ENABLE_RESOURCE_OWNERSHIP_CHECK,
            
            # Session features
            "enhanced_sessions": True,
            "device_tracking": self.session.ENABLE_DEVICE_TRACKING,
            "suspicious_activity_detection": self.session.ENABLE_SUSPICIOUS_ACTIVITY_DETECTION,
            
            # Data management features
            "soft_delete_enabled": True,
            "data_retention_enabled": self.data_retention.RETENTION_CLEANUP_ENABLED,
            "gdpr_compliance_enabled": True,
            
            # Backup features
            "database_backup_enabled": self.backup.DB_BACKUP_ENABLED,
            "incremental_backup_enabled": self.backup.INCREMENTAL_BACKUP_ENABLED,
            "media_backup_enabled": self.backup.MEDIA_BACKUP_ENABLED,
            
            # Performance features
            "query_caching_enabled": self.performance.ENABLE_QUERY_CACHING,
            "auto_indexing_enabled": self.performance.AUTO_CREATE_INDEXES,
            "performance_monitoring_enabled": self.performance.ENABLE_PERFORMANCE_MONITORING,
            
            # Security features
            "rate_limiting_enabled": self.security.RATE_LIMIT_ENABLED,
            "audit_logging_enabled": self.security.ENABLE_AUDIT_LOGGING,
        }
    
    def validate_configuration(self) -> Dict[str, List[str]]:
        """Validate configuration and return any issues"""
        issues = {
            "errors": [],
            "warnings": []
        }
        
        # Check OAuth2 configuration
        if self.auth.GOOGLE_CLIENT_ID and not self.auth.GOOGLE_CLIENT_SECRET:
            issues["errors"].append("Google OAuth2: CLIENT_SECRET missing")
        
        if self.auth.FACEBOOK_APP_ID and not self.auth.FACEBOOK_APP_SECRET:
            issues["errors"].append("Facebook OAuth2: APP_SECRET missing")
        
        # Check 2FA SMS configuration
        if self.auth.TWILIO_ACCOUNT_SID and not self.auth.TWILIO_AUTH_TOKEN:
            issues["errors"].append("Twilio 2FA: AUTH_TOKEN missing")
        
        # Check backup configuration
        if self.backup.DB_BACKUP_ENABLED and not (self.backup.BACKUP_S3_BUCKET or self.backup.LOCAL_BACKUP_PATH):
            issues["warnings"].append("Database backup enabled but no storage configured")
        
        # Check Redis configuration
        if not self.session.REDIS_HOST:
            issues["errors"].append("Redis configuration missing - required for sessions and caching")
        
        return issues

# Global configuration instance
config = BackendEnhancementsConfig()

# Export individual configs for convenience
auth_config = config.auth
rbac_config = config.rbac
session_config = config.session
data_retention_config = config.data_retention
backup_config = config.backup
performance_config = config.performance
security_config = config.security
