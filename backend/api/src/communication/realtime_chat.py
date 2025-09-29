"""
Real-time Chat System
WebSocket-based messaging for item matches with privacy controls
"""

import json
import asyncio
from datetime import datetime
from typing import Dict, List, Optional, Set, Any
from dataclasses import dataclass, asdict
from enum import Enum
import logging

from fastapi import WebSocket, WebSocketDisconnect, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
import redis.asyncio as redis

from app.db.session import get_db
from app.db.models import ChatMessage, Match, User, Item
from src.auth.rbac import get_current_user
from src.config.backend_enhancements import session_config

logger = logging.getLogger(__name__)

class MessageType(Enum):
    """Types of chat messages"""
    TEXT = "text"
    IMAGE = "image"
    LOCATION = "location"
    SYSTEM = "system"
    TYPING = "typing"
    READ_RECEIPT = "read_receipt"

class ChatEventType(Enum):
    """Types of chat events"""
    MESSAGE = "message"
    USER_JOINED = "user_joined"
    USER_LEFT = "user_left"
    TYPING_START = "typing_start"
    TYPING_STOP = "typing_stop"
    MESSAGE_READ = "message_read"
    MATCH_UPDATED = "match_updated"

@dataclass
class ChatMessage:
    """Chat message data structure"""
    id: Optional[int]
    match_id: int
    sender_id: int
    sender_name: str
    message_type: MessageType
    content: str
    metadata: Optional[Dict[str, Any]]
    timestamp: datetime
    is_read: bool = False
    is_masked: bool = True

@dataclass
class ChatEvent:
    """Chat event data structure"""
    event_type: ChatEventType
    match_id: int
    user_id: Optional[int]
    data: Dict[str, Any]
    timestamp: datetime

@dataclass
class TypingIndicator:
    """Typing indicator data"""
    user_id: int
    user_name: str
    match_id: int
    timestamp: datetime

class MessageMasker:
    """Privacy-focused message masking"""
    
    def __init__(self):
        # Patterns to mask for privacy
        self.sensitive_patterns = {
            'phone': r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b',
            'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            'address': r'\b\d+\s+[A-Za-z\s]+(?:Street|St|Avenue|Ave|Road|Rd|Lane|Ln|Drive|Dr|Boulevard|Blvd)\b',
            'name': r'\b[A-Z][a-z]+\s+[A-Z][a-z]+\b',  # Simple name pattern
        }
        
        # Safe replacement patterns
        self.replacements = {
            'phone': '[PHONE NUMBER]',
            'email': '[EMAIL ADDRESS]',
            'address': '[ADDRESS]',
            'name': '[NAME]',
        }
    
    def mask_message(self, content: str, enable_masking: bool = True) -> tuple[str, List[str]]:
        """Mask sensitive information in message content"""
        if not enable_masking:
            return content, []
        
        masked_content = content
        masked_items = []
        
        for pattern_name, pattern in self.sensitive_patterns.items():
            import re
            matches = re.findall(pattern, masked_content, re.IGNORECASE)
            if matches:
                masked_items.extend([f"{pattern_name}: {match}" for match in matches])
                masked_content = re.sub(
                    pattern, 
                    self.replacements[pattern_name], 
                    masked_content, 
                    flags=re.IGNORECASE
                )
        
        return masked_content, masked_items

