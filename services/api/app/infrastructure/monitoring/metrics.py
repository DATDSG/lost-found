"""
Infrastructure Monitoring and Metrics
====================================
Monitoring and metrics collection for the infrastructure layer.
"""

from typing import Dict, Any, Optional
import time
import logging
from prometheus_client import Counter, Histogram, Gauge, CollectorRegistry

logger = logging.getLogger(__name__)


class MetricsCollector:
    """
    Metrics collector for application monitoring.
    Provides Prometheus-compatible metrics collection.
    """
    
    def __init__(self, registry: Optional[CollectorRegistry] = None):
        self.registry = registry or CollectorRegistry()
        self._counters: Dict[str, Counter] = {}
        self._histograms: Dict[str, Histogram] = {}
        self._gauges: Dict[str, Gauge] = {}
    
    def get_or_create_counter(self, name: str, description: str, labelnames: tuple = ()) -> Counter:
        """Get or create a counter metric."""
        if name not in self._counters:
            self._counters[name] = Counter(
                name, description, labelnames=labelnames, registry=self.registry
            )
        return self._counters[name]
    
    def get_or_create_histogram(self, name: str, description: str, labelnames: tuple = ()) -> Histogram:
        """Get or create a histogram metric."""
        if name not in self._histograms:
            self._histograms[name] = Histogram(
                name, description, labelnames=labelnames, registry=self.registry
            )
        return self._histograms[name]
    
    def increment_request_count(self, endpoint: str, method: str = "GET", status_code: int = 200):
        """Increment request count metric."""
        counter = self.get_or_create_counter(
            "http_requests_total",
            "Total number of HTTP requests",
            ("method", "endpoint", "status_code")
        )
        counter.labels(method=method, endpoint=endpoint, status_code=str(status_code)).inc()
    
    def record_request_duration(self, endpoint: str, duration: float, method: str = "GET"):
        """Record request duration metric."""
        histogram = self.get_or_create_histogram(
            "http_request_duration_seconds",
            "HTTP request duration in seconds",
            ("method", "endpoint")
        )
        histogram.labels(method=method, endpoint=endpoint).observe(duration)
    
    def set_active_connections(self, count: int):
        """Set active connections gauge."""
        gauge = self.get_or_create_gauge(
            "active_connections",
            "Number of active connections"
        )
        gauge.set(count)
    
    def increment_error_count(self, error_type: str, endpoint: str = ""):
        """Increment error count metric."""
        counter = self.get_or_create_counter(
            "errors_total",
            "Total number of errors",
            ("error_type", "endpoint")
        )
        counter.labels(error_type=error_type, endpoint=endpoint).inc()
    
    def increment_counter(self, name: str, labels: Optional[Dict[str, str]] = None, value: float = 1.0):
        """Increment a counter metric."""
        try:
            counter = self.get_or_create_counter(name, f"Counter for {name}")
            if labels:
                counter.labels(**labels).inc(value)
            else:
                counter.inc(value)
        except Exception as e:
            logger.error(f"Failed to increment counter {name}: {e}")
    
    def observe_histogram(self, name: str, value: float, labels: Optional[Dict[str, str]] = None):
        """Observe a histogram metric."""
        try:
            histogram = self.get_or_create_histogram(name, f"Histogram for {name}")
            if labels:
                histogram.labels(**labels).observe(value)
            else:
                histogram.observe(value)
        except Exception as e:
            logger.error(f"Failed to observe histogram {name}: {e}")
    
    def set_gauge(self, name: str, value: float, labels: Optional[Dict[str, str]] = None):
        """Set a gauge metric value."""
        try:
            gauge = self.get_or_create_gauge(name, f"Gauge for {name}")
            if labels:
                gauge.labels(**labels).set(value)
            else:
                gauge.set(value)
        except Exception as e:
            logger.error(f"Failed to set gauge {name}: {e}")


# Global metrics collector instance
_metrics_collector: Optional[MetricsCollector] = None


def get_metrics_collector() -> MetricsCollector:
    """Get the global metrics collector instance."""
    global _metrics_collector
    if _metrics_collector is None:
        _metrics_collector = MetricsCollector()
    return _metrics_collector


class PerformanceMonitor:
    """
    Performance monitoring decorator and context manager.
    """
    
    def __init__(self, metrics: MetricsCollector, operation_name: str):
        self.metrics = metrics
        self.operation_name = operation_name
        self.start_time = None
    
    def __enter__(self):
        self.start_time = time.time()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.start_time:
            duration = time.time() - self.start_time
            self.metrics.observe_histogram(
                f"{self.operation_name}_duration_seconds",
                duration,
                {"status": "success" if exc_type is None else "error"}
            )
    
    def __call__(self, func):
        """Decorator for function performance monitoring."""
        def wrapper(*args, **kwargs):
            with self:
                return func(*args, **kwargs)
        return wrapper


def monitor_performance(operation_name: str):
    """Decorator factory for performance monitoring."""
    def decorator(func):
        def wrapper(*args, **kwargs):
            metrics = get_metrics_collector()
            with PerformanceMonitor(metrics, operation_name):
                return func(*args, **kwargs)
        return wrapper
    return decorator
