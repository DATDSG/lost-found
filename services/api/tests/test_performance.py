"""
Performance and load tests for the Lost & Found API
==================================================
Tests for system performance, scalability, and load handling capabilities.
"""

import pytest
import asyncio
import time
import statistics
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Dict, Any
import httpx
from fastapi.testclient import TestClient

from app.main import app


class TestPerformanceMetrics:
    """Test system performance metrics and benchmarks."""
    
    @pytest.mark.asyncio
    async def test_api_response_time(self, async_client):
        """Test API response time under normal load."""
        response_times = []
        
        # Make 100 requests to measure response time
        for _ in range(100):
            start_time = time.time()
            response = await async_client.get("/health")
            end_time = time.time()
            
            assert response.status_code == 200
            response_times.append((end_time - start_time) * 1000)  # Convert to milliseconds
        
        # Calculate statistics
        avg_response_time = statistics.mean(response_times)
        p95_response_time = statistics.quantiles(response_times, n=20)[18]  # 95th percentile
        p99_response_time = statistics.quantiles(response_times, n=100)[98]  # 99th percentile
        
        # Performance assertions
        assert avg_response_time < 200, f"Average response time {avg_response_time:.2f}ms exceeds 200ms"
        assert p95_response_time < 500, f"95th percentile response time {p95_response_time:.2f}ms exceeds 500ms"
        assert p99_response_time < 1000, f"99th percentile response time {p99_response_time:.2f}ms exceeds 1000ms"
        
        print(f"Performance Metrics:")
        print(f"  Average Response Time: {avg_response_time:.2f}ms")
        print(f"  95th Percentile: {p95_response_time:.2f}ms")
        print(f"  99th Percentile: {p99_response_time:.2f}ms")
    
    @pytest.mark.asyncio
    async def test_database_query_performance(self, async_client, auth_headers):
        """Test database query performance."""
        query_times = []
        
        # Test report listing performance
        for _ in range(50):
            start_time = time.time()
            response = await async_client.get("/v1/reports", headers=auth_headers)
            end_time = time.time()
            
            assert response.status_code == 200
            query_times.append((end_time - start_time) * 1000)
        
        avg_query_time = statistics.mean(query_times)
        p95_query_time = statistics.quantiles(query_times, n=20)[18]
        
        assert avg_query_time < 100, f"Average query time {avg_query_time:.2f}ms exceeds 100ms"
        assert p95_query_time < 200, f"95th percentile query time {p95_query_time:.2f}ms exceeds 200ms"
        
        print(f"Database Query Performance:")
        print(f"  Average Query Time: {avg_query_time:.2f}ms")
        print(f"  95th Percentile: {p95_query_time:.2f}ms")
    
    @pytest.mark.asyncio
    async def test_concurrent_request_handling(self, async_client):
        """Test system's ability to handle concurrent requests."""
        async def make_request():
            start_time = time.time()
            response = await async_client.get("/health")
            end_time = time.time()
            return {
                "status_code": response.status_code,
                "response_time": (end_time - start_time) * 1000
            }
        
        # Make 50 concurrent requests
        tasks = [make_request() for _ in range(50)]
        results = await asyncio.gather(*tasks)
        
        # Verify all requests succeeded
        status_codes = [result["status_code"] for result in results]
        response_times = [result["response_time"] for result in results]
        
        assert all(status == 200 for status in status_codes), "Some concurrent requests failed"
        
        avg_response_time = statistics.mean(response_times)
        max_response_time = max(response_times)
        
        assert avg_response_time < 300, f"Average concurrent response time {avg_response_time:.2f}ms exceeds 300ms"
        assert max_response_time < 1000, f"Max concurrent response time {max_response_time:.2f}ms exceeds 1000ms"
        
        print(f"Concurrent Request Performance:")
        print(f"  Average Response Time: {avg_response_time:.2f}ms")
        print(f"  Max Response Time: {max_response_time:.2f}ms")
        print(f"  Success Rate: 100%")


