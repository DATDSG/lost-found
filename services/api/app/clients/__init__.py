"""
Service client integrations for NLP and Vision services.
Handles HTTP communication, caching, retries, and error handling.
"""
import httpx
import hashlib
import json
from typing import List, Optional, Dict, Any
from redis.asyncio import Redis
import logging

from ..config import config

logger = logging.getLogger(__name__)


class ServiceClient:
    """Base class for service clients with retry and caching logic."""
    
    def __init__(self, base_url: str, timeout: int = 30):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.client: Optional[httpx.AsyncClient] = None
        self.redis: Optional[Redis] = None
    
    async def __aenter__(self):
        """Async context manager entry."""
        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            timeout=self.timeout,
            limits=httpx.Limits(max_keepalive_connections=5, max_connections=10)
        )
        
        # Initialize Redis if caching is enabled
        if config.ENABLE_REDIS_CACHE:
            try:
                self.redis = Redis.from_url(
                    config.REDIS_URL,
                    max_connections=config.REDIS_MAX_CONNECTIONS,
                    decode_responses=True
                )
                await self.redis.ping()
            except Exception as e:
                logger.warning(f"Redis connection failed: {e}. Proceeding without cache.")
                self.redis = None
        
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        if self.client:
            await self.client.aclose()
        if self.redis:
            await self.redis.close()
    
    def _cache_key(self, prefix: str, data: Any) -> str:
        """Generate cache key from data."""
        data_str = json.dumps(data, sort_keys=True)
        hash_hex = hashlib.md5(data_str.encode()).hexdigest()
        return f"{prefix}:{hash_hex}"
    
    async def _get_cached(self, key: str) -> Optional[Any]:
        """Get value from cache."""
        if not self.redis:
            return None
        
        try:
            cached = await self.redis.get(key)
            if cached:
                return json.loads(cached)
        except Exception as e:
            logger.warning(f"Cache read failed: {e}")
        
        return None
    
    async def _set_cache(self, key: str, value: Any, ttl: Optional[int] = None):
        """Set value in cache."""
        if not self.redis:
            return
        
        try:
            ttl = ttl or config.REDIS_CACHE_TTL
            await self.redis.set(key, json.dumps(value), ex=ttl)
        except Exception as e:
            logger.warning(f"Cache write failed: {e}")


class NLPClient(ServiceClient):
    """Client for NLP service - text embeddings."""
    
    def __init__(self):
        super().__init__(
            base_url=config.NLP_SERVICE_URL,
            timeout=config.NLP_SERVICE_TIMEOUT
        )
    
    async def get_embedding(self, text: str, use_cache: bool = True) -> Optional[List[float]]:
        """
        Get text embedding from NLP service.
        
        Args:
            text: Input text to embed
            use_cache: Whether to use Redis cache
        
        Returns:
            384-dimensional embedding vector or None if failed
        """
        if not text or not text.strip():
            return None
        
        # Check cache first
        if use_cache and config.ENABLE_NLP_CACHE:
            cache_key = self._cache_key("nlp:embed", text)
            cached = await self._get_cached(cache_key)
            if cached:
                logger.debug(f"NLP cache hit for text: {text[:50]}...")
                return cached.get("embedding")
        
        # Call NLP service
        try:
            response = await self.client.post(
                "/embed",
                json={"text": text}
            )
            response.raise_for_status()
            
            result = response.json()
            embedding = result.get("embedding")
            
            # Cache result
            if use_cache and config.ENABLE_NLP_CACHE and embedding:
                await self._set_cache(cache_key, {"embedding": embedding})
            
            logger.info(f"NLP embedding generated for text: {text[:50]}...")
            return embedding
            
        except httpx.HTTPError as e:
            logger.error(f"NLP service error: {e}")
            return None
    
    async def get_embeddings_batch(
        self,
        texts: List[str],
        use_cache: bool = True
    ) -> List[Optional[List[float]]]:
        """
        Get embeddings for multiple texts in batch.
        
        Args:
            texts: List of input texts
            use_cache: Whether to use Redis cache
        
        Returns:
            List of embeddings (None for failed items)
        """
        if not texts:
            return []
        
        # Split into batches
        batch_size = config.NLP_BATCH_SIZE
        results = []
        
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            
            try:
                response = await self.client.post(
                    "/embed/batch",
                    json={"texts": batch}
                )
                response.raise_for_status()
                
                batch_results = response.json().get("embeddings", [])
                results.extend(batch_results)
                
                # Cache individual results
                if use_cache and config.ENABLE_NLP_CACHE:
                    for text, embedding in zip(batch, batch_results):
                        if embedding:
                            cache_key = self._cache_key("nlp:embed", text)
                            await self._set_cache(cache_key, {"embedding": embedding})
                
            except httpx.HTTPError as e:
                logger.error(f"NLP batch service error: {e}")
                results.extend([None] * len(batch))
        
        return results
    
    async def health_check(self) -> bool:
        """Check if NLP service is healthy."""
        try:
            response = await self.client.get("/health")
            return response.status_code == 200
        except Exception:
            return False


