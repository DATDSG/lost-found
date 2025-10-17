# Lost & Found System

A comprehensive lost and found platform with AI-powered matching capabilities, featuring a **fully async FastAPI backend**, Flutter mobile app, and React admin panel with **real-time WebSocket messaging**.

## ⚡ What's New - Version 2.1.0

### Recent Updates (October 2025)

- ✅ **Enhanced Security** - Removed public admin endpoints, enforced authentication
- ✅ **Complete Admin API** - Full CRUD operations for users, reports, and matches
- ✅ **Database Optimizations** - 12 new performance indexes for faster queries
- ✅ **Audit Logging** - Comprehensive tracking of all admin actions
- ✅ **Database Management** - Seeding, backup, and restore scripts
- ✅ **API Consistency** - All endpoints now use `/api/v1` prefix
- ✅ **Frontend Sync** - Mobile and admin panel APIs fully synchronized

### Version 2.0 Features

- ✅ **Fully Async Database Layer** - Migrated to AsyncSession with asyncpg for better concurrency
- ✅ **Real-time Messaging** - WebSocket support for instant chat and notifications
- ✅ **Background Task Processing** - Automatic embedding generation and matching
- ✅ **Complete Messages System** - Full conversation and messaging API
- ✅ **Comprehensive Health Checks** - Detailed monitoring for all services
- ✅ **Enhanced Environment Configuration** - Strict validation and documentation

## 🚀 Quick Start

### Prerequisites

1. **Generate JWT Secret Key** (Required!):

   ```bash
   openssl rand -hex 32
   ```

2. **Create Environment File**:
   Create `infra/compose/.env` with:
   ```bash
   JWT_SECRET_KEY=your-generated-secret-from-step-1
   ```

### Start All Services

```bash
cd infra/compose
docker-compose up -d
```

**Access the system:**

- **API Documentation**: http://localhost:8000/docs
- **API Health Check**: http://localhost:8000/health/detailed
- **Admin Panel**: http://localhost:3000 (after setup)
- **Mobile App**: See `apps/mobile/README.md`

**Complete setup guide:** See [ENVIRONMENT_SETUP.md](ENVIRONMENT_SETUP.md)

## 🏗️ Architecture

### Backend Services

- **API Service** (FastAPI) - Main backend with authentication, reports, matching
- **NLP Service** (FastAPI) - Text embeddings using sentence transformers
- **Vision Service** (FastAPI) - Image processing and perceptual hashing
- **PostgreSQL** - Database with PostGIS and pgvector extensions
- **Redis** - Caching and session storage

### Frontend Applications

- **Mobile App** (Flutter) - Cross-platform mobile application
- **Admin Panel** (React) - Web-based administration interface

### Key Features

- ✅ **Async Architecture** - Fully async database and API with asyncpg driver
- ✅ **Real-time Messaging** - WebSocket-based instant messaging and notifications
- ✅ **Multi-signal Matching** - Text (45%), Image (35%), Geo (15%), Time (5%)
- ✅ **Background Processing** - Automatic embedding generation and matching
- ✅ **Complete Chat System** - Conversations, messages, read receipts
- ✅ **Comprehensive Health Checks** - Detailed status for all services
- ✅ **Redis Caching** - Service call caching for better performance
- ✅ **Prometheus Metrics** - Full observability
- ✅ **Rate Limiting** - Protection against abuse
- ✅ **CORS Support** - Cross-origin resource sharing
- ✅ **API Documentation** - Interactive Swagger/ReDoc docs

## 📁 Project Structure

```
lost-found/
├── services/
│   ├── api/          # Main FastAPI backend
│   ├── nlp/          # NLP service for text embeddings
│   └── vision/       # Vision service for image processing
├── apps/
│   ├── mobile/       # Flutter mobile app
│   └── admin/        # React admin panel
├── infra/
│   └── compose/      # Docker Compose configuration
├── data/             # Database scripts and seed data
└── docs/             # Documentation
```

## 🔧 Technology Stack

### Backend

- **FastAPI** - Modern Python web framework
- **PostgreSQL 16** - Database with PostGIS and pgvector
- **Redis 7** - Caching and session storage
- **SQLAlchemy** - ORM
- **Alembic** - Database migrations
- **JWT** - Authentication
- **Prometheus** - Metrics

### Frontend

- **Flutter** - Cross-platform mobile development
- **React** - Web admin interface
- **Material-UI** - React component library
- **Axios** - HTTP client

### AI/ML

- **Sentence Transformers** - Text embeddings
- **OpenCV** - Image processing
- **Perceptual Hashing** - Image similarity

## 🚦 Status

### ✅ Version 2.0 - Production Ready

**Core Infrastructure:**

- ✅ Fully async database layer with asyncpg
- ✅ All API routers migrated to async
- ✅ Complete environment configuration system
- ✅ Docker Compose with health checks
- ✅ Comprehensive error handling

**API Features:**

- ✅ Authentication with JWT (register, login, refresh, me)
- ✅ Reports CRUD with filtering and pagination
- ✅ Media upload with image processing
- ✅ Match candidates with multi-signal scoring
- ✅ **Messages & Conversations** (NEW!)
- ✅ **WebSocket real-time chat** (NEW!)
- ✅ **WebSocket notifications** (NEW!)
- ✅ Notifications with unread counts
- ✅ Taxonomy (categories, colors)
- ✅ **Detailed health checks** (NEW!)

**Background Processing:**

