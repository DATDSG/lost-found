# Developer Makefile (primarily for Unix-like shells; on Windows use scripts/dev.ps1)

COMPOSE ?= docker-compose
API    ?= api

.PHONY: up down migrate seed reset smoke logs psql beatlogs

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down -v

migrate:
	$(COMPOSE) exec $(API) alembic upgrade head

seed:
	$(COMPOSE) exec $(API) python -m scripts.seed_minimal_data

reset:
	$(COMPOSE) exec $(API) python scripts/reset_database.py --seed

smoke:
	$(COMPOSE) exec $(API) python scripts/smoke_test_api.py

logs:
	$(COMPOSE) logs -f $(API)

psql:
	$(COMPOSE) exec postgres psql -U lostfound -d lostfound

beatlogs:
	$(COMPOSE) logs -f worker-beat
