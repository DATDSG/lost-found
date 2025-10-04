"""Pytest configuration and shared fixtures."""
import sys
from pathlib import Path

# Add backend to Python path for tests
backend_path = Path(__file__).parent.parent / "backend"
if str(backend_path) not in sys.path:
    sys.path.insert(0, str(backend_path))
