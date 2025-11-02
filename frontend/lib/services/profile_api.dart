import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';

class UserProfileDto {
  UserProfileDto({this.age, this.gender, this.heightCm});
  final int? age; // years
  final String? gender; // male | female | other
  final double? heightCm;

  static UserProfileDto fromJson(Map<String, dynamic> j) => UserProfileDto(
        age: (j['age'] as num?)?.toInt(),
        gender: j['gender']?.toString(),
        heightCm: (j['heightCm'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (heightCm != null) 'heightCm': heightCm,
      };
}

class ProfileApi {
  static Future<UserProfileDto?> fetchMyProfile(String jwt) async {
    final r = await http.get(Uri.parse('$apiBase/profile/me'), headers: authHeaders(jwt));
    if (r.statusCode == 200) {
      final obj = jsonDecode(r.body);
      if (obj is Map<String, dynamic> && obj.isNotEmpty) {
        return UserProfileDto.fromJson(obj);
      }
      return null;
    }
    throw Exception('Failed to fetch profile (${r.statusCode})');
  }

  static Future<UserProfileDto> upsertMyProfile(String jwt, UserProfileDto payload) async {
    final r = await http.put(
      Uri.parse('$apiBase/profile/me'),
      headers: authHeaders(jwt),
      body: jsonEncode(payload.toJson()),
    );
    if (r.statusCode == 200) {
      final obj = jsonDecode(r.body) as Map<String, dynamic>;
      final prof = obj['profile'] as Map<String, dynamic>;
      return UserProfileDto.fromJson(prof);
    }
    throw Exception('Failed to save profile (${r.statusCode})');
  }
}



