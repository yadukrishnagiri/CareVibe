import 'package:flutter/foundation.dart';

// Production backend URL (Render.com)
const String apiBase = 'https://carevibe-backend.onrender.com';

Map<String, String> authHeaders(String jwt) => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    };


