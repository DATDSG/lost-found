# Lost & Found Platform

A comprehensive, AI-powered lost item recovery system built with modern microservices architecture. This platform leverages artificial intelligence, computer vision, and natural language processing to intelligently match lost items with found items across multiple platforms.

## 🎯 Overview

The Lost & Found Platform addresses the critical need for efficient lost item recovery systems by combining:

- **AI-Powered Matching**: Advanced algorithms using NLP and computer vision
- **Multi-Platform Support**: Mobile app, admin panel, and API services
- **Geographic Intelligence**: Location-based proximity matching
- **Real-time Processing**: Fast, scalable microservices architecture
- **Comprehensive Management**: Full admin dashboard with analytics

## 🏗️ Architecture

The system follows Domain-Driven Design (DDD) principles with a microservices architecture:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │   Admin Panel   │    │   External APIs │
│   (Flutter)     │    │   (Next.js)     │    │                 │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────┴─────────────┐
                    │      Load Balancer       │
                    │        (Nginx)            │
                    └─────────────┬─────────────┘
                                 │
                    ┌─────────────┴─────────────┐
                    │      API Gateway         │
                    │       (FastAPI)          │
                    └─────────────┬─────────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                       │                        │
┌───────┴───────┐    ┌─────────┴─────────┐    ┌────────┴────────┐
│   Database    │    │   Redis Cache     │    │   MinIO Storage │
│  (PostgreSQL) │    │                   │    │                 │
└───────────────┘    └───────────────────┘    └─────────────────┘
        │                       │                        │
        └───────────────────────┼────────────────────────┘
                                │
                    ┌─────────────┴─────────────┐
                    │    Microservices         │
                    │  ┌─────────┐ ┌─────────┐ │
                    │  │   NLP   │ │ Vision  │ │
                    │  │ Service │ │ Service │ │
                    │  └─────────┘ └─────────┘ │
                    └───────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Git
- Node.js 18+ (for local development)
- Python 3.11+ (for local development)
- Flutter 3.16+ (for mobile development)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-username/lost-found.git
   cd lost-found
   ```

2. **Set up environment variables**

   ```bash
   cp infra/compose/env.example infra/compose/.env
   # Edit the .env file with your configuration
   ```

3. **Start the services**

   ```bash
   cd infra/compose
   docker-compose up -d
   ```

4. **Access the applications**
   - **Admin Panel**: <http://localhost:3000>
   - **API Documentation**: <http://localhost:8000/docs>
   - **Database Admin**: <http://localhost:5050>
   - **MinIO Console**: <http://localhost:9001>
   - **Nginx Gateway**: <http://localhost:8080>

### Default Credentials

- **Admin Panel**: `admin@lostfound.com` / `admin123`
- **Database**: `postgres` / `postgres`
- **MinIO**: `minioadmin` / `minioadmin123`
- **pgAdmin**: `admin@lostfound.com` / `postgres`

## 📱 Applications

### Mobile App (Flutter)

- **Location**: `apps/mobile/`
- **Features**: Offline support, camera integration, GPS tracking, multi-language support
- **Architecture**: Clean Architecture with Feature-Driven Development
- **State Management**: Riverpod
- **Navigation**: Go Router

### Admin Panel (Next.js)

- **Location**: `apps/admin/`
- **Features**: Dashboard, user management, report management, analytics
- **Tech Stack**: Next.js 14, TypeScript, Tailwind CSS, React Query
- **Authentication**: JWT-based with role-based access control

### API Service (FastAPI)

- **Location**: `services/api/`
- **Features**: RESTful API, authentication, report management, matching
- **Database**: PostgreSQL with PostGIS for geospatial data
- **Caching**: Redis for performance optimization
- **Storage**: MinIO for file storage

### AI Services

- **NLP Service**: `services/nlp/` - Text similarity matching
- **Vision Service**: `services/vision/` - Image similarity matching

## 🛠️ Development

### Local Development Setup

1. **Backend Services**

   ```bash
   cd services/api
   pip install -r requirements.txt
   uvicorn app.main:app --reload --port 8000
   ```

2. **Admin Panel**

   ```bash
   cd apps/admin
   npm install
   npm run dev
   ```

3. **Mobile App**

   ```bash
   cd apps/mobile
   flutter pub get
   flutter run
   ```

### Running Tests

```bash
# Run comprehensive tests
./run_comprehensive_tests.sh

