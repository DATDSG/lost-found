"""Performance and load tests for the API."""

import pytest
import asyncio
import time
from typing import List
from unittest.mock import AsyncMock, Mock
import statistics

from app.matching import MatchingPipeline
from app.clients import NLPClient, VisionClient


@pytest.mark.performance
class TestMatchingPerformance:
    """Performance tests for matching pipeline."""

    @pytest.mark.asyncio
    async def test_matching_latency_single_report(self, matching_pipeline, sample_report):
        """Test matching latency for a single report."""
        # Mock database with 100 candidate reports
        candidates = [Mock() for _ in range(100)]
        for i, candidate in enumerate(candidates):
            candidate.id = i
            candidate.type = "found"
            candidate.embedding = [0.1] * 384
            candidate.image_hash = f"hash{i}"
            candidate.location_point = "POINT(-73.935242 40.730610)"
            candidate.created_at = sample_report.created_at
            candidate.user_id = i + 1000
        
        mock_result = Mock()
        mock_result.scalars = Mock(return_value=Mock(all=Mock(return_value=candidates)))
        matching_pipeline.db.execute = AsyncMock(return_value=mock_result)
        
        # Measure time
        start_time = time.perf_counter()
        matches = await matching_pipeline.find_matches(sample_report, max_results=20)
        end_time = time.perf_counter()
        
        latency = end_time - start_time
        
        # Performance assertion: Should complete in < 2 seconds
        assert latency < 2.0, f"Matching took {latency:.2f}s, expected < 2.0s"
        assert len(matches) <= 20

    @pytest.mark.asyncio
    async def test_matching_throughput(self, matching_pipeline):
        """Test matching throughput with concurrent requests."""
        # Create test reports
        reports = []
        for i in range(10):
            report = Mock()
            report.id = i
            report.type = "lost"
            report.embedding = [0.1] * 384
            report.location_point = "POINT(-73.935242 40.730610)"
            report.created_at = Mock()
            report.user_id = i
            reports.append(report)
        
        # Mock empty results for speed
        mock_result = Mock()
        mock_result.scalars = Mock(return_value=Mock(all=Mock(return_value=[])))
        matching_pipeline.db.execute = AsyncMock(return_value=mock_result)
        
        # Measure concurrent throughput
        start_time = time.perf_counter()
        tasks = [matching_pipeline.find_matches(report) for report in reports]
        await asyncio.gather(*tasks)
        end_time = time.perf_counter()
        
        total_time = end_time - start_time
        throughput = len(reports) / total_time
        
        # Should handle at least 5 requests/second
        assert throughput >= 5.0, f"Throughput: {throughput:.2f} req/s, expected >= 5.0 req/s"

    @pytest.mark.asyncio
    async def test_cache_performance(self, matching_pipeline, sample_report):
        """Test cache hit performance improvement."""
        # Mock database
        mock_result = Mock()
        mock_result.scalars = Mock(return_value=Mock(all=Mock(return_value=[])))
        matching_pipeline.db.execute = AsyncMock(return_value=mock_result)
        
        # First call (cache miss)
        matching_pipeline.cache.get = AsyncMock(return_value=None)
        start_time = time.perf_counter()
        await matching_pipeline.find_matches(sample_report)
        miss_time = time.perf_counter() - start_time
        
        # Second call (cache hit)
        import json
        matching_pipeline.cache.get = AsyncMock(return_value=json.dumps([]))
        start_time = time.perf_counter()
        await matching_pipeline.find_matches(sample_report)
        hit_time = time.perf_counter() - start_time
        
        # Cache hit should be significantly faster
        assert hit_time < miss_time / 2, "Cache hit should be at least 2x faster"


@pytest.mark.performance
class TestServiceClientPerformance:
    """Performance tests for NLP and Vision clients."""

    @pytest.mark.asyncio
    async def test_nlp_client_latency(self, nlp_client, mock_httpx_client):
        """Test NLP client response time."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"embedding": [0.1] * 384}
        mock_httpx_client.post.return_value = mock_response
        
        # Measure 10 sequential calls
        latencies = []
        for _ in range(10):
            start_time = time.perf_counter()
            await nlp_client.generate_embedding("test text")
            latency = time.perf_counter() - start_time
            latencies.append(latency)
        
        avg_latency = statistics.mean(latencies)
        p95_latency = statistics.quantiles(latencies, n=20)[18]  # 95th percentile
        
        # Should complete in < 500ms on average, < 1s for p95
        assert avg_latency < 0.5, f"Avg latency: {avg_latency:.3f}s, expected < 0.5s"
        assert p95_latency < 1.0, f"P95 latency: {p95_latency:.3f}s, expected < 1.0s"

    @pytest.mark.asyncio
    async def test_vision_client_concurrent_requests(self, vision_client, mock_httpx_client):
        """Test Vision client concurrent request handling."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"hash": "abc123"}
        mock_httpx_client.post.return_value = mock_response
        
        # Test 20 concurrent requests
        image_urls = [f"http://example.com/image{i}.jpg" for i in range(20)]
        
        start_time = time.perf_counter()
        tasks = [vision_client.generate_hash(url) for url in image_urls]
        results = await asyncio.gather(*tasks)
        total_time = time.perf_counter() - start_time
        
        # All should succeed
        assert all(result is not None for result in results)
        
        # Should handle 20 requests in < 5 seconds
        assert total_time < 5.0, f"20 concurrent requests took {total_time:.2f}s, expected < 5.0s"


