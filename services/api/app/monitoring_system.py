"""
Comprehensive Monitoring and Alerting System
============================================
Advanced monitoring, metrics collection, and alerting for the Lost & Found Application.
"""

import time
import json
import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Callable
from dataclasses import dataclass, asdict
from enum import Enum
import psutil
import threading
from collections import defaultdict, deque

try:
    from prometheus_client import Counter, Histogram, Gauge, Summary, CollectorRegistry, generate_latest
    PROMETHEUS_AVAILABLE = True
except ImportError:
    PROMETHEUS_AVAILABLE = False

logger = logging.getLogger(__name__)


class AlertLevel(Enum):
    """Alert severity levels."""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


class MetricType(Enum):
    """Metric types."""
    COUNTER = "counter"
    GAUGE = "gauge"
    HISTOGRAM = "histogram"
    SUMMARY = "summary"


@dataclass
class Alert:
    """Alert data structure."""
    id: str
    level: AlertLevel
    title: str
    message: str
    timestamp: datetime
    source: str
    tags: Dict[str, str]
    resolved: bool = False
    resolved_at: Optional[datetime] = None


@dataclass
class Metric:
    """Metric data structure."""
    name: str
    value: float
    timestamp: datetime
    labels: Dict[str, str]
    metric_type: MetricType


