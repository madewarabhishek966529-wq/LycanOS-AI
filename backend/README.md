# LycanOS AI — Backend

FastAPI backend for LycanOS AI. Phase 1 delivers the project skeleton: app
factory, config, DB engine setup, security utilities, and a working
health-check API — everything later phases (auth, POS, inventory, AI
assistant) build on top of.

## Stack

- FastAPI + Uvicorn
- SQLAlchemy 2.0 (async) + PostgreSQL (via `asyncpg`)
- Alembic for migrations (added when the first real models land in Phase 4)
- Redis (caching / pub-sub for websockets, wired in later phases)
- JWT auth via `python-jose`, password hashing via `passlib[bcrypt]`
- Ollama + LangChain + ChromaDB for the local AI assistant (Phase 9)

## Project layout

```
app/
  core/          # config.py (Settings), security.py (JWT + hashing)
  db/            # database.py (async engine, session factory, Base)
  api/v1/        # router.py aggregates versioned endpoint routers
    endpoints/   # one module per resource (health.py so far)
  models/        # SQLAlchemy ORM models (Phase 4+)
  schemas/       # Pydantic request/response schemas (Phase 2+)
  services/      # business logic, orchestrates repositories
  repositories/  # DB access layer, one per aggregate/entity
  main.py        # app factory: CORS, router mounting, lifespan
tests/           # pytest + httpx ASGI transport tests
```

Layering follows `api → service → repository → model`, matching the
pattern used across the Flutter side and prior projects: endpoints stay
thin (parse request, call a service, return a schema), services hold
business rules, repositories are the only layer that touches the DB
session directly.

## Local setup

```bash
# 1. Start Postgres + Redis
docker compose up -d

# 2. Create a virtualenv and install deps
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt

# 3. Configure environment
cp .env.example .env
# edit .env — at minimum set a real SECRET_KEY for anything beyond local dev

# 4. Run the API
uvicorn app.main:app --reload --port 8000
```

Visit `http://localhost:8000/docs` for interactive OpenAPI docs, and
`http://localhost:8000/api/v1/health` for the liveness check.

## Tests

```bash
pytest tests/ -v
```

Phase 1 ships 3 passing tests covering app boot, the health endpoint, and
docs availability. DB-backed tests (readiness check, and every feature
endpoint from Phase 2 onward) will spin up a disposable test database via
a pytest fixture once real models exist — no point mocking a schema that
isn't defined yet.

## What's deliberately not here yet

- No POS/sales endpoints yet — stock only moves via the manual
  `/inventory/products/{id}/adjust-stock` endpoint until Phase 4 adds
  checkout-driven decrements
- No Alembic migration has been run against a real Postgres in this
  environment (no live DB reachable in this sandbox) — the migration file
  is hand-written to match the model definitions; run `alembic upgrade head`
  against your own Postgres instance to apply it
- Ollama/LangChain/ChromaDB are commented out in `requirements.txt` —
  installed when Phase 9 (AI Assistant) actually uses them