@pytest.mark.slow
class TestLoadScenarios:
    """Load testing scenarios."""

    @pytest.mark.asyncio
    @pytest.mark.slow
    async def test_high_load_matching(self, matching_pipeline):
        """Simulate high load on matching endpoint."""
        # Simulate 100 concurrent matching requests
        reports = [Mock() for _ in range(100)]
        for i, report in enumerate(reports):
            report.id = i
            report.type = "lost" if i % 2 == 0 else "found"
            report.embedding = [0.1] * 384
            report.location_point = "POINT(-73.935242 40.730610)"
            report.created_at = Mock()
            report.user_id = i
        
        # Mock empty results
        mock_result = Mock()
        mock_result.scalars = Mock(return_value=Mock(all=Mock(return_value=[])))
        matching_pipeline.db.execute = AsyncMock(return_value=mock_result)
        
        # Execute load test
        start_time = time.perf_counter()
        tasks = [matching_pipeline.find_matches(report) for report in reports]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        total_time = time.perf_counter() - start_time
        
        # Analyze results
        successful = sum(1 for r in results if not isinstance(r, Exception))
        failed = len(results) - successful
        throughput = successful / total_time
        
        print(f"\nLoad Test Results:")
        print(f"  Total requests: {len(results)}")
        print(f"  Successful: {successful}")
        print(f"  Failed: {failed}")
        print(f"  Total time: {total_time:.2f}s")
        print(f"  Throughput: {throughput:.2f} req/s")
        
        # Assertions
        assert failed == 0, f"{failed} requests failed"
        assert throughput >= 10.0, f"Throughput {throughput:.2f} req/s too low"

    @pytest.mark.asyncio
    @pytest.mark.slow
    async def test_sustained_load(self, matching_pipeline):
        """Test system under sustained load."""
        duration_seconds = 10
        requests_per_second = 5
        
        async def make_request():
            report = Mock()
            report.id = 1
            report.type = "lost"
            report.embedding = [0.1] * 384
            report.location_point = "POINT(-73.935242 40.730610)"
            report.created_at = Mock()
            report.user_id = 1
            
            return await matching_pipeline.find_matches(report)
        
        # Mock database
        mock_result = Mock()
        mock_result.scalars = Mock(return_value=Mock(all=Mock(return_value=[])))
        matching_pipeline.db.execute = AsyncMock(return_value=mock_result)
        
        # Run sustained load
        latencies = []
        start_time = time.perf_counter()
        
        while time.perf_counter() - start_time < duration_seconds:
            request_start = time.perf_counter()
            await make_request()
            latency = time.perf_counter() - request_start
            latencies.append(latency)
            
            # Wait to maintain target RPS
            await asyncio.sleep(1.0 / requests_per_second)
        
        # Analyze latencies
        avg_latency = statistics.mean(latencies)
        p95_latency = statistics.quantiles(latencies, n=20)[18]
        p99_latency = statistics.quantiles(latencies, n=100)[98]
        
        print(f"\nSustained Load Test ({duration_seconds}s @ {requests_per_second} RPS):")
        print(f"  Total requests: {len(latencies)}")
        print(f"  Avg latency: {avg_latency*1000:.2f}ms")
        print(f"  P95 latency: {p95_latency*1000:.2f}ms")
        print(f"  P99 latency: {p99_latency*1000:.2f}ms")
        
        # Performance targets
        assert avg_latency < 0.5, f"Avg latency {avg_latency:.3f}s exceeds 500ms"
        assert p95_latency < 1.0, f"P95 latency {p95_latency:.3f}s exceeds 1.0s"
        assert p99_latency < 2.0, f"P99 latency {p99_latency:.3f}s exceeds 2.0s"


@pytest.mark.performance
class TestDatabasePerformance:
    """Database query performance tests."""

    @pytest.mark.asyncio
    async def test_vector_search_performance(self, matching_pipeline):
        """Test pgvector ANN search performance."""
        # This would require a real database connection
        # Placeholder for integration testing
        pass

    @pytest.mark.asyncio
    async def test_geo_search_performance(self, matching_pipeline):
        """Test PostGIS geospatial query performance."""
        # This would require a real database connection
        # Placeholder for integration testing
        pass


def benchmark_decorator(func):
    """Decorator to benchmark function execution time."""
    async def wrapper(*args, **kwargs):
        start_time = time.perf_counter()
        result = await func(*args, **kwargs)
        end_time = time.perf_counter()
        
        print(f"\n{func.__name__} took {(end_time - start_time)*1000:.2f}ms")
        return result
    
    return wrapper


class LoadTestReport:
    """Generate load test report."""
    
    def __init__(self):
        self.results = []
    
    def add_result(self, name: str, successful: int, failed: int, duration: float):
        self.results.append({
            'test': name,
            'successful': successful,
            'failed': failed,
            'duration': duration,
            'throughput': successful / duration if duration > 0 else 0
        })
    
    def print_report(self):
        print("\n" + "="*80)
        print("LOAD TEST REPORT")
        print("="*80)
        
        for result in self.results:
            print(f"\n{result['test']}:")
            print(f"  Successful: {result['successful']}")
            print(f"  Failed: {result['failed']}")
            print(f"  Duration: {result['duration']:.2f}s")
            print(f"  Throughput: {result['throughput']:.2f} req/s")
        
        print("\n" + "="*80)