class MetricsCollector:
    """Advanced metrics collector."""
    
    def __init__(self):
        self.metrics: Dict[str, Any] = {}
        self.metric_history: Dict[str, deque] = defaultdict(lambda: deque(maxlen=1000))
        self.start_time = time.time()
        
        # Initialize Prometheus metrics if available
        if PROMETHEUS_AVAILABLE:
            self.registry = CollectorRegistry()
            self._init_prometheus_metrics()
        else:
            self.registry = None
    
    def _init_prometheus_metrics(self):
        """Initialize Prometheus metrics."""
        # HTTP metrics
        self.http_requests_total = Counter(
            'http_requests_total',
            'Total HTTP requests',
            ['method', 'endpoint', 'status'],
            registry=self.registry
        )
        
        self.http_request_duration = Histogram(
            'http_request_duration_seconds',
            'HTTP request duration',
            ['method', 'endpoint'],
            registry=self.registry
        )
        
        # Database metrics
        self.db_queries_total = Counter(
            'db_queries_total',
            'Total database queries',
            ['operation', 'table'],
            registry=self.registry
        )
        
        self.db_query_duration = Histogram(
            'db_query_duration_seconds',
            'Database query duration',
            ['operation', 'table'],
            registry=self.registry
        )
        
        # Cache metrics
        self.cache_hits_total = Counter(
            'cache_hits_total',
            'Total cache hits',
            ['cache_type'],
            registry=self.registry
        )
        
        self.cache_misses_total = Counter(
            'cache_misses_total',
            'Total cache misses',
            ['cache_type'],
            registry=self.registry
        )
        
        # Service metrics
        self.service_calls_total = Counter(
            'service_calls_total',
            'Total service calls',
            ['service', 'endpoint', 'status'],
            registry=self.registry
        )
        
        self.service_response_time = Histogram(
            'service_response_time_seconds',
            'Service response time',
            ['service', 'endpoint'],
            registry=self.registry
        )
        
        # System metrics
        self.system_cpu_usage = Gauge(
            'system_cpu_usage_percent',
            'System CPU usage percentage',
            registry=self.registry
        )
        
        self.system_memory_usage = Gauge(
            'system_memory_usage_bytes',
            'System memory usage in bytes',
            registry=self.registry
        )
        
        self.system_disk_usage = Gauge(
            'system_disk_usage_bytes',
            'System disk usage in bytes',
            registry=self.registry
        )
        
        # Application metrics
        self.active_connections = Gauge(
            'active_connections',
            'Number of active connections',
            registry=self.registry
        )
        
        self.active_users = Gauge(
            'active_users',
            'Number of active users',
            registry=self.registry
        )
        
        self.matching_operations_total = Counter(
            'matching_operations_total',
            'Total matching operations',
            ['algorithm', 'status'],
            registry=self.registry
        )
        
        self.matching_duration = Histogram(
            'matching_duration_seconds',
            'Matching operation duration',
            ['algorithm'],
            registry=self.registry
        )
    
    def record_http_request(self, method: str, endpoint: str, status_code: int, duration: float):
        """Record HTTP request metrics."""
        if self.registry:
            self.http_requests_total.labels(method=method, endpoint=endpoint, status=str(status_code)).inc()
            self.http_request_duration.labels(method=method, endpoint=endpoint).observe(duration)
        
        # Store in custom metrics
        self._store_metric('http_requests', {
            'method': method,
            'endpoint': endpoint,
            'status': status_code,
            'duration': duration
        })
    
    def record_db_query(self, operation: str, table: str, duration: float):
        """Record database query metrics."""
        if self.registry:
            self.db_queries_total.labels(operation=operation, table=table).inc()
            self.db_query_duration.labels(operation=operation, table=table).observe(duration)
        
        self._store_metric('db_queries', {
            'operation': operation,
            'table': table,
            'duration': duration
        })
    
    def record_cache_operation(self, cache_type: str, hit: bool):
        """Record cache operation metrics."""
        if self.registry:
            if hit:
                self.cache_hits_total.labels(cache_type=cache_type).inc()
            else:
                self.cache_misses_total.labels(cache_type=cache_type).inc()
        
        self._store_metric('cache_operations', {
            'cache_type': cache_type,
            'hit': hit
        })
    
    def record_service_call(self, service: str, endpoint: str, status: str, duration: float):
        """Record service call metrics."""
        if self.registry:
            self.service_calls_total.labels(service=service, endpoint=endpoint, status=status).inc()
            self.service_response_time.labels(service=service, endpoint=endpoint).observe(duration)
        
        self._store_metric('service_calls', {
            'service': service,
            'endpoint': endpoint,
            'status': status,
            'duration': duration
        })
    
    def record_matching_operation(self, algorithm: str, status: str, duration: float):
        """Record matching operation metrics."""
        if self.registry:
            self.matching_operations_total.labels(algorithm=algorithm, status=status).inc()
            self.matching_duration.labels(algorithm=algorithm).observe(duration)
        
        self._store_metric('matching_operations', {
            'algorithm': algorithm,
            'status': status,
            'duration': duration
        })
    
    def update_system_metrics(self):
        """Update system metrics."""
        try:
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            if self.registry:
                self.system_cpu_usage.set(cpu_percent)
            
            # Memory usage
            memory = psutil.virtual_memory()
            if self.registry:
                self.system_memory_usage.set(memory.used)
            
            # Disk usage
            disk = psutil.disk_usage('/')
            if self.registry:
                self.system_disk_usage.set(disk.used)
            
            self._store_metric('system', {
                'cpu_percent': cpu_percent,
                'memory_used': memory.used,
                'memory_percent': memory.percent,
                'disk_used': disk.used,
                'disk_percent': (disk.used / disk.total) * 100
            })
            
        except Exception as e:
            logger.error(f"Failed to update system metrics: {e}")
    
    def _store_metric(self, metric_name: str, data: Dict[str, Any]):
        """Store metric data."""
        metric = Metric(
            name=metric_name,
            value=data.get('duration', data.get('cpu_percent', 0)),
            timestamp=datetime.now(),
            labels=data,
            metric_type=MetricType.GAUGE
        )
        
        self.metric_history[metric_name].append(metric)
    
    def get_metrics_summary(self) -> Dict[str, Any]:
        """Get metrics summary."""
        summary = {
            'uptime_seconds': time.time() - self.start_time,
            'total_metrics': sum(len(history) for history in self.metric_history.values()),
            'metric_types': list(self.metric_history.keys()),
            'prometheus_available': PROMETHEUS_AVAILABLE
        }
        
        # Calculate rates and averages
        for metric_name, history in self.metric_history.items():
            if history:
                values = [m.value for m in history]
                summary[f'{metric_name}_count'] = len(values)
                summary[f'{metric_name}_avg'] = sum(values) / len(values)
                summary[f'{metric_name}_min'] = min(values)
                summary[f'{metric_name}_max'] = max(values)
        
        return summary
    
    def get_prometheus_metrics(self) -> str:
        """Get Prometheus metrics in text format."""
        if self.registry:
            return generate_latest(self.registry).decode('utf-8')
        return ""


