# Lost & Found Platform

A comprehensive, AI-powered lost and found item tracking system with cross-platform mobile app, intelligent admin panel, and advanced matching algorithms powered by machine learning.

## 📖 Project Overview

The Lost & Found Platform is designed to efficiently facilitate the recovery of lost items through intelligent AI-powered matching. The system connects individuals who have lost items with those who have found items, using advanced matching algorithms that combine natural language processing, computer vision, and geographic proximity analysis.

### Problem Statement

Current lost and found systems lack intelligent matching capabilities, making it difficult for users to find their items or reconnect lost items with their owners. This platform solves this by:

- **Intelligent Matching:** Uses AI to match lost items with found items based on descriptions, images, location, and time
- **Multi-Platform Access:** Available on mobile devices and web for maximum accessibility
- **Real-Time Processing:** Instant notifications and matches for users
- **Secure & Private:** User data protection and privacy compliance

### Key Features

#### For End Users

- **Report Lost/Found Items:** Easily report lost or found items with descriptions, photos, and location
- **AI-Powered Matching:** Automatic matching suggestions based on AI algorithms
- **Location Services:** GPS-based location tracking and proximity matching
- **Real-Time Notifications:** Instant alerts when potential matches are found
- **Secure Messaging:** Contact matched users securely through the platform
- **Item Categories:** Organized categorization system for better searchability
- **Offline Support:** Use app features offline with automatic sync when online

#### For Administrators

- **Dashboard Analytics:** Real-time statistics and platform metrics
- **User Management:** Manage users, roles, and permissions
- **Report Moderation:** Review and approve/reject reports
- **Match Validation:** Verify and manage matching results
- **Fraud Detection:** Automated detection of suspicious activities
- **Audit Logs:** Complete audit trail of all platform activities
- **Advanced Analytics:** Detailed reports on system usage and effectiveness

## 🚀 Quick Start

**New to the project?** Follow the setup instructions below.

## 📱 Platform Components

### Mobile App (Flutter)

Cross-platform mobile application for iOS and Android, allowing users to report lost/found items and receive matches.

- **Location:** `apps/mobile/`
- **Guide:** [`apps/mobile/README.md`](apps/mobile/README.md)
- **Quick Start:** [`apps/mobile/QUICK_START.md`](apps/mobile/QUICK_START.md)
- **Features:**
  - Offline-first architecture with local data persistence
  - Real-time location services with GPS integration
  - Camera integration for item photo capture
  - Multi-language support (English, Sinhala, Tamil)
  - Dark mode theme support
  - Push notifications for match alerts

### Admin Panel (React)

Modern web-based administration interface for platform managers and moderators.

- **Location:** `apps/admin/`
- **Guide:** [`apps/admin/README.md`](apps/admin/README.md)
- **Features:**
  - Real-time dashboard with key metrics
  - User and report management interface
  - Match validation and review tools
  - Fraud detection and monitoring
  - Comprehensive analytics and reporting
  - Audit log visualization

### Backend Services

#### API Service (FastAPI)

Main REST API server handling all business logic, user authentication, data management, and orchestration.

- **Location:** `services/api/`
- **Responsibilities:**
  - User authentication and authorization (JWT)
  - Report management (CRUD operations)
  - Match processing and orchestration
  - Media upload and management
  - Real-time notifications
  - Admin operations and audit logging
- **Architecture:** Clean architecture with domain-driven design
- **Database:** PostgreSQL 18 with PostGIS for geospatial queries

#### NLP Service

Natural language processing service for intelligent text-based matching and similarity analysis.

- **Location:** `services/nlp/`
- **Capabilities:**
  - Text similarity analysis using sentence transformers
  - Semantic search and matching
  - Description normalization and tokenization
  - Item categorization and tagging
  - Multi-language support

#### Vision Service

Computer vision service for image-based item recognition and matching.

- **Location:** `services/vision/`
- **Capabilities:**
  - Image feature extraction
  - Perceptual hashing for image similarity
  - YOLO-based object detection
  - Color histogram analysis
  - Image-to-image matching
  - Duplicate detection

