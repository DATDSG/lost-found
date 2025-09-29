"""
Two-Factor Authentication (2FA) System
Implements TOTP (Time-based One-Time Password) and SMS-based 2FA
"""

import pyotp
import qrcode
import io
import base64
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
import secrets
import logging

from ..models.user import User
from ..core.config import settings
from ..services.sms_service import SMSService
from ..services.email_service import EmailService

logger = logging.getLogger(__name__)

class TwoFactorSetupRequest(BaseModel):
    method: str  # "totp" or "sms"
    phone_number: Optional[str] = None

class TwoFactorSetupResponse(BaseModel):
    method: str
    secret: Optional[str] = None
    qr_code: Optional[str] = None
    backup_codes: list[str]
    setup_complete: bool = False

class TwoFactorVerifyRequest(BaseModel):
    code: str
    method: str
    remember_device: bool = False

class TwoFactorVerifyResponse(BaseModel):
    verified: bool
    backup_codes_used: Optional[list[str]] = None
    device_token: Optional[str] = None

class BackupCode(BaseModel):
    code: str
    used: bool = False
    used_at: Optional[datetime] = None

class TrustedDevice(BaseModel):
    device_id: str
    device_name: str
    created_at: datetime
    last_used: datetime
    expires_at: datetime

class TwoFactorService:
    """Service for managing two-factor authentication"""
    
    def __init__(self, db: Session):
        self.db = db
        self.sms_service = SMSService()
        self.email_service = EmailService()
    
    def setup_totp(self, user: User) -> TwoFactorSetupResponse:
        """Set up TOTP-based 2FA for user"""
        # Generate secret key
        secret = pyotp.random_base32()
        
        # Create TOTP object
        totp = pyotp.TOTP(secret)
        
        # Generate QR code
        provisioning_uri = totp.provisioning_uri(
            name=user.email,
            issuer_name=settings.APP_NAME
        )
        
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(provisioning_uri)
        qr.make(fit=True)
        
        # Convert QR code to base64 string
        img = qr.make_image(fill_color="black", back_color="white")
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        qr_code_b64 = base64.b64encode(buffer.getvalue()).decode()
        
        # Generate backup codes
        backup_codes = self._generate_backup_codes()
        
        # Store 2FA settings (temporarily, until verified)
        user.two_factor_secret = secret
        user.two_factor_method = "totp"
        user.two_factor_enabled = False  # Will be enabled after verification
        user.two_factor_backup_codes = self._encrypt_backup_codes(backup_codes)
        
        self.db.commit()
        
        return TwoFactorSetupResponse(
            method="totp",
            secret=secret,
            qr_code=f"data:image/png;base64,{qr_code_b64}",
            backup_codes=backup_codes,
            setup_complete=False
        )
    
    def setup_sms(self, user: User, phone_number: str) -> TwoFactorSetupResponse:
        """Set up SMS-based 2FA for user"""
        # Validate phone number format
        if not self._validate_phone_number(phone_number):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid phone number format"
            )
        
        # Generate and send verification code
        verification_code = self._generate_sms_code()
        
        # Store phone number and code temporarily
        user.two_factor_phone = phone_number
        user.two_factor_method = "sms"
        user.two_factor_enabled = False
        user.two_factor_temp_code = verification_code
        user.two_factor_temp_code_expires = datetime.utcnow() + timedelta(minutes=5)
        
        # Generate backup codes
        backup_codes = self._generate_backup_codes()
        user.two_factor_backup_codes = self._encrypt_backup_codes(backup_codes)
        
        self.db.commit()
        
        # Send SMS
        try:
            self.sms_service.send_verification_code(phone_number, verification_code)
        except Exception as e:
            logger.error(f"Failed to send SMS verification: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send SMS verification code"
            )
        
        return TwoFactorSetupResponse(
            method="sms",
            backup_codes=backup_codes,
            setup_complete=False
        )
    
    def verify_setup(self, user: User, code: str) -> TwoFactorVerifyResponse:
        """Verify 2FA setup with provided code"""
        if not user.two_factor_method:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="2FA setup not initiated"
            )
        
        verified = False
        
        if user.two_factor_method == "totp":
            verified = self._verify_totp_code(user, code)
        elif user.two_factor_method == "sms":
            verified = self._verify_sms_code(user, code)
        
        if verified:
            # Enable 2FA
            user.two_factor_enabled = True
            user.two_factor_temp_code = None
            user.two_factor_temp_code_expires = None
            self.db.commit()
            
            logger.info(f"2FA enabled for user {user.id} using {user.two_factor_method}")
        
        return TwoFactorVerifyResponse(verified=verified)
    
    def verify_login(self, user: User, code: str, remember_device: bool = False) -> TwoFactorVerifyResponse:
        """Verify 2FA code during login"""
        if not user.two_factor_enabled:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="2FA not enabled for this user"
            )
        
        verified = False
        backup_codes_used = None
        device_token = None
        
        # Try regular 2FA code first
        if user.two_factor_method == "totp":
            verified = self._verify_totp_code(user, code)
        elif user.two_factor_method == "sms":
            # Generate and send new SMS code for login
            sms_code = self._generate_sms_code()
            user.two_factor_temp_code = sms_code
            user.two_factor_temp_code_expires = datetime.utcnow() + timedelta(minutes=5)
            self.db.commit()
            
            self.sms_service.send_verification_code(user.two_factor_phone, sms_code)
            verified = self._verify_sms_code(user, code)
        
        # If regular code fails, try backup codes
        if not verified:
            backup_code_result = self._verify_backup_code(user, code)
            if backup_code_result:
                verified = True
                backup_codes_used = [backup_code_result]
        
        # Generate trusted device token if requested and verified
        if verified and remember_device:
            device_token = self._generate_device_token(user)
        
        if verified:
            user.last_login = datetime.utcnow()
            self.db.commit()
        
        return TwoFactorVerifyResponse(
            verified=verified,
            backup_codes_used=backup_codes_used,
            device_token=device_token
        )
    
    def disable_2fa(self, user: User) -> bool:
        """Disable 2FA for user"""
        user.two_factor_enabled = False
        user.two_factor_method = None
        user.two_factor_secret = None
        user.two_factor_phone = None
        user.two_factor_backup_codes = None
        user.two_factor_temp_code = None
        user.two_factor_temp_code_expires = None
        
        self.db.commit()
        
        logger.info(f"2FA disabled for user {user.id}")
        return True
    
    def regenerate_backup_codes(self, user: User) -> list[str]:
        """Generate new backup codes for user"""
        if not user.two_factor_enabled:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="2FA not enabled"
            )
        
        backup_codes = self._generate_backup_codes()
        user.two_factor_backup_codes = self._encrypt_backup_codes(backup_codes)
        self.db.commit()
        
        return backup_codes
    
    def is_trusted_device(self, user: User, device_token: str) -> bool:
        """Check if device is trusted"""
        # In a real implementation, you'd store trusted devices in the database
        # For now, we'll validate the token structure and expiry
        try:
            import jwt
            payload = jwt.decode(
                device_token, 
                settings.JWT_SECRET, 
                algorithms=[settings.JWT_ALGORITHM]
            )
            
            return (
                payload.get("user_id") == user.id and
                payload.get("type") == "trusted_device" and
                datetime.utcnow() < datetime.fromtimestamp(payload.get("exp", 0))
            )
        except:
            return False
    
    def _verify_totp_code(self, user: User, code: str) -> bool:
        """Verify TOTP code"""
        if not user.two_factor_secret:
            return False
        
        totp = pyotp.TOTP(user.two_factor_secret)
        return totp.verify(code, valid_window=1)  # Allow 1 window tolerance
    
    def _verify_sms_code(self, user: User, code: str) -> bool:
        """Verify SMS code"""
        if not user.two_factor_temp_code or not user.two_factor_temp_code_expires:
            return False
        
        if datetime.utcnow() > user.two_factor_temp_code_expires:
            return False
        
        return user.two_factor_temp_code == code
    
    def _verify_backup_code(self, user: User, code: str) -> Optional[str]:
        """Verify backup code and mark as used"""
        if not user.two_factor_backup_codes:
            return None
        
        backup_codes = self._decrypt_backup_codes(user.two_factor_backup_codes)
        
        for backup_code in backup_codes:
            if backup_code["code"] == code and not backup_code["used"]:
                # Mark as used
                backup_code["used"] = True
                backup_code["used_at"] = datetime.utcnow().isoformat()
                
                # Update in database
                user.two_factor_backup_codes = self._encrypt_backup_codes(backup_codes)
                self.db.commit()
                
                return code
        
        return None
    
    def _generate_backup_codes(self, count: int = 10) -> list[str]:
        """Generate backup codes"""
        codes = []
        for _ in range(count):
            code = ''.join([str(secrets.randbelow(10)) for _ in range(8)])
            codes.append(f"{code[:4]}-{code[4:]}")
        return codes
    
    def _encrypt_backup_codes(self, codes: list[str]) -> str:
        """Encrypt backup codes for storage"""
        import json
        from cryptography.fernet import Fernet
        
        # In production, use a proper encryption key
        key = settings.BACKUP_CODES_ENCRYPTION_KEY.encode()
        f = Fernet(key)
        
        backup_codes_data = [
            {"code": code, "used": False, "used_at": None}
            for code in codes
        ]
        
        encrypted = f.encrypt(json.dumps(backup_codes_data).encode())
        return base64.b64encode(encrypted).decode()
    
    def _decrypt_backup_codes(self, encrypted_codes: str) -> list[dict]:
        """Decrypt backup codes from storage"""
        import json
        from cryptography.fernet import Fernet
        
        key = settings.BACKUP_CODES_ENCRYPTION_KEY.encode()
        f = Fernet(key)
        
        try:
            decrypted = f.decrypt(base64.b64decode(encrypted_codes.encode()))
            return json.loads(decrypted.decode())
        except:
            return []
    
    def _generate_sms_code(self) -> str:
        """Generate 6-digit SMS verification code"""
        return ''.join([str(secrets.randbelow(10)) for _ in range(6)])
    
    def _validate_phone_number(self, phone: str) -> bool:
        """Validate phone number format"""
        import re
        # Basic international phone number validation
        pattern = r'^\+[1-9]\d{1,14}$'
        return bool(re.match(pattern, phone))
    
    def _generate_device_token(self, user: User) -> str:
        """Generate trusted device token"""
        import jwt
        
        payload = {
            "user_id": user.id,
            "type": "trusted_device",
            "iat": datetime.utcnow(),
            "exp": datetime.utcnow() + timedelta(days=30)  # 30 days validity
        }
        
        return jwt.encode(
            payload,
            settings.JWT_SECRET,
            algorithm=settings.JWT_ALGORITHM
        )
    
    def get_2fa_status(self, user: User) -> Dict[str, Any]:
        """Get 2FA status for user"""
        return {
            "enabled": user.two_factor_enabled,
            "method": user.two_factor_method,
            "phone_number": user.two_factor_phone[-4:] if user.two_factor_phone else None,
            "backup_codes_remaining": self._count_unused_backup_codes(user)
        }
    
    def _count_unused_backup_codes(self, user: User) -> int:
        """Count unused backup codes"""
        if not user.two_factor_backup_codes:
            return 0
        
        backup_codes = self._decrypt_backup_codes(user.two_factor_backup_codes)
        return sum(1 for code in backup_codes if not code["used"])