class TestLoadTesting:
    """Test system behavior under various load conditions."""
    
    @pytest.mark.asyncio
    async def test_normal_load(self, async_client):
        """Test system performance under normal expected load."""
        async def make_request():
            response = await async_client.get("/health")
            return response.status_code
        
        # Simulate normal load: 10 requests per second for 30 seconds
        start_time = time.time()
        success_count = 0
        total_requests = 0
        
        while time.time() - start_time < 30:  # 30 seconds
            tasks = [make_request() for _ in range(10)]  # 10 concurrent requests
            results = await asyncio.gather(*tasks)
            
            success_count += sum(1 for status in results if status == 200)
            total_requests += len(results)
            
            await asyncio.sleep(1)  # Wait 1 second before next batch
        
        success_rate = (success_count / total_requests) * 100
        requests_per_second = total_requests / 30
        
        assert success_rate >= 99, f"Success rate {success_rate:.2f}% below 99%"
        assert requests_per_second >= 8, f"Requests per second {requests_per_second:.2f} below 8"
        
        print(f"Normal Load Test Results:")
        print(f"  Total Requests: {total_requests}")
        print(f"  Success Rate: {success_rate:.2f}%")
        print(f"  Requests/Second: {requests_per_second:.2f}")
    
    @pytest.mark.asyncio
    async def test_high_load(self, async_client):
        """Test system performance under high load conditions."""
        async def make_request():
            response = await async_client.get("/health")
            return response.status_code
        
        # Simulate high load: 50 requests per second for 10 seconds
        start_time = time.time()
        success_count = 0
        total_requests = 0
        
        while time.time() - start_time < 10:  # 10 seconds
            tasks = [make_request() for _ in range(50)]  # 50 concurrent requests
            results = await asyncio.gather(*tasks)
            
            success_count += sum(1 for status in results if status == 200)
            total_requests += len(results)
            
            await asyncio.sleep(1)  # Wait 1 second before next batch
        
        success_rate = (success_count / total_requests) * 100
        requests_per_second = total_requests / 10
        
        assert success_rate >= 95, f"Success rate {success_rate:.2f}% below 95%"
        assert requests_per_second >= 40, f"Requests per second {requests_per_second:.2f} below 40"
        
        print(f"High Load Test Results:")
        print(f"  Total Requests: {total_requests}")
        print(f"  Success Rate: {success_rate:.2f}%")
        print(f"  Requests/Second: {requests_per_second:.2f}")
    
    @pytest.mark.asyncio
    async def test_spike_load(self, async_client):
        """Test system behavior under sudden load spikes."""
        async def make_request():
            response = await async_client.get("/health")
            return response.status_code
        
        # Simulate spike load: 100 requests in 1 second
        tasks = [make_request() for _ in range(100)]
        start_time = time.time()
        results = await asyncio.gather(*tasks)
        end_time = time.time()
        
        success_count = sum(1 for status in results if status == 200)
        success_rate = (success_count / len(results)) * 100
        spike_duration = end_time - start_time
        
        assert success_rate >= 90, f"Success rate {success_rate:.2f}% below 90%"
        assert spike_duration < 5, f"Spike handling time {spike_duration:.2f}s exceeds 5s"
        
        print(f"Spike Load Test Results:")
        print(f"  Total Requests: {len(results)}")
        print(f"  Success Rate: {success_rate:.2f}%")
        print(f"  Spike Duration: {spike_duration:.2f}s")


class TestMemoryUsage:
    """Test memory usage and potential memory leaks."""
    
    @pytest.mark.asyncio
    async def test_memory_usage_under_load(self, async_client):
        """Test memory usage under sustained load."""
        import psutil
        import os
        
        process = psutil.Process(os.getpid())
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        async def make_request():
            response = await async_client.get("/health")
            return response.status_code
        
        # Make many requests to test memory usage
        for batch in range(20):  # 20 batches
            tasks = [make_request() for _ in range(50)]  # 50 requests per batch
            results = await asyncio.gather(*tasks)
            
            # Check memory usage every 5 batches
            if batch % 5 == 0:
                current_memory = process.memory_info().rss / 1024 / 1024  # MB
                memory_increase = current_memory - initial_memory
                
                print(f"Batch {batch}: Memory usage {current_memory:.2f}MB (+{memory_increase:.2f}MB)")
                
                # Memory increase should be reasonable (less than 100MB)
                assert memory_increase < 100, f"Memory increase {memory_increase:.2f}MB exceeds 100MB"
        
        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        total_memory_increase = final_memory - initial_memory
        
        print(f"Final Memory Usage: {final_memory:.2f}MB")
        print(f"Total Memory Increase: {total_memory_increase:.2f}MB")
        
        assert total_memory_increase < 200, f"Total memory increase {total_memory_increase:.2f}MB exceeds 200MB"


