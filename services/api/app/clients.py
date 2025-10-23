"""
Enhanced service client integrations for NLP and Vision services.
Handles HTTP communication, caching, retries, and error handling with improved matching capabilities.
"""
import httpx
import hashlib
import json
from typing import List, Optional, Dict, Any, Tuple
from redis.asyncio import Redis
import logging
import asyncio

from .config import config

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
                # Test Redis connection
                await self.redis.ping()
                logger.debug(f"Redis connected for {self.__class__.__name__}")
            except Exception as e:
                logger.warning(f"Redis connection failed for {self.__class__.__name__}: {e}. Proceeding without cache.")
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
    """Enhanced client for NLP service - text processing and matching."""
    
    def __init__(self):
        super().__init__(
            base_url=config.NLP_SERVICE_URL,
            timeout=config.NLP_SERVICE_TIMEOUT
        )
    
    async def process_text(
        self, 
        text: str, 
        normalize: bool = True,
        remove_stopwords: bool = True,
        lemmatize: bool = True,
        use_cache: bool = True
    ) -> Optional[Dict[str, Any]]:
        """
        Process text with enhanced preprocessing.
        
        Args:
            text: Input text to process
            normalize: Whether to normalize the text
            remove_stopwords: Whether to remove stopwords
            lemmatize: Whether to lemmatize words
            use_cache: Whether to use Redis cache
        
        Returns:
            Processed text data or None if failed
        """
        if not text or not text.strip():
            return None
        
        # Check cache first
        if use_cache and config.ENABLE_NLP_CACHE:
            cache_key = self._cache_key("nlp:process", {
                "text": text,
                "normalize": normalize,
                "remove_stopwords": remove_stopwords,
                "lemmatize": lemmatize
            })
            cached = await self._get_cached(cache_key)
            if cached:
                logger.debug(f"NLP cache hit for text processing: {text[:50]}...")
                return cached
        
        # Call NLP service
        try:
            response = await self.client.post(
                "/process",
                json={
                    "text": text,
                    "normalize": normalize,
                    "remove_stopwords": remove_stopwords,
                    "lemmatize": lemmatize
                }
            )
            response.raise_for_status()
            
            result = response.json()
            
            # Cache result
            if use_cache and config.ENABLE_NLP_CACHE:
                await self._set_cache(cache_key, result)
            
            logger.info(f"NLP text processed: {text[:50]}...")
            return result
            
        except httpx.HTTPError as e:
            logger.error(f"NLP service error: {e}")
            return None
    
    async def calculate_similarity(
        self,
        text1: str,
        text2: str,
        algorithm: str = "combined",
        use_cache: bool = True
    ) -> Optional[float]:
        """
        Calculate similarity between two texts.
        
        Args:
            text1: First text
            text2: Second text
            algorithm: Similarity algorithm (fuzzy, cosine, levenshtein, jaro_winkler, combined)
            use_cache: Whether to use Redis cache
        
        Returns:
            Similarity score (0.0 to 1.0) or None if failed
        """
        if not text1 or not text2:
            return None
        
        # Check cache first
        if use_cache and config.ENABLE_NLP_CACHE:
            cache_key = self._cache_key("nlp:similarity", {
                "text1": text1,
                "text2": text2,
                "algorithm": algorithm
            })
            cached = await self._get_cached(cache_key)
            if cached:
                logger.debug(f"NLP cache hit for similarity: {text1[:30]}... vs {text2[:30]}...")
                return cached.get("similarity_score")
        
        # Call NLP service
        try:
            response = await self.client.post(
                "/similarity",
                json={
                    "text1": text1,
                    "text2": text2,
                    "algorithm": algorithm
                }
            )
            response.raise_for_status()
            
            result = response.json()
            similarity_score = result.get("similarity_score")
            
            # Cache result
            if use_cache and config.ENABLE_NLP_CACHE and similarity_score is not None:
                await self._set_cache(cache_key, {"similarity_score": similarity_score})
            
            logger.info(f"NLP similarity calculated: {similarity_score:.3f}")
            return similarity_score
            
        except httpx.HTTPError as e:
            logger.error(f"NLP similarity service error: {e}")
            return None
    
    async def find_matches(
        self,
        query_text: str,
        candidate_texts: List[str],
        algorithm: str = "combined",
        threshold: float = 0.7,
        use_cache: bool = True
    ) -> Optional[List[Dict[str, Any]]]:
        """
        Find best matches for a query text against candidate texts.
        
        Args:
            query_text: Query text to match
            candidate_texts: List of candidate texts
            algorithm: Matching algorithm
            threshold: Minimum similarity threshold
            use_cache: Whether to use Redis cache
        
        Returns:
            List of matches with similarity scores or None if failed
        """
        if not query_text or not candidate_texts:
            return None
        
        # Check cache first
        if use_cache and config.ENABLE_NLP_CACHE:
            cache_key = self._cache_key("nlp:match", {
                "query_text": query_text,
                "candidate_texts": candidate_texts,
                "algorithm": algorithm,
                "threshold": threshold
            })
            cached = await self._get_cached(cache_key)
            if cached:
                logger.debug(f"NLP cache hit for matching: {query_text[:30]}...")
                return cached.get("matches")
        
        # Call NLP service
        try:
            response = await self.client.post(
                "/match",
                json={
                    "query_text": query_text,
                    "candidate_texts": candidate_texts,
                    "algorithm": algorithm,
                    "threshold": threshold
                }
            )
            response.raise_for_status()
            
            result = response.json()
            matches = result.get("matches", [])
            
            # Cache result
            if use_cache and config.ENABLE_NLP_CACHE:
                await self._set_cache(cache_key, {"matches": matches})
            
            logger.info(f"NLP found {len(matches)} matches for: {query_text[:30]}...")
            return matches
            
        except httpx.HTTPError as e:
            logger.error(f"NLP matching service error: {e}")
            return None
    
    async def process_batch(
        self,
        texts: List[str],
        normalize: bool = True,
        remove_stopwords: bool = True,
        lemmatize: bool = True,
        use_cache: bool = True
    ) -> Optional[List[Dict[str, Any]]]:
        """
        Process multiple texts in batch.
        
        Args:
            texts: List of texts to process
            normalize: Whether to normalize the texts
            remove_stopwords: Whether to remove stopwords
            lemmatize: Whether to lemmatize words
            use_cache: Whether to use Redis cache
        
        Returns:
            List of processed text results or None if failed
        """
        if not texts:
            return None
        
        # Call NLP service
        try:
            response = await self.client.post(
                "/process/batch",
                json={
                    "texts": texts,
                    "normalize": normalize,
                    "remove_stopwords": remove_stopwords,
                    "lemmatize": lemmatize
                }
            )
            response.raise_for_status()
            
            result = response.json()
            processed_results = result.get("results", [])
            
            logger.info(f"NLP batch processed {len(processed_results)} texts")
            return processed_results
            
        except httpx.HTTPError as e:
            logger.error(f"NLP batch service error: {e}")
            return None
    
    async def health_check(self) -> bool:
        """Check if NLP service is healthy."""
        try:
            response = await self.client.get("/health")
            if response.status_code == 200:
                data = response.json()
                return data.get("status") == "healthy"
            return False
        except Exception:
            return False


