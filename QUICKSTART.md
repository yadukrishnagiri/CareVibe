## CareVibe — Quick Start (Clone and Run)

This guide shows ONLY the essential steps to run the app after cloning, using the already-deployed cloud backend. No local backend setup required.

### 1) Prerequisites (install once)
- **Flutter SDK**: Install Flutter and add it to PATH. Verify: `flutter --version`.
- **Android Studio** (for Android SDK, emulator, and `adb`). Open it once to finish setup.
- **Git**: Verify: `git --version`.

Optional:
- Chrome (for `flutter run -d chrome` web demo).

### 2) Get the code
```bash
git clone https://github.com/your-username/CareVibe.git
cd CareVibe
```

### 3) Backend is already in the cloud
- The app is preconfigured to use the cloud API at your Render URL.
- If you ever need to change it, edit `frontend/lib/services/api.dart` and set `apiBase` to your deployed URL.

### 4) Install Flutter dependencies
```bash
cd frontend
flutter pub get
```

### 5) Run the app
Pick one:

- Web (Chrome):
```bash
flutter run -d chrome
```

- Android Emulator (from Android Studio):
1. Start an emulator in Android Studio (AVD Manager → Play).
2. Then run:
```bash
flutter devices
flutter run
```

- Physical Android device:
1. Enable Developer Options + USB debugging on the phone.
2. Connect via USB → accept the RSA prompt on device.
3. Verify device:
```bash
adb devices
```
4. Run:
```bash
flutter run
```

### 6) Build a release APK (to share/install)
```bash
cd frontend
flutter build apk --release
```
The APK will be at:
```
frontend/build/app/outputs/flutter-apk/app-release.apk
```
Copy it to your phone and install.

### That’s it
You don’t need Node.js, MongoDB, or any server config to run the app, because the backend is already deployed to the cloud and the app points to it by default.

---

### Troubleshooting (quick fixes)
- Java/Gradle issues: Use JDK 17 (Android Studio bundles one). Restart your terminal/IDE.
- `adb` not found: Ensure Android SDK Platform Tools are installed and in PATH.
- No devices: Start an emulator in Android Studio or connect a phone and run `adb devices`.
- Windows symlink error: Enable Windows Developer Mode and reopen terminal.
- If API calls fail: Confirm `frontend/lib/services/api.dart` has your Render URL.


