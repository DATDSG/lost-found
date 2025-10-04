# Backend Tests

Test suite for Lost & Found backend services.

## Running Tests

Install dev dependencies:

```bash
pip install -e ".[dev]"
```

Run all tests:

```bash
pytest
```

Run with coverage:

```bash
pytest --cov=backend --cov-report=html
```

Run specific test file:

```bash
pytest tests/test_health_endpoints.py
```

Run only unit tests (skip integration):

```bash
pytest -m "not integration"
```

## Test Structure

- `test_health_endpoints.py` - Health and readiness endpoint tests
- `conftest.py` - Shared fixtures and configuration

## Integration Tests

Integration tests are marked with `@pytest.mark.integration` and require running services.
Skip them for local unit testing:

```bash
pytest -m "not integration"
```
