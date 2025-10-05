"""
Sentry integration for error tracking and performance monitoring.

Automatically captures:
- Exceptions and errors
- Performance metrics
- User context
- Request details
"""
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
from sentry_sdk.integrations.redis import RedisIntegration
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)


def init_sentry():
    """Initialize Sentry error tracking."""
    if not settings.SENTRY_ENABLED or not settings.SENTRY_DSN:
        logger.info("Sentry is disabled")
        return

    try:
        sentry_sdk.init(
            dsn=settings.SENTRY_DSN,
            environment=settings.SENTRY_ENVIRONMENT,
            release=settings.SENTRY_RELEASE,
            
            # Performance monitoring
            traces_sample_rate=0.1 if settings.ENV == 'production' else 1.0,
            
            # Integrations
            integrations=[
                FastApiIntegration(),
                SqlalchemyIntegration(),
                RedisIntegration(),
            ],
            
            # Send default PII (Personally Identifiable Information)
            # Set to False in production for privacy
            send_default_pii=settings.ENV != 'production',
            
            # Attach stack traces to messages
            attach_stacktrace=True,
            
            # Maximum breadcrumbs to keep
            max_breadcrumbs=50,
            
            # Before send callback to filter/modify events
            before_send=before_send_filter,
        )
        
        logger.info(f"Sentry initialized successfully for environment: {settings.SENTRY_ENVIRONMENT}")
        
    except Exception as e:
        logger.error(f"Failed to initialize Sentry: {e}")


def before_send_filter(event, hint):
    """
    Filter events before sending to Sentry.
    
    Use this to:
    - Remove sensitive data
    - Filter out certain errors
    - Modify event data
    """
    
    # Don't send health check errors
    if event.get('request', {}).get('url', '').endswith('/health'):
        return None
    
    # Don't send 404 errors
    if event.get('exception', {}).get('values', [{}])[0].get('type') == 'NotFoundError':
        return None
    
    # Remove sensitive headers
    if 'request' in event and 'headers' in event['request']:
        sensitive_headers = ['Authorization', 'Cookie', 'X-API-Key']
        for header in sensitive_headers:
            if header in event['request']['headers']:
                event['request']['headers'][header] = '[Filtered]'
    
    return event


def capture_exception(error: Exception, context: dict = None):
    """
    Manually capture an exception with optional context.
    
    Args:
        error: The exception to capture
        context: Additional context data
    """
    if settings.SENTRY_ENABLED:
        with sentry_sdk.push_scope() as scope:
            if context:
                for key, value in context.items():
                    scope.set_context(key, value)
            
            sentry_sdk.capture_exception(error)


def capture_message(message: str, level: str = "info", context: dict = None):
    """
    Manually capture a message.
    
    Args:
        message: The message to capture
        level: Severity level (debug, info, warning, error, fatal)
        context: Additional context data
    """
    if settings.SENTRY_ENABLED:
        with sentry_sdk.push_scope() as scope:
            if context:
                for key, value in context.items():
                    scope.set_context(key, value)
            
            sentry_sdk.capture_message(message, level=level)


def set_user_context(user_id: int, email: str = None, username: str = None):
    """
    Set user context for Sentry events.
    
    Args:
        user_id: User ID
        email: User email (optional)
        username: Username (optional)
    """
    if settings.SENTRY_ENABLED:
        sentry_sdk.set_user({
            "id": user_id,
            "email": email,
            "username": username
        })


def add_breadcrumb(message: str, category: str = "default", level: str = "info", data: dict = None):
    """
    Add a breadcrumb to help debug issues.
    
    Args:
        message: Breadcrumb message
        category: Category (auth, database, http, etc.)
        level: Severity level
        data: Additional data
    """
    if settings.SENTRY_ENABLED:
        sentry_sdk.add_breadcrumb(
            message=message,
            category=category,
            level=level,
            data=data or {}
        )
