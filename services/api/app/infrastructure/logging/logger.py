"""
Enhanced Logging System for Lost & Found Services
Provides structured logging, error tracking, and performance monitoring
"""

import logging
import logging.config
import json
import sys
import traceback
from datetime import datetime, timezone
from typing import Dict, Any, Optional, Union
from pathlib import Path
import os
from contextvars import ContextVar
import uuid

# Request context for tracking requests across services
request_id_var: ContextVar[Optional[str]] = ContextVar('request_id', default=None)
user_id_var: ContextVar[Optional[str]] = ContextVar('user_id', default=None)

class StructuredFormatter(logging.Formatter):
    """Custom formatter for structured JSON logging"""
    
    def format(self, record: logging.LogRecord) -> str:
        # Create structured log entry
        log_entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
            "thread": record.thread,
            "process": record.process,
        }
        
        # Add request context if available
        request_id = request_id_var.get()
        if request_id:
            log_entry["request_id"] = request_id
        
        user_id = user_id_var.get()
        if user_id:
            log_entry["user_id"] = user_id
        
        # Add exception info if present
        if record.exc_info:
            log_entry["exception"] = {
                "type": record.exc_info[0].__name__ if record.exc_info[0] else None,
                "message": str(record.exc_info[1]) if record.exc_info[1] else None,
                "traceback": traceback.format_exception(*record.exc_info),
            }
        
        # Add extra fields from record
        for key, value in record.__dict__.items():
            if key not in {
                'name', 'msg', 'args', 'levelname', 'levelno', 'pathname',
                'filename', 'module', 'exc_info', 'exc_text', 'stack_info',
                'lineno', 'funcName', 'created', 'msecs', 'relativeCreated',
                'thread', 'threadName', 'processName', 'process', 'getMessage'
            }:
                log_entry[key] = value
        
        return json.dumps(log_entry, default=str)

class RequestContextFilter(logging.Filter):
    """Filter to add request context to log records"""
    
    def filter(self, record: logging.LogRecord) -> bool:
        request_id = request_id_var.get()
        if request_id:
            record.request_id = request_id
        
        user_id = user_id_var.get()
        if user_id:
            record.user_id = user_id
        
        return True

class ServiceLogger:
    """Enhanced logger for Lost & Found services"""
    
    def __init__(self, service_name: str, log_level: str = "INFO"):
        self.service_name = service_name
        self.logger = logging.getLogger(service_name)
        self.logger.setLevel(getattr(logging, log_level.upper()))
        
        # Clear existing handlers
        self.logger.handlers.clear()
        
        # Setup handlers
        self._setup_handlers()
    
    def _setup_handlers(self):
        """Setup logging handlers"""
        
        # Console handler with structured formatting
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(StructuredFormatter())
        console_handler.addFilter(RequestContextFilter())
        self.logger.addHandler(console_handler)
        
        # File handler for application logs
        log_dir = Path("/app/logs")
        log_dir.mkdir(exist_ok=True)
        
        file_handler = logging.FileHandler(log_dir / f"{self.service_name}.log")
        file_handler.setFormatter(StructuredFormatter())
        file_handler.addFilter(RequestContextFilter())
        self.logger.addHandler(file_handler)
        
        # Error file handler for errors only
        error_handler = logging.FileHandler(log_dir / f"{self.service_name}_errors.log")
        error_handler.setLevel(logging.ERROR)
        error_handler.setFormatter(StructuredFormatter())
        error_handler.addFilter(RequestContextFilter())
        self.logger.addHandler(error_handler)
    
    def _log_with_context(self, level: str, message: str, **kwargs):
        """Log message with additional context"""
        extra = {
            "service": self.service_name,
            **kwargs
        }
        getattr(self.logger, level.lower())(message, extra=extra)
    
    def info(self, message: str, **kwargs):
        """Log info message"""
        self._log_with_context("INFO", message, **kwargs)
    
    def warning(self, message: str, **kwargs):
        """Log warning message"""
        self._log_with_context("WARNING", message, **kwargs)
    
    def error(self, message: str, **kwargs):
        """Log error message"""
        self._log_with_context("ERROR", message, **kwargs)
    
    def critical(self, message: str, **kwargs):
        """Log critical message"""
        self._log_with_context("CRITICAL", message, **kwargs)
    
    def debug(self, message: str, **kwargs):
        """Log debug message"""
        self._log_with_context("DEBUG", message, **kwargs)
    
    def exception(self, message: str, **kwargs):
        """Log exception with traceback"""
        self._log_with_context("ERROR", message, **kwargs)
        self.logger.exception(message, extra={"service": self.service_name, **kwargs})

