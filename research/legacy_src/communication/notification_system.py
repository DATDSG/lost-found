"""
Multi-language Notification System
Email, SMS, and push notifications with template management
"""

import asyncio
import json
from datetime import datetime
from typing import Dict, List, Optional, Any, Union
from dataclasses import dataclass, asdict
from enum import Enum
import logging
from pathlib import Path

from sqlalchemy.orm import Session
from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, JSON, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from jinja2 import Environment, FileSystemLoader, Template
import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from twilio.rest import Client as TwilioClient
import boto3

from app.db.models import User, Item, Match, Notification
from src.config.backend_enhancements import auth_config

logger = logging.getLogger(__name__)

class NotificationType(Enum):
    """Types of notifications"""
    MATCH_FOUND = "match_found"
    CLAIM_SUBMITTED = "claim_submitted"
    CLAIM_APPROVED = "claim_approved"
    CLAIM_REJECTED = "claim_rejected"
    MESSAGE_RECEIVED = "message_received"
    ITEM_EXPIRED = "item_expired"
    SYSTEM_ANNOUNCEMENT = "system_announcement"
    SECURITY_ALERT = "security_alert"
    BACKUP_COMPLETED = "backup_completed"
    MAINTENANCE_NOTICE = "maintenance_notice"

class NotificationChannel(Enum):
    """Notification delivery channels"""
    EMAIL = "email"
    SMS = "sms"
    PUSH = "push"
    IN_APP = "in_app"
    WEBHOOK = "webhook"

