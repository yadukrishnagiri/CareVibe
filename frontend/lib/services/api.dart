import 'package:flutter/foundation.dart';

const String apiBase = kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000';

Map<String, String> authHeaders(String jwt) => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    };


