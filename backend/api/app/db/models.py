from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, Float, ForeignKey, JSON, Index
from sqlalchemy.orm import relationship, Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
from geoalchemy2 import Geography
import uuid
from app.db.session import Base
from src.models.soft_delete import SoftDeleteMixin, AuditLogMixin


class User(Base, SoftDeleteMixin):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    preferred_language: Mapped[str] = mapped_column(String(5), default="en", nullable=False)  # si/ta/en
    is_superuser: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    items = relationship("Item", back_populates="owner")


class Item(Base, SoftDeleteMixin):
    __tablename__ = "items"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    
    # Core identification
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    language: Mapped[str] = mapped_column(String(5), default="en", nullable=False)  # si/ta/en
    status: Mapped[str] = mapped_column(String(20), default="lost", nullable=False)  # lost/found/claimed/closed
    
    # Structured categorization for baseline matching
    category: Mapped[str] = mapped_column(String(100), nullable=False, index=True)  # electronics, clothing, documents, etc.
    subcategory: Mapped[str | None] = mapped_column(String(100), nullable=True, index=True)  # phone, laptop, shirt, etc.
    brand: Mapped[str | None] = mapped_column(String(100), nullable=True, index=True)
    model: Mapped[str | None] = mapped_column(String(100), nullable=True)
    color: Mapped[str | None] = mapped_column(String(50), nullable=True, index=True)
    
    # Unique identifiers for proof-of-ownership
    unique_marks: Mapped[str | None] = mapped_column(Text, nullable=True)  # scratches, stickers, etc.
    evidence_hash: Mapped[str | None] = mapped_column(String(64), nullable=True)  # hashed IMEI, serial, etc.
    
    # Geospatial data
    location_point = Column(Geography('POINT', srid=4326), nullable=True)  # PostGIS point
    location_name: Mapped[str | None] = mapped_column(String(255), nullable=True)  # human-readable location
    geohash6: Mapped[str | None] = mapped_column(String(6), nullable=True, index=True)  # for spatial blocking
    location_fuzzing: Mapped[int] = mapped_column(Integer, default=100, nullable=False)  # meters to fuzz for privacy
    
    # Temporal data
    lost_found_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)  # when item was lost/found
    time_window_start: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    time_window_end: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    
    # System fields
    owner_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # NLP features (optional, controlled by feature flags)
    text_embedding = Column(JSON, nullable=True)  # vector embedding for text similarity
    extracted_entities = Column(JSON, nullable=True)  # NER results
    
    owner = relationship("User", back_populates="items")
    media = relationship("MediaAsset", back_populates="item", cascade="all, delete-orphan")
    flags = relationship("Flag", back_populates="item")
    moderation_logs = relationship("ModerationLog", back_populates="item")
    
    # Indexes for efficient querying
    __table_args__ = (
        Index('idx_items_category_subcategory', 'category', 'subcategory'),
        Index('idx_items_geohash_time', 'geohash6', 'lost_found_at'),
        Index('idx_items_status_category', 'status', 'category'),
        Index('idx_items_time_window', 'time_window_start', 'time_window_end'),
    )

class MediaAsset(Base):
    __tablename__ = "media_assets"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    item_id: Mapped[int] = mapped_column(Integer, ForeignKey("items.id", ondelete="CASCADE"), nullable=False)
    s3_key: Mapped[str] = mapped_column(String(512), nullable=False)
    mime_type: Mapped[str | None] = mapped_column(String(100))
    phash: Mapped[str | None] = mapped_column(String(64))
    width: Mapped[int | None] = mapped_column(Integer)
    height: Mapped[int | None] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    item = relationship("Item", back_populates="media")

class Match(Base):
    __tablename__ = "matches"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    lost_item_id: Mapped[int] = mapped_column(Integer, ForeignKey("items.id", ondelete="CASCADE"), nullable=False)
    found_item_id: Mapped[int] = mapped_column(Integer, ForeignKey("items.id", ondelete="CASCADE"), nullable=False)
    
    # Explainable scoring breakdown
    score_final: Mapped[float] = mapped_column(Float, default=0, index=True)
    score_breakdown = Column(JSON, nullable=True)  # {"category": 0.8, "distance": 0.6, "time": 0.9, "text": 0.7, "image": 0.5}
    
    # Match metadata
    distance_km: Mapped[float | None] = mapped_column(Float, nullable=True)
    time_diff_hours: Mapped[float | None] = mapped_column(Float, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)  # pending/viewed/dismissed/claimed
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)
    
    lost_item = relationship("Item", foreign_keys=[lost_item_id])
    found_item = relationship("Item", foreign_keys=[found_item_id])
    
    __table_args__ = (
        Index('idx_matches_score', 'score_final'),
        Index('idx_matches_lost_item', 'lost_item_id', 'status'),
        Index('idx_matches_found_item', 'found_item_id', 'status'),
    )

class Claim(Base):
    __tablename__ = "claims"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    match_id: Mapped[int] = mapped_column(Integer, ForeignKey("matches.id", ondelete="CASCADE"), nullable=False)
    claimant_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    owner_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    status: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)  # pending/approved/rejected/disputed
    evidence_provided: Mapped[str | None] = mapped_column(Text, nullable=True)
    evidence_hash: Mapped[str | None] = mapped_column(String(64), nullable=True)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    
    match = relationship("Match")
    claimant = relationship("User", foreign_keys=[claimant_id])
    owner = relationship("User", foreign_keys=[owner_id])


class ChatMessage(Base):
    __tablename__ = "chat_messages"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    match_id: Mapped[int] = mapped_column(Integer, ForeignKey("matches.id", ondelete="CASCADE"), nullable=False)
    sender_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    message: Mapped[str] = mapped_column(Text, nullable=False)
    is_masked: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)  # for privacy
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    
    match = relationship("Match")
    sender = relationship("User")

class Notification(Base):
    __tablename__ = "notifications"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    type: Mapped[str] = mapped_column(String(50), nullable=False)
    payload = Column(JSON, nullable=True)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)


class Flag(Base):
    __tablename__ = "flags"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    item_id: Mapped[int] = mapped_column(Integer, ForeignKey("items.id", ondelete="CASCADE"), nullable=False)
    reporter_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    source: Mapped[str] = mapped_column(String(50), default="user", nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="open", nullable=False)
    metadata = Column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    item = relationship("Item", back_populates="flags")
    reporter = relationship("User", backref="flags_reported")


class ModerationLog(Base):
    __tablename__ = "moderation_logs"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    item_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("items.id", ondelete="SET NULL"))
    moderator_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    action: Mapped[str] = mapped_column(String(50), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    metadata = Column(JSON, nullable=True)

    item = relationship("Item", back_populates="moderation_logs")
    moderator = relationship("User", backref="moderation_logs")


class AuditLog(Base):
    __tablename__ = "audit_logs"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    action: Mapped[str] = mapped_column(String(100), nullable=False)  # item.created, match.generated, claim.submitted, etc.
    resource_type: Mapped[str] = mapped_column(String(50), nullable=False)  # item, match, claim, user
    resource_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    ip_address: Mapped[str | None] = mapped_column(String(45), nullable=True)  # IPv6 support
    user_agent: Mapped[str | None] = mapped_column(Text, nullable=True)
    metadata = Column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    
    user = relationship("User")
    
    __table_args__ = (
        Index('idx_audit_logs_user_action', 'user_id', 'action'),
        Index('idx_audit_logs_resource', 'resource_type', 'resource_id'),
        Index('idx_audit_logs_created', 'created_at'),
    )