# Or on Windows
run_comprehensive_tests.bat
```

### Code Quality

- **Linting**: ESLint, Flutter Lints, Python Black
- **Testing**: Jest, Flutter Test, pytest
- **Coverage**: Minimum 80% code coverage
- **Security**: Automated security scanning

## 🔧 Configuration

### Environment Variables

Key configuration options in `infra/compose/.env`:

```bash
# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=lostfound

# Redis
REDIS_PASSWORD=LF_Redis_2025_Pass!

# JWT
JWT_SECRET_KEY=super-secret-jwt-key-change-me-in-production

# Service Ports
API_PORT=8000
ADMIN_PORT=3000
NLP_PORT=8001
VISION_PORT=8002
```

### Feature Flags

- `FRAUD_DETECTION_ENABLED`: Enable fraud detection algorithms
- `AUDIT_LOGS_ENABLED`: Enable comprehensive audit logging
- `MATCHING_ENABLED`: Enable AI-powered matching
- `RATE_LIMIT_ENABLED`: Enable API rate limiting

## 📊 Features

### Core Features

- **User Management**: Registration, authentication, profile management
- **Report Management**: Lost/found item reporting with media upload
- **AI Matching**: Intelligent matching using text and image similarity
- **Location Services**: GPS-based location tracking and proximity matching
- **Admin Dashboard**: Comprehensive management interface
- **Analytics**: Detailed reporting and performance metrics

### AI-Powered Matching

- **Text Similarity**: NLP-based text matching using multiple algorithms
- **Image Similarity**: Computer vision-based image matching
- **Geographic Matching**: Location-based proximity matching
- **Temporal Matching**: Time-based relevance scoring
- **Combined Scoring**: Weighted multi-factor matching algorithm

### Security Features

- **Authentication**: JWT-based with refresh tokens
- **Authorization**: Role-based access control
- **Data Protection**: Encryption at rest and in transit
- **Rate Limiting**: Protection against abuse
- **Audit Logging**: Comprehensive security event logging

## 📈 Performance

### System Requirements

- **Minimum**: 4GB RAM, 2 CPU cores
- **Recommended**: 8GB RAM, 4 CPU cores
- **Storage**: 20GB+ for development, 100GB+ for production

### Performance Metrics

- **API Response Time**: < 200ms (95th percentile)
- **Concurrent Users**: 1000+ supported
- **Requests Per Second**: 500+ RPS sustained
- **Matching Accuracy**: 85%+ for combined matching

## 🔒 Security

### Authentication & Authorization

- JWT tokens with RS256 algorithm
- Short-lived access tokens (30 minutes)
- Long-lived refresh tokens (7 days)
- Argon2id password hashing

### Data Protection

- TLS 1.3 encryption in transit
- Database encryption at rest
- Field-level encryption for sensitive data
- GDPR compliance features

### Security Monitoring

- Automated threat detection
- Anomaly detection
- Security event logging
- Incident response procedures

## 🚀 Deployment

### Production Deployment

1. **Environment Setup**

   ```bash
   # Set production environment variables
   export ENVIRONMENT=production
   export LOG_LEVEL=WARNING
   ```

2. **Database Migration**

   ```bash
   cd services/api
   alembic upgrade head
   ```

3. **Docker Deployment**

   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

### Monitoring

- **Metrics**: Prometheus + Grafana
- **Logging**: Structured JSON logging
- **Health Checks**: Comprehensive health monitoring
- **Alerting**: Automated alerting for critical issues

## 📚 Documentation

- [Comprehensive Project Report](COMPREHENSIVE_PROJECT_REPORT.md)
- [Testing Report](COMPREHENSIVE_TESTING_REPORT.md)
- [API Documentation](http://localhost:8000/docs)
- [Mobile App README](apps/mobile/README.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow the existing code style and architecture patterns
- Write comprehensive tests for new features
- Update documentation for any API changes
- Ensure all tests pass before submitting PR

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎓 Academic Research

This project is part of academic research following Design Science Research (DSR) methodology. Key research contributions:

- Novel hybrid matching algorithm combining NLP and computer vision
- Framework for evaluating AI-powered matching systems
- Real-world deployment case studies
- Performance analysis and optimization techniques

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-username/lost-found/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/lost-found/discussions)
- **Email**: <support@lostfound.com>

## 🙏 Acknowledgments

- Flutter team for the excellent mobile framework
- FastAPI team for the high-performance API framework
- PostgreSQL and PostGIS for robust geospatial capabilities
- The open-source community for the amazing tools and libraries

---

**Version**: 1.0.0  
**Last Updated**: January 2025  
**Status**: Production Ready
