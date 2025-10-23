# Lost & Found Platform

A comprehensive lost and found item tracking system with mobile app, admin panel, and AI-powered matching.

## 🚀 Quick Start

**New to the project?** Follow the setup instructions below.

## 📱 Platform Components

### Mobile App (Flutter)

Cross-platform mobile application for reporting and finding lost items.

- Location: `apps/mobile/`
- Guide: [`apps/mobile/README.md`](apps/mobile/README.md)
- Quick Start: [`apps/mobile/QUICK_START.md`](apps/mobile/QUICK_START.md)
- **Note**: Mobile app runs natively with Flutter (not containerized)

### Admin Panel (React)

Web-based administration interface for managing the platform.

- Location: `apps/admin/`
- Guide: [`apps/admin/README.md`](apps/admin/README.md)

### Backend Services

#### API Service (FastAPI)

Main REST API server handling all business logic.

- Location: `services/api/`

#### NLP Service

Natural language processing for intelligent item matching.

- Location: `services/nlp/`

#### Vision Service

Computer vision service for image-based item recognition using YOLO.

- Location: `services/vision/`

## 🗄️ Database

PostgreSQL database with pgvector extension for AI-powered semantic search.

- Setup: See Docker Compose configuration in `infra/compose/`

## 🐳 Infrastructure

Docker-based infrastructure with monitoring and logging.

- Location: `infra/compose/`
- Docker Compose configuration
- Grafana dashboards
- Prometheus monitoring
- Loki logging

## 📚 Documentation

### Essential Guides

- **[Mobile App](apps/mobile/README.md)** - Flutter mobile app setup and features
- **[Admin Panel](apps/admin/README.md)** - React admin interface guide
- **[Mobile Quick Start](apps/mobile/QUICK_START.md)** - Fast mobile app setup

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
```

### 2. Run Mobile App (Quick Start)

```bash
cd apps/mobile
flutter pub get
flutter run
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
├── infra/
│   └── compose/        # Docker infrastructure
└── README.md           # Project documentation

```

## 🧪 Testing

### Mobile App

See [`apps/mobile/README.md`](apps/mobile/README.md) for testing instructions.

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

- [Mobile App Guide](apps/mobile/README.md) - Mobile app setup and features
- [Admin Panel Guide](apps/admin/README.md) - Admin interface documentation
