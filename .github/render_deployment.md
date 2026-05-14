What you need to do (5 steps, ~10 min)
Push these files to your GitHub repo (Bishal-IITPATNA/MedicalApp) — instructions in _render_deploy/README.md section 1.
Create the Render account, click New → Blueprint, point at the repo. Render auto-detects render.yaml.
Set 3 env vars in the Render dashboard (Render won't auto-fill secrets):
seevak-backend.DATABASE_URL → your Supabase URL
seevak-backend.APP_PUBLIC_URL → https://seevak-frontend.onrender.com
seevak-frontend.API_BASE_URL → https://seevak-backend.onrender.com
Generate Deploy Hooks (Render → each service → Settings → Deploy Hooks).
Add 2 GitHub repository secrets at Settings → Secrets and variables → Actions:
RENDER_BACKEND_DEPLOY_HOOK
RENDER_FRONTEND_DEPLOY_HOOK
