"""WebSocket routes for real-time messaging and notifications."""
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Dict, Set
import json
import logging
from datetime import datetime

from ..database import get_db
from ..models import User, Conversation, Message
from ..auth import decode_token

router = APIRouter()
logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manages WebSocket connections for users."""
    
    def __init__(self):
        # user_id -> set of WebSocket connections
        self.active_connections: Dict[str, Set[WebSocket]] = {}
        # conversation_id -> set of user_ids
        self.conversation_participants: Dict[str, Set[str]] = {}
    
    async def connect(self, websocket: WebSocket, user_id: str):
        """Accept and register a new WebSocket connection."""
        await websocket.accept()
        
        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()
        
        self.active_connections[user_id].add(websocket)
        logger.info(f"WebSocket connected for user {user_id}. Total connections: {len(self.active_connections[user_id])}")
    
    def disconnect(self, websocket: WebSocket, user_id: str):
        """Remove a WebSocket connection."""
        if user_id in self.active_connections:
            self.active_connections[user_id].discard(websocket)
            
            # Clean up if no more connections
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        
        logger.info(f"WebSocket disconnected for user {user_id}")
    
    async def send_personal_message(self, message: dict, user_id: str):
        """Send a message to a specific user (all their connections)."""
        if user_id in self.active_connections:
            disconnected = set()
            
            for connection in self.active_connections[user_id]:
                try:
                    await connection.send_json(message)
                except Exception as e:
                    logger.error(f"Error sending message to user {user_id}: {e}")
                    disconnected.add(connection)
            
            # Clean up dead connections
            for connection in disconnected:
                self.active_connections[user_id].discard(connection)
    
    async def broadcast_to_conversation(self, message: dict, conversation_id: str, exclude_user: str = None):
        """Broadcast a message to all participants in a conversation."""
        if conversation_id in self.conversation_participants:
            for user_id in self.conversation_participants[conversation_id]:
                if exclude_user and user_id == exclude_user:
                    continue
                await self.send_personal_message(message, user_id)
    
    def join_conversation(self, user_id: str, conversation_id: str):
        """Register a user as participant in a conversation."""
        if conversation_id not in self.conversation_participants:
            self.conversation_participants[conversation_id] = set()
        
        self.conversation_participants[conversation_id].add(user_id)
        logger.info(f"User {user_id} joined conversation {conversation_id}")
    
    def leave_conversation(self, user_id: str, conversation_id: str):
        """Remove a user from a conversation."""
        if conversation_id in self.conversation_participants:
            self.conversation_participants[conversation_id].discard(user_id)
            
            # Clean up if no more participants
            if not self.conversation_participants[conversation_id]:
                del self.conversation_participants[conversation_id]
        
        logger.info(f"User {user_id} left conversation {conversation_id}")


# Global connection manager
manager = ConnectionManager()


async def get_current_user_ws(token: str, db: AsyncSession) -> User:
    """Authenticate WebSocket connection using JWT token."""
    payload = decode_token(token)
    
    if payload is None or payload.get("type") != "access":
        raise ValueError("Invalid token")
    
    user_id = payload.get("sub")
    if not user_id:
        raise ValueError("Invalid token")
    
    result = await db.execute(
        select(User).where(User.id == user_id, User.is_active == True)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise ValueError("User not found")
    
    return user


@router.websocket("/ws/chat")
async def websocket_chat_endpoint(
    websocket: WebSocket,
    token: str = Query(..., description="JWT access token")
):
    """
    WebSocket endpoint for real-time chat.
    
    Client connects with: ws://localhost:8000/ws/chat?token=YOUR_JWT_TOKEN
    
    Message format from client:
    {
        "type": "message",
        "conversation_id": "conv-id",
        "content": "Hello!"
    }
    
    Message format to client:
    {
        "type": "message",
        "conversation_id": "conv-id",
        "message_id": "msg-id",
        "sender_id": "user-id",
        "content": "Hello!",
        "created_at": "2024-01-01T00:00:00Z"
    }
    
    Control messages:
    - {"type": "ping"} → {"type": "pong"}
    - {"type": "join", "conversation_id": "..."} → Join conversation
    - {"type": "leave", "conversation_id": "..."} → Leave conversation
    """
    db_session = None
    user = None
    
    try:
        # Get database session
        from ..database import AsyncSessionLocal
        db_session = AsyncSessionLocal()
        
        # Authenticate user
        try:
            user = await get_current_user_ws(token, db_session)
        except Exception as e:
            logger.error(f"WebSocket authentication failed: {e}")
            await websocket.close(code=1008, reason="Authentication failed")
            return
        
        # Connect user
        await manager.connect(websocket, str(user.id))
        
        # Send welcome message
        await websocket.send_json({
            "type": "connected",
            "user_id": str(user.id),
            "timestamp": datetime.utcnow().isoformat()
        })
        
        # Message handling loop
        while True:
            try:
                # Receive message from client
                data = await websocket.receive_json()
                message_type = data.get("type")
                
                if message_type == "ping":
                    # Respond to ping
                    await websocket.send_json({"type": "pong", "timestamp": datetime.utcnow().isoformat()})
                
                elif message_type == "join":
                    # Join a conversation
                    conversation_id = data.get("conversation_id")
                    if conversation_id:
                        # Verify user is participant
                        result = await db_session.execute(
                            select(Conversation).where(Conversation.id == conversation_id)
                        )
                        conversation = result.scalar_one_or_none()
                        
                        if conversation and (
                            conversation.participant_one_id == user.id or
                            conversation.participant_two_id == user.id
                        ):
                            manager.join_conversation(str(user.id), conversation_id)
                            await websocket.send_json({
                                "type": "joined",
                                "conversation_id": conversation_id
                            })
                        else:
                            await websocket.send_json({
                                "type": "error",
                                "message": "Not authorized to join this conversation"
                            })
                
                elif message_type == "leave":
                    # Leave a conversation
                    conversation_id = data.get("conversation_id")
                    if conversation_id:
                        manager.leave_conversation(str(user.id), conversation_id)
                        await websocket.send_json({
                            "type": "left",
                            "conversation_id": conversation_id
                        })
                
                elif message_type == "message":
                    # Send a message in a conversation
                    conversation_id = data.get("conversation_id")
                    content = data.get("content")
                    
                    if not conversation_id or not content:
                        await websocket.send_json({
                            "type": "error",
                            "message": "Missing conversation_id or content"
                        })
                        continue
                    
                    # Verify user is participant
                    result = await db_session.execute(
                        select(Conversation).where(Conversation.id == conversation_id)
                    )
                    conversation = result.scalar_one_or_none()
                    
                    if not conversation:
                        await websocket.send_json({
                            "type": "error",
                            "message": "Conversation not found"
                        })
                        continue
                    
                    if (conversation.participant_one_id != user.id and
                        conversation.participant_two_id != user.id):
                        await websocket.send_json({
                            "type": "error",
                            "message": "Not authorized to send messages in this conversation"
                        })
                        continue
                    
                    # Create message in database
                    from uuid import uuid4
                    from sqlalchemy import func
                    
                    message = Message(
                        id=str(uuid4()),
                        conversation_id=conversation_id,
                        sender_id=user.id,
                        content=content,
                        is_read=False
                    )
                    db_session.add(message)
                    
                    # Update conversation timestamp
                    conversation.updated_at = func.now()
                    
                    await db_session.commit()
                    await db_session.refresh(message)
                    
                    # Broadcast to all participants in the conversation
                    message_data = {
                        "type": "message",
                        "conversation_id": conversation_id,
                        "message_id": message.id,
                        "sender_id": str(user.id),
                        "content": content,
                        "created_at": message.created_at.isoformat(),
                        "is_read": False
                    }
                    
                    # Send to both participants
                    other_user_id = (
                        conversation.participant_two_id
                        if conversation.participant_one_id == user.id
                        else conversation.participant_one_id
                    )
                    
                    await manager.send_personal_message(message_data, str(user.id))
                    await manager.send_personal_message(message_data, str(other_user_id))
                
                else:
                    await websocket.send_json({
                        "type": "error",
                        "message": f"Unknown message type: {message_type}"
                    })
            
            except WebSocketDisconnect:
                break
            except json.JSONDecodeError:
                await websocket.send_json({
                    "type": "error",
                    "message": "Invalid JSON"
                })
            except Exception as e:
                logger.error(f"Error processing WebSocket message: {e}")
                await websocket.send_json({
                    "type": "error",
                    "message": "Internal server error"
                })
    
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
    
    finally:
        # Cleanup
        if user:
            manager.disconnect(websocket, str(user.id))
        
        if db_session:
            await db_session.close()


@router.websocket("/ws/notifications")
async def websocket_notifications_endpoint(
    websocket: WebSocket,
    token: str = Query(..., description="JWT access token")
):
    """
    WebSocket endpoint for real-time notifications.
    
    Client connects with: ws://localhost:8000/ws/notifications?token=YOUR_JWT_TOKEN
    
    Message format to client:
    {
        "type": "notification",
        "notification_id": "notif-id",
        "title": "Match Found",
        "content": "We found a match for your report",
        "reference_id": "report-id",
        "created_at": "2024-01-01T00:00:00Z"
    }
    """
    db_session = None
    user = None
    
    try:
        # Get database session
        from ..database import AsyncSessionLocal
        db_session = AsyncSessionLocal()
        
        # Authenticate user
        try:
            user = await get_current_user_ws(token, db_session)
        except Exception as e:
            logger.error(f"WebSocket authentication failed: {e}")
            await websocket.close(code=1008, reason="Authentication failed")
            return
        
        # Connect user
        await manager.connect(websocket, str(user.id))
        
        # Send welcome message
        await websocket.send_json({
            "type": "connected",
            "user_id": str(user.id),
            "channel": "notifications"
        })
        
        # Keep connection alive with ping/pong
        while True:
            try:
                data = await websocket.receive_json()
                
                if data.get("type") == "ping":
                    await websocket.send_json({"type": "pong"})
            
            except WebSocketDisconnect:
                break
            except Exception as e:
                logger.error(f"Error in notifications WebSocket: {e}")
                break
    
    finally:
        if user:
            manager.disconnect(websocket, str(user.id))
        
        if db_session:
            await db_session.close()

