# Seevak Care - GitHub + Render Deployment Setup

This folder contains everything needed to wire up automated deployments
from GitHub → Render for the Seevak Care app. The structure of this
folder mirrors what should land in your GitHub repo at
<https://github.com/Bishal-IITPATNA/MedicalApp>.

```
_render_deploy/
├── render.yaml                                      # → repo root
├── .github/workflows/ci.yml                         # → repo root
├── .github/workflows/deploy.yml                     # → repo root
├── backend/
│   ├── app/__init__.py                              # REPLACES backend/app/__init__.py
│   ├── seed_default_users.py                        # NEW file
│   └── requirements.txt                             # REPLACES backend/requirements.txt
└── frontend/
    ├── render-build.sh                              # NEW file (chmod +x)
    ├── lib/main.dart                                # REPLACES frontend/lib/main.dart
    └── web/index.html                               # REPLACES frontend/web/index.html
```

---

## 1. Push these files to GitHub

From your local clone of the repo:

```bash
git checkout -b setup-render-deploy

# Copy in the new / changed files (paths above), then:
git add render.yaml .github backend/seed_default_users.py \
        backend/app/__init__.py backend/requirements.txt \
        frontend/render-build.sh frontend/lib/main.dart frontend/web/index.html
git commit -m "ci: GitHub Actions + Render Blueprint for prod deploy"
git push origin setup-render-deploy
```

