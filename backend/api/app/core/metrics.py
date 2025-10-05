"""
Prometheus metrics for monitoring API performance.

Tracks:
- Request counts
- Response times
- Error rates
- Business metrics
"""
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import time
from app.core.config import settings

# Request metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint']
)

http_requests_in_progress = Gauge(
    'http_requests_in_progress',
    'HTTP requests in progress',
    ['method', 'endpoint']
)

# Business metrics
items_reported_total = Counter(
    'items_reported_total',
    'Total items reported',
    ['type', 'category']
)

matches_found_total = Counter(
    'matches_found_total',
    'Total matches found'
)

matches_accepted_total = Counter(
    'matches_accepted_total',
    'Total matches accepted by users'
)

claims_submitted_total = Counter(
    'claims_submitted_total',
    'Total claims submitted'
)

claims_approved_total = Counter(
    'claims_approved_total',
    'Total claims approved'
)

active_users = Gauge(
    'active_users',
    'Number of active users'
)

# Database metrics
db_connections_active = Gauge(
    'db_connections_active',
    'Active database connections'
)

db_query_duration_seconds = Histogram(
    'db_query_duration_seconds',
    'Database query duration in seconds',
    ['query_type']
)

# Service health metrics
service_health = Gauge(
    'service_health',
    'Service health status (1=healthy, 0=unhealthy)',
    ['service']
)

# ML service metrics
ml_inference_duration_seconds = Histogram(
    'ml_inference_duration_seconds',
    'ML inference duration in seconds',
    ['model_type']
)


class PrometheusMiddleware(BaseHTTPMiddleware):
    """Middleware to collect Prometheus metrics."""

    async def dispatch(self, request: Request, call_next):
        """Process request and collect metrics."""
        
        # Skip metrics endpoint itself
        if request.url.path == "/metrics":
            return await call_next(request)

        method = request.method
        path = request.url.path
        
        # Increment in-progress requests
        http_requests_in_progress.labels(method=method, endpoint=path).inc()
        
        # Track request duration
        start_time = time.time()
        
        try:
            response = await call_next(request)
            status = response.status_code
        except Exception as e:
            status = 500
            raise e
        finally:
            # Record metrics
            duration = time.time() - start_time
            
            http_requests_total.labels(
                method=method,
                endpoint=path,
                status=status
            ).inc()
            
            http_request_duration_seconds.labels(
                method=method,
                endpoint=path
            ).observe(duration)
            
            http_requests_in_progress.labels(method=method, endpoint=path).dec()
        
        return response


def metrics_endpoint():
    """Endpoint to expose Prometheus metrics."""
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


def setup_prometheus(app):
    """Setup Prometheus metrics collection."""
    if settings.PROMETHEUS_ENABLED:
        # Add middleware
        app.add_middleware(PrometheusMiddleware)
        
        # Add metrics endpoint
        app.add_route("/metrics", metrics_endpoint, methods=["GET"])
        
        # Initialize service health metrics
        service_health.labels(service="api").set(1)
