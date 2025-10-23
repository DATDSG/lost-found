"""
Taxonomy Domain Models
=====================
Domain-specific models for the Taxonomy bounded context.
Following Domain-Driven Design principles.
"""

from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
from typing import Optional

from ....infrastructure.database.base import Base


class Category(Base):
    """
    Category Entity - Core domain model for item categories.
    
    This entity represents a category in the taxonomy system
    used for classifying lost and found items.
    """
    __tablename__ = "categories"

    # Primary Key
    id = Column(String(64), primary_key=True)
    
    # Category Information
    name = Column(String(100), nullable=False)
    description = Column(Text)
    icon = Column(String(50))
    
    # Hierarchy and Organization
    parent_id = Column(String(64), nullable=True)  # For hierarchical categories
    sort_order = Column(Integer, default=0, nullable=False)
    level = Column(Integer, default=0, nullable=False)  # Hierarchy level
    
    # Status and Metadata
    is_active = Column(Boolean, default=True, nullable=False)
    is_leaf = Column(Boolean, default=True, nullable=False)  # Has no children
    
    # Audit Fields
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Domain Relationships
    children = relationship("Category", backref="parent", remote_side=[id])
    
    def __repr__(self):
        return f"<Category(id='{self.id}', name='{self.name}', level={self.level})>"
    
    def is_root(self) -> bool:
        """Check if category is a root category."""
        return self.parent_id is None
    
    def has_children(self) -> bool:
        """Check if category has child categories."""
        return not self.is_leaf
    
    def get_full_path(self) -> str:
        """Get full hierarchical path of the category."""
        if self.is_root():
            return self.name
        
        # This would need to be implemented with a recursive query
        # For now, return just the name
        return self.name
    
    def get_ancestors(self) -> list:
        """Get all ancestor categories."""
        # This would need to be implemented with a recursive query
        # For now, return empty list
        return []
    
    def get_descendants(self) -> list:
        """Get all descendant categories."""
        # This would need to be implemented with a recursive query
        # For now, return direct children
        return self.children
    
    def activate(self):
        """Activate the category."""
        self.is_active = True
        self.updated_at = datetime.utcnow()
    
    def deactivate(self):
        """Deactivate the category."""
        self.is_active = False
        self.updated_at = datetime.utcnow()
    
    def move_to_parent(self, new_parent_id: Optional[str]):
        """Move category to a new parent."""
        self.parent_id = new_parent_id
        self.updated_at = datetime.utcnow()
    
    def update_sort_order(self, new_order: int):
        """Update the sort order of the category."""
        self.sort_order = new_order
        self.updated_at = datetime.utcnow()


class Color(Base):
    """
    Color Entity - Core domain model for color classification.
    
    This entity represents a color in the taxonomy system
    used for describing lost and found items.
    """
    __tablename__ = "colors"

    # Primary Key
    id = Column(String(32), primary_key=True)
    
    # Color Information
    name = Column(String(50), nullable=False)
    hex_code = Column(String(7))  # #RRGGBB format
    rgb_red = Column(Integer)
    rgb_green = Column(Integer)
    rgb_blue = Column(Integer)
    
    # Organization
    sort_order = Column(Integer, default=0, nullable=False)
    color_family = Column(String(50))  # e.g., "red", "blue", "green"
    
    # Status
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Audit Fields
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    def __repr__(self):
        return f"<Color(id='{self.id}', name='{self.name}', hex='{self.hex_code}')>"
    
    def get_rgb_tuple(self) -> Optional[tuple]:
        """Get RGB values as tuple."""
        if all([self.rgb_red, self.rgb_green, self.rgb_blue]):
            return (self.rgb_red, self.rgb_green, self.rgb_blue)
        return None
    
    def get_hex_code(self) -> str:
        """Get hex code with # prefix."""
        if self.hex_code and not self.hex_code.startswith('#'):
            return f"#{self.hex_code}"
        return self.hex_code or "#000000"
    
    def is_dark_color(self) -> bool:
        """Check if color is dark based on RGB values."""
        rgb = self.get_rgb_tuple()
        if rgb:
            # Calculate luminance
            luminance = (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) / 255
            return luminance < 0.5
        return False
    
    def is_light_color(self) -> bool:
        """Check if color is light based on RGB values."""
        return not self.is_dark_color()
    
    def get_color_family(self) -> str:
        """Get color family or 'unknown' if not set."""
        return self.color_family or "unknown"
    
    def activate(self):
        """Activate the color."""
        self.is_active = True
        self.updated_at = datetime.utcnow()
    
    def deactivate(self):
        """Deactivate the color."""
        self.is_active = False
        self.updated_at = datetime.utcnow()
    
    def update_sort_order(self, new_order: int):
        """Update the sort order of the color."""
        self.sort_order = new_order
        self.updated_at = datetime.utcnow()