- ✅ Text embedding generation (NLP service)
- ✅ Image hash generation (Vision service)
- ✅ Automatic matching pipeline
- ✅ Notification creation for high-score matches

**Frontend:**

- ✅ Admin panel with API integration
- ✅ Mobile app with API configuration
- ✅ CORS configuration for all frontends
- ✅ WebSocket-ready for real-time features

### 🔄 Ready for Testing

- End-to-end user journey: Register → Create Report → Upload Images → Match → Chat
- Real-time messaging between users
- Background task processing
- Multi-signal matching with all components

## 📖 Documentation

- **[Environment Setup Guide](ENVIRONMENT_SETUP.md)** - **START HERE!** Complete environment configuration
- [Phase 2 Deployment Guide](PHASE2_DEPLOYMENT_GUIDE.md) - Database & connectivity fixes
- [Security Deployment Guide](SECURITY_DEPLOYMENT_GUIDE.md) - Security hardening
- [Database Guide](data/README.md) - Database setup and queries
- [Mobile App Setup](apps/mobile/README.md) - Flutter app configuration
- [Admin Panel Setup](apps/admin/README.md) - React admin interface

### API Endpoints

**Authentication:**

- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/refresh` - Refresh token
- `GET /api/v1/auth/me` - Get current user

**Reports:**

- `POST /api/v1/reports` - Create report
- `GET /api/v1/reports` - List reports (with filters)
- `GET /api/v1/reports/{id}` - Get report details
- `GET /api/v1/reports/me` - Get my reports

**Media:**

- `POST /api/v1/media/upload` - Upload image
- `GET /api/v1/media/{id}` - Get media
- `DELETE /api/v1/media/{id}` - Delete media

**Matches:**

- `GET /api/v1/matches/report/{report_id}` - Get matches for report
- `POST /api/v1/matches/{id}/confirm` - Confirm match
- `POST /api/v1/matches/{id}/dismiss` - Dismiss match

**Messages (NEW!):**

- `POST /api/v1/messages/conversations` - Create conversation
- `GET /api/v1/messages/conversations` - List conversations
- `GET /api/v1/messages/conversations/{id}` - Get conversation details
- `POST /api/v1/messages/conversations/{id}/messages` - Send message
- `PATCH /api/v1/messages/messages/{id}/read` - Mark as read

**WebSocket (NEW!):**

- `WS /ws/chat?token={jwt}` - Real-time chat
- `WS /ws/notifications?token={jwt}` - Real-time notifications

**Health Checks (NEW!):**

- `GET /health` - Basic health check
- `GET /health/detailed` - Comprehensive system health
- `GET /health/ready` - Kubernetes readiness probe
- `GET /health/live` - Kubernetes liveness probe

**Full API Documentation:** http://localhost:8000/docs (after starting services)

## 🛠️ Development

### Prerequisites

- Docker and Docker Compose
- Python 3.11+ (for local development)
- Flutter SDK (for mobile development)
- Node.js 18+ (for admin panel)

### Local Development

1. **Start Services**

   ```bash
   cd infra/compose
   docker-compose up -d
   ```

2. **Run Mobile App**

   ```bash
   cd apps/mobile
   flutter pub get
   flutter run
   ```

3. **Run Admin Panel**
   ```bash
   cd apps/admin
   npm install
   npm run dev
   ```

## 🧪 Testing

### Health Checks

```bash
curl http://localhost:8000/health  # API
curl http://localhost:8001/health  # NLP
curl http://localhost:8002/health  # Vision
```

### Integration Test

```bash
# Register user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## 🚀 Deployment

### Production Checklist

**Critical Security:**

- [ ] Generate **strong** `JWT_SECRET_KEY` (`openssl rand -hex 32`)
- [ ] Set `JWT_SECRET_KEY` in environment (NEVER commit to git!)
- [ ] Set `ENVIRONMENT=production`
- [ ] Set `DEBUG=false`
- [ ] Configure proper `CORS_ORIGINS` (only your domains)
- [ ] Enable HTTPS with reverse proxy (nginx/Caddy)
- [ ] Use secure PostgreSQL credentials
- [ ] Enable rate limiting

**Database:**

- [ ] Verify asyncpg driver in `DATABASE_URL` (`postgresql+asyncpg://...`)
- [ ] Set appropriate connection pool size (`DB_POOL_SIZE=20-50` for production)
- [ ] Run Alembic migrations: `alembic upgrade head`
- [ ] Verify pgvector extension is installed
- [ ] Set up automated database backups
- [ ] Configure database replication (optional)

**Services:**

- [ ] Ensure all services start with Docker Compose
- [ ] Verify health endpoints return "healthy"
- [ ] Test NLP and Vision service integration
- [ ] Configure Redis persistence
- [ ] Set appropriate cache TTLs

**Monitoring:**

- [ ] Set up Prometheus + Grafana dashboards
- [ ] Configure log aggregation (ELK/Loki)
- [ ] Set up alerts for service failures
- [ ] Monitor WebSocket connection counts
- [ ] Track background task processing times

**Testing:**

- [ ] Test complete user registration flow
- [ ] Test report creation with media upload
- [ ] Test matching pipeline
- [ ] Test real-time messaging (WebSocket)
- [ ] Test mobile app connectivity
- [ ] Test admin panel functionality

**Documentation:**

- [ ] Update API documentation
- [ ] Document environment variables
- [ ] Create runbook for common issues
- [ ] Document backup/restore procedures

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

[Your License Here]

---

**Version**: 2.0.0  
**Last Updated**: January 2024  
**Status**: ✅ Production Ready
