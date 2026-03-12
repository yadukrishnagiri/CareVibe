## CareVibe

CareVibe is a **patient engagement & self‑service** app that combines a **Flutter mobile UI** with a **Node.js/Express backend**, **MongoDB** for data, **Firebase Authentication** for login, and **Groq (LLM)** for an AI wellness/chat experience.

It also includes a security workflow: **GitHub CodeQL** scans the backend, and a local toolkit (**FixQL**) can turn **SARIF** results into **AI-generated fix guides** (Markdown) inside `fixprompt/`.

---

## Why these tools (high-level)

- **Flutter**: single codebase for Android (and optionally web), fast UI iteration, good Firebase support.
- **Node.js + Express**: simple REST API, fast iteration, huge ecosystem for auth/security middleware.
- **MongoDB + Mongoose**: flexible schema for health metrics/profile data; easy prototyping and queries.
- **Firebase Auth (client) + Firebase Admin (server)**: secure sign-in (Google / email), server-side token verification.
- **Groq LLM API**: fast model inference for chat responses and security-fix guide generation.
- **CodeQL + SARIF**: industry-standard static security scanning with a portable result format.
- **Render (deployment)**: easy demo hosting for the backend; works well for prototypes.

---

## Architecture (how the pieces connect)

```mermaid
flowchart LR
  A[Flutter App] -->|Google/Firebase sign-in| F[Firebase Auth]
  A -->|POST /auth/firebase (idToken)| B[Node.js / Express API]
  B -->|verifyIdToken| FA[Firebase Admin SDK]
  B --> M[(MongoDB via Mongoose)]
  B -->|/ai/chat| G[Groq LLM API]
  A -->|/api/weather/*| B
  B -->|Weather provider| W[OpenWeather API (key kept local)]
```

Notes:
- The mobile app stores a **backend JWT** (issued by the API) and sends it on protected routes.
- Weather is exposed as **public** endpoints in the backend, while health/profile/chat endpoints require auth.

---

## End-to-end runtime pipeline (user flow)

### Authentication pipeline

- **Frontend**: user signs in with Firebase (Google or email/password).
- **Frontend → Backend**: app sends Firebase `idToken` to `POST /auth/firebase`.
- **Backend**:
  - verifies the Firebase token using `firebase-admin`
  - upserts the user record in MongoDB
  - issues a **backend JWT** (`jsonwebtoken`) used for subsequent API calls

There is also a **demo auth** endpoint (`POST /auth/demo`) intended for presentations and local testing (not production).

### Data + AI pipeline (chat)

- **Frontend**: user asks a question in the chat UI.
- **Backend**:
  - authorizes the request using JWT middleware
  - fetches relevant profile + metrics from MongoDB
  - builds a constrained prompt (policy + templates) and calls **Groq**
  - returns a safe, structured reply (plain-text formatting rules are enforced server-side)

### Health metrics pipeline

- Seed demo metrics: `POST /metrics/seed` (auth required)
- Fetch current user metrics: `GET /metrics/me` (auth required)
- Analyze metrics: `GET /metrics/analyze` (auth required)

### Medication reminders pipeline

- CRUD medication list (auth required)
- “Today reminders” endpoint supports a reminder-style UI
- Frontend uses **local notifications** (`flutter_local_notifications`, `timezone`) to alert the user on-device

### Weather pipeline

- Backend exposes public routes:
  - `GET /api/weather/city`
  - `GET /api/weather/coordinates`
- Frontend keeps the weather provider key **out of Git** using `weather_service.template.dart` → local `weather_service.dart` (ignored by `.gitignore`).

---

## Security pipeline (CodeQL → FixQL → Fix guides)

### 1) GitHub Actions CodeQL scanning (CI)

This repo includes a workflow at `.github/workflows/codeql.yml` that:
- installs backend dependencies
- runs **CodeQL** on **JavaScript** (backend)
- uploads security results to GitHub Security tab

CodeQL config lives in `.github/codeql/codeql-config.yml` and is scoped to:
- include: `backend/`
- ignore: `frontend/`

### 2) Local “FixQL” toolkit (turn findings into Markdown guides)

Folder: `backend/fixql/`

What it does:
- runs **CodeQL CLI** locally to generate a SARIF report
- reads SARIF findings
- calls **Groq** to generate an **actionable fix guide** per issue
- writes the results as Markdown into `fixprompt/<name>-prompts/`

Command:

```bash
node backend/fixql/run-codeql.js --name demo
```

Outputs:
- database folder: `demo-db/`
- SARIF file: `demo.sarif`
- fix guides: `fixprompt/demo-prompts/*.md`

Why this exists:
- CodeQL findings can be hard to apply quickly.
- FixQL accelerates learning by generating “explain + fix + test plan” documents from real findings.

---

## APIs (backend)

Backend entrypoint: `backend/src/server.js`

### Public

- `GET /health`
- `GET /doctors`
- `GET /api/weather/city`
- `GET /api/weather/coordinates`

### Auth

