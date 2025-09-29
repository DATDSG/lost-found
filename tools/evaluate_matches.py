"""Offline evaluation toolkit for match scoring.

This script gathers resolved item pairs and computes evaluation metrics
(Recall@K, MRR, latency) for the current matching configuration.

Usage:
    pipenv run python notebooks/evaluate_matches.py --limit 200
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from statistics import mean
from typing import Iterable, List, Tuple

from sqlalchemy import create_engine, text

from services.api.app.core.config import settings
from services.api.app.services.matching_service import matching_service
from services.api.app.db.session import SessionLocal
from services.api.app.db import models

@dataclass
class EvaluationResult:
    item_id: int
    matched_id: int
    rank: int | None
    score: float | None
    expected_id: int
    latency_seconds: float


def fetch_resolved_pairs(limit: int) -> List[Tuple[int, int]]:
    engine = create_engine(settings.DATABASE_URL)
    with engine.connect() as conn:
        rows = conn.execute(
            text(
                """
                SELECT resolved_lost.id AS lost_id, resolved_found.id AS found_id
                FROM items AS resolved_lost
                JOIN matches ON matches.lost_item_id = resolved_lost.id
                JOIN items AS resolved_found ON resolved_found.id = matches.found_item_id
                WHERE resolved_lost.status = 'resolved' AND resolved_found.status = 'resolved'
                ORDER BY matches.created_at DESC
                LIMIT :limit
                """
            ),
            {"limit": limit},
        ).fetchall()
    return [(row.lost_id, row.found_id) for row in rows]


def evaluate(limit: int, top_k: int = 10) -> dict:
    pairs = fetch_resolved_pairs(limit)
    if not pairs:
        raise SystemExit("No resolved pairs available. Populate data before evaluation.")

    session = SessionLocal()
    try:
        results: List[EvaluationResult] = []
        for lost_id, expected_found_id in pairs:
            matches = matching_service.rank_for_item(session, lost_id, limit=top_k)
            rank = None
            score = None
            for idx, match in enumerate(matches, start=1):
                if match.found_item_id == expected_found_id:
                    rank = idx
                    score = match.score
                    break
            latency = 0.0
            lost = session.get(models.Item, lost_id)
            expected = session.get(models.Item, expected_found_id)
            if lost and expected and lost.created_at and expected.created_at:
                earliest = min(lost.created_at, expected.created_at)
                match_time = max(lost.created_at, expected.created_at)
                latency = (match_time - earliest).total_seconds()
            results.append(
                EvaluationResult(
                    item_id=lost_id,
                    matched_id=expected_found_id,
                    rank=rank,
                    score=score,
                    expected_id=expected_found_id,
                    latency_seconds=latency,
                )
            )

        recall_at_k = sum(1 for r in results if r.rank and r.rank <= top_k) / len(results)
        reciprocal_ranks = [1 / r.rank for r in results if r.rank]
        mrr = mean(reciprocal_ranks) if reciprocal_ranks else 0.0
        avg_latency = mean(r.latency_seconds for r in results) if results else 0.0

        return {
            "pairs": len(results),
            "recall_at_k": recall_at_k,
            "mrr": mrr,
            "average_latency_seconds": avg_latency,
        }
    finally:
        session.close()


def main():
    parser = argparse.ArgumentParser(description="Evaluate matching quality")
    parser.add_argument("--limit", type=int, default=100, help="Number of resolved pairs to sample")
    parser.add_argument("--output", type=Path, default=Path("reports/match_eval.json"), help="Where to write metrics")
    args = parser.parse_args()

    metrics = evaluate(limit=args.limit)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(metrics, indent=2))
    print(json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
