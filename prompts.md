# CareVibe — Sample Prompts

This file contains the actual prompts you'd use (or that were used) to build and ship CareVibe from scratch using AI assistance. Organized by phase.

---

## Phase 1 — Project Discovery & Planning

**Q: I'm building a patient engagement app called CareVibe. It has a Flutter frontend and a Node.js backend, with Firebase Auth, MongoDB, and a Groq-powered AI health assistant. Walk me through what I need to set up before writing any code.**

**Q: What's the best free hosting for a Node.js backend that supports WebSockets and environment variables, given I want zero monthly cost during demo?**

**Q: Should I use MongoDB Atlas or Firebase Firestore? My backend is already Express + Mongoose and I just need a flexible document store.**

---

## Phase 2 — Firebase Setup

**Q: How do I create a Firebase project, enable Google sign-in, and get the API keys? Give me exact steps for the web console.**

**Q: My Flutter app shows `firebase_auth/api-key-not-valid` when I tap "Sign in with Google". What's wrong?**
→ *Answer: `firebase_options.dart` was using placeholder `mock-api-key-replace-if-real-auth-needed` values. Replace with real keys from Firebase Console → Project Settings → General → Your apps.*

**Q: flutterfire CLI throws `FlutterAppRequiredException` even though `pubspec.yaml` exists. How do I bypass it?**
→ *Answer: skip flutterfire and write `firebase_options.dart` manually using `firebase apps:sdkconfig web --project <id>` and `firebase apps:sdkconfig android --project <id>`.*

**Q: I'm getting `PlatformException(sign_in_failed, com.google.android.gms.common.api.b: 10)` on the APK. How do I fix it?**
→ *Answer: SHA-1 fingerprint mismatch. Run `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` to get your SHA-1, then add it in Firebase Console → Project Settings → Android app → Add fingerprint.*

---

## Phase 3 — MongoDB Atlas Setup

**Q: Walk me through creating a free MongoDB Atlas cluster and getting the connection string for my Node.js backend.**

**Q: My Render deploy logs show `querySrv ENOTFOUND _mongodb._tcp.carevibe.josksix.mongodb.net`. The hostname matches Atlas. Why is it failing?**
→ *Answer: The cluster's DNS records weren't propagating publicly. Solution: delete the cluster, recreate it as a new M0, use the new non-SRV connection string format (`mongodb://user:pass@host1:27017,host2:27017,host3:27017/db?ssl=true&replicaSet=...`).*

**Q: My Atlas cluster is "Active" in the dashboard but `nslookup` returns NXDOMAIN globally. Is the cluster broken?**
→ *Answer: Yes — Atlas sometimes creates a cluster whose DNS records never propagate. Delete and recreate. After recreating, verify with `nslookup -type=SRV _mongodb._tcp.<newname>.<newsuffix>.mongodb.net 8.8.8.8` — it must return 3 shard hostnames.*

**Q: Render can't connect to my MongoDB Atlas cluster even though I added `0.0.0.0/0` to the IP Access List. Why?**
→ *Answer: Verify both that `0.0.0.0/0` exists in **Network Access** AND the database user has the right password. Also switch to non-SRV connection string since some Render regions block SRV DNS.*

---

## Phase 4 — Groq AI Setup

**Q: How do I get a Groq API key for free and what model should I use for a healthcare chatbot?**

**Q: My backend's Groq call returns 401 Unauthorized. Where does the API key go?**
→ *Answer: Set `GROQ_API_KEY` in Render's Environment Variables tab. Make sure the value is just the key starting with `gsk_...` with no quotes or extra spaces.*

**Q: The Groq integration works locally but fails in production with "Invalid API Key". What's different?**
→ *Answer: Local `.env` file is being read by dotenv but on Render, dotenv sees no file. Confirm the env var is set in Render dashboard (not just `.env.example`).*

---

## Phase 5 — Backend Deployment (Render)

**Q: My repo has a `backend/` folder and a `frontend/` folder. How do I deploy only the backend to Render as a monorepo?**
→ *Answer: Set **Root Directory** to `backend` in Render service settings. Build command: `npm install`. Start command: `npm run start`.*

**Q: How do I upload `firebase-admin-key.json` as a secret file on Render?**
→ *Answer: Render dashboard → service → **Files** → **Secret Files** → add the file with contents pasted. Reference it in env vars as `GOOGLE_APPLICATION_CREDENTIALS=/etc/secrets/firebase-admin-key.json`.*