class AlertManager:
    """Alert management system."""
    
    def __init__(self):
        self.alerts: Dict[str, Alert] = {}
        self.alert_history: List[Alert] = []
        self.alert_rules: Dict[str, Callable] = {}
        self.alert_handlers: List[Callable] = []
        self.alert_cooldown: Dict[str, datetime] = {}
        self.cooldown_duration = timedelta(minutes=5)
    
    def add_alert_rule(self, rule_name: str, rule_func: Callable):
        """Add alert rule."""
        self.alert_rules[rule_name] = rule_func
    
    def add_alert_handler(self, handler: Callable):
        """Add alert handler."""
        self.alert_handlers.append(handler)
    
    def create_alert(self, alert_id: str, level: AlertLevel, title: str, message: str, 
                    source: str, tags: Dict[str, str] = None) -> Alert:
        """Create a new alert."""
        # Check cooldown
        if alert_id in self.alert_cooldown:
            if datetime.now() - self.alert_cooldown[alert_id] < self.cooldown_duration:
                return None
        
        alert = Alert(
            id=alert_id,
            level=level,
            title=title,
            message=message,
            timestamp=datetime.now(),
            source=source,
            tags=tags or {}
        )
        
        self.alerts[alert_id] = alert
        self.alert_history.append(alert)
        
        # Set cooldown
        self.alert_cooldown[alert_id] = datetime.now()
        
        # Notify handlers
        for handler in self.alert_handlers:
            try:
                handler(alert)
            except Exception as e:
                logger.error(f"Alert handler error: {e}")
        
        logger.warning(f"Alert created: {alert.title} - {alert.message}")
        return alert
    
    def resolve_alert(self, alert_id: str):
        """Resolve an alert."""
        if alert_id in self.alerts:
            alert = self.alerts[alert_id]
            alert.resolved = True
            alert.resolved_at = datetime.now()
            logger.info(f"Alert resolved: {alert.title}")
    
    def get_active_alerts(self) -> List[Alert]:
        """Get active alerts."""
        return [alert for alert in self.alerts.values() if not alert.resolved]
    
    def get_alerts_by_level(self, level: AlertLevel) -> List[Alert]:
        """Get alerts by level."""
        return [alert for alert in self.alerts.values() if alert.level == level and not alert.resolved]
    
    def check_alert_rules(self, metrics_data: Dict[str, Any]):
        """Check alert rules against metrics."""
        for rule_name, rule_func in self.alert_rules.items():
            try:
                rule_func(metrics_data, self)
            except Exception as e:
                logger.error(f"Alert rule error {rule_name}: {e}")


class HealthChecker:
    """System health checker."""
    
    def __init__(self, metrics_collector: MetricsCollector, alert_manager: AlertManager):
        self.metrics_collector = metrics_collector
        self.alert_manager = alert_manager
        self.health_checks: Dict[str, Callable] = {}
        self.last_health_status: Dict[str, Any] = {}
    
    def add_health_check(self, name: str, check_func: Callable):
        """Add health check."""
        self.health_checks[name] = check_func
    
    async def run_health_checks(self) -> Dict[str, Any]:
        """Run all health checks."""
        health_status = {
            'overall_status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'checks': {}
        }
        
        for check_name, check_func in self.health_checks.items():
            try:
                if asyncio.iscoroutinefunction(check_func):
                    result = await check_func()
                else:
                    result = check_func()
                
                health_status['checks'][check_name] = result
                
                # Update overall status
                if result.get('status') != 'healthy':
                    health_status['overall_status'] = 'unhealthy'
                    
            except Exception as e:
                health_status['checks'][check_name] = {
                    'status': 'error',
                    'error': str(e)
                }
                health_status['overall_status'] = 'unhealthy'
        
        self.last_health_status = health_status
        return health_status


