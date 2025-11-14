import 'package:flutter/foundation.dart';

// Choose API base by build mode and platform.
// - Web debug: local backend
// - Mobile debug: special IP for Android emulator, localhost for iOS
// - Release builds: cloud backend
const _forcedApiBase = String.fromEnvironment('API_BASE');

String get apiBase {
  if (_forcedApiBase.isNotEmpty) return _forcedApiBase;

  // In debug mode, prioritize local backend for all platforms
  if (!kReleaseMode) {
    if (kIsWeb) {
      // Web debug uses localhost
      return 'http://localhost:5000';
    } else {
      // This block is for mobile (non-web) builds.
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android emulators connect to host machine's localhost via 10.0.2.2
        return 'http://10.0.2.2:5000';
      } else {
        // iOS simulators and other platforms can use localhost directly
        return 'http://localhost:5000';
      }
    }
  }

  // In release mode, always use the cloud backend
  return 'https://carevibe-backend.onrender.com';
}

Map<String, String> authHeaders(String jwt) => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    };
