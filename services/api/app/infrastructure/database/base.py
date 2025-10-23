"""
Infrastructure Database Base
============================
Base database configuration and models for the infrastructure layer.
"""

from sqlalchemy import Column, String, DateTime, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
import uuid as uuid_pkg

# Create base class for all domain models
Base = declarative_base()


class InfrastructureModel(Base):
    """
    Base model for infrastructure-level entities.
    Provides common fields for audit and metadata.
    """
    __abstract__ = True
    
    id = Column(String, primary_key=True, default=lambda: str(uuid_pkg.uuid4()))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    is_active = Column(Boolean, default=True)
