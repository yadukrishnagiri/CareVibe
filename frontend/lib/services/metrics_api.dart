import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';

class HealthMetricDto {
  HealthMetricDto({
    required this.date,
    required this.restingHeartRateBpm,
    required this.sleepDurationHr,
    required this.stepCount,
    this.weightKg,
    this.bmi,
    this.bloodPressureMmHg,
    this.spo2Percent,
    this.bodyTemperatureC,
    this.remSleepHr,
    this.sleepInterruptions,
    this.exerciseDurationMin,
    this.caloriesBurned,
    this.physicalActivityLevel,
    this.stressLevel,
    this.smokingStatus,
    this.alcoholConsumption,
  });

  final DateTime date;
  final int restingHeartRateBpm;
  final double sleepDurationHr;
  final int stepCount;

  final double? weightKg;
  final double? bmi;
  final String? bloodPressureMmHg;
  final int? spo2Percent;
  final double? bodyTemperatureC;
  final double? remSleepHr;
  final int? sleepInterruptions;
  final int? exerciseDurationMin;
  final int? caloriesBurned;
  final String? physicalActivityLevel;
  final int? stressLevel;
  final String? smokingStatus;
  final String? alcoholConsumption;

  static HealthMetricDto fromJson(Map<String, dynamic> j) => HealthMetricDto(
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        restingHeartRateBpm: (j['restingHeartRateBpm'] as num?)?.toInt() ?? 72,
        sleepDurationHr: (j['sleepDurationHr'] as num?)?.toDouble() ?? 7.0,
        stepCount: (j['stepCount'] as num?)?.toInt() ?? 5000,
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        bmi: (j['bmi'] as num?)?.toDouble(),
        bloodPressureMmHg: j['bloodPressureMmHg']?.toString(),
        spo2Percent: (j['spo2Percent'] as num?)?.toInt(),
        bodyTemperatureC: (j['bodyTemperatureC'] as num?)?.toDouble(),
        remSleepHr: (j['remSleepHr'] as num?)?.toDouble(),
        sleepInterruptions: (j['sleepInterruptions'] as num?)?.toInt(),
        exerciseDurationMin: (j['exerciseDurationMin'] as num?)?.toInt(),
        caloriesBurned: (j['caloriesBurned'] as num?)?.toInt(),
        physicalActivityLevel: j['physicalActivityLevel']?.toString(),
        stressLevel: (j['stressLevel'] as num?)?.toInt(),
        smokingStatus: j['smokingStatus']?.toString(),
        alcoholConsumption: j['alcoholConsumption']?.toString(),
      );
}

class MetricsApi {
  static Future<List<HealthMetricDto>> fetchMyMetrics(String jwt, {int days = 7}) async {
    final r = await http.get(Uri.parse('$apiBase/metrics/me?days=$days'), headers: authHeaders(jwt));
    if (r.statusCode != 200) {
      throw Exception('Failed to fetch metrics (${r.statusCode})');
    }
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => HealthMetricDto.fromJson(e as Map<String, dynamic>)).toList().reversed.toList();
  }
}



