import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';

class MedicationReminderDto {
  MedicationReminderDto({
    required this.medicationId,
    required this.name,
    required this.dosage,
    required this.time,
    this.timeUntil,
  });

  final String medicationId;
  final String name;
  final String dosage;
  final String time;
  final int? timeUntil;

  static MedicationReminderDto fromJson(Map<String, dynamic> json) {
    return MedicationReminderDto(
      medicationId: json['medicationId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      timeUntil: json['timeUntil'] as int?,
    );
  }
}

class MedicationApi {
  static Future<List<MedicationReminderDto>> getTodayReminders(String jwt) async {
    final url = '$apiBase/medications/me/today';
    
    final response = await http.get(
      Uri.parse(url),
      headers: authHeaders(jwt),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch medication reminders (${response.statusCode})');
    }
    
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json.map((item) => MedicationReminderDto.fromJson(item as Map<String, dynamic>)).toList();
  }

  static Future<List<dynamic>> getMyMedications(String jwt) async {
    final url = '$apiBase/medications/me';
    
    final response = await http.get(
      Uri.parse(url),
      headers: authHeaders(jwt),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch medications (${response.statusCode})');
    }
    
    return jsonDecode(response.body) as List<dynamic>;
  }
}

