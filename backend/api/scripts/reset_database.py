"""Reset the application database (DANGEROUS).

This will:
  1. Drop all tables (via alembic downgrade base)
  2. Re-apply all migrations (alembic upgrade head)
  3. Optionally re-seed minimal data

Usage inside API container:
  docker-compose exec api python scripts/reset_database.py            # without seed
  docker-compose exec api python scripts/reset_database.py --seed     # with seed

Safety: This script guards against running in production unless FORCE_RESET=1.
"""
from __future__ import annotations
import os
import subprocess
import sys

ENV = os.getenv("ENV", "development")
FORCE = os.getenv("FORCE_RESET") == "1"


def run(cmd: list[str]):
    print(f"[run] {' '.join(cmd)}")
    result = subprocess.run(cmd, text=True)
    if result.returncode != 0:
        print(f"Command failed: {' '.join(cmd)}", file=sys.stderr)
        sys.exit(result.returncode)


def main():
    if ENV not in {"local", "development", "dev", "test"} and not FORCE:
        print(f"Refusing to reset database in ENV={ENV}. Set FORCE_RESET=1 to override.")
        sys.exit(1)

    print("-- Dropping schema via alembic downgrade base --")
    run(["alembic", "downgrade", "base"])  # safe because migrations are idempotent enough after fixes

    print("-- Re-applying migrations --")
    run(["alembic", "upgrade", "head"])    

    if "--seed" in sys.argv or "-s" in sys.argv:
        print("-- Seeding minimal data --")
        run(["python", "scripts/seed_minimal_data.py"])  

    print("Database reset complete.")

if __name__ == "__main__":
    main()
