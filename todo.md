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

- [ ] Test APK on phone with Google login → verify it actually works end-to-end
- [ ] If login still fails after SHA-1 fix → check Firebase Auth Google provider is enabled

## 🚀 High Priority

- [ ] Add release keystore + register release SHA-1 in Firebase (for production builds)
- [ ] Health Connect / Google Fit integration (real steps, heart rate)
- [ ] Push notifications via FCM (already wired with `flutter_local_notifications`)
- [ ] App icon + splash screen polish
- [ ] Onboarding flow for first-time users
- [ ] Privacy policy page (required for any app using health data)

## 📋 Medium Priority

- [ ] Add password reset flow (Firebase Auth has it, need UI)
- [ ] Email verification gate
- [ ] Charts for weekly/monthly trends
- [ ] PDF export for health reports
- [ ] Multi-language support (Hindi + English)
- [ ] Light/dark theme toggle in Profile

## 🧹 Code Quality

- [ ] Remove unused `_jumpToTab`, `_showComingSoon`, `_QuickAction` (analyzer warnings)
- [ ] Replace `print()` calls with proper logger
- [ ] Add unit tests for health metric calculations
- [ ] Add integration test for login → dashboard
- [ ] Set up CI/CD (GitHub Actions → auto-deploy to Render on push to main)
- [ ] Add Sentry / error tracking

## 🔒 Security & Compliance

- [ ] Rate limiting per user (not just per IP)
- [ ] HIPAA compliance review (if handling real patient data)
- [ ] Encrypt sensitive fields at rest in MongoDB
- [ ] Audit log for health data access
- [ ] Session timeout after inactivity
- [ ] Refresh token rotation

## 💰 Monetization Ideas (Future)

- [ ] Freemium model: free for 1 device, paid for multi-device sync
- [ ] Family plan: parents can monitor elderly relatives
- [ ] Doctor portal: paid tier for clinics to view patient dashboards
- [ ] White-label for hospitals

## 📱 App Store Prep

- [ ] Switch to Play Store signing key
- [ ] Privacy policy URL
- [ ] App screenshots (phone + tablet)
- [ ] App description + keywords
- [ ] Content rating questionnaire
- [ ] Internal testing track → closed beta → production

## 🎨 Design Polish

- [ ] Skeleton loaders
- [ ] Empty state illustrations
- [ ] Error state illustrations
- [ ] Pull-to-refresh
- [ ] Haptic feedback on key actions
- [ ] Micro-animations on number changes
- [ ] Hero animations between screens

---

## Notes

- Backend free tier on Render sleeps after 15 min of inactivity — first request takes ~30s
- MongoDB Atlas free cluster has 512 MB storage limit
- Groq free tier: ~30 req/min, plenty for demos
- Don't commit `.env` or `firebase-admin-key.json` to Git