class NotificationPriority(Enum):
    """Notification priority levels"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

@dataclass
class NotificationTemplate:
    """Notification template structure"""
    id: str
    type: NotificationType
    language: str
    channel: NotificationChannel
    subject_template: str
    body_template: str
    metadata: Dict[str, Any]

@dataclass
class NotificationRequest:
    """Notification request structure"""
    user_id: int
    type: NotificationType
    priority: NotificationPriority
    channels: List[NotificationChannel]
    data: Dict[str, Any]
    scheduled_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None

@dataclass
class NotificationResult:
    """Notification delivery result"""
    success: bool
    channel: NotificationChannel
    message_id: Optional[str]
    error: Optional[str]
    delivered_at: datetime

class TemplateManager:
    """Manages notification templates with multi-language support"""
    
    def __init__(self, templates_dir: str = "templates/notifications"):
        self.templates_dir = Path(templates_dir)
        self.templates: Dict[str, NotificationTemplate] = {}
        self.jinja_env = Environment(
            loader=FileSystemLoader(str(self.templates_dir)),
            autoescape=True
        )
        self._load_templates()
    
    def _load_templates(self):
        """Load all notification templates"""
        # Create default templates if directory doesn't exist
        if not self.templates_dir.exists():
            self.templates_dir.mkdir(parents=True, exist_ok=True)
            self._create_default_templates()
        
        # Load templates from files
        for template_file in self.templates_dir.glob("*.json"):
            try:
                with open(template_file, 'r', encoding='utf-8') as f:
                    template_data = json.load(f)
                    
                template = NotificationTemplate(**template_data)
                template_key = f"{template.type.value}_{template.language}_{template.channel.value}"
                self.templates[template_key] = template
                
            except Exception as e:
                logger.error(f"Error loading template {template_file}: {e}")
    
    def _create_default_templates(self):
        """Create default notification templates"""
        default_templates = [
            # Match Found - English
            {
                "id": "match_found_en_email",
                "type": "match_found",
                "language": "en",
                "channel": "email",
                "subject_template": "Potential Match Found for Your {{ item_type }} Item",
                "body_template": """
                <h2>Great news! We found a potential match for your {{ item_type }} item.</h2>
                
                <h3>Your Item:</h3>
                <p><strong>{{ your_item.title }}</strong></p>
                <p>{{ your_item.description }}</p>
                
                <h3>Potential Match:</h3>
                <p><strong>{{ match_item.title }}</strong></p>
                <p>{{ match_item.description }}</p>
                
                <h3>Match Details:</h3>
                <ul>
                    <li>Match Score: {{ match_score }}%</li>
                    <li>Distance: {{ distance_km }} km away</li>
                    <li>Posted: {{ match_item.created_at }}</li>
                </ul>
                
                <p><a href="{{ match_url }}" style="background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">View Match Details</a></p>
                
                <p>Best regards,<br>Lost & Found Team</p>
                """,
                "metadata": {"priority": "high", "category": "matching"}
            },
            
            # Match Found - Sinhala
            {
                "id": "match_found_si_email",
                "type": "match_found",
                "language": "si",
                "channel": "email",
                "subject_template": "ඔබගේ {{ item_type }} භාණ්ඩය සඳහා ගැලපීමක් හමු විය",
                "body_template": """
                <h2>සුභ පුවත! ඔබගේ {{ item_type }} භාණ්ඩය සඳහා ගැලපීමක් අපට හමු විය.</h2>
                
                <h3>ඔබගේ භාණ්ඩය:</h3>
                <p><strong>{{ your_item.title }}</strong></p>
                <p>{{ your_item.description }}</p>
                
                <h3>ගැලපෙන භාණ්ඩය:</h3>
                <p><strong>{{ match_item.title }}</strong></p>
                <p>{{ match_item.description }}</p>
                
                <h3>ගැලපීමේ විස්තර:</h3>
                <ul>
                    <li>ගැලපීමේ ලකුණු: {{ match_score }}%</li>
                    <li>දුර: කිලෝමීටර {{ distance_km }}</li>
                    <li>පළ කළ දිනය: {{ match_item.created_at }}</li>
                </ul>
                
                <p><a href="{{ match_url }}" style="background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">ගැලපීමේ විස්තර බලන්න</a></p>
                
                <p>ස්තුතියි,<br>Lost & Found කණ්ඩායම</p>
                """,
                "metadata": {"priority": "high", "category": "matching"}
            },
            
            # SMS Templates
            {
                "id": "match_found_en_sms",
                "type": "match_found",
                "language": "en",
                "channel": "sms",
                "subject_template": "",
                "body_template": "Lost & Found: Potential match found for your {{ item_type }}! Match score: {{ match_score }}%. Check the app for details. {{ short_url }}",
                "metadata": {"priority": "high", "max_length": 160}
            },
            
            # Claim Submitted
            {
                "id": "claim_submitted_en_email",
                "type": "claim_submitted",
                "language": "en",
                "channel": "email",
                "subject_template": "Claim Submitted for Your {{ item_type }}",
                "body_template": """
                <h2>Someone has submitted a claim for your {{ item_type }}.</h2>
                
                <h3>Item Details:</h3>
                <p><strong>{{ item.title }}</strong></p>
                <p>{{ item.description }}</p>
                
                <h3>Claimant Information:</h3>
                <p>A user has provided evidence to claim this item. Please review the claim and verify the evidence provided.</p>
                
                <p><a href="{{ claim_url }}" style="background-color: #28a745; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Review Claim</a></p>
                
                <p><strong>Important:</strong> Please verify the claimant's identity and evidence before approving the claim.</p>
                
                <p>Best regards,<br>Lost & Found Team</p>
                """,
                "metadata": {"priority": "high", "category": "claims"}
            }
        ]
        
        # Save default templates
        for template_data in default_templates:
            filename = f"{template_data['id']}.json"
            filepath = self.templates_dir / filename
            
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(template_data, f, indent=2, ensure_ascii=False)
    
    def get_template(
        self, 
        notification_type: NotificationType, 
        language: str, 
        channel: NotificationChannel
    ) -> Optional[NotificationTemplate]:
        """Get notification template"""
        template_key = f"{notification_type.value}_{language}_{channel.value}"
        
        # Try exact match first
        if template_key in self.templates:
            return self.templates[template_key]
        
        # Fallback to English if language not found
        fallback_key = f"{notification_type.value}_en_{channel.value}"
        if fallback_key in self.templates:
            logger.warning(f"Template not found for {language}, using English fallback")
            return self.templates[fallback_key]
        
        logger.error(f"No template found for {template_key}")
        return None
    
    def render_template(self, template: NotificationTemplate, data: Dict[str, Any]) -> tuple[str, str]:
        """Render notification template with data"""
        try:
            # Render subject
            subject_template = Template(template.subject_template)
            subject = subject_template.render(**data)
            
            # Render body
            body_template = Template(template.body_template)
            body = body_template.render(**data)
            
            return subject, body
            
        except Exception as e:
            logger.error(f"Error rendering template {template.id}: {e}")
            return "Notification", "Error rendering notification content"

class EmailService:
    """Email notification service"""
    
    def __init__(self):
        self.smtp_host = auth_config.SMTP_HOST
        self.smtp_port = auth_config.SMTP_PORT
        self.smtp_username = auth_config.SMTP_USERNAME
        self.smtp_password = auth_config.SMTP_PASSWORD
        self.smtp_use_tls = auth_config.SMTP_USE_TLS
    
    async def send_email(
        self, 
        to_email: str, 
        subject: str, 
        body: str, 
        is_html: bool = True
    ) -> NotificationResult:
        """Send email notification"""
        try:
            # Create message
            message = MIMEMultipart("alternative")
            message["Subject"] = subject
            message["From"] = self.smtp_username
            message["To"] = to_email
            
            # Add body
            if is_html:
                html_part = MIMEText(body, "html")
                message.attach(html_part)
            else:
                text_part = MIMEText(body, "plain")
                message.attach(text_part)
            
            # Send email
            async with aiosmtplib.SMTP(
                hostname=self.smtp_host,
                port=self.smtp_port,
                use_tls=self.smtp_use_tls
            ) as server:
                if self.smtp_username and self.smtp_password:
                    await server.login(self.smtp_username, self.smtp_password)
                
                await server.send_message(message)
            
            return NotificationResult(
                success=True,
                channel=NotificationChannel.EMAIL,
                message_id=message["Message-ID"],
                error=None,
                delivered_at=datetime.utcnow()
            )
            
        except Exception as e:
            logger.error(f"Email sending failed: {e}")
            return NotificationResult(
                success=False,
                channel=NotificationChannel.EMAIL,
                message_id=None,
                error=str(e),
                delivered_at=datetime.utcnow()
            )

class SMSService:
    """SMS notification service"""
    
    def __init__(self):
        self.twilio_client = None
        self.sns_client = None
        
        # Initialize Twilio if configured
        if auth_config.TWILIO_ACCOUNT_SID and auth_config.TWILIO_AUTH_TOKEN:
            self.twilio_client = TwilioClient(
                auth_config.TWILIO_ACCOUNT_SID,
                auth_config.TWILIO_AUTH_TOKEN
            )
        
        # Initialize AWS SNS if configured
        if auth_config.AWS_ACCESS_KEY_ID and auth_config.AWS_SECRET_ACCESS_KEY:
            self.sns_client = boto3.client(
                'sns',
                aws_access_key_id=auth_config.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=auth_config.AWS_SECRET_ACCESS_KEY,
                region_name=auth_config.AWS_REGION
            )
    
    async def send_sms(self, to_phone: str, message: str) -> NotificationResult:
        """Send SMS notification"""
        # Try Twilio first
        if self.twilio_client:
            return await self._send_twilio_sms(to_phone, message)
        
        # Fallback to AWS SNS
        elif self.sns_client:
            return await self._send_sns_sms(to_phone, message)
        
        else:
            return NotificationResult(
                success=False,
                channel=NotificationChannel.SMS,
                message_id=None,
                error="No SMS service configured",
                delivered_at=datetime.utcnow()
            )
    
    async def _send_twilio_sms(self, to_phone: str, message: str) -> NotificationResult:
        """Send SMS via Twilio"""
        try:
            message_obj = self.twilio_client.messages.create(
                body=message,
                from_=auth_config.TWILIO_PHONE_NUMBER,
                to=to_phone
            )
            
            return NotificationResult(
                success=True,
                channel=NotificationChannel.SMS,
                message_id=message_obj.sid,
                error=None,
                delivered_at=datetime.utcnow()
            )
            
        except Exception as e:
            logger.error(f"Twilio SMS failed: {e}")
            return NotificationResult(
                success=False,
                channel=NotificationChannel.SMS,
                message_id=None,
                error=str(e),
                delivered_at=datetime.utcnow()
            )
    
    async def _send_sns_sms(self, to_phone: str, message: str) -> NotificationResult:
        """Send SMS via AWS SNS"""
        try:
            response = self.sns_client.publish(
                PhoneNumber=to_phone,
                Message=message
            )
            
            return NotificationResult(
                success=True,
                channel=NotificationChannel.SMS,
                message_id=response['MessageId'],
                error=None,
                delivered_at=datetime.utcnow()
            )
            
        except Exception as e:
            logger.error(f"SNS SMS failed: {e}")
            return NotificationResult(
                success=False,
                channel=NotificationChannel.SMS,
                message_id=None,
                error=str(e),
                delivered_at=datetime.utcnow()
            )

class PushNotificationService:
    """Push notification service (placeholder for future implementation)"""
    
    async def send_push(self, user_token: str, title: str, body: str) -> NotificationResult:
        """Send push notification"""
        # This would integrate with Firebase Cloud Messaging, Apple Push Notification Service, etc.
        logger.info(f"Push notification: {title} - {body}")
        
        return NotificationResult(
            success=True,
            channel=NotificationChannel.PUSH,
            message_id="push_placeholder",
            error=None,
            delivered_at=datetime.utcnow()
        )

class NotificationService:
    """Main notification service orchestrator"""
    
    def __init__(self, db: Session):
        self.db = db
        self.template_manager = TemplateManager()
        self.email_service = EmailService()
        self.sms_service = SMSService()
        self.push_service = PushNotificationService()
    
    async def send_notification(self, request: NotificationRequest) -> List[NotificationResult]:
        """Send notification via multiple channels"""
        results = []
        
        # Get user information
        user = self.db.query(User).filter(User.id == request.user_id).first()
        if not user:
            logger.error(f"User {request.user_id} not found")
            return results
        
        # Get user's preferred language
        user_language = user.preferred_language or 'en'
        
        # Send via each requested channel
        for channel in request.channels:
            try:
                result = await self._send_via_channel(
                    user, user_language, channel, request.type, request.data
                )
                results.append(result)
                
                # Save notification record
                await self._save_notification_record(request, result)
                
            except Exception as e:
                logger.error(f"Error sending notification via {channel.value}: {e}")
                results.append(NotificationResult(
                    success=False,
                    channel=channel,
                    message_id=None,
                    error=str(e),
                    delivered_at=datetime.utcnow()
                ))
        
        return results
    
    async def _send_via_channel(
        self, 
        user: User, 
        language: str, 
        channel: NotificationChannel, 
        notification_type: NotificationType, 
        data: Dict[str, Any]
    ) -> NotificationResult:
        """Send notification via specific channel"""
        
        # Get template
        template = self.template_manager.get_template(notification_type, language, channel)
        if not template:
            raise Exception(f"No template found for {notification_type.value} in {language}")
        
        # Render template
        subject, body = self.template_manager.render_template(template, data)
        
        # Send via appropriate service
        if channel == NotificationChannel.EMAIL:
            if not user.email:
                raise Exception("User has no email address")
            return await self.email_service.send_email(user.email, subject, body)
        
        elif channel == NotificationChannel.SMS:
            if not user.phone:
                raise Exception("User has no phone number")
            return await self.sms_service.send_sms(user.phone, body)
        
        elif channel == NotificationChannel.PUSH:
            # Would need user's push token
            return await self.push_service.send_push("user_token", subject, body)
        
        elif channel == NotificationChannel.IN_APP:
            # Save as in-app notification
            return await self._save_in_app_notification(user.id, subject, body, notification_type)
        
        else:
            raise Exception(f"Unsupported channel: {channel.value}")
    
    async def _save_in_app_notification(
        self, 
        user_id: int, 
        title: str, 
        content: str, 
        notification_type: NotificationType
    ) -> NotificationResult:
        """Save in-app notification"""
        try:
            notification = Notification(
                user_id=user_id,
                type=notification_type.value,
                payload={
                    "title": title,
                    "content": content,
                    "created_at": datetime.utcnow().isoformat()
                },
                is_read=False,
                created_at=datetime.utcnow()
            )
            
            self.db.add(notification)
            self.db.commit()
            
            return NotificationResult(
                success=True,
                channel=NotificationChannel.IN_APP,
                message_id=str(notification.id),
                error=None,
                delivered_at=datetime.utcnow()
            )
            
        except Exception as e:
            logger.error(f"Error saving in-app notification: {e}")
            self.db.rollback()
            raise
    
    async def _save_notification_record(self, request: NotificationRequest, result: NotificationResult):
        """Save notification delivery record for tracking"""
        # This would save to a notification_logs table for analytics
        logger.info(f"Notification sent: {request.type.value} via {result.channel.value} - Success: {result.success}")
    
    async def send_match_notification(self, match_id: int, user_id: int):
        """Send match found notification"""
        # Get match details
        match = self.db.query(Match).filter(Match.id == match_id).first()
        if not match:
            return
        
        # Prepare notification data
        data = {
            "match_id": match_id,
            "match_score": int(match.score_final * 100),
            "distance_km": round(match.distance_km or 0, 1),
            "your_item": {
                "title": match.lost_item.title,
                "description": match.lost_item.description
            },
            "match_item": {
                "title": match.found_item.title,
                "description": match.found_item.description,
                "created_at": match.found_item.created_at.strftime("%Y-%m-%d %H:%M")
            },
            "match_url": f"https://lostfound.app/matches/{match_id}",
            "short_url": f"https://lf.app/m/{match_id}",
            "item_type": match.lost_item.category
        }
        
        # Send notification
        request = NotificationRequest(
            user_id=user_id,
            type=NotificationType.MATCH_FOUND,
            priority=NotificationPriority.HIGH,
            channels=[NotificationChannel.EMAIL, NotificationChannel.IN_APP],
            data=data
        )
        
        return await self.send_notification(request)
    
    async def send_claim_notification(self, claim_id: int, owner_id: int):
        """Send claim submitted notification"""
        # Implementation similar to match notification
        pass
    
    async def send_bulk_notifications(self, requests: List[NotificationRequest]) -> List[List[NotificationResult]]:
        """Send multiple notifications efficiently"""
        tasks = [self.send_notification(request) for request in requests]
        return await asyncio.gather(*tasks, return_exceptions=True)