# SMS Service for sending verification codes
class SMSService:
    """SMS service for sending 2FA codes"""
    
    def __init__(self):
        self.provider = settings.SMS_PROVIDER  # "twilio", "aws_sns", etc.
    
    def send_verification_code(self, phone_number: str, code: str):
        """Send SMS verification code"""
        message = f"Your {settings.APP_NAME} verification code is: {code}. This code expires in 5 minutes."
        
        if self.provider == "twilio":
            self._send_twilio_sms(phone_number, message)
        elif self.provider == "aws_sns":
            self._send_aws_sns_sms(phone_number, message)
        else:
            # Mock SMS for development
            logger.info(f"SMS to {phone_number}: {message}")
    
    def _send_twilio_sms(self, phone_number: str, message: str):
        """Send SMS via Twilio"""
        try:
            from twilio.rest import Client
            
            client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
            client.messages.create(
                body=message,
                from_=settings.TWILIO_PHONE_NUMBER,
                to=phone_number
            )
        except Exception as e:
            logger.error(f"Twilio SMS error: {e}")
            raise
    
    def _send_aws_sns_sms(self, phone_number: str, message: str):
        """Send SMS via AWS SNS"""
        try:
            import boto3
            
            sns = boto3.client('sns')
            sns.publish(
                PhoneNumber=phone_number,
                Message=message
            )
        except Exception as e:
            logger.error(f"AWS SNS SMS error: {e}")
            raise