- `POST /auth/firebase` → verify Firebase token, returns backend JWT
- `POST /auth/demo` → demo-only JWT issuance

### Protected (JWT required)

- `POST /ai/chat`
- `GET /appointments/:userId`
- `GET /metrics/me`
- `POST /metrics/seed`
- `GET /metrics/analyze`
- `GET /medications/me`
- `GET /medications/me/today`
- `POST /medications`
- `DELETE /medications/:id`
- `GET/PUT /profile/me`
- profile export/search/template routes under `/profile/*`

---

## Libraries and tools (and why)

### Backend (`backend/package.json`)

- **express**: REST routing + middleware model
- **mongoose**: MongoDB ODM for schema + validation + query ergonomics
- **firebase-admin**: verify Firebase `idToken` on the server
- **jsonwebtoken**: issue/verify backend JWTs for API authorization
- **helmet**: safer HTTP headers (baseline hardening)
- **cors**: allow frontend to call backend across origins during development
- **express-rate-limit**: basic abuse protection for public endpoints
- **morgan**: request logging for debugging
- **dotenv**: local env variable loading (`backend/.env`)
- **axios**: HTTP client for calling Groq/weather/other APIs
- **groq-sdk**: Groq client (used by FixQL; backend chat can also use Groq)
- **chrono-node**: natural language date parsing (useful for “last week”, “a month ago” queries)
- **nodemon (dev)**: hot-reload during backend development

### Frontend (`frontend/pubspec.yaml`)

- **firebase_core / firebase_auth / google_sign_in**: auth + Google sign-in flow
- **http**: REST API calls to the backend
- **provider**: state management (session, profile, theme, shell navigation)
- **google_fonts**: consistent, modern typography
- **fl_chart**: charts for analytics dashboard
- **flutter_animate**: UI motion polish for a better UX
- **geolocator**: location for nearby doctors/places and weather-by-coordinates
- **shared_preferences**: light local storage (tokens, user settings)
- **pdf / printing / share_plus / path_provider**: export/share user info (reports, profile exports)
- **flutter_local_notifications / timezone**: medication reminder notifications reliably across timezones

### Dev / Platform tools

- **Flutter SDK + Android Studio**: build and run the app on emulator/device
- **Firebase CLI + FlutterFire CLI**: configure Firebase apps + generate `firebase_options.dart` (this file is ignored by Git for safety)
- **MongoDB Community Server or MongoDB Atlas**: local DB or cloud DB for demos
- **Render**: quick backend hosting for demos (free tier sleeps on inactivity)

---

## Repo structure (what goes where)

- `backend/`: Node.js/Express API + MongoDB models + controllers + scripts
  - `src/server.js`: API entrypoint
  - `src/routes/`: route definitions
  - `src/controllers/`: request handlers (chat, profile, health, meds, etc.)
  - `src/models/`: Mongoose models
  - `src/middleware/`: JWT auth middleware
  - `scripts/`: connection tests and utility scripts
  - `fixql/`: CodeQL automation + SARIF → fix-guide generator
- `frontend/`: Flutter application
  - `lib/main.dart`: app entrypoint
  - `lib/screens/`, `lib/widgets/`: UI
  - `lib/services/`: backend API clients + weather service template
  - `lib/providers/`: Provider-based app state
- `fixprompt/`: generated fix guides (usually ignored to keep the repo clean; sample demos may be kept)
- `.github/`: CodeQL configuration + workflow

---

## Configuration & secrets (important)

Backend environment variables live in `backend/.env` (ignored by Git). Template: `backend/env.example`.

Typical variables:
- `MONGO_URI`: MongoDB connection string
- `JWT_SECRET`: JWT signing secret
- `GROQ_API_KEY`: Groq key for AI features and FixQL
- `GOOGLE_APPLICATION_CREDENTIALS`: path to Firebase Admin SDK JSON key
- `PORT`: backend port (default 5000)

Frontend secrets:
- `frontend/android/app/google-services.json` is **not committed**
- `frontend/lib/firebase_options.dart` is **not committed**
- Weather key is stored only in local `frontend/lib/services/weather_service.dart` (not committed)

These are enforced by `.gitignore` to reduce the chance of leaking credentials.

---

## How to run (local dev)

### Backend

```bash
cd backend
npm install
copy env.example .env   # Windows
# then edit backend/.env values
npm run dev
```

Health check: `http://localhost:5000/health`

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

API base behavior is defined in `frontend/lib/services/api.dart`:
- Web debug uses `http://localhost:5000`
- Mobile defaults to the deployed Render backend
- You can override with `--dart-define=API_BASE=...`

Example (Android emulator → local backend):

```bash
flutter run --dart-define=API_BASE=http://10.0.2.2:5000
```

---

## Extra docs (already in the repo)

- Backend setup: `backend/README.md`
- Frontend setup: `frontend/README.md`
- FixQL guide: `backend/fixql/README.md` and `backend/fixql/SETUP_GUIDE.md`
- Weather setup: `frontend/lib/services/WEATHER_SETUP.md`
