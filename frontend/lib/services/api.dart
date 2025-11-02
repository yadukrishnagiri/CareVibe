import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

// Choose API base by build mode and platform.
// - Debug: local backend (Android emulator uses 10.0.2.2)
// - Release: cloud backend (Render)
const _forcedApiBase = String.fromEnvironment('API_BASE');

String get apiBase {
  if (_forcedApiBase.isNotEmpty) return _forcedApiBase;
  if (kReleaseMode) return 'https://carevibe-backend.onrender.com';
  if (kIsWeb) return 'http://localhost:5000';
  return 'http://10.0.2.2:5000';
}

Map<String, String> authHeaders(String jwt) => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    };