Open a PR and merge it to `main`. The CI workflow will run on the PR;
once you merge to `main`, the deploy workflow will run (but it will
fail until you finish step 3 below — that's expected the first time).

> **Note**: `chmod +x frontend/render-build.sh` before committing,
> or Render will refuse to execute it.

---

## 2. Create the Render services (one-time)

1. Sign up / log in at <https://render.com> and connect your GitHub
   account so Render can read the `MedicalApp` repo.
2. Click **New → Blueprint**, select the `MedicalApp` repo, branch
   `main`. Render will detect `render.yaml` and propose two services:
   - `seevak-backend`  (Python web service)
   - `seevak-frontend` (Static site)
3. Click **Apply**. Both services will be created.
4. **Set the sync-false env vars** in the Render dashboard:
   - On `seevak-backend`:
     - `DATABASE_URL` →
       `postgresql://postgres.hhofsaggdvflmnfduudt:Iitp988325%21%40%23%24@aws-1-ap-northeast-1.pooler.supabase.com:6543/postgres`
       *(URL-encoded password — please rotate this in Supabase before going live)*
     - `APP_PUBLIC_URL` → the URL Render gives the frontend
       (e.g. `https://seevak-frontend.onrender.com`).
     - `SMTP_USERNAME` → `seevakcare@gmail.com`
     - `SMTP_PASSWORD` → Gmail *App Password* (16 chars, e.g.
       `ibxatpdquxonotbl`, **no spaces**). Obtain a new one here:
       <https://myaccount.google.com/apppasswords>.
   - On `seevak-frontend`:
     - `API_BASE_URL` → the URL Render gives the backend without a trailing slash
       (e.g. `https://seevak-backend.onrender.com`).
5. Trigger one manual deploy on each service to verify the initial
   build works. The backend will auto-create tables and (because of
   `SEED_DEFAULT_USERS=true`) seed the 5 README accounts.

---

## 3. Wire GitHub Actions to Render

For each service in Render → Settings → **Deploy Hooks**, click
**Generate Deploy Hook** and copy the URL.

Then in GitHub → repo → **Settings → Secrets and variables → Actions →
New repository secret**, add:

| Secret name                      | Value                                          |
|----------------------------------|------------------------------------------------|
| `RENDER_BACKEND_DEPLOY_HOOK`     | Deploy hook URL of `seevak-backend`            |
| `RENDER_FRONTEND_DEPLOY_HOOK`    | Deploy hook URL of `seevak-frontend`           |

That's it — every push to `main` now runs CI, and on green CI it
triggers both Render services to redeploy. Manual deploys are also
available from the **Actions** tab → *Deploy to Render* →
**Run workflow**.

---

## 4. Default test accounts (after seed)

| Role          | Email                      | Password    |
|---------------|----------------------------|-------------|
| Admin         | admin@medical.com          | password123 |
| Patient       | testpatient2@medical.com   | password123 |
| Doctor        | testdoctor1@medical.com    | password123 |
| Medical Store | testmedical@store.com      | password123 |
| Lab Store     | pathlab@example.com        | password123 |

---

## 5. What changed vs. the original repo

| File                                    | Why                                                                                                |
|-----------------------------------------|----------------------------------------------------------------------------------------------------|
| `backend/app/__init__.py`               | Generic env-driven CORS that allows `*.onrender.com` + `APP_PUBLIC_URL`; `/api/health` route; first-boot `db.create_all()`, runtime migrations and optional seeding. |
| `backend/app/migrations_runtime.py`     | Idempotent `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` runner invoked on every boot so new columns appear on existing DBs without manual SQL. |
| `backend/app/models/medicine.py`        | `MedicineOrder` gets `prescription_image` (TEXT), `prescription_filename` (VARCHAR), `prescription_uploaded_at` (TIMESTAMP). `to_dict()` exposes `has_prescription`. |
| `backend/app/models/lab.py`             | Same three prescription columns on `LabTestOrder`. |
| `backend/app/routes/patient.py`         | Medicine-order + lab-test-booking endpoints accept optional `prescription_image` (base64 data URL) + `prescription_filename`. New GET endpoints `/api/patient/medicine-orders/<id>/prescription` and `/api/patient/lab-orders/<id>/prescription` return the stored file. 3 MB / JPG/PNG/WEBP/PDF validation server-side. |
| `backend/app/services/notification_service.py` | Real Gmail SMTP sender (uses `SMTP_HOST`, `SMTP_USERNAME`, `SMTP_PASSWORD`). Rebranded copy to "Seevak Care". Falls back to simulated log-only send if SMTP env vars are missing. |
| `frontend/lib/screens/auth/otp_verification_screen.dart` | Registration verification screen — SMS radio removed, now email-only. |
| `frontend/lib/screens/auth/password_reset_otp_screen.dart` | Password reset screen — SMS choice-chip removed, email-only. |
| `backend/seed_default_users.py`         | Idempotent seed for the 5 README accounts. Runs on first boot when `SEED_DEFAULT_USERS=true`.       |
| `backend/requirements.txt`              | Added `psycopg2-binary` for Postgres; uncommented `gunicorn`.                                       |
| `frontend/lib/widgets/prescription_picker.dart` | Reusable "Upload prescription" widget (file_picker + client-side 3 MB / MIME check). |
| `frontend/lib/screens/patient/buy_medicine_screen.dart` | Hosts the `PrescriptionPicker` and forwards the selected file to the home-delivery / selected-store order payloads. |
| `frontend/lib/screens/patient/select_medical_store_screen.dart` | Accepts optional prescription params and attaches them to `POST /api/patient/medicine-orders`. |
| `frontend/lib/screens/patient/lab_test_booking_screen.dart` | Hosts the `PrescriptionPicker` in the booking dialog and forwards the file to `POST /api/patient/lab-tests/book`. |
| `frontend/lib/main.dart`                | `Intl.defaultLocale = 'en_US'` so the app boots on browsers with weird/empty locale.                |
| `frontend/web/index.html`               | `navigator.language` shim covering the same edge case before Dart starts.                           |
| `frontend/render-build.sh`              | Render Static-Site build hook: installs Flutter, builds `web/`, injects the locale shim if missing. |
| `render.yaml`                           | Render Blueprint - both services declared with their build/start commands and env vars.            |
| `.github/workflows/ci.yml`              | Lints + import-checks backend, runs `flutter analyze` + `flutter build web` on every PR.            |
| `.github/workflows/deploy.yml`          | On push to `main`, gates on CI, then hits both Render deploy hooks. Manual run also supported.      |

---

## 6. Heads-up

- 🚨 **Rotate your Supabase database password.** It was shared in plain
  text earlier in our chat. Go to Supabase → Settings → Database →
  Reset password, then update `DATABASE_URL` in Render.
- 🟡 The free Render Python plan **spins down** after 15 min of inactivity
  (cold start ~30 s). For real users, upgrade to Starter ($7/mo).
- 🟡 The free Static Site plan is fine for the Flutter web build.
