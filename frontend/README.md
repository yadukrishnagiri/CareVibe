Frontend (Flutter / Android)

Setup (Windows)

1) Ensure Flutter SDK and Android Studio are installed. Create project files:
cd frontend
flutter create .

2) Add packages:
flutter pub add firebase_core firebase_auth google_sign_in http provider

3) Place Firebase config:
- Put google-services.json at android/app/google-services.json

4) Run app:
flutter run

Notes

- Emulator uses http://10.0.2.2:5000 to reach backend.
- After Google sign-in, the app calls /auth/firebase to obtain a backend JWT.