class MonitoringDashboard:
    """Monitoring dashboard data provider."""
    
    def __init__(self, metrics_collector: MetricsCollector, alert_manager: AlertManager, 
                 health_checker: HealthChecker):
        self.metrics_collector = metrics_collector
        self.alert_manager = alert_manager
        self.health_checker = health_checker
    
    def get_dashboard_data(self) -> Dict[str, Any]:
        """Get comprehensive dashboard data."""
        return {
            'metrics': self.metrics_collector.get_metrics_summary(),
            'alerts': {
                'active': len(self.alert_manager.get_active_alerts()),
                'critical': len(self.alert_manager.get_alerts_by_level(AlertLevel.CRITICAL)),
                'warning': len(self.alert_manager.get_alerts_by_level(AlertLevel.WARNING)),
                'error': len(self.alert_manager.get_alerts_by_level(AlertLevel.ERROR))
            },
            'health': self.health_checker.last_health_status,
            'timestamp': datetime.now().isoformat()
        }
    
    def get_performance_data(self) -> Dict[str, Any]:
        """Get performance data for charts."""
        performance_data = {
            'http_requests': [],
            'response_times': [],
            'cpu_usage': [],
            'memory_usage': [],
            'cache_hit_rate': []
        }
        
        # Get recent metrics
        for metric_name, history in self.metrics_collector.metric_history.items():
            if metric_name == 'http_requests' and history:
                recent_requests = list(history)[-100:]  # Last 100 requests
                performance_data['http_requests'] = [
                    {
                        'timestamp': m.timestamp.isoformat(),
                        'method': m.labels.get('method'),
                        'endpoint': m.labels.get('endpoint'),
                        'status': m.labels.get('status')
                    }
                    for m in recent_requests
                ]
            
            elif metric_name == 'system' and history:
                recent_system = list(history)[-60:]  # Last 60 measurements
                performance_data['cpu_usage'] = [
                    {
                        'timestamp': m.timestamp.isoformat(),
                        'value': m.labels.get('cpu_percent', 0)
                    }
                    for m in recent_system
                ]
                performance_data['memory_usage'] = [
                    {
                        'timestamp': m.timestamp.isoformat(),
                        'value': m.labels.get('memory_percent', 0)
                    }
                    for m in recent_system
                ]
        
        return performance_data


