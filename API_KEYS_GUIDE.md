# API Keys and Configuration Guide

This document provides a comprehensive guide for all API keys, secrets, and configuration variables needed for the Lost & Found System.

## 🔑 Required API Keys and Configuration

### 1. **Core System Configuration**

#### Main Environment File: `.env` (Project Root)

```bash
# Copy from .env.example and update with your values
cp .env.example .env
```

**Required Variables:**

```bash
# Database Configuration (Required)
DATABASE_URL=postgresql://username:password@localhost:5432/lostfound
DB_HOST=localhost
DB_PORT=5432
DB_NAME=lostfound
DB_USER=your_db_user
DB_PASSWORD=your_strong_db_password

# JWT Security (Critical - Change in Production)
JWT_SECRET_KEY=your-super-secret-jwt-key-minimum-32-characters-long
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=1440

# Redis Configuration (Required for caching)
REDIS_URL=redis://localhost:6379

# Service URLs (Required)
API_BASE_URL=http://localhost:8000
NLP_SERVICE_URL=http://localhost:8090
VISION_SERVICE_URL=http://localhost:8091
```

### 2. **Backend API Configuration**

#### File: `backend/api/.env`

```bash
# Copy from backend/api/.env.example
cp backend/api/.env.example backend/api/.env
```

**Required Variables:**

```bash
# App Configuration
APP_NAME=lostfound-api
ENV=production  # or dev, staging
PORT=8000
CORS_ORIGINS=https://yourdomain.com,https://admin.yourdomain.com

# Database (Critical)
DATABASE_URL=postgresql+psycopg://username:password@localhost:5432/lostfound

# JWT Security (Critical)
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# File Storage - S3/MinIO (Required for image uploads)
S3_ENDPOINT_URL=https://s3.amazonaws.com  # or your MinIO endpoint
S3_REGION=us-east-1
S3_ACCESS_KEY_ID=your-aws-access-key-id
S3_SECRET_ACCESS_KEY=your-aws-secret-access-key
S3_BUCKET=your-bucket-name
S3_PRESIGN_EXPIRES=3600

# Redis Configuration
REDIS_URL=redis://localhost:6379/0
RQ_DEFAULT_QUEUE=lostfound

# Admin Account (Change defaults)
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=your-strong-admin-password

# AI/ML Model Configuration
TEXT_MODEL_VERSION=intfloat/multilingual-e5-small
IMAGE_MODEL_VERSION=phash-v1
MATCH_WEIGHT_TEXT=0.45
MATCH_WEIGHT_IMAGE=0.30
MATCH_WEIGHT_GEO=0.15
MATCH_WEIGHT_TIME=0.05
MATCH_WEIGHT_META=0.05
```

### 3. **NLP Service Configuration**

#### File: `backend/nlp/.env`

```bash
# Copy from backend/nlp/.env.example
cp backend/nlp/.env.example backend/nlp/.env
```

**Required Variables:**

```bash
# Model Configuration
NLP_MODE=real  # or dummy for testing
EMBEDDING_MODEL=intfloat/multilingual-e5-small
NER_MODEL=xx_ent_wiki_sm

# Translation API (Optional but recommended)
ENABLE_TRANSLATION=true
TRANSLATION_SERVICE=google  # or libre

# Google Translate API (if using Google translation)
GOOGLE_TRANSLATE_API_KEY=your-google-translate-api-key
GOOGLE_APPLICATION_CREDENTIALS=/path/to/your/service-account.json

# Performance Configuration
MAX_TEXT_LENGTH=512
BATCH_SIZE=32
CACHE_SIZE=1000

# Redis Cache (Optional)
REDIS_URL=redis://localhost:6379/1
CACHE_TTL=3600
```

### 4. **Vision Service Configuration**

#### File: `backend/vision/.env`

```bash
# Copy from backend/vision/.env.example
cp backend/vision/.env.example backend/vision/.env
```

**Required Variables:**