class ConnectionManager:
    """Manages WebSocket connections for real-time chat"""
    
    def __init__(self):
        # Active connections: {match_id: {user_id: websocket}}
        self.active_connections: Dict[int, Dict[int, WebSocket]] = {}
        
        # Typing indicators: {match_id: {user_id: TypingIndicator}}
        self.typing_indicators: Dict[int, Dict[int, TypingIndicator]] = {}
        
        # Redis for cross-instance messaging
        self.redis_client: Optional[redis.Redis] = None
        
        # Message masker
        self.masker = MessageMasker()
    
    async def initialize_redis(self):
        """Initialize Redis connection for pub/sub"""
        try:
            self.redis_client = redis.Redis(
                host=session_config.REDIS_HOST,
                port=session_config.REDIS_PORT,
                password=session_config.REDIS_PASSWORD,
                db=session_config.REDIS_CACHE_DB,
                decode_responses=True
            )
            await self.redis_client.ping()
            logger.info("Redis connection established for chat")
        except Exception as e:
            logger.error(f"Failed to connect to Redis: {e}")
            self.redis_client = None
    
    async def connect(self, websocket: WebSocket, match_id: int, user_id: int):
        """Connect a user to a match chat"""
        await websocket.accept()
        
        if match_id not in self.active_connections:
            self.active_connections[match_id] = {}
        
        self.active_connections[match_id][user_id] = websocket
        
        # Notify other users in the match
        await self.broadcast_event(
            match_id,
            ChatEvent(
                event_type=ChatEventType.USER_JOINED,
                match_id=match_id,
                user_id=user_id,
                data={"message": "User joined the chat"},
                timestamp=datetime.utcnow()
            ),
            exclude_user=user_id
        )
        
        logger.info(f"User {user_id} connected to match {match_id}")
    
    async def disconnect(self, match_id: int, user_id: int):
        """Disconnect a user from a match chat"""
        if match_id in self.active_connections:
            self.active_connections[match_id].pop(user_id, None)
            
            # Remove typing indicator
            if match_id in self.typing_indicators:
                self.typing_indicators[match_id].pop(user_id, None)
            
            # Clean up empty match rooms
            if not self.active_connections[match_id]:
                del self.active_connections[match_id]
            else:
                # Notify other users
                await self.broadcast_event(
                    match_id,
                    ChatEvent(
                        event_type=ChatEventType.USER_LEFT,
                        match_id=match_id,
                        user_id=user_id,
                        data={"message": "User left the chat"},
                        timestamp=datetime.utcnow()
                    ),
                    exclude_user=user_id
                )
        
        logger.info(f"User {user_id} disconnected from match {match_id}")
    
    async def send_message_to_user(self, match_id: int, user_id: int, message: Dict[str, Any]):
        """Send message to a specific user"""
        if match_id in self.active_connections and user_id in self.active_connections[match_id]:
            websocket = self.active_connections[match_id][user_id]
            try:
                await websocket.send_text(json.dumps(message))
            except Exception as e:
                logger.error(f"Error sending message to user {user_id}: {e}")
                # Remove broken connection
                await self.disconnect(match_id, user_id)
    
    async def broadcast_to_match(self, match_id: int, message: Dict[str, Any], exclude_user: Optional[int] = None):
        """Broadcast message to all users in a match"""
        if match_id not in self.active_connections:
            return
        
        disconnected_users = []
        
        for user_id, websocket in self.active_connections[match_id].items():
            if exclude_user and user_id == exclude_user:
                continue
            
            try:
                await websocket.send_text(json.dumps(message))
            except Exception as e:
                logger.error(f"Error broadcasting to user {user_id}: {e}")
                disconnected_users.append(user_id)
        
        # Clean up disconnected users
        for user_id in disconnected_users:
            await self.disconnect(match_id, user_id)
    
    async def broadcast_event(self, match_id: int, event: ChatEvent, exclude_user: Optional[int] = None):
        """Broadcast a chat event to match participants"""
        message = {
            "type": "event",
            "event_type": event.event_type.value,
            "match_id": event.match_id,
            "user_id": event.user_id,
            "data": event.data,
            "timestamp": event.timestamp.isoformat()
        }
        
        await self.broadcast_to_match(match_id, message, exclude_user)
        
        # Publish to Redis for cross-instance communication
        if self.redis_client:
            try:
                await self.redis_client.publish(
                    f"chat_events:{match_id}",
                    json.dumps(message)
                )
            except Exception as e:
                logger.error(f"Error publishing to Redis: {e}")
    
    async def handle_typing_indicator(self, match_id: int, user_id: int, user_name: str, is_typing: bool):
        """Handle typing indicators"""
        if match_id not in self.typing_indicators:
            self.typing_indicators[match_id] = {}
        
        if is_typing:
            self.typing_indicators[match_id][user_id] = TypingIndicator(
                user_id=user_id,
                user_name=user_name,
                match_id=match_id,
                timestamp=datetime.utcnow()
            )
            
            event_type = ChatEventType.TYPING_START
        else:
            self.typing_indicators[match_id].pop(user_id, None)
            event_type = ChatEventType.TYPING_STOP
        
        # Broadcast typing status
        await self.broadcast_event(
            match_id,
            ChatEvent(
                event_type=event_type,
                match_id=match_id,
                user_id=user_id,
                data={"user_name": user_name, "is_typing": is_typing},
                timestamp=datetime.utcnow()
            ),
            exclude_user=user_id
        )
    
    def get_active_users(self, match_id: int) -> List[int]:
        """Get list of active users in a match"""
        if match_id in self.active_connections:
            return list(self.active_connections[match_id].keys())
        return []
    
    def get_typing_users(self, match_id: int) -> List[TypingIndicator]:
        """Get list of users currently typing"""
        if match_id in self.typing_indicators:
            # Clean up old typing indicators (older than 10 seconds)
            current_time = datetime.utcnow()
            active_typing = {}
            
            for user_id, indicator in self.typing_indicators[match_id].items():
                if (current_time - indicator.timestamp).total_seconds() < 10:
                    active_typing[user_id] = indicator
            
            self.typing_indicators[match_id] = active_typing
            return list(active_typing.values())
        
        return []

# Global connection manager
connection_manager = ConnectionManager()

