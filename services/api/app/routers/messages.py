"""Messages and conversations routes."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, and_, func
from typing import List, Optional
from uuid import uuid4, UUID
import logging

from ..database import get_db
from ..models import User, Conversation, Message
from ..schemas import MessageCreate, MessageDetail, ConversationSummary, ConversationDetail
from ..dependencies import get_current_user

router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/conversations", status_code=status.HTTP_201_CREATED)
async def create_conversation(
    participant_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new conversation between two users."""
    # Check if conversation already exists
    participant_ids = sorted([current_user.id, UUID(participant_id)])
    
    result = await db.execute(
        select(Conversation).where(
            or_(
                and_(
                    Conversation.participant_one_id == participant_ids[0],
                    Conversation.participant_two_id == participant_ids[1]
                ),
                and_(
                    Conversation.participant_one_id == participant_ids[1],
                    Conversation.participant_two_id == participant_ids[0]
                )
            )
        )
    )
    conversation = result.scalar_one_or_none()
    
    if conversation:
        return {"id": conversation.id, "message": "Conversation already exists"}
    
    # Create new conversation
    conversation = Conversation(
        id=str(uuid4()),
        participant_one_id=participant_ids[0],
        participant_two_id=participant_ids[1]
    )
    
    db.add(conversation)
    await db.commit()
    await db.refresh(conversation)
    
    logger.info(f"Created conversation {conversation.id} between {current_user.id} and {participant_id}")
    
    return {"id": conversation.id, "message": "Conversation created successfully"}


@router.get("/conversations", response_model=List[ConversationSummary])
async def list_conversations(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List all conversations for the current user."""
    result = await db.execute(
        select(Conversation).where(
            or_(
                Conversation.participant_one_id == current_user.id,
                Conversation.participant_two_id == current_user.id
            )
        ).order_by(Conversation.updated_at.desc())
    )
    conversations = result.scalars().all()
    
    # Build response with last message and unread count
    conversation_summaries = []
    for conv in conversations:
        # Get last message
        last_msg_result = await db.execute(
            select(Message)
            .where(Message.conversation_id == conv.id)
            .order_by(Message.created_at.desc())
            .limit(1)
        )
        last_message = last_msg_result.scalar_one_or_none()
        
        # Get unread count
        unread_result = await db.execute(
            select(func.count(Message.id))
            .where(
                Message.conversation_id == conv.id,
                Message.sender_id != current_user.id,
                Message.is_read == False
            )
        )
        unread_count = unread_result.scalar()
        
        conversation_summaries.append(
            ConversationSummary(
                id=conv.id,
                match_id=conv.match_id,
                participant_one_id=conv.participant_one_id,
                participant_two_id=conv.participant_two_id,
                last_message=MessageDetail.from_orm(last_message) if last_message else None,
                unread_count=unread_count,
                updated_at=conv.updated_at
            )
        )
    
    return conversation_summaries


@router.get("/conversations/{conversation_id}", response_model=ConversationDetail)
async def get_conversation(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific conversation with all messages."""
    result = await db.execute(
        select(Conversation).where(Conversation.id == conversation_id)
    )
    conversation = result.scalar_one_or_none()
    
    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found"
        )
    
    # Verify user is a participant
    if conversation.participant_one_id != current_user.id and conversation.participant_two_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this conversation"
        )
    
    # Get all messages
    messages_result = await db.execute(
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .order_by(Message.created_at.asc())
    )
    messages = messages_result.scalars().all()
    
    return ConversationDetail(
        id=conversation.id,
        match_id=conversation.match_id,
        participant_one_id=conversation.participant_one_id,
        participant_two_id=conversation.participant_two_id,
        messages=[MessageDetail.from_orm(msg) for msg in messages],
        created_at=conversation.created_at,
        updated_at=conversation.updated_at
    )


@router.post("/conversations/{conversation_id}/messages", response_model=MessageDetail, status_code=status.HTTP_201_CREATED)
async def send_message(
    conversation_id: str,
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Send a message in a conversation."""
    # Verify conversation exists and user is a participant
    result = await db.execute(
        select(Conversation).where(Conversation.id == conversation_id)
    )
    conversation = result.scalar_one_or_none()
    
    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found"
        )
    
    if conversation.participant_one_id != current_user.id and conversation.participant_two_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to send messages in this conversation"
        )
    
    # Create message
    message = Message(
        id=str(uuid4()),
        conversation_id=conversation_id,
        sender_id=current_user.id,
        content=message_data.content,
        is_read=False
    )
    
    db.add(message)
    
    # Update conversation timestamp
    conversation.updated_at = func.now()
    
    await db.commit()
    await db.refresh(message)
    
    logger.info(f"Message sent in conversation {conversation_id} by user {current_user.id}")
    
    return MessageDetail.from_orm(message)


@router.get("/conversations/{conversation_id}/messages", response_model=List[MessageDetail])
async def get_messages(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    limit: int = 50,
    offset: int = 0
):
    """Get messages from a conversation with pagination."""
    # Verify user is a participant
    result = await db.execute(
        select(Conversation).where(Conversation.id == conversation_id)
    )
    conversation = result.scalar_one_or_none()
    
    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found"
        )
    
    if conversation.participant_one_id != current_user.id and conversation.participant_two_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this conversation"
        )
    
    # Get messages
    result = await db.execute(
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .order_by(Message.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    messages = result.scalars().all()
    
    return [MessageDetail.from_orm(msg) for msg in reversed(messages)]


@router.patch("/messages/{message_id}/read", response_model=MessageDetail)
async def mark_message_read(
    message_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Mark a message as read."""
    result = await db.execute(
        select(Message).where(Message.id == message_id)
    )
    message = result.scalar_one_or_none()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )
    
    # Verify user is the recipient (not the sender)
    result = await db.execute(
        select(Conversation).where(Conversation.id == message.conversation_id)
    )
    conversation = result.scalar_one_or_none()
    
    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found"
        )
    
    is_participant = (
        conversation.participant_one_id == current_user.id or
        conversation.participant_two_id == current_user.id
    )
    
    if not is_participant or message.sender_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to mark this message as read"
        )
    
    message.is_read = True
    await db.commit()
    await db.refresh(message)
    
    return MessageDetail.from_orm(message)

