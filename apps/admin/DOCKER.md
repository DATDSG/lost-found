# Admin Panel Docker Setup

This document explains how to run the Lost & Found admin panel using Docker.

## Prerequisites

- Docker and Docker Compose installed
- Backend services running (API, Database, Redis, MinIO)

## Quick Start

### Production Mode

To run the admin panel in production mode:

```bash
# From the project root
cd infra/compose
docker-compose up admin
```

The admin panel will be available at `http://localhost:3000`

### Development Mode

To run the admin panel in development mode with hot reload:

```bash
# From the project root
cd infra/compose
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up admin
```

## Environment Variables

The admin panel uses the following environment variables:

- `NEXT_PUBLIC_API_URL`: Backend API URL (default: `http://api:8000` for Docker, `http://localhost:8000` for local)
- `NODE_ENV`: Environment mode (`production` or `development`)
- `PORT`: Port to run the application (default: `3000`)

## Docker Configuration

### Production Dockerfile

The production Dockerfile (`Dockerfile`) uses a multi-stage build:
1. **deps**: Installs production dependencies
2. **builder**: Builds the Next.js application
3. **runner**: Creates the final production image

### Development Dockerfile

The development Dockerfile (`Dockerfile.dev`) is optimized for development with:
- Hot reloading enabled
- Source code mounted as volume
- Development dependencies included

## Backend Connection

The admin panel connects to the backend API service through Docker networking:

- **Internal Docker Network**: `http://api:8000`
- **External Access**: `http://localhost:8000`

## CORS Configuration

The backend API is configured to allow requests from:
- `http://localhost:3000` (local development)
- `http://admin:3000` (Docker internal network)

## Troubleshooting

### Build Issues

If you encounter build issues:

```bash
# Clean Docker cache
docker system prune -a

# Rebuild without cache
docker-compose build --no-cache admin
```

### Connection Issues

If the admin panel can't connect to the backend:

1. Ensure the API service is running and healthy
2. Check the `NEXT_PUBLIC_API_URL` environment variable
3. Verify CORS configuration in the API service

### Port Conflicts

If port 3000 is already in use:

```bash
# Use a different port
ADMIN_PORT=3001 docker-compose up admin
```

## Full Stack Deployment

To run the entire Lost & Found platform including the admin panel:

```bash
# Production
docker-compose up

# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

This will start all services:
- PostgreSQL Database
- Redis Cache
- MinIO Object Storage
- API Backend
- NLP Service
- Vision Service
- Admin Panel

## Monitoring

You can monitor the admin panel logs:

```bash
docker-compose logs -f admin
```

## Health Checks

The admin panel includes health checks to ensure it's running properly. You can check the status:

```bash
docker-compose ps admin
```