class VisionClient(ServiceClient):
    """Client for Vision service - image processing and hashing."""
    
    def __init__(self):
        super().__init__(
            base_url=config.VISION_SERVICE_URL,
            timeout=config.VISION_SERVICE_TIMEOUT
        )
    
    async def get_image_hash(
        self,
        image_url: str,
        use_cache: bool = True
    ) -> Optional[str]:
        """
        Get perceptual hash of image.
        
        Args:
            image_url: URL or path to image
            use_cache: Whether to use Redis cache
        
        Returns:
            Hexadecimal hash string or None if failed
        """
        if not image_url:
            return None
        
        # Check cache
        if use_cache and config.ENABLE_VISION_CACHE:
            cache_key = self._cache_key("vision:hash", image_url)
            cached = await self._get_cached(cache_key)
            if cached:
                logger.debug(f"Vision cache hit for image: {image_url}")
                return cached.get("hash")
        
        # Call Vision service
        try:
            response = await self.client.post(
                "/hash",
                json={"image_url": image_url}
            )
            response.raise_for_status()
            
            result = response.json()
            image_hash = result.get("phash")
            
            # Cache result
            if use_cache and config.ENABLE_VISION_CACHE and image_hash:
                await self._set_cache(cache_key, {"hash": image_hash})
            
            logger.info(f"Vision hash generated for image: {image_url}")
            return image_hash
            
        except httpx.HTTPError as e:
            logger.error(f"Vision service error: {e}")
            return None
    
    async def detect_objects(
        self,
        image_url: str,
        confidence_threshold: float = 0.5
    ) -> Optional[List[Dict[str, Any]]]:
        """
        Detect objects in image using YOLO.
        
        Args:
            image_url: URL or path to image
            confidence_threshold: Minimum confidence score
        
        Returns:
            List of detected objects with bbox, class, confidence
        """
        try:
            response = await self.client.post(
                "/detect",
                json={
                    "image_url": image_url,
                    "confidence_threshold": confidence_threshold
                }
            )
            response.raise_for_status()
            
            result = response.json()
            return result.get("detections", [])
            
        except httpx.HTTPError as e:
            logger.error(f"Vision object detection error: {e}")
            return None
    
    async def extract_text(self, image_url: str) -> Optional[str]:
        """
        Extract text from image using OCR.
        
        Args:
            image_url: URL or path to image
        
        Returns:
            Extracted text or None if failed
        """
        try:
            response = await self.client.post(
                "/ocr",
                json={"image_url": image_url}
            )
            response.raise_for_status()
            
            result = response.json()
            return result.get("text", "")
            
        except httpx.HTTPError as e:
            logger.error(f"Vision OCR error: {e}")
            return None
    
    async def check_content_safety(self, image_url: str) -> Optional[Dict[str, Any]]:
        """
        Check image for NSFW content.
        
        Args:
            image_url: URL or path to image
        
        Returns:
            Safety scores dict or None if failed
        """
        try:
            response = await self.client.post(
                "/nsfw",
                json={"image_url": image_url}
            )
            response.raise_for_status()
            
            return response.json()
            
        except httpx.HTTPError as e:
            logger.error(f"Vision NSFW check error: {e}")
            return None
    
    async def health_check(self) -> bool:
        """Check if Vision service is healthy."""
        try:
            response = await self.client.get("/health")
            return response.status_code == 200
        except Exception:
            return False


# Global client instances (use with async context manager)
async def get_nlp_client() -> NLPClient:
    """Get NLP client instance."""
    return NLPClient()


async def get_vision_client() -> VisionClient:
    """Get Vision client instance."""
    return VisionClient()
