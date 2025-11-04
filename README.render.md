Render deployment notes for CareVibe backend

Follow these steps to deploy the backend on Render. This file documents the config we've added and verification steps.

1) Ensure repository changes are pushed
   - `render.yaml`, `backend/scripts/render_start.sh`, and `backend/package.json` were updated to support Render.

2) Create (or open) the Web Service on Render
   - If Render reads `render.yaml` automatically it will prefill settings. Otherwise configure manually:
     - Environment: Node
     - Branch: main
     - Build Command: `cd backend && npm install`
     - Start Command: `cd backend && npm run start:render`

3) Add required environment variables (Render dashboard → Service → Environment)
   - Secrets (mark as secret):
     - `GCP_SA_JSON` — paste the entire Firebase service-account JSON contents (the JSON file contents, not a path).
     - `MONGO_URI` — MongoDB Atlas connection string
     - `JWT_SECRET` — JWT signing secret
     - `AES_KEY` — AES encryption key
     - `GROQ_API_KEY` — Groq / CMS API key
   - Optional vars:
     - `DEMO_UID` — demo user id
     - `PORT` — 5000 (default used by app)
     - `NODE_ENV` — production

4) Deploy and verify
   - Start a manual deploy or push a trivial commit to the branch.
   - Check logs in Render dashboard. Confirm you see:
     - `Writing GCP service account JSON to /tmp/gcp_sa.json` (from `render_start.sh`)
     - `MongoDB connected` (if `MONGO_URI` is set and connection succeeds)
     - `API listening on http://localhost:5000` (server started)
   - Validate endpoint:
     - `https://<your-service>.onrender.com/health` should return `{ ok: true }`.

5) Security cleanup (recommended)
   - Remove any local copy of the service-account JSON from the repository and add to `.gitignore`:
     ```powershell
     git rm --cached vibecare-f9225-firebase-adminsdk-fbsvc-2444ed399a.json
     echo 'vibecare-f9225-firebase-adminsdk-fbsvc-2444ed399a.json' >> .gitignore
     git add .gitignore
     git commit -m "Stop tracking local GCP JSON and add to .gitignore"
     git push origin main
     ```
   - If the JSON was previously committed, rotate the service-account key in the GCP Console.

6) Troubleshooting tips
   - If `GCP_SA_JSON` doesn't seem to be applied, re-check Render env var value (no wrapping quotes, full JSON pasted).
   - If Mongo connection fails, verify Atlas network access / IP whitelisting.
   - If firebase-admin errors on initialization, inspect logs for JSON parsing or permission errors.

Contact / Next steps
   - I can remove the local JSON file from the repo and add the `.gitignore` entry for you, or I can add extra health/readiness checks. Tell me which and I will make the change.