class ChatService:
    """Service for managing chat operations"""
    
    def __init__(self, db: Session):
        self.db = db
        self.masker = MessageMasker()
    
    async def save_message(
        self, 
        match_id: int, 
        sender_id: int, 
        content: str, 
        message_type: MessageType = MessageType.TEXT,
        metadata: Optional[Dict[str, Any]] = None,
        enable_masking: bool = True
    ) -> ChatMessage:
        """Save a chat message to the database"""
        
        # Mask sensitive content
        masked_content, masked_items = self.masker.mask_message(content, enable_masking)
        
        # Get sender info
        sender = self.db.query(User).filter(User.id == sender_id).first()
        if not sender:
            raise HTTPException(status_code=404, detail="Sender not found")
        
        # Create message record
        db_message = ChatMessage(
            match_id=match_id,
            sender_id=sender_id,
            message=masked_content,
            is_masked=enable_masking and len(masked_items) > 0,
            created_at=datetime.utcnow()
        )
        
        self.db.add(db_message)
        self.db.commit()
        self.db.refresh(db_message)
        
        # Create response message
        chat_message = ChatMessage(
            id=db_message.id,
            match_id=match_id,
            sender_id=sender_id,
            sender_name=sender.full_name or sender.email,
            message_type=message_type,
            content=masked_content,
            metadata=metadata or {},
            timestamp=db_message.created_at,
            is_masked=db_message.is_masked
        )
        
        return chat_message
    
    async def get_chat_history(
        self, 
        match_id: int, 
        user_id: int, 
        limit: int = 50, 
        offset: int = 0
    ) -> List[ChatMessage]:
        """Get chat history for a match"""
        
        # Verify user has access to this match
        match = self.db.query(Match).filter(
            Match.id == match_id,
            or_(
                Match.lost_item.has(Item.owner_id == user_id),
                Match.found_item.has(Item.owner_id == user_id)
            )
        ).first()
        
        if not match:
            raise HTTPException(status_code=403, detail="Access denied to this chat")
        
        # Get messages
        db_messages = self.db.query(ChatMessage).filter(
            ChatMessage.match_id == match_id
        ).order_by(ChatMessage.created_at.desc()).offset(offset).limit(limit).all()
        
        # Convert to chat messages
        messages = []
        for db_msg in reversed(db_messages):  # Reverse to get chronological order
            sender = self.db.query(User).filter(User.id == db_msg.sender_id).first()
            
            messages.append(ChatMessage(
                id=db_msg.id,
                match_id=db_msg.match_id,
                sender_id=db_msg.sender_id,
                sender_name=sender.full_name or sender.email if sender else "Unknown",
                message_type=MessageType.TEXT,
                content=db_msg.message,
                metadata={},
                timestamp=db_msg.created_at,
                is_masked=db_msg.is_masked
            ))
        
        return messages
    
    async def mark_messages_as_read(self, match_id: int, user_id: int, message_ids: List[int]):
        """Mark messages as read by a user"""
        # This would update a read_receipts table
        # For now, just broadcast the read receipt event
        
        await connection_manager.broadcast_event(
            match_id,
            ChatEvent(
                event_type=ChatEventType.MESSAGE_READ,
                match_id=match_id,
                user_id=user_id,
                data={"message_ids": message_ids},
                timestamp=datetime.utcnow()
            ),
            exclude_user=user_id
        )

async def websocket_endpoint(
    websocket: WebSocket,
    match_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """WebSocket endpoint for real-time chat"""
    
    # Verify user has access to this match
    match = db.query(Match).filter(
        Match.id == match_id,
        or_(
            Match.lost_item.has(Item.owner_id == current_user.id),
            Match.found_item.has(Item.owner_id == current_user.id)
        )
    ).first()
    
    if not match:
        await websocket.close(code=4003, reason="Access denied")
        return
    
    chat_service = ChatService(db)
    
    try:
        await connection_manager.connect(websocket, match_id, current_user.id)
        
        while True:
            # Receive message from WebSocket
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            message_type = message_data.get("type")
            
            if message_type == "message":
                # Handle chat message
                content = message_data.get("content", "")
                msg_type = MessageType(message_data.get("message_type", "text"))
                metadata = message_data.get("metadata", {})
                
                # Save message
                chat_message = await chat_service.save_message(
                    match_id=match_id,
                    sender_id=current_user.id,
                    content=content,
                    message_type=msg_type,
                    metadata=metadata
                )
                
                # Broadcast to other users
                message_payload = {
                    "type": "message",
                    "data": asdict(chat_message)
                }
                
                await connection_manager.broadcast_to_match(
                    match_id, 
                    message_payload, 
                    exclude_user=current_user.id
                )
            
            elif message_type == "typing":
                # Handle typing indicator
                is_typing = message_data.get("is_typing", False)
                await connection_manager.handle_typing_indicator(
                    match_id, 
                    current_user.id, 
                    current_user.full_name or current_user.email,
                    is_typing
                )
            
            elif message_type == "read_receipt":
                # Handle read receipts
                message_ids = message_data.get("message_ids", [])
                await chat_service.mark_messages_as_read(match_id, current_user.id, message_ids)
    
    except WebSocketDisconnect:
        await connection_manager.disconnect(match_id, current_user.id)
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        await connection_manager.disconnect(match_id, current_user.id)

# Initialize Redis connection on startup
async def initialize_chat_system():
    """Initialize the chat system"""
    await connection_manager.initialize_redis()
    logger.info("Chat system initialized")