```bash
# Model Configuration
CV_MODE=real  # or dummy for testing
CLIP_MODEL=ViT-B/32
HASH_SIZE=8

# Image Processing
MAX_IMAGE_SIZE=1024
SUPPORTED_FORMATS=JPEG,PNG,WEBP,BMP
ENABLE_PREPROCESSING=true

# Performance Settings
BATCH_SIZE=16
CACHE_SIZE=1000

# Redis Cache (Optional)
REDIS_URL=redis://localhost:6379/2
CACHE_TTL=3600
```

### 5. **Frontend Web Admin Configuration**

#### File: `frontend/web-admin/.env`

```bash
# Copy from frontend/web-admin/.env.example
cp frontend/web-admin/.env.example frontend/web-admin/.env
```

**Required Variables:**

```bash
# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:8000
# or in production: https://api.yourdomain.com

# Authentication
NEXT_PUBLIC_APP_NAME="Lost & Found Admin"
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-nextauth-secret-key

# OAuth Providers (Optional)
GOOGLE_CLIENT_ID=your-google-oauth-client-id
GOOGLE_CLIENT_SECRET=your-google-oauth-client-secret
```

### 6. **Mobile App Configuration**

#### For Firebase Push Notifications (Required for mobile notifications)

**Android Configuration:**

1. **Firebase Project Setup:**

   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use existing
   - Add Android app with package name: `com.lostfound.mobile`

2. **Download Configuration:**

   ```bash
   # Download google-services.json from Firebase Console
   # Place it in: frontend/mobile/android/app/google-services.json
   ```

3. **API Configuration in Dart:**
   ```dart
   // File: frontend/mobile/lib/core/config/app_config.dart
   class AppConfig {
     static const String apiBaseUrl = 'http://your-api-domain.com';
     static const String socketUrl = 'ws://your-api-domain.com/ws';
   }
   ```

### 7. **Email Configuration (Optional)**

#### SMTP Configuration (for notifications)

```bash
# Email Service Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password  # Use App Password for Gmail
FROM_EMAIL=noreply@yourdomain.com

# Email Templates
EMAIL_VERIFICATION_TEMPLATE=verification.html
PASSWORD_RESET_TEMPLATE=password_reset.html
```

### 8. **OAuth Providers (Optional)**

#### Google OAuth Setup

```bash
# Google OAuth Configuration
GOOGLE_CLIENT_ID=your-google-client-id.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Setup Instructions:
# 1. Go to Google Cloud Console
# 2. Create OAuth 2.0 credentials
# 3. Add authorized redirect URIs:
#    - http://localhost:3000/auth/callback/google (development)
#    - https://yourdomain.com/auth/callback/google (production)
```

#### Facebook OAuth Setup

```bash
# Facebook OAuth Configuration
FACEBOOK_CLIENT_ID=your-facebook-app-id
FACEBOOK_CLIENT_SECRET=your-facebook-app-secret

# Setup Instructions:
# 1. Go to Facebook Developers
# 2. Create a new app
# 3. Add Facebook Login product
# 4. Configure Valid OAuth Redirect URIs
```

## 🛠️ Configuration Setup Instructions

### Step 1: Environment Files Setup

```bash
# Navigate to project root
cd lost-found

# Copy all environment templates
cp .env.example .env
cp backend/api/.env.example backend/api/.env
cp backend/nlp/.env.example backend/nlp/.env
cp backend/vision/.env.example backend/vision/.env
cp frontend/web-admin/.env.example frontend/web-admin/.env
```

### Step 2: Database Setup

```bash
# Install PostgreSQL with PostGIS
# Ubuntu/Debian:
sudo apt-get install postgresql postgresql-contrib postgis

# Create database and user
sudo -u postgres psql
CREATE DATABASE lostfound;
CREATE USER lostfound WITH PASSWORD 'your_strong_password';
GRANT ALL PRIVILEGES ON DATABASE lostfound TO lostfound;
CREATE EXTENSION postgis;
\q
```

### Step 3: Redis Setup

