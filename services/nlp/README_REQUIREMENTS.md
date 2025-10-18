# Requirements Optimization Guide

## 📦 Overview

This directory contains optimized requirements files for different deployment scenarios:

- **`requirements.txt`** - Production (CPU-only, lightweight) ✅ **Recommended**
- **`requirements-gpu.txt`** - GPU support (heavy, 8-10GB+ image)
- **`requirements-dev.txt`** - Development & testing tools

## 🎯 Quick Start (CPU - Recommended)

**Docker Image Size: ~2-3GB**

```bash
# Build lightweight CPU image
docker build -t nlp-service:latest .

# Run
docker run -p 8001:8001 nlp-service:latest
```

## 🚀 GPU Support (Optional)

**Docker Image Size: 8-10GB+**

Only use if you have:

- NVIDIA GPU with CUDA support
- NVIDIA Docker runtime installed
- High-performance requirements

```bash
# Build GPU image
docker build -f Dockerfile.gpu -t nlp-service:gpu .

# Run with GPU
docker run --gpus all -p 8001:8001 nlp-service:gpu
```

## 📊 Size Comparison

| Version           | Image Size | PyTorch           | Build Time | Use Case                        |
| ----------------- | ---------- | ----------------- | ---------- | ------------------------------- |
| **CPU (Default)** | ~2-3GB     | CPU-only (~200MB) | ~5-10 min  | Production, most deployments    |
| **GPU**           | ~8-10GB    | CUDA (~2GB+)      | ~15-30 min | High-performance, GPU available |

## 🔧 Dependencies Breakdown

### Base Requirements (CPU)

- **FastAPI & Uvicorn**: Web framework (~50MB)
- **PyTorch CPU**: Deep learning (~200MB)
- **Transformers**: NLP models (~150MB)
- **Sentence Transformers**: Semantic search (~100MB)
- **Redis, Prometheus**: Infrastructure (~50MB)

### GPU Additions

- **PyTorch GPU (CUDA)**: +2GB
- **Additional CUDA libraries**: +500MB

## 💡 Recommendations

### ✅ Use CPU Version If:

- You don't have a GPU
- You're deploying to cloud (cost-effective)
- Your load is moderate (<1000 requests/min)
- You want faster build and deployment times

### ⚡ Use GPU Version If:

- You have NVIDIA GPU hardware
- You need maximum performance (>1000 requests/min)
- You're processing large batches
- Latency is critical (<50ms response time)

## 🛠️ Development

```bash
# Install all dependencies including dev tools
pip install -r requirements.txt -r requirements-dev.txt

# Or for GPU development
pip install -r requirements-gpu.txt -r requirements-dev.txt
```

## 📝 Notes

- CPU version uses PyTorch index: `https://download.pytorch.org/whl/cpu`
- GPU version uses PyTorch index: `https://download.pytorch.org/whl/cu118`
- Models are downloaded on first request (~500MB)
- Consider pre-downloading models in Dockerfile for production

## 🔍 Verify Installation

```python
# Check PyTorch installation
import torch
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")

# Check sentence-transformers
from sentence_transformers import SentenceTransformer
model = SentenceTransformer('intfloat/e5-small-v2')
print("✅ Sentence transformers working!")
```