class VisionClient(ServiceClient):
    """Enhanced client for Vision service - image processing and matching."""
    
    def __init__(self):
        super().__init__(
            base_url=config.VISION_SERVICE_URL,
            timeout=config.VISION_SERVICE_TIMEOUT
        )
    
    async def generate_image_hashes(
        self,
        image_file_path: str,
        use_cache: bool = True
    ) -> Optional[Dict[str, str]]:
        """
        Generate multiple perceptual hashes for image.
        
        Args:
            image_file_path: Path to image file
            use_cache: Whether to use Redis cache
        
        Returns:
            Dictionary with multiple hash types or None if failed
        """
        if not image_file_path:
            return None
        
        # Check cache
        if use_cache and config.ENABLE_VISION_CACHE:
            cache_key = self._cache_key("vision:hashes", image_file_path)
            cached = await self._get_cached(cache_key)
            if cached:
                logger.debug(f"Vision cache hit for image hashes: {image_file_path}")
                return cached
        
        # Call Vision service with file upload
        try:
            with open(image_file_path, 'rb') as f:
                files = {'file': f}
                response = await self.client.post("/hash", files=files)
            response.raise_for_status()
            
            result = response.json()
            hashes = {
                "phash": result.get("phash"),
                "dhash": result.get("dhash"),
                "ahash": result.get("ahash"),
                "whash": result.get("whash")
            }
            
            # Cache result
            if use_cache and config.ENABLE_VISION_CACHE:
                await self._set_cache(cache_key, hashes)
            
            logger.info(f"Vision hashes generated for image: {image_file_path}")
            return hashes
            
        except httpx.HTTPError as e:
            logger.error(f"Vision service error: {e}")
            return None
    
    async def calculate_image_similarity(
        self,
        hash1: str,
        hash2: str,
        algorithm: str = "combined",
        use_cache: bool = True
    ) -> Optional[Tuple[float, int]]:
        """
        Calculate similarity between two image hashes.
        
        Args:
            hash1: First image hash
            hash2: Second image hash
            algorithm: Similarity algorithm (hamming, cosine, combined)
            use_cache: Whether to use Redis cache
        
        Returns:
            Tuple of (similarity_score, hamming_distance) or None if failed
        """
        if not hash1 or not hash2:
            return None
        
        # Check cache first
        if use_cache and config.ENABLE_VISION_CACHE:
            cache_key = self._cache_key("vision:similarity", {
                "hash1": hash1,
                "hash2": hash2,
                "algorithm": algorithm
            })
            cached = await self._get_cached(cache_key)
            if cached:
                logger.debug(f"Vision cache hit for similarity")
                return (cached.get("similarity_score"), cached.get("hamming_distance"))
        
        # Call Vision service
        try:
            response = await self.client.post(
                "/similarity",
                json={
                    "hash1": hash1,
                    "hash2": hash2,
                    "algorithm": algorithm
                }
            )
            response.raise_for_status()
            
            result = response.json()
            similarity_score = result.get("similarity_score")
            hamming_distance = result.get("hamming_distance")
            
            # Cache result
            if use_cache and config.ENABLE_VISION_CACHE:
                await self._set_cache(cache_key, {
                    "similarity_score": similarity_score,
                    "hamming_distance": hamming_distance
                })
            
            logger.info(f"Vision similarity calculated: {similarity_score:.3f}")
            return (similarity_score, hamming_distance)
            
        except httpx.HTTPError as e:
            logger.error(f"Vision similarity service error: {e}")
            return None
    
    async def find_image_matches(
        self,
        query_hash: str,
        candidate_hashes: List[Dict[str, str]],
        algorithm: str = "combined",
        threshold: float = 0.8,
        use_cache: bool = True
    ) -> Optional[List[Dict[str, Any]]]:
        """
        Find best matches for a query image hash against candidate hashes.
        
        Args:
            query_hash: Query image hash
            candidate_hashes: List of candidate hashes with metadata
            algorithm: Matching algorithm
            threshold: Minimum similarity threshold
            use_cache: Whether to use Redis cache
        
        Returns:
            List of matches with similarity scores or None if failed
        """
        if not query_hash or not candidate_hashes:
            return None
        
        # Check cache first
        if use_cache and config.ENABLE_VISION_CACHE:
            cache_key = self._cache_key("vision:match", {
                "query_hash": query_hash,
                "candidate_hashes": candidate_hashes,
                "algorithm": algorithm,
                "threshold": threshold
            })
            cached = await self._get_cached(cache_key)
            if cached:
                logger.debug(f"Vision cache hit for matching")
                return cached.get("matches")
        
        # Call Vision service
        try:
            response = await self.client.post(
                "/match",
                json={
                    "query_hash": query_hash,
                    "candidate_hashes": candidate_hashes,
                    "algorithm": algorithm,
                    "threshold": threshold
                }
            )
            response.raise_for_status()
            
            result = response.json()
            matches = result.get("matches", [])
            
            # Cache result
            if use_cache and config.ENABLE_VISION_CACHE:
                await self._set_cache(cache_key, {"matches": matches})
            
            logger.info(f"Vision found {len(matches)} matches")
            return matches
            
        except httpx.HTTPError as e:
            logger.error(f"Vision matching service error: {e}")
            return None
    
    async def get_image_info(
        self,
        image_file_path: str,
        use_cache: bool = True
    ) -> Optional[Dict[str, Any]]:
        """
        Get detailed information about image.
        
        Args:
            image_file_path: Path to image file
            use_cache: Whether to use Redis cache
        
        Returns:
            Image information with quality metrics or None if failed
        """
        if not image_file_path:
            return None
        
        # Check cache
        if use_cache and config.ENABLE_VISION_CACHE:
            cache_key = self._cache_key("vision:info", image_file_path)
            cached = await self._get_cached(cache_key)
            if cached:
                logger.debug(f"Vision cache hit for image info: {image_file_path}")
                return cached
        
        # Call Vision service with file upload
        try:
            with open(image_file_path, 'rb') as f:
                files = {'file': f}
                response = await self.client.post("/info", files=files)
            response.raise_for_status()
            
            result = response.json()
            
            # Cache result
            if use_cache and config.ENABLE_VISION_CACHE:
                await self._set_cache(cache_key, result)
            
            logger.info(f"Vision image info generated for: {image_file_path}")
            return result
            
        except httpx.HTTPError as e:
            logger.error(f"Vision info service error: {e}")
            return None
    
    async def health_check(self) -> bool:
        """Check if Vision service is healthy."""
        try:
            response = await self.client.get("/health")
            if response.status_code == 200:
                data = response.json()
                return data.get("status") == "healthy"
            return False
        except Exception:
            return False


# Global client instances (use with async context manager)
def get_nlp_client() -> NLPClient:
    """Get NLP client instance."""
    return NLPClient()


def get_vision_client() -> VisionClient:
    """Get Vision client instance."""
    return VisionClient()
