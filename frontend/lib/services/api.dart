import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

// Choose API base by build mode and platform.
// - Web debug: local backend
// - Physical devices & emulators: cloud backend (for demo consistency)
const _forcedApiBase = String.fromEnvironment('API_BASE');

String get apiBase {
  if (_forcedApiBase.isNotEmpty) return _forcedApiBase;
  // Use cloud backend for all non-web platforms (physical devices & emulators)
  // This ensures demo data is consistent across all devices
  if (!kIsWeb) return 'https://carevibe-backend.onrender.com';
  // Web debug uses localhost
  if (!kReleaseMode) return 'http://localhost:5000';
  // Web release uses cloud
  return 'https://carevibe-backend.onrender.com';
}

Map<String, String> authHeaders(String jwt) => {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $jwt',
};
