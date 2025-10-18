# Lost & Found Platform

A comprehensive lost and found item tracking system with mobile app, admin panel, and AI-powered matching.

## 🚀 Quick Start

**New to the project?** Start here: [`GETTING_STARTED.md`](GETTING_STARTED.md)

## 📱 Platform Components

### Mobile App (Flutter)

Cross-platform mobile application for reporting and finding lost items.

- Location: `apps/mobile/`
- Guide: [`apps/mobile/README.md`](apps/mobile/README.md)
- Quick Start: [`apps/mobile/QUICK_START.md`](apps/mobile/QUICK_START.md)

### Admin Panel (React)

Web-based administration interface for managing the platform.

- Location: `apps/admin/`
- Guide: [`apps/admin/README.md`](apps/admin/README.md)
- Quick Start: [`apps/admin/QUICK_START.md`](apps/admin/QUICK_START.md)

### Backend Services

#### API Service (FastAPI)

Main REST API server handling all business logic.

- Location: `services/api/`
- Documentation: [`API_ENDPOINTS.md`](API_ENDPOINTS.md)

#### NLP Service

Natural language processing for intelligent item matching.

- Location: `services/nlp/`

#### Vision Service

Computer vision service for image-based item recognition using YOLO.

- Location: `services/vision/`

## 🗄️ Database

PostgreSQL database with pgvector extension for AI-powered semantic search.

- Setup Guide: [`DATABASE_SETUP_README.md`](DATABASE_SETUP_README.md)
- Quick Setup: [`DATABASE_QUICK_SETUP.md`](DATABASE_QUICK_SETUP.md)
- Schema: [`data/queries/`](data/queries/)

## 🐳 Infrastructure

Docker-based infrastructure with monitoring and logging.

- Location: `infra/compose/`
- Docker Compose configuration
- Grafana dashboards
- Prometheus monitoring
- Loki logging

## 📚 Documentation

### Essential Guides

- **[Getting Started](GETTING_STARTED.md)** - Complete project overview and setup
- **[Documentation Guide](DOCUMENTATION_GUIDE.md)** - Map of all documentation
- **[API Endpoints](API_ENDPOINTS.md)** - API reference
- **[Database Setup](DATABASE_SETUP_README.md)** - Complete database guide
- **[Continue Without Database](CONTINUE_WITHOUT_DATABASE.md)** - Mock development setup

### App-Specific Guides

- **Mobile:** Testing Guide, Backend Integration
- **Admin:** Services Guide

## 🛠️ Technology Stack

### Frontend

- **Mobile:** Flutter, Dart
- **Admin:** React, TypeScript, Vite

### Backend

- **API:** FastAPI, Python
- **Database:** PostgreSQL 18, pgvector
- **Cache:** Redis (optional)

### AI/ML

- **NLP:** Sentence transformers, semantic search
- **Vision:** YOLO object detection

### Infrastructure

- **Containers:** Docker, Docker Compose
- **Monitoring:** Grafana, Prometheus, Loki

## 🚦 Development Workflow

### 1. Setup Environment

```bash
# Clone repository
git clone <repository-url>
cd lost-found

# See GETTING_STARTED.md for detailed setup
```

### 2. Run Mobile App (Quick Start)

```bash
cd apps/mobile
python mock_server.py  # Start mock API server
flutter run           # Run mobile app
```

### 3. Run Services

```bash
# Start all services with Docker
cd infra/compose
docker-compose up
```

### 4. Run Admin Panel

```bash
cd apps/admin
npm install
npm run dev
```

## 📂 Project Structure

```
lost-found/
├── apps/
│   ├── mobile/          # Flutter mobile app
│   └── admin/           # React admin panel
├── services/
│   ├── api/            # FastAPI backend
│   ├── nlp/            # NLP matching service
│   └── vision/         # Computer vision service
├── data/
│   ├── queries/        # SQL schema and queries
│   ├── seed/           # Sample data
│   └── migrations/     # Database migrations
├── infra/
│   └── compose/        # Docker infrastructure
└── docs/               # Documentation

```

## 🧪 Testing

### Mobile App

See [`apps/mobile/TESTING_GUIDE.md`](apps/mobile/TESTING_GUIDE.md)

### API

```bash
cd services/api
pytest
```

## 🤝 Contributing

1. Follow the existing code structure
2. Update documentation for new features
3. Write tests for new functionality
4. Keep commits focused and descriptive

## 📄 License

[Add your license information here]

## 📞 Support

For questions or issues, please refer to:

- [Documentation Guide](DOCUMENTATION_GUIDE.md) - Find the right documentation
- [Getting Started](GETTING_STARTED.md) - Setup and onboarding
- [API Documentation](API_ENDPOINTS.md) - API reference

---

**Ready to start?** Head to [`GETTING_STARTED.md`](GETTING_STARTED.md) for a complete walkthrough!
