"""Global exception handlers for the Lost & Found API."""

import logging
import traceback
from typing import Union
from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from sqlalchemy.exc import SQLAlchemyError, IntegrityError
from pydantic import ValidationError as PydanticValidationError

from .exceptions import LostFoundException
from .config import config

logger = logging.getLogger(__name__)


async def lost_found_exception_handler(request: Request, exc: LostFoundException) -> JSONResponse:
    """Handle custom Lost & Found exceptions."""
    logger.warning(
        f"LostFoundException: {exc.message}",
        extra={
            "status_code": exc.status_code,
            "details": exc.details,
            "path": request.url.path,
            "method": request.method,
        }
    )
    
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": exc.__class__.__name__.lower(),
                "message": exc.message,
                "details": exc.details,
                "path": request.url.path,
                "method": request.method,
            }
        }
    )


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """Handle FastAPI HTTP exceptions."""
    logger.warning(
        f"HTTPException: {exc.detail}",
        extra={
            "status_code": exc.status_code,
            "path": request.url.path,
            "method": request.method,
        }
    )
    
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": "http_error",
                "message": exc.detail,
                "status_code": exc.status_code,
                "path": request.url.path,
                "method": request.method,
            }
        }
    )


async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    """Handle request validation errors."""
    errors = []
    for error in exc.errors():
        errors.append({
            "field": ".".join(str(loc) for loc in error["loc"]),
            "message": error["msg"],
            "type": error["type"],
            "input": error.get("input"),
        })
    
    logger.warning(
        f"Validation error: {len(errors)} field(s) invalid",
        extra={
            "errors": errors,
            "path": request.url.path,
            "method": request.method,
        }
    )
    
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": {
                "code": "validation_error",
                "message": "Request validation failed",
                "details": {
                    "errors": errors,
                    "total_errors": len(errors),
                },
                "path": request.url.path,
                "method": request.method,
            }
        }
    )


async def pydantic_validation_exception_handler(request: Request, exc: PydanticValidationError) -> JSONResponse:
    """Handle Pydantic validation errors."""
    errors = []
    for error in exc.errors():
        errors.append({
            "field": ".".join(str(loc) for loc in error["loc"]),
            "message": error["msg"],
            "type": error["type"],
            "input": error.get("input"),
        })
    
    logger.warning(
        f"Pydantic validation error: {len(errors)} field(s) invalid",
        extra={
            "errors": errors,
            "path": request.url.path,
            "method": request.method,
        }
    )
    
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": {
                "code": "pydantic_validation_error",
                "message": "Data validation failed",
                "details": {
                    "errors": errors,
                    "total_errors": len(errors),
                },
                "path": request.url.path,
                "method": request.method,
            }
        }
    )


async def sqlalchemy_exception_handler(request: Request, exc: SQLAlchemyError) -> JSONResponse:
    """Handle SQLAlchemy database errors."""
    error_message = "Database operation failed"
    error_details = {}
    
    if isinstance(exc, IntegrityError):
        error_message = "Data integrity constraint violation"
        error_details["constraint"] = str(exc.orig) if hasattr(exc, 'orig') else "Unknown constraint"
    else:
        error_message = f"Database error: {str(exc)}"
    
    # Log the full error for debugging
    logger.error(
        f"SQLAlchemy error: {error_message}",
        extra={
            "error_type": exc.__class__.__name__,
            "path": request.url.path,
            "method": request.method,
        },
        exc_info=True
    )
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": {
                "code": "database_error",
                "message": error_message,
                "details": error_details,
                "path": request.url.path,
                "method": request.method,
            }
        }
    )


async def general_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Handle all other unhandled exceptions."""
    # Log the full error for debugging
    logger.error(
        f"Unhandled exception: {str(exc)}",
        extra={
            "error_type": exc.__class__.__name__,
            "path": request.url.path,
            "method": request.method,
        },
        exc_info=True
    )
    
    # Include traceback in development mode
    error_details = {}
    if config.DEBUG:
        error_details["traceback"] = traceback.format_exc()
        error_details["exception_type"] = exc.__class__.__name__
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": {
                "code": "internal_server_error",
                "message": "An unexpected error occurred",
                "details": error_details,
                "path": request.url.path,
                "method": request.method,
            }
        }
    )


def register_exception_handlers(app):
    """Register all exception handlers with the FastAPI app."""
    from .exceptions import (
        ValidationError,
        AuthenticationError,
        AuthorizationError,
        NotFoundError,
        ConflictError,
        RateLimitError,
        ServiceUnavailableError,
        DatabaseError,
        ExternalServiceError,
    )
    
    # Custom exceptions
    app.add_exception_handler(LostFoundException, lost_found_exception_handler)
    app.add_exception_handler(ValidationError, lost_found_exception_handler)
    app.add_exception_handler(AuthenticationError, lost_found_exception_handler)
    app.add_exception_handler(AuthorizationError, lost_found_exception_handler)
    app.add_exception_handler(NotFoundError, lost_found_exception_handler)
    app.add_exception_handler(ConflictError, lost_found_exception_handler)
    app.add_exception_handler(RateLimitError, lost_found_exception_handler)
    app.add_exception_handler(ServiceUnavailableError, lost_found_exception_handler)
    app.add_exception_handler(DatabaseError, lost_found_exception_handler)
    app.add_exception_handler(ExternalServiceError, lost_found_exception_handler)
    
    # Standard exceptions
    app.add_exception_handler(HTTPException, http_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(PydanticValidationError, pydantic_validation_exception_handler)
    app.add_exception_handler(SQLAlchemyError, sqlalchemy_exception_handler)
    app.add_exception_handler(Exception, general_exception_handler)
