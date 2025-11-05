# CareVibe — Patient Engagement & AI Health Assistant

A modern healthcare demo built with Flutter (Android/Web) and Node.js, featuring an AI assistant, professional day-focused dashboard, analytics with exports, and cloud-first connectivity.

---

## 📋 Table of Contents

1. [What is CareVibe?](#what-is-carevibe)
2. [What You Need Before Starting](#what-you-need-before-starting)
3. [Step-by-Step Setup Guide](#step-by-step-setup-guide)
4. [Running the Application](#running-the-application)
5. [Troubleshooting](#troubleshooting)
6. [Project Structure](#project-structure)

---

## 🎯 What is CareVibe?

CareVibe is a demo application that allows patients to:
- Sign in securely using Google or Email/Password (Firebase Authentication)
- Chat with an AI health assistant powered by Groq AI
- Browse a list of nearby doctors
- View their appointments dashboard
- Access health insights and tips

**Technologies Used:**
- **Frontend:** Flutter (Android & Web)
- **Backend:** Node.js with Express.js
- **Database:** MongoDB
- **Authentication:** Firebase
- **AI Chat:** Groq API

---

## ✨ Key Features

- AI Assistant (Groq) with natural-language date parsing, intent detection, and adaptive, plain‑text responses
- Shared demo data via `DEMO_UID` so every login sees the same dataset (or point to your own Atlas data)
- Demo authentication bypass (`POST /auth/demo`) for quick testing without Firebase
- Day-focused Home: Health Score, contextual weather tips, medication reminders, and Today vs Yesterday comparisons
- Analytics with date range picker, reset, and PDF/CSV export (includes AI summary)
- Cloud-first API base for devices/emulators; web debug uses localhost automatically
- Startup connection checks (MongoDB, Groq, Firebase) logged on backend boot

## 🏗️ Architecture

- Flutter app → REST API (JWT)
- Backend verifies Firebase tokens (or demo auth), queries MongoDB Atlas
- AI pipeline uses templates + policy to ensure accurate numbers and concise tone
- API base selection in `frontend/lib/services/api.dart`:
  - Web (debug): `http://localhost:5000`
  - Non-web (devices/emulators): `https://carevibe-backend.onrender.com` (override with `--dart-define=API_BASE=`)

---

## 📦 What You Need Before Starting

### Required Software (Install These First!)

1. **Node.js** (version 18 or higher)
   - Download from: https://nodejs.org/
   - Install the LTS version
   - Verify installation: Open PowerShell/Command Prompt and type `node --version`

2. **MongoDB Community Server**
   - Download from: https://www.mongodb.com/try/download/community
   - Install it and make sure MongoDB service is running
   - **Windows:** MongoDB usually runs automatically as a Windows service. Verify by opening Services (`services.msc`) and checking if "MongoDB" is running.

3. **Flutter SDK**
   - Download from: https://docs.flutter.dev/get-started/install/windows
   - Extract and add Flutter to your PATH environment variable
   - Verify installation: Open PowerShell and type `flutter doctor`

4. **Android Studio** (for Android development)
   - Download from: https://developer.android.com/studio
   - Install Android SDK, Android SDK Platform-Tools, and Android Emulator
   - Or use Chrome for web development (simpler for beginners)

5. **Git** (to clone/download the project)
   - Download from: https://git-scm.com/download/win

6. **Firebase CLI** (for Firebase setup)
   - After installing Node.js, open PowerShell and run:
     ```
     npm install -g firebase-tools
     ```

7. **FlutterFire CLI** (for Firebase configuration)
   - After installing Node.js, open PowerShell and run:
     ```
     dart pub global activate flutterfire_cli
     ```

8. **A Code Editor** (Visual Studio Code recommended)
   - Download from: https://code.visualstudio.com/

### Required Accounts & API Keys

1. **Firebase Account** (Free)
   - Go to: https://console.firebase.google.com/
   - Create a new project
   - Enable Authentication (Google Sign-in + Email/Password)
   - Create an Android app (package name: `com.carevibe.patient`)
   - Download `google-services.json` (you'll need this later)
   - Go to Project Settings → Service Accounts → Generate New Private Key
   - Download the Firebase Admin SDK JSON file (you'll need this later)

2. **Groq API Key** (Free)
   - Go to: https://console.groq.com/
   - Sign up for a free account
   - Go to API Keys section
   - Create a new API key
   - Copy the key (you'll need this later)

3. **MongoDB** (Local installation is fine, or use MongoDB Atlas free tier)
   - If using local MongoDB, make sure it's running on `mongodb://127.0.0.1:27017`

---

## 🚀 Step-by-Step Setup Guide

> **Note:** Follow these steps EXACTLY in order. Don't skip any step!

### Step 1: Download/Clone the Project

If you have Git installed:
```powershell
git clone <your-repository-url>
cd CareVibe
```

Or download the ZIP file and extract it to a folder called `CareVibe`.

---

### Step 2: Set Up MongoDB

**For Windows:**
1. Open Services (`Win + R`, type `services.msc`, press Enter)
2. Look for "MongoDB" service
3. If it's not running, right-click → Start
4. If MongoDB is not installed, download and install from: https://www.mongodb.com/try/download/community

**Verify MongoDB is running:**
- Open PowerShell and run: `mongosh` (or `mongo` if using older version)
- If you see a MongoDB prompt, you're good! Type `exit` to leave.

---

### Step 3: Set Up Firebase

#### 3.1 Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. Enter project name: `CareVibe` (or any name)
4. Continue and finish the setup

#### 3.2 Enable Authentication
1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable **Google** sign-in provider
3. Enable **Email/Password** sign-in provider
4. Save both changes

#### 3.3 Create Android App in Firebase
1. In Firebase Console, click the Android icon (or "Add app" → Android)
2. Package name: `com.carevibe.patient`
3. App nickname: `CareVibe Patient`
4. Click "Register app"
5. **Download `google-services.json`** — Save this file!

#### 3.4 Add SHA Fingerprints (For Android)
1. Open PowerShell and navigate to your project:
   ```powershell
   cd C:\Users\yaduk\OneDrive\Documents\GitHub\CareVibe\frontend\android
   ```
2. Run:
   ```powershell
   .\gradlew signingReport
   ```
3. Copy the **SHA-1** and **SHA-256** fingerprints (they look like: `C9:E9:64:79:7A:67:...`)
4. Go back to Firebase Console → Your Android App → App Settings
5. Scroll to "SHA certificate fingerprints"
6. Click "Add fingerprint" and paste both SHA-1 and SHA-256
7. **Re-download `google-services.json`** and replace the old one

#### 3.5 Get Firebase Admin SDK Key
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Go to **Service Accounts** tab
3. Click **Generate New Private Key**
4. Click "Generate key" — a JSON file will download
5. Save this file somewhere safe (e.g., `C:\CareVibe\firebase-admin-key.json`)
6. **Remember this path!** You'll need it in Step 4.

---

### Step 4: Set Up Backend (Node.js)

#### 4.1 Install Backend Dependencies
1. Open PowerShell and navigate to the backend folder:
   ```powershell
   cd C:\Users\yaduk\OneDrive\Documents\GitHub\CareVibe\backend
   ```
2. Install all required packages:
   ```powershell
   npm install
   ```
   This will take a few minutes. Wait for it to finish.

#### 4.2 Create Backend Environment File
1. In the `backend` folder, you should see a file called `env.example`
2. Copy this file and rename it to `.env` (yes, starting with a dot!)
   - **Windows:** You can do this in PowerShell:
     ```powershell
     copy env.example .env
     ```
3. Open `.env` file with Notepad or VS Code
4. Fill in the values (replace the placeholders):

   ```
   MONGO_URI=mongodb://127.0.0.1:27017/patient_ai_demo
   JWT_SECRET=your_super_secret_jwt_key_change_this_to_something_random
   AES_KEY=32characterslongsecretkey!!
   GROQ_API_KEY=your_groq_api_key_here
   GOOGLE_APPLICATION_CREDENTIALS=C:\CareVibe\firebase-admin-key.json
   PORT=5000
   ```

   **Important Notes:**
   - Replace `your_groq_api_key_here` with your actual Groq API key
   - Replace `C:\CareVibe\firebase-admin-key.json` with the actual path where you saved your Firebase Admin SDK JSON file
   - Replace `your_super_secret_jwt_key_change_this_to_something_random` with any random string (like `mySecretKey123!@#`)
   - For `AES_KEY`, use exactly 32 characters (e.g., `12345678901234567890123456789012`)
   - For cloud deployment, set `MONGO_URI` to your MongoDB Atlas connection string (Step 7)

5. Save the `.env` file

#### 4.3 Test Backend Connection
1. Start the backend server:
   ```powershell
   npm run dev
   ```
2. You should see: `API up` or `Server running on port 5000`
3. Open a browser and go to: http://localhost:5000/health
4. You should see: `{"ok":true}`
5. **Keep this PowerShell window open!** The backend must keep running.

#### 4.4 Test Groq API Connection (Optional but Recommended)
1. Open a **NEW** PowerShell window
2. Navigate to backend folder:
   ```powershell
   cd C:\Users\yaduk\OneDrive\Documents\GitHub\CareVibe\backend
   ```
3. Run:
   ```powershell
   npm run test:groq
   ```
4. If you see "✅ Groq API responded successfully", you're good!
5. If you see an error, check your `GROQ_API_KEY` in the `.env` file

---

### Step 5: Set Up Frontend (Flutter)

#### 5.1 Install Flutter Dependencies
1. Open a **NEW** PowerShell window (keep backend running!)
2. Navigate to the frontend folder:
   ```powershell
   cd C:\Users\yaduk\OneDrive\Documents\GitHub\CareVibe\frontend
   ```
3. Install Flutter packages:
   ```powershell
   flutter pub get
   ```
   Wait for it to finish.

#### 5.2 Add Firebase Configuration File
1. Copy the `google-services.json` file you downloaded from Firebase
2. Paste it into: `frontend\android\app\google-services.json`
3. Make sure the file path is exactly: `frontend\android\app\google-services.json`

#### 5.3 Configure Firebase for Flutter (Web Support)
1. Make sure you have FlutterFire CLI installed:
   ```powershell
   dart pub global activate flutterfire_cli
   ```
2. Add FlutterFire CLI to PATH (for current session):
   ```powershell
   $env:PATH += ";$env:LocalAppData\Pub\Cache\bin"
   ```
3. From the `frontend` folder, run:
   ```powershell
   flutterfire configure
   ```
4. Follow the prompts:
   - Select your Firebase project
   - Select platforms: `android`, `web`
   - This will generate `lib/firebase_options.dart` automatically

#### 5.4 Verify Flutter Setup
1. Run Flutter doctor to check everything:
   ```powershell
   flutter doctor
   ```
2. Fix any issues it reports (usually related to Android SDK or licenses)

---

### Step 6: Run the Application

#### Option A: Run on Web (Easier for Beginners)

1. **Make sure backend is running** (Step 4.3)
2. Open PowerShell in the `frontend` folder:
   ```powershell
   cd C:\Users\yaduk\OneDrive\Documents\GitHub\CareVibe\frontend
   ```
3. Run the Flutter web app:
   ```powershell
   flutter run -d chrome
   ```
4. Wait for the app to compile and open in Chrome
5. Sign in with Google or Email/Password
6. Start using the app!

#### Option B: Run on Android Emulator

1. **Start Android Emulator:**
   - Open Android Studio
   - Go to Tools → Device Manager
   - Click "Create Device" if you don't have one
   - Start an emulator (API 30 or higher recommended)

2. **Make sure backend is running** (Step 4.3)

3. **Run Flutter app:**
   ```powershell
   cd C:\Users\yaduk\OneDrive\Documents\GitHub\CareVibe\frontend
   flutter run
   ```
   Or specify device:
   ```powershell
   flutter run -d <device-id>
   ```
   (Find device ID with: `flutter devices`)

---

### Step 7: Deploy to the Cloud & Build the APK

Want the app to run on a real phone without your laptop on? Deploy the backend to Render (free tier) and point the Flutter app to that URL.

#### 7.1 Deploy backend to Render.com
1. Sign up at [render.com](https://render.com) with your GitHub account.
2. Click **New → Web Service** and choose the `yadukrishnagiri/CareVibe` repository.
3. Use these settings:
   - **Root Directory:** `backend`
   - **Build Command:** `npm install`
   - **Start Command:** `npm run start`
   - **Instance Type:** Free
4. In the **Environment** section add your secrets:
   - `MONGO_URI` → Atlas connection string (with password encoded, e.g. `%40` for `@`)
   - `JWT_SECRET`, `AES_KEY`, `GROQ_API_KEY`
   - `GOOGLE_APPLICATION_CREDENTIALS` → `/etc/secrets/firebase-admin-key.json`
5. In **Secret Files**, create `firebase-admin-key.json` and paste your Firebase Admin SDK JSON.
6. Click **Deploy web service**.

#### 7.2 Whitelist Render in MongoDB Atlas
1. In MongoDB Atlas go to **Security → Network Access**.
2. Add IP `0.0.0.0/0` (allow all) or the specific Render IPs.
3. Wait until the status shows **Active** and redeploy if needed.

#### 7.3 Update Flutter to use the cloud API
1. Open `frontend/lib/services/api.dart`.
2. Replace the `apiBase` value with your Render URL, e.g.
   ```dart
   const String apiBase = 'https://carevibe-backend.onrender.com';
   ```
3. (Optional) commit and push the change to GitHub so future deploys use it.

#### 7.4 Build the release APK
1. In PowerShell:
   ```powershell
   cd C:\Users\yaduk\OneDrive\Documents\GitHub\CareVibe\frontend
   flutter clean
   flutter pub get
   flutter build apk --release
   ```
2. APK output: `frontend\build\app\outputs\flutter-apk\app-release.apk`

#### 7.5 Install on a real device
- Copy the APK to your phone and open it, or run:
  ```powershell
  adb install frontend\build\app\outputs\flutter-apk\app-release.apk
  ```
- Sign in with Google, open AI chat, doctors, dashboard — everything now uses the Render backend.

---

## 🔑 Environment Variables

Backend `.env` (use `backend/env.example` as a template):

```
MONGO_URI=mongodb+srv://<user>:<pass>@cluster..../patient_ai_demo
DEMO_UID=demo-shared
JWT_SECRET=<random-strong-string>
AES_KEY=<32-characters>
GROQ_API_KEY=<your-groq-api-key>
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}  # preferred in cloud
# or
GOOGLE_APPLICATION_CREDENTIALS=/etc/secrets/firebase-admin-key.json
PORT=5000
```

Frontend API base is auto-selected in `frontend/lib/services/api.dart` (see Architecture above).

---

## 🔧 Troubleshooting

### Backend Issues

**Problem:** `Cannot find module` error
- **Solution:** Run `npm install` in the `backend` folder

**Problem:** `MongoDB connection failed`
- **Solution:** Make sure MongoDB service is running (check Services)

**Problem:** `Firebase verification failed`
- **Solution:** Check `GOOGLE_APPLICATION_CREDENTIALS` path in `.env` file. Make sure the file exists and path is correct.

**Problem:** `GROQ_API_KEY` error
- **Solution:** Check your `.env` file. Make sure `GROQ_API_KEY` has a value (no spaces around the `=` sign)

**Problem:** Port 5000 already in use
- **Solution:** Change `PORT=5000` to `PORT=5001` in `.env` file, then update `frontend/lib/services/api.dart` to use port 5001

### Frontend Issues

**Problem:** `google-services.json` not found
- **Solution:** Make sure the file is at `frontend\android\app\google-services.json`

**Problem:** Flutter build fails
- **Solution:** Run `flutter clean` then `flutter pub get`

**Problem:** Firebase authentication doesn't work
- **Solution:** 
  - Verify `google-services.json` is in the correct location
  - Check SHA fingerprints are added in Firebase Console
  - Re-download `google-services.json` after adding fingerprints

**Problem:** Can't connect to backend API
- **Solution:** 
  - If running locally: start the backend with `npm run dev`
  - For web (local): backend should be accessible at `http://localhost:5000`
  - For Android emulator (local): backend should be accessible at `http://10.0.2.2:5000`
  - For Render deployment: open `https://<your-service>.onrender.com/health` and confirm `{"ok":true}`
  - Ensure `frontend/lib/services/api.dart` points to the same URL you just verified

**Problem:** AI chat shows "AI service unavailable"
- **Solution:** 
  - Check your `GROQ_API_KEY` in backend `.env` file
  - Run `npm run test:groq` in backend folder to test Groq connection
  - Check backend console logs for detailed error messages

### General Issues

**Problem:** PowerShell commands not recognized
- **Solution:** Make sure you're using PowerShell (not CMD). Some commands require PowerShell.

**Problem:** Flutter doctor shows issues
- **Solution:** Follow the instructions `flutter doctor` provides. Usually involves:
  - Accepting Android licenses: `flutter doctor --android-licenses`
  - Installing missing SDK components in Android Studio

---

## 📁 Project Structure

```
CareVibe/
├── backend/                 # Node.js backend API
│   ├── src/
│   │   ├── controllers/    # Request handlers
│   │   ├── models/         # Database models
│   │   ├── routes/         # API routes
│   │   ├── middleware/     # Auth middleware
│   │   └── server.js       # Main server file
│   ├── scripts/            # Utility scripts (Groq/Mongo tests, validators)
│   ├── env.example         # Environment template
│   ├── package.json        # Node.js dependencies
│   └── README.md           # Backend-specific docs
│
├── frontend/               # Flutter app
│   ├── lib/
│   │   ├── screens/       # Login, Home, AI Assistant, Dashboard, Analytics, Doctors
│   │   ├── widgets/       # Reusable UI components
│   │   ├── providers/     # Auth/session/theme
│   │   ├── services/      # API client, metrics, medications
│   │   └── main.dart      # App entry point
│   ├── android/app/google-services.json  # Firebase config (add this)
│   ├── pubspec.yaml       # Flutter dependencies
│   └── README.md          # Frontend-specific docs
│
├── docs/                  # Dev docs (design, cloud, stories)
│   ├── DEMO_SETUP.md
│   ├── PROJECT_STORY.md
│   ├── CHAT_IMPROVEMENTS_SUMMARY.md
│   └── cloud_dotty.md
│
├── project_document/
│   └── PROJECT_DOCUMENTATION.md  # Formal, end-to-end documentation
│
├── REQUIREMENTS.txt
├── README.md
└── .gitignore
```

---

## 🔒 Security & Code Quality

- Code scanning with GitHub CodeQL is enabled for the Node backend. It runs on pushes/PRs to `main` and weekly.
- Workflow: `.github/workflows/codeql.yml` (scopes analysis to `backend/` via `./.github/codeql/codeql-config.yml`).
- View results: GitHub → Security → Code scanning alerts.

## 🗂️ Documentation Folder (ignored by Git)

- The `docs/` folder is ignored by Git to keep the repository lean for app code.
- If docs were previously committed, untrack them (files stay locally):
  ```powershell
  git rm -r --cached docs
  git commit -m "chore: stop tracking docs/"
  git push
  ```
- Want to keep specific files tracked? Remove `docs/` from `.gitignore` and add explicit ignores (e.g., `docs/*.md` except one file), or add a `.gitignore` inside `docs/` to fine-tune.

---

## ✅ Quick Checklist

Before running the app, make sure:

- [ ] Node.js is installed (`node --version` works)
- [ ] MongoDB is installed and running
- [ ] Flutter is installed (`flutter doctor` shows mostly green checkmarks)
- [ ] Firebase project created with Authentication enabled
- [ ] `google-services.json` downloaded and placed in `frontend/android/app/`
- [ ] Firebase Admin SDK JSON downloaded
- [ ] Groq API key obtained
- [ ] Backend `.env` file created with all values filled
- [ ] Backend dependencies installed (`npm install` in backend folder)
- [ ] Frontend dependencies installed (`flutter pub get` in frontend folder)
- [ ] Backend server running locally (`npm run dev`) **or** Render deployment responding at `/health`
- [ ] `frontend/lib/services/api.dart` points to the correct backend URL (local or Render)
- [ ] Frontend app running (`flutter run`) *(for local testing)*
- [ ] Release APK built (`flutter build apk --release`) and installed on device *(for mobile demo)*

---

## 📚 Documentation References

- `docs/DEMO_SETUP.md` — Shared demo data, Atlas integration, and testing
- `docs/PROJECT_STORY.md` — Development journey and key milestones
- `docs/CHAT_IMPROVEMENTS_SUMMARY.md` — AI upgrades (intents, dates, policy)
- `docs/cloud_dotty.md` — Cloud behaviors and redeploy notes
- `project_document/PROJECT_DOCUMENTATION.md` — Formal, end-to-end documentation

---

## 🆘 Need Help?

If you're stuck:
1. Check Troubleshooting above
2. Inspect backend logs (look for connection status lines)
3. Verify environment variables in Render or `.env`
4. Confirm Atlas Network Access is active
5. Ensure Flutter and Android SDK setups are complete (`flutter doctor`)

---

**Happy Coding! 🚀**

CareVibe is demo-ready and cloud-first: quick onboarding, consistent data, and an AI assistant that understands your metrics.
