#!/usr/bin/env python3
"""
Configuration Validation Script

This script validates all required environment variables and API keys
for the Lost & Found System.
"""

import os
import sys
import json
from pathlib import Path
from typing import Dict, List, Optional
import psycopg2
import redis
import requests
from urllib.parse import urlparse

class ConfigValidator:
    """Validates system configuration and API keys"""
    
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.success = []
        
    def validate_all(self) -> bool:
        """Run all validation checks"""
        print("🔍 Validating Lost & Found System Configuration...\n")
        
        # Core validations
        self.validate_environment_files()
        self.validate_database_connection()
        self.validate_redis_connection()
        self.validate_jwt_security()
        self.validate_s3_configuration()
        self.validate_service_urls()
        self.validate_api_keys()
        
        # Print results
        self.print_results()
        
        return len(self.errors) == 0
    
    def validate_environment_files(self):
        """Check if all required .env files exist"""
        required_env_files = [
            ".env",
            "backend/api/.env", 
            "backend/nlp/.env",
            "backend/vision/.env",
            "frontend/web-admin/.env"
        ]
        
        for env_file in required_env_files:
            if Path(env_file).exists():
                self.success.append(f"✅ Found {env_file}")
            else:
                self.errors.append(f"❌ Missing {env_file} (copy from {env_file}.example)")
    
    def validate_database_connection(self):
        """Test database connection"""
        database_url = os.getenv('DATABASE_URL')
        
        if not database_url:
            self.errors.append("❌ DATABASE_URL not set")
            return
        
        try:
            # Parse URL to validate format
            parsed = urlparse(database_url)
            if not all([parsed.scheme, parsed.hostname, parsed.username, parsed.password]):
                self.errors.append("❌ Invalid DATABASE_URL format")
                return
            
            # Test connection
            conn = psycopg2.connect(database_url)
            conn.close()
            self.success.append("✅ Database connection successful")
            
        except psycopg2.Error as e:
            self.errors.append(f"❌ Database connection failed: {e}")
        except Exception as e:
            self.errors.append(f"❌ Database URL error: {e}")
    
    def validate_redis_connection(self):
        """Test Redis connection"""
        redis_url = os.getenv('REDIS_URL', 'redis://localhost:6379')
        
        try:
            r = redis.from_url(redis_url)
            r.ping()
            self.success.append("✅ Redis connection successful")
        except redis.ConnectionError:
            self.errors.append(f"❌ Redis connection failed: {redis_url}")
        except Exception as e:
            self.errors.append(f"❌ Redis error: {e}")
    
    def validate_jwt_security(self):
        """Validate JWT configuration"""
        jwt_secret = os.getenv('JWT_SECRET') or os.getenv('JWT_SECRET_KEY')
        
        if not jwt_secret:
            self.errors.append("❌ JWT_SECRET not set")
            return
        
        if jwt_secret in ['changeme', 'change_me_in_production', 'dev-secret']:
            self.errors.append("❌ Using default JWT_SECRET - SECURITY RISK!")
            return
        
        if len(jwt_secret) < 32:
            self.warnings.append("⚠️ JWT_SECRET should be at least 32 characters")
        else:
            self.success.append("✅ JWT_SECRET is properly configured")
    
    def validate_s3_configuration(self):
        """Validate S3/MinIO configuration"""
        s3_access_key = os.getenv('S3_ACCESS_KEY_ID')
        s3_secret_key = os.getenv('S3_SECRET_ACCESS_KEY')
        s3_bucket = os.getenv('S3_BUCKET')
        s3_endpoint = os.getenv('S3_ENDPOINT_URL')
        
        if not all([s3_access_key, s3_secret_key, s3_bucket]):
            self.warnings.append("⚠️ S3 configuration incomplete (file uploads may not work)")
            return
        
        if s3_access_key == 'minioadmin' and s3_secret_key == 'minioadmin':
            self.warnings.append("⚠️ Using default MinIO credentials")
        
        # Test S3 connection if boto3 is available
        try:
            import boto3
            from botocore.exceptions import ClientError
            
            s3_client = boto3.client(
                's3',
                endpoint_url=s3_endpoint,
                aws_access_key_id=s3_access_key,
                aws_secret_access_key=s3_secret_key,
                region_name=os.getenv('S3_REGION', 'us-east-1')
            )
            
            # Test bucket access
            s3_client.head_bucket(Bucket=s3_bucket)
            self.success.append("✅ S3/MinIO connection successful")
            
        except ImportError:
            self.warnings.append("⚠️ boto3 not installed - cannot test S3 connection")
        except ClientError as e:
            self.errors.append(f"❌ S3 connection failed: {e}")
    
    def validate_service_urls(self):
        """Validate service URL connectivity"""
        services = {
            'API': os.getenv('API_BASE_URL', 'http://localhost:8000'),
            'NLP': os.getenv('NLP_SERVICE_URL', 'http://localhost:8090'),
            'Vision': os.getenv('VISION_SERVICE_URL', 'http://localhost:8091')
        }
        
        for service_name, url in services.items():
            try:
                response = requests.get(f"{url}/health", timeout=5)
                if response.status_code == 200:
                    self.success.append(f"✅ {service_name} service healthy")
                else:
                    self.warnings.append(f"⚠️ {service_name} service returned {response.status_code}")
            except requests.exceptions.ConnectionError:
                self.warnings.append(f"⚠️ {service_name} service not reachable (may not be running)")
            except requests.exceptions.Timeout:
                self.warnings.append(f"⚠️ {service_name} service timeout")
            except Exception as e:
                self.warnings.append(f"⚠️ {service_name} service error: {e}")
    
    def validate_api_keys(self):
        """Validate optional API keys"""
        # Google Translate API
        google_api_key = os.getenv('GOOGLE_TRANSLATE_API_KEY')
        if google_api_key:
            self.success.append("✅ Google Translate API key configured")
        else:
            self.warnings.append("⚠️ Google Translate API key not set (translation features disabled)")
        
        # OAuth keys
        google_client_id = os.getenv('GOOGLE_CLIENT_ID')
        if google_client_id:
            self.success.append("✅ Google OAuth configured")
        else:
            self.warnings.append("⚠️ Google OAuth not configured")
        
        facebook_client_id = os.getenv('FACEBOOK_CLIENT_ID')
        if facebook_client_id:
            self.success.append("✅ Facebook OAuth configured")
        else:
            self.warnings.append("⚠️ Facebook OAuth not configured")
        
        # Email configuration
        smtp_host = os.getenv('SMTP_HOST')
        smtp_user = os.getenv('SMTP_USER')
        if smtp_host and smtp_user:
            self.success.append("✅ Email configuration found")
        else:
            self.warnings.append("⚠️ Email configuration incomplete")
    
    def print_results(self):
        """Print validation results"""
        print("\n" + "="*60)
        print("📋 CONFIGURATION VALIDATION RESULTS")
        print("="*60)
        
        if self.success:
            print(f"\n✅ SUCCESS ({len(self.success)} items):")
            for item in self.success:
                print(f"  {item}")
        
        if self.warnings:
            print(f"\n⚠️ WARNINGS ({len(self.warnings)} items):")
            for item in self.warnings:
                print(f"  {item}")
        
        if self.errors:
            print(f"\n❌ ERRORS ({len(self.errors)} items):")
            for item in self.errors:
                print(f"  {item}")
        
        print("\n" + "="*60)
        
        if self.errors:
            print("❌ VALIDATION FAILED - Please fix the errors above")
            print("\n📖 See API_KEYS_GUIDE.md for detailed setup instructions")
        else:
            print("✅ VALIDATION PASSED - System ready to run!")
            if self.warnings:
                print("⚠️ Note: Some warnings above may affect functionality")
        
        print("="*60)

def load_env_files():
    """Load environment variables from .env files"""
    env_files = [
        ".env",
        "backend/api/.env",
        "backend/nlp/.env", 
        "backend/vision/.env",
        "frontend/web-admin/.env"
    ]
    
    for env_file in env_files:
        if Path(env_file).exists():
            with open(env_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        # Only set if not already in environment
                        if key not in os.environ:
                            os.environ[key] = value

def main():
    """Main validation function"""
    print("🚀 Lost & Found System - Configuration Validator")
    print("="*60)
    
    # Load environment files
    load_env_files()
    
    # Run validation
    validator = ConfigValidator()
    success = validator.validate_all()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()