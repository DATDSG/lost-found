"""Unified health and readiness helpers.

Each service can import these lightweight utilities to expose /healthz and /readyz.
Avoid heavy imports (DB drivers, ML libs) at module import time; keep them lazy.
"""
from __future__ import annotations
from typing import Callable, Dict, Any

HealthCheck = Callable[[], bool]

class ReadinessRegistry:
    def __init__(self) -> None:
        self._checks: Dict[str, HealthCheck] = {}

    def register(self, name: str, fn: HealthCheck) -> None:
        self._checks[name] = fn

    def status(self) -> Dict[str, Any]:
        results = {}
        all_ok = True
        for name, fn in self._checks.items():
            try:
                ok = bool(fn())
            except Exception as exc:  # pragma: no cover - defensive
                ok = False
                results[name] = {"ok": False, "error": repr(exc)}
            else:
                results[name] = {"ok": ok}
            all_ok &= ok
        results["overall_ok"] = all_ok
        return results

readiness = ReadinessRegistry()

__all__ = ["readiness", "ReadinessRegistry"]
