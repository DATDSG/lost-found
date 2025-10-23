"""
Legacy Models for Backward Compatibility
=======================================
These are temporary models to maintain backward compatibility
while the full domain migration is completed.
"""

from sqlalchemy import Column, String, Boolean, DateTime, Enum as SQLEnum, Text, ForeignKey, Integer, Float, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
import uuid as uuid_pkg
from datetime import datetime
from typing import Optional

from .infrastructure.database.base import Base


class User(Base):
    """
    User Entity - Legacy model for backward compatibility.
    """
    __tablename__ = "users"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid_pkg.uuid4)
    
    # Authentication
    email = Column(String, unique=True, nullable=False, index=True)
    password = Column(String, nullable=False)
    
    # Profile Information
    display_name = Column(String)
    phone_number = Column(String(20))
    avatar_url = Column(String(500))
    bio = Column(Text)
    location = Column(String(100))
    gender = Column(String(20))
    date_of_birth = Column(DateTime)
    
    # Role and Status
    role = Column(String, default="user")
    status = Column(String, default="active")
    is_active = Column(Boolean, default=True)
    
    # Audit Fields
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Relationships
    reports = relationship("Report", back_populates="owner", foreign_keys="Report.owner_id")
    
    def __repr__(self):
        return f"<User(id='{self.id}', email='{self.email}', role='{self.role}')>"


class AuditLog(Base):
    """
    AuditLog Entity - Legacy model for backward compatibility.
    """
    __tablename__ = "audit_logs"

    # Primary Key
    id = Column(String, primary_key=True, default=lambda: str(uuid_pkg.uuid4()))
    
    # Audit Information
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    action = Column(String, nullable=False, index=True)
    resource_type = Column(String, index=True)
    resource_id = Column(String, index=True)
    details = Column(Text)
    
    # Audit Fields
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    def __repr__(self):
        return f"<AuditLog(id='{self.id}', action='{self.action}', user_id='{self.user_id}')>"


# Fraud Detection Models
class FraudRiskLevel(str, enum.Enum):
    """Fraud risk levels."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class FraudDetectionResult(Base):
    """
    Stores fraud detection analysis results for reports.
    """
    __tablename__ = "fraud_detection_results"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid_pkg.uuid4)
    
    # Foreign Keys
    report_id = Column(UUID(as_uuid=True), ForeignKey("reports.id"), nullable=False, index=True)
    
    # Analysis Results
    fraud_score = Column(Float, nullable=False, index=True)
    risk_level = Column(SQLEnum(FraudRiskLevel), nullable=False, index=True)
    confidence = Column(Float)
    flags = Column(JSON)  # List of detected fraud flags
    
    # Review Status
    is_reviewed = Column(Boolean, default=False, index=True)
    is_confirmed_fraud = Column(Boolean, default=False, index=True)
    reviewed_by = Column(String)
    reviewed_at = Column(DateTime(timezone=True))
    admin_notes = Column(Text)
    
    # Audit Fields
    detected_at = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Relationships
    report = relationship("Report", back_populates="fraud_detection_results")
    
    def __repr__(self):
        return f"<FraudDetectionResult(id='{self.id}', report_id='{self.report_id}', risk_level='{self.risk_level}')>"


class FraudPattern(Base):
    """
    Stores known fraud patterns for detection.
    """
    __tablename__ = "fraud_patterns"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid_pkg.uuid4)
    
    # Pattern Information
    name = Column(String, nullable=False, unique=True, index=True)
    description = Column(Text)
    pattern_type = Column(String, nullable=False, index=True)  # text, image, behavior
    pattern_data = Column(JSON)  # Pattern-specific data
    
    # Scoring
    weight = Column(Float, default=1.0)
    threshold = Column(Float, default=0.5)
    
    # Status
    is_active = Column(Boolean, default=True, index=True)
    
    # Audit Fields
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    def __repr__(self):
        return f"<FraudPattern(id='{self.id}', name='{self.name}', type='{self.pattern_type}')>"


class FraudDetectionLog(Base):
    """
    Logs fraud detection analysis runs and results.
    """
    __tablename__ = "fraud_detection_logs"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid_pkg.uuid4)
    
    # Analysis Information
    report_id = Column(UUID(as_uuid=True), ForeignKey("reports.id"), nullable=False, index=True)
    analysis_type = Column(String, nullable=False, index=True)  # automatic, manual, batch
    triggered_by = Column(String)  # user_id, system, scheduled
    
    # Results Summary
    total_patterns_checked = Column(Integer, default=0)
    patterns_matched = Column(Integer, default=0)
    final_score = Column(Float)
    final_risk_level = Column(SQLEnum(FraudRiskLevel))
    
    # Processing Information
    processing_time_ms = Column(Integer)
    error_message = Column(Text)
    
    # Audit Fields
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    report = relationship("Report")
    
    def __repr__(self):
        return f"<FraudDetectionLog(id='{self.id}', report_id='{self.report_id}', analysis_type='{self.analysis_type}')>"