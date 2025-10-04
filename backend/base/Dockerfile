# Common base image for Lost & Found Python services
# Provides system build tools and curl, minimizes duplication.
# cspell:ignore libpq appuser gecos uvicorn spacy
FROM python:3.11-slim AS base

LABEL org.opencontainers.image.source="https://github.com/DATDSG/lost-found" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.vendor="LostFound" \
    org.opencontainers.image.title="lost-found-python-base" \
    org.opencontainers.image.description="Shared base layer with system deps for API, NLP, Vision, Worker"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Core system deps (alphabetized)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libpq-dev; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Non-root user creation (name kept generic)
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser:appuser /app
USER appuser

