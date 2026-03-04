# Python Stack Profile

## Package Manager
- pip (requirements.txt) or Poetry (pyproject.toml, poetry.lock) or uv
- Virtual env: `python -m venv .venv`, `source .venv/bin/activate`
- Check: pyproject.toml → Poetry/Hatch, requirements.txt → pip, Pipfile → pipenv

## Build & Run
- Script: `python main.py` or `python -m package_name`
- Flask: `flask run` or `python app.py`
- Django: `python manage.py runserver`
- FastAPI: `uvicorn app.main:app --reload`

## Testing
- Framework: pytest (preferred), unittest, or Django test
- Run: `pytest`, `pytest -v`, `pytest -x` (stop on first fail)
- Single: `pytest tests/test_auth.py::test_login`
- Markers: `pytest -m "not slow"`, `@pytest.mark.slow`
- Fixtures: `conftest.py` files, `@pytest.fixture`
- Mocking: `unittest.mock`, `pytest-mock`
- Coverage: `pytest --cov=src --cov-report=html`
- Convention: `tests/` mirrors `src/` structure, files prefixed `test_`

## Linting & Formatting
- Formatter: `ruff format` or `black`
- Linter: `ruff check` or `flake8` + `pylint`
- Type checker: `mypy` or `pyright`
- Import sorting: `ruff` or `isort`
- Config: `pyproject.toml` [tool.ruff], [tool.mypy], etc.

## Security Scanners
- Bandit — Python SAST (hardcoded passwords, injection, eval, exec)
  Run: `bandit -r src/ -f json`
- pip-audit — known CVEs in installed packages
  Run: `pip-audit --format json`
- Safety — alternative to pip-audit
- Semgrep — has Python rules
- Gitleaks / Trivy — secrets + dependency CVEs

## Common Vulnerabilities
- eval/exec: never with user input
- pickle: deserializing untrusted data = remote code execution
- SQL injection: use parameterized queries, ORM query builders
- Command injection: `subprocess.run(shell=True)` with user input
- Path traversal: validate paths, use `pathlib`, don't join user input directly
- SSRF: validate URLs before `requests.get(user_url)`
- YAML: `yaml.safe_load()` never `yaml.load()`
- Jinja2: autoescape should be ON, watch for `|safe` filter
- Secrets: use environment variables or secret managers, never hardcode
- Dependencies: pin exact versions in requirements.txt

## Database
- Django ORM, SQLAlchemy, or Tortoise ORM
- Migrations: Alembic (SQLAlchemy), Django migrations
- Django: `python manage.py makemigrations`, `python manage.py migrate`
- Alembic: `alembic revision --autogenerate`, `alembic upgrade head`

## Dependencies
- Lockfile: poetry.lock, requirements.txt with pinned versions
- Audit: `pip-audit`, `safety check`
- Outdated: `pip list --outdated`
- Virtual env: always use one, check `.venv/`, `venv/`

## DevOps
- Docker: `python:3.x-slim`, multi-stage, `pip install --no-cache-dir`
- CI: `pip install` → `ruff check` → `mypy` → `pytest` → deploy
- WSGI/ASGI: gunicorn (sync), uvicorn (async)
- Process manager: gunicorn with workers, or systemd
- ENV: python-dotenv or env vars, 12-factor app pattern

## Architecture Patterns
- Django: MVT (Model-View-Template), apps in `app_name/`
- FastAPI: routers in `routers/`, schemas in `schemas/`, services in `services/`
- Flask: blueprints, application factory pattern
- Clean architecture: `domain/`, `application/`, `infrastructure/`, `presentation/`
- Data classes: `dataclasses` or `pydantic` for validation
- Async: `asyncio`, `aiohttp`, `httpx` for async HTTP
- Logging: `logging` module, structured logging with `structlog`

## Code Review Focus
- Type hints: are they present and correct?
- Exception handling: bare `except:` is a red flag, catch specific exceptions
- Resource management: use `with` statements for files, connections
- Mutable defaults: `def f(x=[])` is a classic bug
- Global state: avoid module-level mutable state
- Import structure: circular imports, unused imports
