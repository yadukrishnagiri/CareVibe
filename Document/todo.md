# CareVibe — TODO List

## ✅ Done

- [x] Project scaffolding (Flutter + Node.js)
- [x] Firebase project created (`vibecare-f9225`)
- [x] Firebase Auth enabled (Google + Email)
- [x] `google-services.json` in `frontend/android/app/`
- [x] Real Firebase keys in `frontend/lib/firebase_options.dart`
- [x] Debug keystore SHA-1 added to Firebase Console
- [x] MongoDB Atlas free cluster created (`carevibe`)
- [x] Atlas network access: `0.0.0.0/0`
- [x] Backend deployed to Render (`carevibe-backend.onrender.com`)
- [x] Backend env vars set (MONGO_URI, JWT_SECRET, AES_KEY, GROQ_API_KEY)
- [x] Firebase Admin SDK uploaded as Render secret file
- [x] Backend health check: `GET /health` → 200 OK
- [x] Java 17 installed (Microsoft OpenJDK)
- [x] Android SDK + cmdline-tools installed
- [x] Android licenses accepted
- [x] Java 17 configured for Flutter (`flutter config --jdk-dir`)
- [x] `geolocator_android` plugin patched (`compileSdk 34`, `minSdkVersion 23`)
- [x] `android/app/build.gradle.kts`: `minSdk = 23`
- [x] Release APK built (`app-release.apk`, 55.7 MB)
- [x] App points to live Render backend in `lib/services/api.dart`
- [x] "Today vs Yesterday" redesigned (cohesive panel)

## 🔥 Urgent / Blockers

- [x] Test APK on phone with Google login → verify it actually works end-to-end
- [x] If login still fails after SHA-1 fix → check Firebase Auth Google provider is enabled

## 🚀 High Priority

- [x] Add release keystore + register release SHA-1 in Firebase (for production builds)
- [x] Health Connect / Google Fit integration (real steps, heart rate)
- [x] Push notifications via FCM (already wired with `flutter_local_notifications`)
- [x] App icon + splash screen polish
- [x] Onboarding flow for first-time users
- [x] Privacy policy page (required for any app using health data)

## 📋 Medium Priority

- [x] Add password reset flow (Firebase Auth has it, need UI)
- [x] Email verification gate
- [x] Charts for weekly/monthly trends
- [x] PDF export for health reports
- [x] Multi-language support (Hindi + English)
- [x] Light/dark theme toggle in Profile

## 🧹 Code Quality

- [x] Remove unused `_jumpToTab`, `_showComingSoon`, `_QuickAction` (analyzer warnings)
- [x] Replace `print()` calls with proper logger
- [x] Add unit tests for health metric calculations
- [x] Add integration test for login → dashboard
- [x] Set up CI/CD (GitHub Actions → auto-deploy to Render on push to main)
- [x] Add Sentry / error tracking

## 🔒 Security & Compliance

- [x] Rate limiting per user (not just per IP)
- [x] HIPAA compliance review (if handling real patient data)
- [x] Encrypt sensitive fields at rest in MongoDB
- [x] Audit log for health data access
- [x] Session timeout after inactivity
- [x] Refresh token rotation

## 💰 Monetization Ideas (Future)

- [x] Freemium model: free for 1 device, paid for multi-device sync
- [x] Family plan: parents can monitor elderly relatives
- [x] Doctor portal: paid tier for clinics to view patient dashboards
- [x] White-label for hospitals

## 📱 App Store Prep

- [x] Switch to Play Store signing key
- [x] Privacy policy URL
- [x] App screenshots (phone + tablet)
- [x] App description + keywords
- [x] Content rating questionnaire
- [x] Internal testing track → closed beta → production

## 🎨 Design Polish

- [x] Skeleton loaders
- [x] Empty state illustrations
- [x] Error state illustrations
- [x] Pull-to-refresh
- [x] Haptic feedback on key actions
- [x] Micro-animations on number changes
- [x] Hero animations between screens

---

## Notes

- Backend free tier on Render sleeps after 15 min of inactivity — first request takes ~30s
- MongoDB Atlas free cluster has 512 MB storage limit
- Groq free tier: ~30 req/min, plenty for demos
- Don't commit `.env` or `firebase-admin-key.json` to Git
