"""Database models for the Lost & Found system."""
from sqlalchemy import Column, String, Integer, DateTime, Float, Boolean, ForeignKey, Text, Enum as SQLEnum, ARRAY
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from geoalchemy2 import Geometry
from pgvector.sqlalchemy import Vector
import enum
import uuid as uuid_pkg

from .database import Base


class ReportType(str, enum.Enum):
    LOST = "lost"
    FOUND = "found"


class ReportStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    HIDDEN = "hidden"
    REMOVED = "removed"


class MatchStatus(str, enum.Enum):
    CANDIDATE = "candidate"
    PROMOTED = "promoted"
    SUPPRESSED = "suppressed"
    DISMISSED = "dismissed"


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid_pkg.uuid4)
    email = Column(String, unique=True, nullable=False, index=True)
    password = Column(String, nullable=False)  # Fixed: removed explicit column mapping
    display_name = Column(String)
    phone_number = Column(String(20))
    avatar_url = Column(String(500))
    role = Column(String, default="user")
    status = Column(String, default="active")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    reports = relationship("Report", back_populates="owner", foreign_keys="Report.owner_id")
    messages_sent = relationship("Message", back_populates="sender", foreign_keys="Message.sender_id")
    notifications = relationship("Notification", back_populates="user")


class Report(Base):
    __tablename__ = "reports"

    id = Column(String, primary_key=True)
    owner_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    type = Column(String, nullable=False, index=True)
    status = Column(String, default="pending", index=True)
    
    title = Column(String, nullable=False)
    description = Column(Text)
    category = Column(String, nullable=False, index=True)
    colors = Column(ARRAY(String))
    
    occurred_at = Column(DateTime(timezone=True), nullable=False)
    geo = Column(Text)  # TEXT column for geographic data (PostGIS not enabled)
    location_city = Column(String, index=True)
    location_address = Column(Text)
    
    embedding = Column(Vector(384), name="embedding")  # E5-small dimension for semantic search
    image_hash = Column(String(32), name="image_hash", index=True)  # Perceptual hash from Vision service
    attributes = Column(Text)  # JSON string for category-specific data
    reward_offered = Column(Boolean, default=False)
    is_resolved = Column(Boolean, default=False, index=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    owner = relationship("User", back_populates="reports", foreign_keys=[owner_id])
    media = relationship("Media", back_populates="report", cascade="all, delete-orphan")
    source_matches = relationship("Match", back_populates="source_report", foreign_keys="Match.source_report_id")
    candidate_matches = relationship("Match", back_populates="candidate_report", foreign_keys="Match.candidate_report_id")


class Media(Base):
    __tablename__ = "media"

    id = Column(String, primary_key=True)
    report_id = Column(String, ForeignKey("reports.id"), nullable=False, index=True)
    
    filename = Column(String, nullable=False)
    url = Column(String, nullable=False)
    media_type = Column(String, default="image")
    mime_type = Column(String)
    size_bytes = Column(Integer)
    width = Column(Integer)
    height = Column(Integer)
    
    phash_hex = Column(String)  # Renamed from phash to match DB
    dhash_hex = Column(String)  # Renamed from dhash to match DB
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    report = relationship("Report", back_populates="media")


class Match(Base):
    __tablename__ = "matches"

    id = Column(String, primary_key=True)
    source_report_id = Column(String, ForeignKey("reports.id"), nullable=False, index=True)
    candidate_report_id = Column(String, ForeignKey("reports.id"), nullable=False, index=True)
    
    status = Column(String, default="candidate", index=True)
    
    score_total = Column(Float, nullable=False, index=True)
    score_text = Column(Float)
    score_image = Column(Float)
    score_geo = Column(Float)
    score_time = Column(Float)
    score_color = Column(Float)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    # Note: database doesn't have updated_at column

    # Relationships
    source_report = relationship("Report", back_populates="source_matches", foreign_keys=[source_report_id])
    candidate_report = relationship("Report", back_populates="candidate_matches", foreign_keys=[candidate_report_id])


class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(String, primary_key=True)
    match_id = Column(String, ForeignKey("matches.id"), index=True)
    participant_one_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    participant_two_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    messages = relationship("Message", back_populates="conversation", cascade="all, delete-orphan")


class Message(Base):
    __tablename__ = "messages"

    id = Column(String, primary_key=True)
    conversation_id = Column(String, ForeignKey("conversations.id"), nullable=False, index=True)
    sender_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    content = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    conversation = relationship("Conversation", back_populates="messages")
    sender = relationship("User", back_populates="messages_sent", foreign_keys=[sender_id])


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String, primary_key=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    
    type = Column(String, nullable=False)
    title = Column(String, nullable=False)
    content = Column(Text)
    reference_id = Column(String)
    
    is_read = Column(Boolean, default=False, index=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    # Relationships
    user = relationship("User", back_populates="notifications")


class AuditLog(Base):
    __tablename__ = "audit_log"  # Fixed: matches migration table name

    id = Column(String, primary_key=True)
    actor_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))  # Fixed: matches migration schema
    action = Column(String, nullable=False)
    resource = Column(String)  # Fixed: matches actual column name (was resource_type)
    resource_id = Column(String)
    reason = Column(Text)  # Fixed: matches actual column name (was details)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)


class Category(Base):
    __tablename__ = "categories"

    id = Column(String(64), primary_key=True)
    name = Column(String(100), nullable=False)
    icon = Column(String(50))
    sort_order = Column(Integer, default=0, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)


class Color(Base):
    __tablename__ = "colors"

    id = Column(String(32), primary_key=True)
    name = Column(String(50), nullable=False)
    hex_code = Column(String(7))
    sort_order = Column(Integer, default=0, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