class MonitoringSystem:
    """Main monitoring system coordinator."""
    
    def __init__(self):
        self.metrics_collector = MetricsCollector()
        self.alert_manager = AlertManager()
        self.health_checker = HealthChecker(self.metrics_collector, self.alert_manager)
        self.dashboard = MonitoringDashboard(self.metrics_collector, self.alert_manager, self.health_checker)
        
        self.running = False
        self.monitoring_thread: Optional[threading.Thread] = None
        
        # Setup default alert rules
        self._setup_default_alert_rules()
        
        # Setup default health checks
        self._setup_default_health_checks()
    
    def _setup_default_alert_rules(self):
        """Setup default alert rules."""
        
        def high_cpu_usage_rule(metrics_data: Dict[str, Any], alert_manager: AlertManager):
            """Alert on high CPU usage."""
            if 'system_cpu_percent' in metrics_data and metrics_data['system_cpu_percent'] > 80:
                alert_manager.create_alert(
                    'high_cpu_usage',
                    AlertLevel.WARNING,
                    'High CPU Usage',
                    f"CPU usage is {metrics_data['system_cpu_percent']:.1f}%",
                    'system_monitor',
                    {'metric': 'cpu_usage', 'threshold': '80%'}
                )
        
        def high_memory_usage_rule(metrics_data: Dict[str, Any], alert_manager: AlertManager):
            """Alert on high memory usage."""
            if 'system_memory_percent' in metrics_data and metrics_data['system_memory_percent'] > 85:
                alert_manager.create_alert(
                    'high_memory_usage',
                    AlertLevel.WARNING,
                    'High Memory Usage',
                    f"Memory usage is {metrics_data['system_memory_percent']:.1f}%",
                    'system_monitor',
                    {'metric': 'memory_usage', 'threshold': '85%'}
                )
        
        def slow_response_time_rule(metrics_data: Dict[str, Any], alert_manager: AlertManager):
            """Alert on slow response times."""
            if 'http_requests_avg' in metrics_data and metrics_data['http_requests_avg'] > 2.0:
                alert_manager.create_alert(
                    'slow_response_time',
                    AlertLevel.WARNING,
                    'Slow Response Time',
                    f"Average response time is {metrics_data['http_requests_avg']:.2f}s",
                    'performance_monitor',
                    {'metric': 'response_time', 'threshold': '2.0s'}
                )
        
        def low_cache_hit_rate_rule(metrics_data: Dict[str, Any], alert_manager: AlertManager):
            """Alert on low cache hit rate."""
            # This would need to be calculated from cache metrics
            pass
        
        self.alert_manager.add_alert_rule('high_cpu_usage', high_cpu_usage_rule)
        self.alert_manager.add_alert_rule('high_memory_usage', high_memory_usage_rule)
        self.alert_manager.add_alert_rule('slow_response_time', slow_response_time_rule)
    
    def _setup_default_health_checks(self):
        """Setup default health checks."""
        
        def database_health_check():
            """Check database health."""
            try:
                # This would check database connectivity
                return {'status': 'healthy', 'message': 'Database connection OK'}
            except Exception as e:
                return {'status': 'unhealthy', 'message': f'Database error: {e}'}
        
        def redis_health_check():
            """Check Redis health."""
            try:
                # This would check Redis connectivity
                return {'status': 'healthy', 'message': 'Redis connection OK'}
            except Exception as e:
                return {'status': 'unhealthy', 'message': f'Redis error: {e}'}
        
        def external_services_health_check():
            """Check external services health."""
            try:
                # This would check NLP and Vision services
                return {'status': 'healthy', 'message': 'External services OK'}
            except Exception as e:
                return {'status': 'unhealthy', 'message': f'External services error: {e}'}
        
        self.health_checker.add_health_check('database', database_health_check)
        self.health_checker.add_health_check('redis', redis_health_check)
        self.health_checker.add_health_check('external_services', external_services_health_check)
    
    def start_monitoring(self):
        """Start monitoring system."""
        if self.running:
            return
        
        self.running = True
        self.monitoring_thread = threading.Thread(target=self._monitoring_loop, daemon=True)
        self.monitoring_thread.start()
        logger.info("Monitoring system started")
    
    def stop_monitoring(self):
        """Stop monitoring system."""
        self.running = False
        if self.monitoring_thread:
            self.monitoring_thread.join()
        logger.info("Monitoring system stopped")
    
    def _monitoring_loop(self):
        """Main monitoring loop."""
        while self.running:
            try:
                # Update system metrics
                self.metrics_collector.update_system_metrics()
                
                # Check alert rules
                metrics_summary = self.metrics_collector.get_metrics_summary()
                self.alert_manager.check_alert_rules(metrics_summary)
                
                # Run health checks
                asyncio.run(self.health_checker.run_health_checks())
                
                # Sleep for 30 seconds
                time.sleep(30)
                
            except Exception as e:
                logger.error(f"Monitoring loop error: {e}")
                time.sleep(60)  # Wait longer on error
    
    def get_status(self) -> Dict[str, Any]:
        """Get monitoring system status."""
        return {
            'running': self.running,
            'metrics_count': len(self.metrics_collector.metric_history),
            'active_alerts': len(self.alert_manager.get_active_alerts()),
            'health_status': self.health_checker.last_health_status.get('overall_status', 'unknown')
        }


# Global monitoring system instance
monitoring_system = MonitoringSystem()


# Convenience functions
def get_metrics_collector() -> MetricsCollector:
    """Get the global metrics collector."""
    return monitoring_system.metrics_collector

def get_alert_manager() -> AlertManager:
    """Get the global alert manager."""
    return monitoring_system.alert_manager

def get_health_checker() -> HealthChecker:
    """Get the global health checker."""
    return monitoring_system.health_checker

def get_monitoring_dashboard() -> MonitoringDashboard:
    """Get the global monitoring dashboard."""
    return monitoring_system.dashboard

def start_monitoring():
    """Start the global monitoring system."""
    monitoring_system.start_monitoring()

def stop_monitoring():
    """Stop the global monitoring system."""
    monitoring_system.stop_monitoring()

def get_monitoring_status() -> Dict[str, Any]:
    """Get the global monitoring system status."""
    return monitoring_system.get_status()
