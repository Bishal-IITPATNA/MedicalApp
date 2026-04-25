# Seevak Care - Healthcare Management System

## Original Problem Statement
> "Analyse the code and deploy the application. Use postgres sql database for production."

The user provided the GitHub repository: <https://github.com/Bishal-IITPATNA/MedicalApp>
(Flask backend + Flutter multi-platform frontend) and Supabase Postgres credentials.

## Architecture (deployed on Emergent)

| Layer        | Tech                                                | Port | Notes |
|--------------|-----------------------------------------------------|------|-------|
| Frontend     | Flutter 3.41.6 → built to static **web** assets     | 3000 | Served by `node server.js` (no deps). SPA fallback to `index.html`. |
| Backend      | Flask 3 + SQLAlchemy 2 + Flask-JWT-Extended         | 8001 | Wrapped with `a2wsgi.WSGIMiddleware` so the read-only supervisor command `uvicorn server:app` can serve the WSGI Flask app. |
| Database     | **PostgreSQL on Supabase** (transaction pooler)     | 6543 | `aws-1-ap-northeast-1.pooler.supabase.com`. Tables auto-created via `db.create_all()` on backend boot. |
| Ingress      | Emergent ingress                                    | -    | Routes `/api/*` → backend:8001, everything else → frontend:3000. |

## What's Implemented (2026-04-25)
- Migrated from author's Azure SQL/SQLite default to Supabase Postgres via `DATABASE_URL` env var.
- Added `psycopg2-binary` and `a2wsgi` to backend requirements.
- Created `/app/backend/server.py` ASGI entrypoint that wraps the Flask `create_app()` factory.
- Replaced the original Azure-hardcoded CORS list with an env-driven list plus a regex that allows any `*.emergentagent.com` host (preview & production).
- Added `/api/health` route to the Flask app for ingress health checks.
- Built Flutter Web with `--dart-define=API_BASE_URL=/api` so the same artefact works for preview AND any future Emergent production URL.
- Added a **navigator.language shim** in `index.html` to fix the Dart `intl` startup crash ("Incorrect locale information provided") that occurs in headless / preview browsers that send a non-canonical locale.
- Custom dependency-free Node static server (`/app/frontend/server.js`) with proper MIME types, immutable caching for fingerprinted assets, and SPA fallback - launched via `yarn start` to satisfy the read-only supervisor command.
- Idempotent seed script `seed_default_users.py` creating the 5 default users from the README (admin / patient / doctor / medical_store / lab_store).
- Convenience rebuild script: `bash /app/scripts/build_frontend.sh`.

## Endpoints (verified end-to-end)
- `GET  /api/health` → 200 healthy
- `GET  /api/test`   → 200 working
- `POST /api/auth/login` with each of the five seeded accounts → 200 with JWT access/refresh tokens.

Other registered blueprints (not smoke tested but mounted): `/api/auth/*`, `/api/patient/*`, `/api/doctor/*`, `/api/nurse/*`, `/api/medical-store/*`, `/api/lab-store/*`, `/api/admin/*`, `/api/appointments/*`, `/api/notifications/*`, `/api/payments/*`, `/api/prescriptions/*`, `/api/patient-history/*`, `/api/doctor-lab-tests/*`.

## Environment Variables (`/app/backend/.env`)
- `DATABASE_URL` - Supabase Postgres pooler URL (URL-encoded password).
- `JWT_SECRET_KEY`, `SECRET_KEY` - rotate before going live.
- `APP_PUBLIC_URL` - preview URL used to seed the CORS allow-list.
- `SUPABASE_URL`, `SUPABASE_KEY` - kept for completeness; not used by Flask (Flask connects directly via `DATABASE_URL`).

## Known Gaps / Backlog (P1+P2)
- **P1**: Optional integrations (Razorpay, Twilio SMS) are not wired - graceful no-ops only. Provide keys to enable.
- **P1**: Custom-domain CORS - if user adds a non-`emergentagent.com` domain on production, append it to `cors_origins` in `app/__init__.py` or extend the regex.
- **P1**: Use Flask-Migrate (`flask db upgrade`) instead of `db.create_all()` for schema evolution once new migrations are added.
- **P2**: Frontend test suite - none currently set up; consider Flutter integration tests + Postman collection for backend.
- **P2**: Native iOS / Android Flutter builds - only Flutter Web is deployed at the moment.

## Repo Hygiene
- `/app/backend_old_fastapi/` and `/app/frontend_old_react/` - backups of the original starter shells; safe to delete.
- `/app/.flutter/` - Flutter SDK 3.41.6 (~1.5 GB). Required only when re-building the web bundle. Can be removed after final build is committed.
- `/app/.flutter_app/` - Flutter source mirror of the GitHub repo, used by `scripts/build_frontend.sh`.
