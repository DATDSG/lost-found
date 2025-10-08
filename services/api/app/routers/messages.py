"""Messages routes for chat functionality."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, desc
from typing import List, Optional
from uuid import uuid4
from datetime import datetime

from ..database import get_db
from ..models import User, Message, Conversation, Match
from ..schemas import MessageCreate, MessageDetail, ConversationDetail, ConversationSummary
from ..dependencies import get_current_user
import logging

router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/", response_model=MessageDetail, status_code=status.HTTP_201_CREATED)
async def send_message(
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Send a message in a conversation."""
    # Verify conversation exists
    result = await db.execute(
        select(Conversation).where(Conversation.id == message_data.conversation_id)
    )
    conversation = result.scalar_one_or_none()
    
    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found"
        )
    
    # Verify user is a participant
    if (conversation.participant_one_id != current_user.id and 
        conversation.participant_two_id != current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to send messages in this conversation"
        )
    
    # Create message
    message = Message(
        id=str(uuid4()),
        conversation_id=message_data.conversation_id,
        sender_id=current_user.id,
        content=message_data.content,
        is_read=False
    )
    
    db.add(message)
    
    # Update conversation timestamp
    conversation.updated_at = datetime.utcnow()
    
    await db.commit()
    await db.refresh(message)
    
    logger.info(f"Message sent in conversation {message_data.conversation_id} by user {current_user.id}")
    
    return message


@router.get("/{conversation_id}", response_model=ConversationDetail)
async def get_conversation(
    conversation_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get messages in a conversation with pagination."""
    # Verify conversation exists and user is participant
    result = await db.execute(
        select(Conversation).where(Conversation.id == conversation_id)
    )
    conversation = result.scalar_one_or_none()
    
    if not conversation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found"
        )
    
    if (conversation.participant_one_id != current_user.id and 
        conversation.participant_two_id != current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this conversation"
        )
    
    # Get messages with pagination
    offset = (page - 1) * page_size
    
    result = await db.execute(
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .order_by(desc(Message.created_at))
        .offset(offset)
        .limit(page_size)
    )
    messages = result.scalars().all()
    
    # Mark messages as read for current user
    for message in messages:
        if message.sender_id != current_user.id and not message.is_read:
            message.is_read = True
    
    await db.commit()
    
    return {
        "id": conversation.id,
        "match_id": conversation.match_id,
        "participant_one_id": conversation.participant_one_id,
        "participant_two_id": conversation.participant_two_id,
        "messages": messages,
        "created_at": conversation.created_at,
        "updated_at": conversation.updated_at
    }


@router.get("/", response_model=List[ConversationSummary])
async def list_conversations(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List all conversations for the current user."""
    offset = (page - 1) * page_size
    
    result = await db.execute(
        select(Conversation)
        .where(
            or_(
                Conversation.participant_one_id == current_user.id,
                Conversation.participant_two_id == current_user.id
            )
        )
        .order_by(desc(Conversation.updated_at))
        .offset(offset)
        .limit(page_size)
    )
    conversations = result.scalars().all()
    
    # Get last message for each conversation
    conversation_summaries = []
    for conv in conversations:
        # Get last message
        result = await db.execute(
            select(Message)
            .where(Message.conversation_id == conv.id)
            .order_by(desc(Message.created_at))
            .limit(1)
        )
        last_message = result.scalar_one_or_none()
        
        # Count unread messages
        result = await db.execute(
            select(Message)
            .where(
                and_(
                    Message.conversation_id == conv.id,
                    Message.sender_id != current_user.id,
                    Message.is_read == False
                )
            )
        )
        unread_count = len(result.scalars().all())
        
        conversation_summaries.append({
            "id": conv.id,
            "match_id": conv.match_id,
            "participant_one_id": conv.participant_one_id,
            "participant_two_id": conv.participant_two_id,
            "last_message": last_message,
            "unread_count": unread_count,
            "updated_at": conv.updated_at
        })
    
    return conversation_summaries


@router.post("/conversation/create", response_model=ConversationDetail)
async def create_conversation(
    match_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a conversation for a match."""
    # Verify match exists
    result = await db.execute(
        select(Match).where(Match.id == match_id)
    )
    match = result.scalar_one_or_none()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )
    
    # Get participants from match reports
    participant_one = match.source_report.owner_id
    participant_two = match.target_report.owner_id
    
    # Verify current user is one of the participants
    if current_user.id not in [participant_one, participant_two]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create conversation for this match"
        )
    
    # Check if conversation already exists
    result = await db.execute(
        select(Conversation).where(Conversation.match_id == match_id)
    )
    existing = result.scalar_one_or_none()
    
    if existing:
        return {
            "id": existing.id,
            "match_id": existing.match_id,
            "participant_one_id": existing.participant_one_id,
            "participant_two_id": existing.participant_two_id,
            "messages": [],
            "created_at": existing.created_at,
            "updated_at": existing.updated_at
        }
    
    # Create new conversation
    conversation = Conversation(
        id=str(uuid4()),
        match_id=match_id,
        participant_one_id=participant_one,
        participant_two_id=participant_two
    )
    
    db.add(conversation)
    await db.commit()
    await db.refresh(conversation)
    
    logger.info(f"Conversation created for match {match_id}")
    
    return {
        "id": conversation.id,
        "match_id": conversation.match_id,
        "participant_one_id": conversation.participant_one_id,
        "participant_two_id": conversation.participant_two_id,
        "messages": [],
        "created_at": conversation.created_at,
        "updated_at": conversation.updated_at
    }


@router.patch("/{message_id}/read", response_model=MessageDetail)
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
    
    if (conversation.participant_one_id != current_user.id and 
        conversation.participant_two_id != current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized"
        )
    
    if message.sender_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot mark own message as read"
        )
    
    message.is_read = True
    await db.commit()
    await db.refresh(message)
    
    return message