class TestDatabasePerformance:
    """Test database performance and connection handling."""
    
    @pytest.mark.asyncio
    async def test_database_connection_pool(self, async_client, auth_headers):
        """Test database connection pool performance."""
        async def make_db_request():
            response = await async_client.get("/v1/reports", headers=auth_headers)
            return response.status_code
        
        # Test concurrent database requests
        tasks = [make_db_request() for _ in range(100)]
        start_time = time.time()
        results = await asyncio.gather(*tasks)
        end_time = time.time()
        
        success_count = sum(1 for status in results if status == 200)
        success_rate = (success_count / len(results)) * 100
        avg_response_time = ((end_time - start_time) * 1000) / len(results)
        
        assert success_rate >= 95, f"Database success rate {success_rate:.2f}% below 95%"
        assert avg_response_time < 500, f"Average DB response time {avg_response_time:.2f}ms exceeds 500ms"
        
        print(f"Database Connection Pool Test:")
        print(f"  Success Rate: {success_rate:.2f}%")
        print(f"  Average Response Time: {avg_response_time:.2f}ms")
    
    @pytest.mark.asyncio
    async def test_database_query_optimization(self, async_client, auth_headers):
        """Test database query optimization."""
        query_times = []
        
        # Test various query patterns
        endpoints = [
            "/v1/reports",
            "/v1/matches",
            "/v1/users/profile"
        ]
        
        for endpoint in endpoints:
            for _ in range(20):  # 20 requests per endpoint
                start_time = time.time()
                response = await async_client.get(endpoint, headers=auth_headers)
                end_time = time.time()
                
                if response.status_code == 200:
                    query_times.append((end_time - start_time) * 1000)
        
        avg_query_time = statistics.mean(query_times)
        p95_query_time = statistics.quantiles(query_times, n=20)[18]
        
        assert avg_query_time < 200, f"Average query time {avg_query_time:.2f}ms exceeds 200ms"
        assert p95_query_time < 400, f"95th percentile query time {p95_query_time:.2f}ms exceeds 400ms"
        
        print(f"Database Query Optimization:")
        print(f"  Average Query Time: {avg_query_time:.2f}ms")
        print(f"  95th Percentile: {p95_query_time:.2f}ms")


class TestCachePerformance:
    """Test caching system performance."""
    
    @pytest.mark.asyncio
    async def test_cache_hit_rate(self, async_client):
        """Test cache hit rate performance."""
        # Make repeated requests to the same endpoint
        cache_times = []
        no_cache_times = []
        
        # First request (cache miss)
        start_time = time.time()
        response1 = await async_client.get("/health")
        end_time = time.time()
        no_cache_times.append((end_time - start_time) * 1000)
        
        # Second request (cache hit)
        start_time = time.time()
        response2 = await async_client.get("/health")
        end_time = time.time()
        cache_times.append((end_time - start_time) * 1000)
        
        assert response1.status_code == 200
        assert response2.status_code == 200
        
        avg_cache_time = statistics.mean(cache_times)
        avg_no_cache_time = statistics.mean(no_cache_times)
        
        # Cache should be faster
        if avg_cache_time < avg_no_cache_time:
            improvement = ((avg_no_cache_time - avg_cache_time) / avg_no_cache_time) * 100
            print(f"Cache Performance Improvement: {improvement:.2f}%")
        
        print(f"Cache Performance:")
        print(f"  No Cache Time: {avg_no_cache_time:.2f}ms")
        print(f"  Cache Time: {avg_cache_time:.2f}ms")
    
    @pytest.mark.asyncio
    async def test_cache_scalability(self, async_client):
        """Test cache performance under load."""
        async def make_cached_request():
            start_time = time.time()
            response = await async_client.get("/health")
            end_time = time.time()
            return (end_time - start_time) * 1000
        
        # Make many requests to test cache scalability
        tasks = [make_cached_request() for _ in range(200)]
        response_times = await asyncio.gather(*tasks)
        
        avg_response_time = statistics.mean(response_times)
        p95_response_time = statistics.quantiles(response_times, n=20)[18]
        
        assert avg_response_time < 100, f"Average cached response time {avg_response_time:.2f}ms exceeds 100ms"
        assert p95_response_time < 200, f"95th percentile cached response time {p95_response_time:.2f}ms exceeds 200ms"
        
        print(f"Cache Scalability:")
        print(f"  Average Response Time: {avg_response_time:.2f}ms")
        print(f"  95th Percentile: {p95_response_time:.2f}ms")


