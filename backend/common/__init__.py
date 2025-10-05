"""Common shared internal package for backend services.
Add shared utilities (db session helpers, config loaders, reusable exceptions, logging setup) here.
"""
from importlib import metadata as _md

from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import Boolean, DateTime, String, Text
from sqlalchemy.orm import Mapped, mapped_column


class SoftDeleteMixin:
    """Mixin supplying soft delete columns consistent with Alembic migration.

    Ensures ORM sets is_deleted default False on INSERT to satisfy NOT NULL constraint.
    """
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    deleted_by: Mapped[str | None] = mapped_column(String(255), nullable=True)
    deletion_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)


class AuditLogMixin:  # Placeholder for future audit logging fields
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

__all__ = ["SoftDeleteMixin", "AuditLogMixin", "get_version"]

def get_version() -> str:
    try:
        return _md.version("lost-found-common")  # if later packaged
    except _md.PackageNotFoundError:  # pragma: no cover
        return "0.0.0-dev"