class PerformanceLogger:
    """Logger for performance metrics and timing"""
    
    def __init__(self, logger: ServiceLogger):
        self.logger = logger
    
    def log_request(self, method: str, path: str, status_code: int, 
                   duration_ms: float, **kwargs):
        """Log HTTP request performance"""
        self.logger.info(
            f"HTTP Request: {method} {path}",
            method=method,
            path=path,
            status_code=status_code,
            duration_ms=duration_ms,
            **kwargs
        )
    
    def log_database_query(self, query: str, duration_ms: float, 
                          rows_affected: Optional[int] = None, **kwargs):
        """Log database query performance"""
        self.logger.info(
            f"Database Query: {query[:100]}...",
            query=query,
            duration_ms=duration_ms,
            rows_affected=rows_affected,
            **kwargs
        )
    
    def log_external_service_call(self, service: str, endpoint: str, 
                                 duration_ms: float, status_code: Optional[int] = None, **kwargs):
        """Log external service call performance"""
        self.logger.info(
            f"External Service Call: {service} {endpoint}",
            service=service,
            endpoint=endpoint,
            duration_ms=duration_ms,
            status_code=status_code,
            **kwargs
        )
    
    def log_cache_operation(self, operation: str, key: str, hit: bool, 
                           duration_ms: float, **kwargs):
        """Log cache operation performance"""
        self.logger.info(
            f"Cache {operation}: {key}",
            operation=operation,
            key=key,
            hit=hit,
            duration_ms=duration_ms,
            **kwargs
        )

class ErrorTracker:
    """Enhanced error tracking and reporting"""
    
    def __init__(self, logger: ServiceLogger):
        self.logger = logger
    
    def track_error(self, error: Exception, context: Optional[Dict[str, Any]] = None):
        """Track and log error with context"""
        error_id = str(uuid.uuid4())
        
        self.logger.error(
            f"Error tracked: {type(error).__name__}",
            error_id=error_id,
            error_type=type(error).__name__,
            error_message=str(error),
            context=context or {},
            traceback=traceback.format_exc(),
        )
        
        return error_id
    
    def track_api_error(self, error: Exception, endpoint: str, method: str, 
                       user_id: Optional[str] = None, **kwargs):
        """Track API-specific errors"""
        return self.track_error(error, {
            "endpoint": endpoint,
            "method": method,
            "user_id": user_id,
            **kwargs
        })
    
    def track_database_error(self, error: Exception, query: str, 
                           table: Optional[str] = None, **kwargs):
        """Track database-specific errors"""
        return self.track_error(error, {
            "query": query,
            "table": table,
            **kwargs
        })
    
    def track_external_service_error(self, error: Exception, service: str, 
                                   endpoint: str, **kwargs):
        """Track external service errors"""
        return self.track_error(error, {
            "service": service,
            "endpoint": endpoint,
            **kwargs
        })

# Context managers for request tracking
class RequestContext:
    """Context manager for request tracking"""
    
    def __init__(self, request_id: Optional[str] = None, user_id: Optional[str] = None):
        self.request_id = request_id or str(uuid.uuid4())
        self.user_id = user_id
        self._token = None
    
    def __enter__(self):
        self._token = request_id_var.set(self.request_id)
        if self.user_id:
            user_id_var.set(self.user_id)
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self._token:
            request_id_var.reset(self._token)
        if self.user_id:
            user_id_var.set(None)

class PerformanceTimer:
    """Context manager for performance timing"""
    
    def __init__(self, logger: ServiceLogger, operation: str, **context):
        self.logger = logger
        self.operation = operation
        self.context = context
        self.start_time = None
    
    def __enter__(self):
        self.start_time = datetime.now(timezone.utc)
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.start_time:
            duration = (datetime.now(timezone.utc) - self.start_time).total_seconds() * 1000
            self.logger.info(
                f"Performance: {self.operation}",
                operation=self.operation,
                duration_ms=duration,
                **self.context
            )

# Global logger instances
def get_logger(service_name: str, log_level: str = "INFO") -> ServiceLogger:
    """Get logger instance for service"""
    return ServiceLogger(service_name, log_level)

def get_performance_logger(logger: ServiceLogger) -> PerformanceLogger:
    """Get performance logger instance"""
    return PerformanceLogger(logger)

def get_error_tracker(logger: ServiceLogger) -> ErrorTracker:
    """Get error tracker instance"""
    return ErrorTracker(logger)

# Utility functions
def log_function_call(func):
    """Decorator to log function calls"""
    def wrapper(*args, **kwargs):
        logger = get_logger("function_calls")
        func_name = f"{func.__module__}.{func.__name__}"
        
        with PerformanceTimer(logger, f"Function call: {func_name}"):
            try:
                result = func(*args, **kwargs)
                logger.debug(f"Function completed: {func_name}")
                return result
            except Exception as e:
                error_tracker = get_error_tracker(logger)
                error_tracker.track_error(e, {"function": func_name})
                raise
    
    return wrapper

def log_async_function_call(func):
    """Decorator to log async function calls"""
    async def wrapper(*args, **kwargs):
        logger = get_logger("async_function_calls")
        func_name = f"{func.__module__}.{func.__name__}"
        
        with PerformanceTimer(logger, f"Async function call: {func_name}"):
            try:
                result = await func(*args, **kwargs)
                logger.debug(f"Async function completed: {func_name}")
                return result
            except Exception as e:
                error_tracker = get_error_tracker(logger)
                error_tracker.track_error(e, {"function": func_name})
                raise
    
    return wrapper