```bash
# Install Redis
# Ubuntu/Debian:
sudo apt-get install redis-server

# Start Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

### Step 4: S3/MinIO Setup

#### Option A: AWS S3

1. Create AWS account
2. Create S3 bucket
3. Create IAM user with S3 permissions
4. Get Access Key ID and Secret Access Key

#### Option B: MinIO (Self-hosted)

```bash
# Install MinIO
docker run -p 9000:9000 -p 9001:9001 \
  --name minio \
  -e "MINIO_ACCESS_KEY=minioadmin" \
  -e "MINIO_SECRET_KEY=minioadmin" \
  -v /mnt/data:/data \
  minio/minio server /data --console-address ":9001"
```

### Step 5: Firebase Setup (for Mobile)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create project
3. Add Android app
4. Download `google-services.json`
5. Place in `frontend/mobile/android/app/`

## 🔒 Security Best Practices

### Production Security Checklist

- [ ] Change all default passwords
- [ ] Use strong JWT secrets (32+ characters)
- [ ] Enable HTTPS in production
- [ ] Restrict CORS_ORIGINS to your domains
- [ ] Use environment-specific API keys
- [ ] Enable database SSL connections
- [ ] Set up proper firewall rules
- [ ] Use secrets management (AWS Secrets Manager, Azure Key Vault)

### Environment-Specific Configuration

#### Development

```bash
ENV=development
DEBUG=true
CORS_ORIGINS=*
JWT_SECRET=dev-secret-key-not-for-production
```

#### Production

```bash
ENV=production
DEBUG=false
CORS_ORIGINS=https://yourdomain.com,https://admin.yourdomain.com
JWT_SECRET=super-secure-production-jwt-secret-minimum-32-chars
```

## 🚀 Quick Start Commands

### Complete Setup

```bash
# 1. Clone and setup environment files
git clone https://github.com/DATDSG/lost-found.git
cd lost-found
make setup-env  # This will copy all .env.example files

# 2. Install dependencies
make install

# 3. Start database and Redis
make start-services

# 4. Run migrations
make migrate

# 5. Start all services
make dev
```

### Individual Service Configuration

```bash
# Backend API only
cd backend/api
cp .env.example .env
# Edit .env with your values
pip install -r requirements.txt
uvicorn app.main:app --reload

# Frontend Admin only
cd frontend/web-admin
cp .env.example .env
# Edit .env with your values
npm install
npm run dev

# Mobile app
cd frontend/mobile
flutter pub get
flutter run
```

## ❗ Critical Configuration Notes

### 1. **JWT_SECRET** - Most Important

- **NEVER** use default values in production
- Must be at least 32 characters long
- Use a secure random generator
- Different for each environment

### 2. **Database Credentials**

- Use strong passwords
- Different credentials for each environment
- Enable SSL in production
- Regular backups configured

### 3. **API Keys Rotation**

- Rotate keys regularly
- Monitor usage
- Use different keys for different environments
- Store securely (not in code)

### 4. **File Upload Security**

- Validate file types
- Scan for malware
- Limit file sizes
- Use signed URLs

## 🆘 Troubleshooting

### Common Issues

1. **Database Connection Failed**

   ```bash
   # Check if PostgreSQL is running
   sudo systemctl status postgresql

   # Check connection
   psql -h localhost -U lostfound -d lostfound
   ```

2. **Redis Connection Failed**

   ```bash
   # Check if Redis is running
   sudo systemctl status redis-server

   # Test connection
   redis-cli ping
   ```

3. **S3 Upload Failed**

   - Verify bucket permissions
   - Check IAM user policies
   - Validate region configuration

4. **NLP Service Not Working**
   - Check model downloads
   - Verify GPU/CPU configuration
   - Check memory usage

### Configuration Validation

```bash
# Run configuration validation
python tools/validate_config.py

# Test all services
make test-services
```

---

**⚠️ Security Warning:** Never commit actual API keys, passwords, or secrets to version control. Always use environment variables and keep `.env` files in `.gitignore`.