## 🗄️ Database

**PostgreSQL 18** with specialized extensions:

- **PostGIS:** Geospatial data types and functions for location-based queries
- **pgvector:** Vector similarity search for AI-powered semantic matching
- **UUID:** For globally unique identifiers
- **JSON:** For flexible metadata storage

### Core Tables

- **Users:** User profiles, authentication, and roles
- **Reports:** Lost and found item reports with metadata
- **Media:** Images and files associated with reports
- **Matches:** Matching results between lost and found items
- **Audit Logs:** Complete audit trail of all activities

## 🐳 Infrastructure & Deployment

Docker-based containerized infrastructure with comprehensive monitoring, logging, and orchestration.

- **Location:** `infra/compose/`
- **Components:**
  - **Docker Compose:** Local development and production deployment
  - **Nginx:** Reverse proxy and load balancing
  - **Grafana:** Metrics visualization and dashboards
  - **Prometheus:** Metrics collection and monitoring
  - **Loki:** Centralized logging system
  - **pgAdmin:** Database management interface
  - **Redis:** Optional caching layer for performance

## 📚 Documentation

### Essential Guides

- **[Mobile App](apps/mobile/README.md)** - Flutter mobile app setup, features, and development
- **[Admin Panel](apps/admin/README.md)** - React admin interface documentation
- **[Mobile Quick Start](apps/mobile/QUICK_START.md)** - Fast mobile app setup guide
- **[API Documentation](#api-endpoints)** - REST API endpoint reference

## 🛠️ Technology Stack

### Frontend Technologies

#### Mobile App (Flutter)

- **Framework:** Flutter 3.16.0+, Dart 3.8.0+
- **State Management:** Riverpod 2.4.9
- **Navigation:** Go Router 14.2.7
- **HTTP Client:** Dio 5.4.0
- **Local Storage:** Hive 2.2.3, SharedPreferences 2.2.2
- **Location:** Geolocator 10.1.0, Geocoding 2.1.1
- **Media:** Image Picker 1.0.4, Cached Network Image 3.3.0
- **Authentication:** Local Auth with biometric support

#### Admin Panel (React)

- **Framework:** React 18.2.0, Next.js 14.0.0
- **Language:** TypeScript 5.0.0
- **Styling:** Tailwind CSS 3.3.0
- **Build Tool:** Vite
- **State Management:** React Query 3.39.0
- **Forms:** React Hook Form 7.47.0
- **Charts:** Recharts 2.8.0
- **UI Components:** Headless UI, Heroicons 2.0.0

### Backend Technologies

#### API Service (FastAPI)

- **Framework:** FastAPI 0.115.5, Python 3.11+
- **ASGI Server:** Uvicorn 0.32.1
- **ORM:** SQLAlchemy 2.0.36
- **Database Driver:** psycopg2-binary
- **Authentication:** JWT with python-jose
- **Data Validation:** Pydantic v2
- **Caching:** Redis 7-alpine
- **File Storage:** MinIO 7.2.8
- **Background Tasks:** ARQ 0.26.1
- **API Documentation:** Swagger/OpenAPI

#### NLP Service (FastAPI)

- **Framework:** FastAPI
- **NLP Libraries:** NLTK, spaCy, scikit-learn
- **Embeddings:** Sentence Transformers
- **Vectorization:** TF-IDF, Word2Vec
- **Text Processing:** Tokenization, stemming, lemmatization

#### Vision Service (FastAPI)

- **Framework:** FastAPI
- **Computer Vision:** OpenCV, PIL
- **Object Detection:** YOLO (YOLOv8)
- **Feature Extraction:** ORB, SIFT
- **Hash Algorithms:** Perceptual hashing, color histograms

### Database & Storage

- **Primary Database:** PostgreSQL 18 with PostGIS 3.4
- **Vector Database:** pgvector extension
- **Caching Layer:** Redis 7-alpine
- **Object Storage:** MinIO 7.2.8
- **Monitoring:** Prometheus 0.21.1, Grafana, Loki

### Infrastructure & DevOps

- **Containerization:** Docker, Docker Compose
- **Reverse Proxy:** Nginx
- **Metrics:** Prometheus + Grafana
- **Logging:** Structured logging with Loki
- **CI/CD:** GitHub Actions (configured in .github/)

## 🏗️ System Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │   Admin Panel   │
│   (Flutter)     │    │   (React/Next)  │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          └──────────────────────┼──────────────┐
                                 │              │
                    ┌─────────────┴──────────┐  │
                    │   Nginx Load Balancer │  │
                    └─────────────┬──────────┘  │
                                 │              │
                    ┌─────────────┴──────────┐  │
                    │   FastAPI Gateway     │◄─┘
                    │   (Authentication)    │
                    └─────────────┬──────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                       │                        │
┌───────┴──────────┐   ┌─────────┴─────────┐   ┌────────┴────────┐
│   PostgreSQL     │   │   Redis Cache     │   │   MinIO Storage │
│   + PostGIS      │   │                   │   │                 │
│   + pgvector     │   │                   │   │                 │
└────────┬─────────┘   └───────────────────┘   └─────────────────┘
         │
         │
    ┌────┴────────────────────────┐
    │    Microservices             │
    │  ┌─────────┐  ┌──────────┐  │
    │  │   NLP   │  │ Vision   │  │
    │  │ Service │  │ Service  │  │
    │  └─────────┘  └──────────┘  │
    └──────────────────────────────┘
```

### Matching Algorithm Flow

1. **User Reports Item:** User creates a report with description, photos, and location
2. **Data Processing:**
   - NLP Service extracts semantic features from description
   - Vision Service extracts visual features from images
   - Location data is indexed for geographic queries
3. **Matching Engine:**
   - Text similarity matching using sentence transformers
   - Image similarity matching using perceptual hashing
   - Geographic proximity scoring using PostGIS
   - Temporal matching based on dates
4. **Result Ranking:** Combined scoring with weighted factors
5. **User Notification:** Real-time notification of potential matches

## 🚦 Setup & Development Workflow

### Prerequisites

- Docker and Docker Compose
- Flutter SDK 3.16.0+ (for mobile development)
- Node.js 18+ (for admin panel)
- Python 3.11+ (for backend services)
- PostgreSQL 18+ (if running locally without Docker)

### 1. Clone & Setup Environment

bash

# Clone repository

git clone <repository-url>
cd lost-found

# Copy environment template

cp .env.template .env

# Edit .env with your configuration

```

### 2. Run Full Stack with Docker

bash
cd infra/compose
docker-compose up -d
# Services will be available at:
# - API: http://localhost:8000
# - Admin: http://localhost:3000
# - pgAdmin: http://localhost:5050
# - Grafana: http://localhost:3001
```

### 3. Run Mobile App (Development)

bash
cd apps/mobile
flutter pub get
flutter run

```

### 4. Run Admin Panel (Development)

bash
cd apps/admin
npm install
npm run dev
# Available at http://localhost:3000
```

### 5. Run Backend Services Individually

bash

# API Service

cd services/api
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload

# NLP Service

cd services/nlp
pip install -r requirements.txt
python main.py

# Vision Service

cd services/vision
pip install -r requirements.txt
python main.py

```

## 📂 Project Structure

```

lost-found/
├── apps/
│   ├── mobile/
│   │   ├── lib/                 # Dart source code
│   │   ├── test/                # Flutter unit tests
│   │   ├── pubspec.yaml         # Flutter dependencies
│   │   └── README.md            # Mobile app documentation
│   └── admin/
│       ├── pages/               # Next.js pages
│       ├── components/          # React components
│       ├── services/            # API client services
│       ├── package.json         # npm dependencies
│       └── README.md            # Admin panel documentation
├── services/
│   ├── api/
│   │   ├── app/
│   │   │   ├── models/          # SQLAlchemy models
│   │   │   ├── schemas/         # Pydantic schemas
│   │   │   ├── routes/          # API endpoints
│   │   │   └── core/            # Configuration, auth, etc.
│   │   ├── tests/               # Unit and integration tests
│   │   ├── requirements.txt     # Python dependencies
│   │   └── Dockerfile
│   ├── nlp/
│   │   ├── main.py              # NLP service entry point
│   │   ├── requirements.txt     # Dependencies
│   │   └── Dockerfile
│   └── vision/
│       ├── main.py              # Vision service entry point
│       ├── requirements.txt     # Dependencies
│       └── Dockerfile
├── infra/
│   └── compose/
│       ├── docker-compose.yml   # Full stack orchestration
│       ├── env.example          # Environment variables template
│       ├── nginx/               # Nginx configuration
│       └── init/                # Database initialization scripts
├── .github/
│   └── workflows/               # CI/CD pipelines
├── .env.template                # Environment template
├── README.md                     # This file
├── LICENSE                       # MIT License
└── .gitignore

```

## 🧪 Testing

### Mobile App Testing

bash
cd apps/mobile
flutter test
```

See [`apps/mobile/README.md`](apps/mobile/README.md) for detailed testing instructions.

### Backend API Testing

bash
cd services/api
pytest -v                    # Run all tests
pytest --cov               # Run with coverage
pytest tests/test_auth.py  # Run specific test file

```

### Admin Panel Testing

bash
cd apps/admin
npm test                   # Run test suite
npm run lint              # Lint code
```

## 🔐 Security Features

- **Authentication:** JWT-based authentication with refresh tokens
- **Password Security:** Argon2id hashing with unique salts
- **Rate Limiting:** Per-endpoint rate limiting to prevent abuse
- **CORS:** Configurable CORS policies
- **Encryption:** TLS 1.3 for data in transit
- **Audit Logging:** Complete audit trail of all activities
- **Data Privacy:** GDPR-compliant data handling
- **Input Validation:** Pydantic-based input validation

## 📊 API Endpoints

### Authentication

- `POST /v1/auth/login` - User login
- `POST /v1/auth/register` - User registration
- `POST /v1/auth/refresh` - Refresh access token
- `POST /v1/auth/logout` - User logout

### Reports

- `GET /v1/reports` - List all reports
- `POST /v1/reports` - Create new report
- `GET /v1/reports/{id}` - Get report details
- `PUT /v1/reports/{id}` - Update report
- `DELETE /v1/reports/{id}` - Delete report

### Matching

- `GET /v1/matches` - Get user's matches
- `POST /v1/matches/search` - Search for matches
- `GET /v1/matches/{id}` - Get match details
- `PUT /v1/matches/{id}/status` - Update match status

### Media

- `POST /v1/media/upload` - Upload image/file
- `GET /v1/media/{id}` - Get media details
- `DELETE /v1/media/{id}` - Delete media

### Admin

- `GET /v1/admin/dashboard` - Dashboard statistics
- `GET /v1/admin/users` - List all users
- `GET /v1/admin/reports` - List all reports
- `GET /v1/admin/matches` - List all matches

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/feature-name`
2. Follow the existing code structure and style
3. Write unit tests for new functionality (minimum 80% coverage)
4. Update documentation for new features
5. Keep commits focused and descriptive
6. Submit a pull request with detailed description

### Coding Standards

- **Python:** PEP 8 (checked with flake8, black)
- **TypeScript/JavaScript:** ESLint + Prettier
- **Dart:** Dart formatting with dartfmt

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 📞 Support & Contact

For questions, issues, or contributions:

1. **Mobile App Issues:** Check [`apps/mobile/README.md`](apps/mobile/README.md)
2. **Admin Panel Issues:** Check [`apps/admin/README.md`](apps/admin/README.md)
3. **Backend Issues:** Review [`services/api/`](services/api/) documentation
4. **General Issues:** Open a GitHub issue

## 🎯 Project Status

**Status:** Production Ready
**Version:** 1.0.0
**Last Updated:** November 2025

### Roadmap

- [ ] Mobile app optimization for low-end devices
- [ ] Advanced search filters and preferences
- [ ] Video support for item descriptions
- [ ] Blockchain-based item verification
- [ ] Integration with local law enforcement
- [ ] Mobile wallet for rewards system
- [ ] Cloud synchronization across devices
