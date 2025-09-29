# Lost & Found System

A comprehensive trilingual (English, Sinhala, Tamil) lost and found platform with AI-powered matching capabilities.

## Architecture

```
lost-found/
├── frontend/           # Frontend applications
│   ├── web-admin/     # Admin dashboard (Next.js)
│   └── mobile/        # Mobile app (Flutter)
├── backend/           # Backend services
│   ├── api/          # Main API service (FastAPI)
│   ├── nlp/          # NLP processing service
│   ├── vision/       # Computer vision service
│   └── worker/       # Background job processor
├── shared/           # Shared resources
│   ├── types/        # Type definitions
│   └── config/       # Configuration files
├── tools/            # Development and analysis tools
├── deployment/       # Deployment configurations
└── docs/            # Documentation
```

## Quick Start

### Prerequisites

- Python 3.11+
- Node.js 18+
- Flutter 3.19+
- PostgreSQL with PostGIS
- Redis (optional, for caching)

### Development Setup

1. **Backend Services**

   ```bash
   cd backend/api
   python -m venv venv
   source venv/bin/activate  # or venv\Scripts\activate on Windows
   pip install -r requirements.txt
   uvicorn app.main:app --reload
   ```

2. **Admin Dashboard**

   ```bash
   cd frontend/web-admin
   npm install
   npm run dev
   ```

3. **Mobile App**
   ```bash
   cd frontend/mobile
   flutter pub get
   flutter run
   ```

## Features

- **Trilingual Support**: English, Sinhala, Tamil
- **AI-Powered Matching**: Smart item matching using NLP and computer vision
- **Geospatial Search**: Location-based item discovery
- **Real-time Notifications**: Instant match alerts
- **Admin Dashboard**: Comprehensive management interface
- **Mobile App**: Cross-platform mobile application

## Technology Stack

- **Backend**: FastAPI, PostgreSQL, Redis, Python
- **Frontend**: Next.js, React, TypeScript
- **Mobile**: Flutter, Dart
- **AI/ML**: Sentence Transformers, OpenCV, scikit-learn
- **Infrastructure**: Docker, Docker Compose

## Research Components

This project serves as a comprehensive research platform for multilingual, multi-modal information retrieval. Key research areas include:

### 🔬 **Active Research Areas**

- **Cross-lingual Item Matching**: Semantic similarity across English, Sinhala, and Tamil
- **Multi-modal Fusion**: Optimal combination of text, image, location, and temporal signals
- **Privacy-Preserving Geospatial Matching**: Location accuracy vs. privacy trade-offs
- **Adaptive Learning Systems**: Continuous improvement from user feedback

### 📊 **Research Framework Features**

- **Comprehensive Evaluation Metrics**: Recall@K, MRR, precision, latency analysis
- **A/B Testing Infrastructure**: Live experiment framework with statistical analysis
- **Cross-lingual Performance Analysis**: Language pair effectiveness evaluation
- **Continuous Learning Pipeline**: Automatic weight optimization from user interactions

### 🎯 **Research Applications**

- **Academic Publications**: Framework for reproducible multilingual AI research
- **Industry Applications**: Production-ready optimization techniques
- **Open Source Contribution**: Research tools and benchmarks for the community
- **Educational Use**: Learning platform for multilingual AI development

### 📚 **Research Documentation**

- **[Research Proposal](docs/RESEARCH_PROPOSAL.md)**: Comprehensive research plan and methodology
- **[Research Configuration](docs/RESEARCH_CONFIGURATION.md)**: Detailed experimental setup and parameters
- **[Research Implementation](docs/RESEARCH_IMPLEMENTATION.md)**: Complete implementation guide and usage examples
- **[Research Results](research_output/reports/)**: Experimental results and analysis reports

### 🚀 **Getting Started with Research**

```bash
# Enable research mode
export ENV=research
export NLP_ON=true
export CV_ON=true

# Run research experiments
python tools/run_research_experiments.py --experiment all

# View results
ls research_output/reports/
```

**Expected Research Impact**:

- 20-30% improvement in matching accuracy
- Academic publications in top-tier venues (AAAI, SIGIR, ICML)
- Open source framework for multilingual AI research
- Industry adoption of optimization techniques

## License

MIT License - see LICENSE file for details
