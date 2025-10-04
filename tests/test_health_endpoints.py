"""Tests for backend service health and readiness endpoints."""
import pytest
from fastapi.testclient import TestClient


def test_common_health_registry():
    """Test the common health registry infrastructure."""
    from backend.common.health import ReadinessRegistry
    
    registry = ReadinessRegistry()
    
    # Register a healthy check
    def check_ok():
        return True
    
    # Register a failing check
    def check_fail():
        return False
    
    registry.register("service_ok", check_ok)
    registry.register("service_fail", check_fail)
    
    status = registry.status()
    assert "service_ok" in status
    assert "service_fail" in status
    assert status["service_ok"]["ok"] is True
    assert status["service_fail"]["ok"] is False
    assert status["overall_ok"] is False


def test_common_health_registry_exception():
    """Test registry handles check exceptions gracefully."""
    from backend.common.health import ReadinessRegistry
    
    registry = ReadinessRegistry()
    
    def check_raises():
        raise ValueError("Simulated error")
    
    registry.register("failing", check_raises)
    
    status = registry.status()
    assert status["failing"]["ok"] is False
    assert "error" in status["failing"]
    assert status["overall_ok"] is False


class TestNLPServiceHealth:
    """Tests for NLP service health endpoints."""
    
    @pytest.fixture
    def nlp_app(self):
        """Create NLP FastAPI app for testing."""
        # Import after sys.path is set up
        import sys
        from pathlib import Path
        backend_path = Path(__file__).parent.parent / "backend"
        if str(backend_path) not in sys.path:
            sys.path.insert(0, str(backend_path))
        
        from backend.nlp.server.main import app
        return app
    
    def test_healthz_endpoint(self, nlp_app):
        """Test liveness endpoint returns ok."""
        client = TestClient(nlp_app)
        response = client.get("/healthz")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}
    
    def test_readyz_endpoint_structure(self, nlp_app):
        """Test readiness endpoint returns proper structure."""
        client = TestClient(nlp_app)
        response = client.get("/readyz")
        assert response.status_code == 200
        data = response.json()
        assert "ready" in data
        assert "embedding_model_loaded" in data
        assert "ner_model_loaded" in data
        assert isinstance(data["ready"], bool)
    
    def test_readyz_triggers_model_load(self, nlp_app):
        """Test readiness endpoint attempts lazy model loading."""
        client = TestClient(nlp_app)
        # First call should trigger model loading attempt
        response = client.get("/readyz")
        assert response.status_code == 200
        # Second call should use cached state
        response2 = client.get("/readyz")
        assert response2.status_code == 200


class TestAPIServiceHealth:
    """Tests for API service health endpoints."""
    
    @pytest.fixture
    def api_app(self):
        """Create API FastAPI app for testing."""
        import sys
        from pathlib import Path
        backend_path = Path(__file__).parent.parent / "backend" / "api"
        if str(backend_path) not in sys.path:
            sys.path.insert(0, str(backend_path))
        
        from backend.api.app.main import app
        return app
    
    def test_healthz_endpoint(self, api_app):
        """Test API liveness endpoint."""
        client = TestClient(api_app)
        response = client.get("/healthz")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}
    
    def test_readyz_endpoint(self, api_app):
        """Test API readiness endpoint structure."""
        client = TestClient(api_app)
        response = client.get("/readyz")
        assert response.status_code == 200
        data = response.json()
        assert "ready" in data
        assert "database" in data
        assert "app" in data
        assert "version" in data
        assert "features" in data
    
    def test_legacy_health_endpoint(self, api_app):
        """Test deprecated /health endpoint still works."""
        client = TestClient(api_app)
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"


class TestVisionServiceHealth:
    """Tests for Vision service health endpoints."""
    
    @pytest.fixture
    def vision_app(self):
        """Create Vision FastAPI app for testing."""
        import sys
        from pathlib import Path
        backend_path = Path(__file__).parent.parent / "backend"
        if str(backend_path) not in sys.path:
            sys.path.insert(0, str(backend_path))
        
        from backend.vision.server.main import app
        return app
    
    def test_healthz_endpoint(self, vision_app):
        """Test Vision liveness endpoint."""
        client = TestClient(vision_app)
        response = client.get("/healthz")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}
    
    def test_readyz_endpoint(self, vision_app):
        """Test Vision readiness endpoint."""
        client = TestClient(vision_app)
        response = client.get("/readyz")
        assert response.status_code == 200
        data = response.json()
        assert "ready" in data
        assert data["ready"] is True
        assert "model_version" in data


class TestWorkerHealth:
    """Tests for Worker service health functions."""
    
    def test_worker_health_function(self):
        """Test worker health helper function."""
        import sys
        from pathlib import Path
        backend_path = Path(__file__).parent.parent / "backend"
        if str(backend_path) not in sys.path:
            sys.path.insert(0, str(backend_path))
        
        from backend.worker.worker.health import worker_health
        result = worker_health()
        assert result["status"] == "ok"
        assert result["worker"] == "celery"
    
    def test_worker_readyz_function(self):
        """Test worker readiness helper function."""
        import sys
        from pathlib import Path
        backend_path = Path(__file__).parent.parent / "backend"
        if str(backend_path) not in sys.path:
            sys.path.insert(0, str(backend_path))
        
        from backend.worker.worker.health import worker_readyz
        result = worker_readyz()
        assert "ready" in result
        assert result["worker"] == "celery"


@pytest.mark.integration
class TestHealthEndpointsIntegration:
    """Integration tests requiring running services."""
    
    def test_nlp_embedding_fallback(self, nlp_app):
        """Test NLP service falls back to dummy embeddings gracefully."""
        # This test validates the embedding fallback path works
        client = TestClient(nlp_app)
        
        # Call embed endpoint (may fall back to dummy if model unavailable)
        response = client.post(
            "/embed",
            json={"texts": ["test query"], "kind": "query"}
        )
        assert response.status_code == 200
        data = response.json()
        assert "vectors" in data
        assert "dim" in data
        assert "mode" in data
        assert len(data["vectors"]) == 1
        assert len(data["vectors"][0]) == data["dim"]