class TestExternalServicePerformance:
    """Test performance of external service integrations."""
    
    @pytest.mark.asyncio
    async def test_nlp_service_performance(self, async_client, auth_headers):
        """Test NLP service performance."""
        # Mock NLP service for performance testing
        with patch('app.clients.get_nlp_client') as mock_nlp:
            mock_nlp.return_value.calculate_similarity.return_value = {
                "similarity_score": 0.85,
                "confidence": 0.9
            }
            
            search_data = {
                "query": "test search query",
                "max_results": 10
            }
            
            response_times = []
            for _ in range(50):
                start_time = time.time()
                response = await async_client.post(
                    "/v1/matches/search",
                    json=search_data,
                    headers=auth_headers
                )
                end_time = time.time()
                
                if response.status_code == 200:
                    response_times.append((end_time - start_time) * 1000)
            
            avg_response_time = statistics.mean(response_times)
            p95_response_time = statistics.quantiles(response_times, n=20)[18]
            
            assert avg_response_time < 1000, f"NLP service response time {avg_response_time:.2f}ms exceeds 1000ms"
            assert p95_response_time < 2000, f"NLP service 95th percentile {p95_response_time:.2f}ms exceeds 2000ms"
            
            print(f"NLP Service Performance:")
            print(f"  Average Response Time: {avg_response_time:.2f}ms")
            print(f"  95th Percentile: {p95_response_time:.2f}ms")
    
    @pytest.mark.asyncio
    async def test_vision_service_performance(self, async_client, auth_headers):
        """Test Vision service performance."""
        # Mock Vision service for performance testing
        with patch('app.clients.get_vision_client') as mock_vision:
            mock_vision.return_value.calculate_similarity.return_value = {
                "similarity_score": 0.78,
                "confidence": 0.85
            }
            
            # Test image similarity endpoint
            similarity_data = {
                "image1": "base64_encoded_image1",
                "image2": "base64_encoded_image2"
            }
            
            response_times = []
            for _ in range(30):  # Fewer requests due to image processing overhead
                start_time = time.time()
                response = await async_client.post(
                    "/v1/matches/image-similarity",
                    json=similarity_data,
                    headers=auth_headers
                )
                end_time = time.time()
                
                if response.status_code == 200:
                    response_times.append((end_time - start_time) * 1000)
            
            if response_times:  # Only test if we have successful responses
                avg_response_time = statistics.mean(response_times)
                p95_response_time = statistics.quantiles(response_times, n=20)[18]
                
                assert avg_response_time < 2000, f"Vision service response time {avg_response_time:.2f}ms exceeds 2000ms"
                assert p95_response_time < 5000, f"Vision service 95th percentile {p95_response_time:.2f}ms exceeds 5000ms"
                
                print(f"Vision Service Performance:")
                print(f"  Average Response Time: {avg_response_time:.2f}ms")
                print(f"  95th Percentile: {p95_response_time:.2f}ms")
