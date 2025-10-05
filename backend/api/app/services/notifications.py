"""
Notification Service - Handles email, push, and SMS notifications.

This service provides a unified interface for sending notifications
through multiple channels: email, push notifications (FCM), and SMS.
"""
import logging
from typing import Optional, Dict, Any, List
from enum import Enum
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from app.core.config import settings

logger = logging.getLogger(__name__)


class NotificationType(str, Enum):
    """Types of notifications."""
    MATCH_FOUND = "match_found"
    CLAIM_SUBMITTED = "claim_submitted"
    CLAIM_APPROVED = "claim_approved"
    CLAIM_REJECTED = "claim_rejected"
    MESSAGE_RECEIVED = "message_received"
    ITEM_STATUS_CHANGED = "item_status_changed"


class NotificationChannel(str, Enum):
    """Notification delivery channels."""
    EMAIL = "email"
    PUSH = "push"
    SMS = "sms"
    IN_APP = "in_app"


class NotificationService:
    """Service for sending notifications through various channels."""

    def __init__(self):
        self.email_enabled = settings.EMAIL_ENABLED
        self.push_enabled = settings.FCM_ENABLED
        self.sms_enabled = settings.SMS_ENABLED

    async def send_notification(
        self,
        user_id: int,
        notification_type: NotificationType,
        data: Dict[str, Any],
        channels: Optional[List[NotificationChannel]] = None
    ) -> Dict[str, bool]:
        """
        Send notification through specified channels.

        Args:
            user_id: Recipient user ID
            notification_type: Type of notification
            data: Notification data (varies by type)
            channels: List of channels to use (default: all enabled)

        Returns:
            Dict with channel names as keys and success status as values
        """
        if channels is None:
            channels = self._get_default_channels()

        results = {}
        
        # Always create in-app notification
        if NotificationChannel.IN_APP in channels:
            results[NotificationChannel.IN_APP] = await self._create_in_app_notification(
                user_id, notification_type, data
            )

        # Send email
        if NotificationChannel.EMAIL in channels and self.email_enabled:
            results[NotificationChannel.EMAIL] = await self.send_email(
                user_id, notification_type, data
            )

        # Send push notification
        if NotificationChannel.PUSH in channels and self.push_enabled:
            results[NotificationChannel.PUSH] = await self.send_push(
                user_id, notification_type, data
            )

        # Send SMS
        if NotificationChannel.SMS in channels and self.sms_enabled:
            results[NotificationChannel.SMS] = await self.send_sms(
                user_id, notification_type, data
            )

        return results

    async def send_email(
        self,
        user_id: int,
        notification_type: NotificationType,
        data: Dict[str, Any]
    ) -> bool:
        """Send email notification."""
        try:
            from app.db.session import SessionLocal
            from app.db import models

            db = SessionLocal()
            user = db.query(models.User).filter(models.User.id == user_id).first()
            
            if not user or not user.email:
                logger.warning(f"Cannot send email: User {user_id} not found or no email")
                return False

            subject, body = self._get_email_content(notification_type, data, user)
            
            return await self._send_email_smtp(user.email, subject, body)

        except Exception as e:
            logger.error(f"Failed to send email to user {user_id}: {e}")
            return False
        finally:
            db.close()

    async def _send_email_smtp(self, to_email: str, subject: str, body: str) -> bool:
        """Send email via SMTP."""
        try:
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = settings.EMAIL_FROM
            msg['To'] = to_email

            # Create HTML and plain text versions
            text_part = MIMEText(body, 'plain')
            html_part = MIMEText(self._wrap_html(body), 'html')

            msg.attach(text_part)
            msg.attach(html_part)

            with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
                if settings.SMTP_USE_TLS:
                    server.starttls()
                
                if settings.SMTP_USERNAME and settings.SMTP_PASSWORD:
                    server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
                
                server.send_message(msg)

            logger.info(f"Email sent successfully to {to_email}")
            return True

        except Exception as e:
            logger.error(f"SMTP error sending email to {to_email}: {e}")
            return False

    async def send_push(
        self,
        user_id: int,
        notification_type: NotificationType,
        data: Dict[str, Any]
    ) -> bool:
        """Send push notification via Firebase Cloud Messaging."""
        try:
            from app.db.session import SessionLocal
            from app.db import models

            db = SessionLocal()
            user = db.query(models.User).filter(models.User.id == user_id).first()
            
            if not user:
                logger.warning(f"Cannot send push: User {user_id} not found")
                return False

            # Get user's FCM tokens from database
            # TODO: Implement FCM token storage in User model
            # fcm_tokens = user.fcm_tokens or []
            
            # For now, log that push would be sent
            logger.info(f"Push notification would be sent to user {user_id}: {notification_type}")
            
            # TODO: Implement actual FCM sending
            # from firebase_admin import messaging
            # message = messaging.Message(
            #     notification=messaging.Notification(
            #         title=title,
            #         body=body
            #     ),
            #     data=data,
            #     token=fcm_token
            # )
            # response = messaging.send(message)
            
            return True

        except Exception as e:
            logger.error(f"Failed to send push to user {user_id}: {e}")
            return False
        finally:
            db.close()

    async def send_sms(
        self,
        user_id: int,
        notification_type: NotificationType,
        data: Dict[str, Any]
    ) -> bool:
        """Send SMS notification via Twilio."""
        try:
            from app.db.session import SessionLocal
            from app.db import models

            db = SessionLocal()
            user = db.query(models.User).filter(models.User.id == user_id).first()
            
            if not user or not user.phone_number:
                logger.warning(f"Cannot send SMS: User {user_id} not found or no phone")
                return False

            # For now, log that SMS would be sent
            logger.info(f"SMS notification would be sent to user {user_id}: {notification_type}")
            
            # TODO: Implement actual Twilio sending
            # from twilio.rest import Client
            # client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
            # message = client.messages.create(
            #     body=sms_body,
            #     from_=settings.TWILIO_PHONE_NUMBER,
            #     to=user.phone_number
            # )
            
            return True

        except Exception as e:
            logger.error(f"Failed to send SMS to user {user_id}: {e}")
            return False
        finally:
            db.close()

    async def _create_in_app_notification(
        self,
        user_id: int,
        notification_type: NotificationType,
        data: Dict[str, Any]
    ) -> bool:
        """Create in-app notification record in database."""
        try:
            from app.db.session import SessionLocal
            from app.db import models
            import json

            db = SessionLocal()
            
            title, body = self._get_notification_text(notification_type, data)
            
            notification = models.Notification(
                user_id=user_id,
                type=notification_type.value,
                title=title,
                message=body,
                data=json.dumps(data),
                read=False
            )
            
            db.add(notification)
            db.commit()
            
            logger.info(f"In-app notification created for user {user_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to create in-app notification for user {user_id}: {e}")
            return False
        finally:
            db.close()

    def _get_default_channels(self) -> List[NotificationChannel]:
        """Get list of default notification channels based on configuration."""
        channels = [NotificationChannel.IN_APP]
        
        if self.email_enabled:
            channels.append(NotificationChannel.EMAIL)
        
        if self.push_enabled:
            channels.append(NotificationChannel.PUSH)
        
        return channels

    def _get_notification_text(
        self,
        notification_type: NotificationType,
        data: Dict[str, Any]
    ) -> tuple[str, str]:
        """Get title and body text for notification."""
        templates = {
            NotificationType.MATCH_FOUND: (
                "New Match Found!",
                f"We found {data.get('match_count', 1)} potential match(es) for your {data.get('item_type', 'item')}."
            ),
            NotificationType.CLAIM_SUBMITTED: (
                "New Claim Submitted",
                f"Someone has submitted a claim for your {data.get('item_type', 'item')}."
            ),
            NotificationType.CLAIM_APPROVED: (
                "Claim Approved",
                f"Your claim for the {data.get('item_type', 'item')} has been approved!"
            ),
            NotificationType.CLAIM_REJECTED: (
                "Claim Status Update",
                f"Your claim for the {data.get('item_type', 'item')} has been rejected."
            ),
            NotificationType.MESSAGE_RECEIVED: (
                "New Message",
                f"You have a new message regarding your {data.get('item_type', 'item')}."
            ),
            NotificationType.ITEM_STATUS_CHANGED: (
                "Item Status Updated",
                f"The status of your {data.get('item_type', 'item')} has been updated to {data.get('status', 'unknown')}."
            ),
        }
        
        return templates.get(notification_type, ("Notification", "You have a new notification"))

    def _get_email_content(
        self,
        notification_type: NotificationType,
        data: Dict[str, Any],
        user
    ) -> tuple[str, str]:
        """Get email subject and body."""
        title, body = self._get_notification_text(notification_type, data)
        
        # Add personalization
        greeting = f"Hi {user.name if hasattr(user, 'name') else 'there'},\n\n"
        
        footer = "\n\nBest regards,\nThe Lost & Found Team"
        
        email_body = greeting + body + footer
        
        return title, email_body

    def _wrap_html(self, text: str) -> str:
        """Wrap plain text in basic HTML template."""
        return f"""
        <html>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                    {text.replace(chr(10), '<br>')}
                </div>
            </body>
        </html>
        """


# Global notification service instance
notification_service = NotificationService()
