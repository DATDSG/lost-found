# Requirements Optimization Guide

## 📦 Overview

This directory contains optimized requirements files for different deployment scenarios:

- **`requirements.txt`** - Production (CPU-only, basic features) ✅ **Recommended**
- **`requirements-gpu.txt`** - GPU support (full ML features, 12-15GB+ image)

## 🎯 Quick Start (CPU - Recommended)

**Docker Image Size: ~800MB-1GB**

```bash
# Build lightweight CPU image
docker build -t vision-service:latest .

# Run
docker run -p 8002:8002 vision-service:latest
```

**Features Available (CPU):**

- ✅ Image validation & format checking
- ✅ Image hashing (duplicate detection)
- ✅ Basic OpenCV processing
- ✅ Color analysis
- ✅ Metadata extraction
- ❌ Object detection (YOLO) - Requires GPU
- ❌ OCR text extraction - Requires GPU
- ❌ CLIP embeddings - Requires GPU
- ❌ NSFW detection - Requires GPU

## 🚀 GPU Support (Full Features)

**Docker Image Size: 12-15GB+**

Only use if you have:

- NVIDIA GPU with CUDA support
- NVIDIA Docker runtime installed
- Need for advanced ML features

```bash
# Build GPU image with all features
docker build -f Dockerfile.gpu -t vision-service:gpu .

# Run with GPU
docker run --gpus all -p 8002:8002 vision-service:gpu
```

**Additional Features (GPU):**

- ✅ Object detection with YOLOv8
- ✅ OCR text extraction (EasyOCR)
- ✅ CLIP embeddings (image understanding)
- ✅ NSFW content detection
- ✅ Advanced image classification

## 📊 Size Comparison

| Version           | Image Size | Dependencies | Build Time | Models Download | Total Size |
| ----------------- | ---------- | ------------ | ---------- | --------------- | ---------- |
| **CPU (Default)** | ~800MB     | Basic only   | ~3-5 min   | None            | ~800MB-1GB |
| **GPU Full**      | ~8GB       | All ML libs  | ~20-40 min | ~2-4GB          | ~12-15GB   |

## 🔧 Dependencies Breakdown

### Base Requirements (CPU) - Lightweight

```
FastAPI & Uvicorn      ~50MB   - Web framework
Pillow                 ~10MB   - Image processing
OpenCV (headless)      ~80MB   - Computer vision
ImageHash              ~5MB    - Perceptual hashing
Redis, Prometheus      ~50MB   - Infrastructure
NumPy                  ~30MB   - Array operations
─────────────────────────────
TOTAL                  ~300MB + Python base
```

### GPU Additions (Heavy)

```
PyTorch + CUDA         ~2GB    - Deep learning framework
Ultralytics (YOLO)     ~200MB  - Object detection
EasyOCR                ~500MB  - OCR engine
CLIP                   ~1GB    - Image embeddings
Transformers           ~200MB  - NLP models
Scikit-learn           ~100MB  - ML utilities
Model files            ~2-4GB  - Pre-trained models
─────────────────────────────
TOTAL                  ~6-8GB additional
```

## 💡 Recommendations

### ✅ Use CPU Version If:

- You don't need object detection or OCR
- Basic image processing is sufficient
- You don't have a GPU
- Cost optimization is important
- Deployment to cloud/serverless
- Small to medium workloads

### ⚡ Use GPU Version If:

- You need object detection (finding items in images)
- OCR text extraction is required
- Advanced image similarity needed
- NSFW content filtering required
- You have GPU infrastructure
- High-volume image processing

## 🔄 Hybrid Approach

You can also:

1. **Use CPU version for basic validation**
2. **Call external ML APIs for advanced features**
   - AWS Rekognition
   - Google Cloud Vision
   - Azure Computer Vision

This gives you lightweight deployment + powerful ML when needed.

## 🛠️ Manual Installation

```bash
# CPU version (lightweight)
pip install -r requirements.txt

# GPU version (full features)
pip install -r requirements-gpu.txt
```

## 🎮 Feature Toggles

Set environment variables to control features:

```bash
# Disable heavy ML features (even if libraries installed)
export ENABLE_OBJECT_DETECTION=false
export ENABLE_OCR=false
export ENABLE_CLIP=false
export ENABLE_NSFW_DETECTION=false

# Enable basic features only
export USE_GPU=false
```

## 📝 GPU Setup Requirements

### Prerequisites

```bash
# Install NVIDIA Docker runtime
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

### Verify GPU

```bash
# Test GPU access
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

## 🔍 Verify Installation

```python
# CPU version
from PIL import Image
import imagehash
import cv2
print("✅ Basic image processing working!")

# GPU version
import torch
print(f"CUDA available: {torch.cuda.is_available()}")

from ultralytics import YOLO
model = YOLO('yolov8n.pt')
print("✅ YOLO object detection ready!")

import easyocr
reader = easyocr.Reader(['en'])
print("✅ OCR ready!")
```

## 📈 Performance Comparison

| Feature          | CPU  | GPU   | Speedup  |
| ---------------- | ---- | ----- | -------- |
| Image validation | 5ms  | 5ms   | 1x       |
| Image hashing    | 50ms | 50ms  | 1x       |
| Object detection | N/A  | 100ms | GPU only |
| OCR              | N/A  | 200ms | GPU only |
| CLIP embedding   | N/A  | 150ms | GPU only |

## 🌐 Cloud Deployment Costs

**Monthly Costs Estimate (24/7):**

- CPU version: $20-50/month (basic VM)
- GPU version: $200-500/month (GPU instance)

💡 **Recommendation:** Use CPU for validation, call ML APIs as needed.
