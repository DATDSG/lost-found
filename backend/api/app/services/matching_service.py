from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List, Optional

import httpx
import numpy as np
from loguru import logger
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db import models
from app.schemas.matches import MatchPublic
from app.utils.geo import haversine_km

_TEXT_CLIENT_TIMEOUT = httpx.Timeout(5.0, connect=2.0)
_NLP_ENDPOINT = f"{settings.NLP_SERVICE_URL}/embed"


@dataclass
class ScoredCandidate:
    item: models.Item
    score: float
    explain: Dict[str, float]


class MatchingService:
    """Produces weighted match scores for lost/found item pairs."""

    def __init__(self) -> None:
        self._weights = {
            "text": settings.MATCH_WEIGHT_TEXT,
            "image": settings.MATCH_WEIGHT_IMAGE,
            "geo": settings.MATCH_WEIGHT_GEO,
            "time": settings.MATCH_WEIGHT_TIME,
            "meta": settings.MATCH_WEIGHT_META,
        }

    # ---------------------------------------------------------------------
    # Public API
    # ---------------------------------------------------------------------
    def rank_for_item(self, db: Session, item_id: int, limit: int = 20) -> List[MatchPublic]:
        base_item = db.query(models.Item).filter(models.Item.id == item_id).first()
        if base_item is None:
            raise ValueError(f"Item {item_id} not found")

        counterpart_status = "found" if base_item.status.lower() == "lost" else "lost"
        candidates: List[models.Item] = (
            db.query(models.Item)
            .filter(models.Item.status == counterpart_status, models.Item.id != base_item.id)
            .order_by(models.Item.created_at.desc())
            .limit(50)
            .all()
        )

        if not candidates:
            return []

        text_scores = self._score_text(base_item, candidates)
        image_scores = self._score_image(base_item, candidates)
        geo_scores = self._score_geo(base_item, candidates)
        time_scores = self._score_time(base_item, candidates)
        meta_scores = self._score_meta(base_item, candidates)

        scored: List[ScoredCandidate] = []
        for candidate in candidates:
            explain = {
                "text": text_scores.get(candidate.id, 0.0),
                "image": image_scores.get(candidate.id, 0.0),
                "geo": geo_scores.get(candidate.id, 0.0),
                "time": time_scores.get(candidate.id, 0.0),
                "meta": meta_scores.get(candidate.id, 0.0),
            }
            total = sum(explain[key] * self._weights[key] for key in explain)
            scored.append(ScoredCandidate(item=candidate, score=total, explain=explain))

        scored.sort(key=lambda sc: sc.score, reverse=True)

        results: List[MatchPublic] = []
        for idx, sc in enumerate(scored[:limit]):
            if base_item.status.lower() == "lost":
                lost_id, found_id = base_item.id, sc.item.id
            else:
                lost_id, found_id = sc.item.id, base_item.id

            results.append(
                MatchPublic(
                    id=sc.item.id,  # virtual identifier aligned with candidate item
                    lost_item_id=lost_id,
                    found_item_id=found_id,
                    score=sc.score,
                    explain=sc.explain,
                )
            )

        return results

    # ------------------------------------------------------------------
    # Individual component scorers
    # ------------------------------------------------------------------
    def _score_text(self, base: models.Item, candidates: List[models.Item]) -> Dict[int, float]:
        base_text = self._render_text(base)
        candidate_texts = [self._render_text(c) for c in candidates]
        try:
            base_vec, cand_mat = self._embed_pair(base_text, candidate_texts)
        except Exception as exc:  # pragma: no cover - network failures are expected in tests
            logger.warning("Falling back to keyword text scoring: {}", exc)
            return self._keyword_overlap(base_text, candidates)

        if base_vec is None or cand_mat is None:
            return self._keyword_overlap(base_text, candidates)

        scores: Dict[int, float] = {}
        for cand, vec in zip(candidates, cand_mat):
            if base_vec is None or vec is None:
                scores[cand.id] = 0.0
                continue
            similarity = float(np.dot(base_vec, vec))
            scores[cand.id] = (similarity + 1.0) / 2.0  # map [-1, 1] -> [0, 1]
        return scores

    def _score_image(self, base: models.Item, candidates: List[models.Item]) -> Dict[int, float]:
        base_hash = self._first_phash(base)
        scores: Dict[int, float] = {}
        if not base_hash:
            return {c.id: 0.0 for c in candidates}
        for cand in candidates:
            cand_hash = self._first_phash(cand)
            if not cand_hash:
                scores[cand.id] = 0.0
                continue
            distance = self._hash_distance(base_hash, cand_hash)
            scores[cand.id] = max(0.0, 1.0 - (distance / 64.0))
        return scores

    def _score_geo(self, base: models.Item, candidates: List[models.Item]) -> Dict[int, float]:
        if base.lat is None or base.lng is None:
            return {c.id: 0.0 for c in candidates}
        scores: Dict[int, float] = {}
        for cand in candidates:
            if cand.lat is None or cand.lng is None:
                scores[cand.id] = 0.0
                continue
            distance_km = haversine_km(base.lat, base.lng, cand.lat, cand.lng)
            scores[cand.id] = max(0.0, 1.0 - (distance_km / 50.0))
        return scores

    def _score_time(self, base: models.Item, candidates: List[models.Item]) -> Dict[int, float]:
        base_created = base.created_at or datetime.utcnow()
        scores: Dict[int, float] = {}
        for cand in candidates:
            cand_created = cand.created_at or datetime.utcnow()
            delta_days = abs((base_created - cand_created).total_seconds()) / 86400.0
            scores[cand.id] = max(0.0, 1.0 - (delta_days / 30.0))
        return scores

    def _score_meta(self, base: models.Item, candidates: List[models.Item]) -> Dict[int, float]:
        scores: Dict[int, float] = {}
        for cand in candidates:
            same_category = 1.0 if base.category and cand.category and base.category == cand.category else 0.0
            same_owner = 1.0 if base.owner_id == cand.owner_id else 0.0
            scores[cand.id] = min(1.0, (same_category * 0.7) + (same_owner * 0.3))
        return scores

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------
    def _render_text(self, item: models.Item) -> str:
        return "\n".join(filter(None, [item.title or "", item.description or ""]))

    def _embed_pair(self, query_text: str, candidate_texts: List[str]) -> tuple[Optional[np.ndarray], Optional[np.ndarray]]:
        payload = {
            "texts": [query_text],
            "kind": "query",
            "normalize": True,
        }
        cand_payload = {
            "texts": candidate_texts,
            "kind": "passage",
            "normalize": True,
        }
        with httpx.Client(timeout=_TEXT_CLIENT_TIMEOUT) as client:
            query_resp = client.post(_NLP_ENDPOINT, json=payload)
            cand_resp = client.post(_NLP_ENDPOINT, json=cand_payload)
        if query_resp.status_code != 200 or cand_resp.status_code != 200:
            raise RuntimeError(
                f"NLP service error: {query_resp.status_code}/{cand_resp.status_code}"
            )
        query_vecs = np.asarray(query_resp.json()["vectors"], dtype=np.float32)
        cand_vecs = np.asarray(cand_resp.json()["vectors"], dtype=np.float32)
        if query_vecs.size == 0 or cand_vecs.size == 0:
            return None, None
        query_vec = query_vecs[0]
        return query_vec, cand_vecs

    def _keyword_overlap(self, base_text: str, candidates: List[models.Item]) -> Dict[int, float]:
        base_tokens = set(base_text.lower().split())
        if not base_tokens:
            return {c.id: 0.0 for c in candidates}
        scores: Dict[int, float] = {}
        for cand in candidates:
            cand_tokens = set(self._render_text(cand).lower().split())
            overlap = len(base_tokens & cand_tokens)
            union = len(base_tokens | cand_tokens) or 1
            scores[cand.id] = overlap / union
        return scores

    def _first_phash(self, item: models.Item) -> Optional[str]:
        for asset in item.media:
            if asset.phash:
                return asset.phash
        return None

    def _hash_distance(self, h1: str, h2: str) -> int:
        try:
            n1 = int(h1, 16)
            n2 = int(h2, 16)
            xor = n1 ^ n2
            return bin(xor).count("1")
        except ValueError:
            return 64


matching_service = MatchingService()