**Q: Create a `render.yaml` Blueprint for my backend so Render auto-configures from the repo.**
→ *Answer: see `render.yaml` in this repo — uses `rootDir: backend`, env vars, and references the secret file path.*

**Q: My Render service exits with status 1 right after `npm run start`. How do I read the actual error?**
→ *Answer: Render dashboard → service → **Logs** tab. Look for the last lines before "Exited with status 1". Most common: MongoDB connection failure, missing env var, or port binding issue.*

---

## Phase 6 — Flutter APK Build

**Q: How do I build a release APK for my Flutter app to install on my personal phone?**
→ *Answer: `flutter build apk --release`. Output lands at `build/app/outputs/flutter-apk/app-release.apk`.*

**Q: `flutter build apk --release` fails with `No Android SDK found`. How do I install the SDK?**
→ *Answer: Install Android Studio (Standard setup installs SDK + cmdline-tools). Then `flutter doctor --android-licenses` and accept all.*

**Q: Gradle build fails with `IllegalArgumentException: 25.0.2`. My Java is too new.**
→ *Answer: AGP 8.x doesn't support Java 25. Install Java 17 via `winget install --id Microsoft.OpenJDK.17 -e --source winget`, then `flutter config --jdk-dir "C:\Program Files\Microsoft\jdk-17.0.20.8-hotspot"`.*

**Q: Build fails with `geolocator_android does not specify compileSdk`. How do I fix legacy plugin issues?**
→ *Answer: Edit `~/.pub-cache/hosted/pub.dev/geolocator_android-4.6.2/android/build.gradle`, replace `compileSdk flutter.compileSdkVersion` with `compileSdk 34`, and replace `minSdkVersion flutter.minSdkVersion` with `minSdkVersion 23`.*

**Q: Build fails asking for `minSdkVersion 23`. Where do I set it?**
→ *Answer: In `android/app/build.gradle.kts`, set `minSdk = 23` in `defaultConfig`.*

---

## Phase 7 — UI Design

**Q: Redesign my dashboard's "Today vs Yesterday" section to look like a premium medical app — single cohesive panel, vertical metric rows, green for positive change, red for negative. Keep the dark navy theme.**

**Q: What's the color code for a polished dark navy health-app background?**
→ *Answer: Page bg `0xFF0F172A`, surface `0xFF111827`, primary blue `0xFF3A7AFE`, success green `0xFF10B981`, danger red `0xFFEF4444`.*

**Q: How do I add a legend (Today vs Yesterday) with colored dots in Flutter?**
→ *Answer: Use `Row` of two `Container` + `Text` widgets, with 8px circles and 12px muted text.*

---

## Phase 8 — Pointing App at Live Backend

**Q: My Flutter app hardcodes `http://localhost:5000`. How do I make it use my Render backend in production?**
→ *Answer: In `lib/services/api.dart`, return `https://carevibe-backend.onrender.com` for release builds. Or use `String.fromEnvironment('API_BASE')` with `--dart-define=API_BASE=https://...`.*

---

## Phase 9 — First Install & Test

**Q: I installed the APK on my phone but Google login fails. Checklist?**
→ *Answer: 1) Firebase Console has SHA-1 added for debug keystore, 2) Google sign-in provider enabled in Firebase Auth, 3) `google-services.json` matches your Firebase project, 4) uninstall & reinstall APK to clear cached tokens.*

**Q: My app works on web but not on Android. Backend logs show no requests. Why?**
→ *Answer: Android requires cleartext HTTP disabled by default. Either use HTTPS (Render gives HTTPS by default) or add `android:usesCleartextTraffic="true"` to AndroidManifest.xml.*

---

## General Debugging Prompts

**Q: I'm getting this Flutter error: `[paste error]`. What's the fix?**

**Q: My Node.js backend crashes on startup. Here's the stack trace: `[paste]`. What's missing?**

**Q: The Render deploy succeeded but the service returns 404 on `/`. How do I make my Express app respond?**
→ *Answer: Add an `app.get('/', ...)` or `app.get('/health', ...)` route. Render's health check needs `/healthz` or whichever path you configured.*

**Q: How do I check if my backend is actually reachable from the internet?**
→ *Answer: `curl https://your-app.onrender.com/health` — should return JSON. Or visit the URL in a browser.*
