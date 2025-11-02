import 'dart:math' as math;

import 'health_analytics.dart';
import '../services/metrics_api.dart';

/// Clinical Scores Calculator
/// Implements medical scoring systems using available health metrics

/// Shock Index = Heart Rate / Systolic Blood Pressure
/// Thresholds: <0.7 normal, 0.7-0.9 elevated, >0.9 high (possible shock/sepsis)
double calculateShockIndex(int? hr, int? sbp) {
  if (hr == null || sbp == null || sbp == 0) return double.nan;
  return hr / sbp;
}

/// Get Shock Index interpretation
String shockIndexLevel(double si) {
  if (si.isNaN) return 'unknown';
  if (si < 0.7) return 'normal';
  if (si < 0.9) return 'elevated';
  return 'high';
}

/// Body Surface Area (DuBois formula)
/// Derives height from BMI: height_cm = sqrt(weight_kg / BMI) * 100
/// Then: BSA = 0.007184 × (weight^0.425) × (height^0.725)
double calculateBSA(double? weightKg, double? bmi) {
  if (weightKg == null || bmi == null || weightKg <= 0 || bmi <= 0) {
    return double.nan;
  }
  // Derive height from BMI: BMI = weight / (height_m)^2
  // height_m = sqrt(weight_kg / BMI)
  final heightM = math.sqrt(weightKg / bmi);
  final heightCm = heightM * 100;
  
  // DuBois formula: BSA = 0.007184 × weight^0.425 × height^0.725
  return 0.007184 * 
         math.pow(weightKg, 0.425) * 
         math.pow(heightCm, 0.725);
}

/// Sepsis-like Pattern Detector
/// Pattern: HR>90 + Temp>37.5°C + (SBP<100 OR SpO2<95%)
/// Returns score 0-4 points and risk level
({
  int score,
  String level,
  String interpretation,
}) detectSepsisPattern(HealthMetricDto metric) {
  int score = 0;
  final conditions = <String>[];
  
  // HR > 90 bpm
  if (metric.restingHeartRateBpm > 90) {
    score++;
    conditions.add('HR >90');
  }
  
  // Temp > 37.5°C
  if (metric.bodyTemperatureC != null && metric.bodyTemperatureC! > 37.5) {
    score++;
    conditions.add('Temp >37.5°C');
  }
  
  // SBP < 100 mmHg
  final bp = parseBp(metric.bloodPressureMmHg);
  if (bp.systolic != null && bp.systolic! < 100) {
    score++;
    conditions.add('SBP <100');
  }
  
  // SpO2 < 95%
  if (metric.spo2Percent != null && metric.spo2Percent! < 95) {
    score++;
    conditions.add('SpO2 <95%');
  }
  
  String level;
  String interpretation;
  
  if (score == 0) {
    level = 'low';
    interpretation = 'No sepsis-like pattern detected.';
  } else if (score <= 2) {
    level = 'medium';
    interpretation = 
        'Mild sepsis-like pattern ($score/4 criteria: ${conditions.join(', ')}). Monitor closely.';
  } else {
    level = 'high';
    interpretation = 
        'Strong sepsis-like pattern ($score/4 criteria: ${conditions.join(', ')}). Consider clinical review if symptoms persist or worsen.';
  }
  
  return (
    score: score,
    level: level,
    interpretation: interpretation,
  );
}

/// Respiratory Distress Pattern
/// Pattern: SpO2<94% + HR>100 (compensatory tachycardia)
/// Missing RR, so use surrogate: HR↑ + SpO2↓ = respiratory compensation
({
  bool flag,
  String severity,
  String interpretation,
}) detectRespiratoryDistress(HealthMetricDto metric) {
  final spo2Low = metric.spo2Percent != null && metric.spo2Percent! < 94;
  final hrHigh = metric.restingHeartRateBpm > 100;
  
  if (!spo2Low && !hrHigh) {
    return (
      flag: false,
      severity: 'none',
      interpretation: 'No respiratory distress pattern.',
    );
  }
  
  if (spo2Low && hrHigh) {
    return (
      flag: true,
      severity: 'moderate',
      interpretation: 
          'Respiratory distress pattern: SpO₂ ${metric.spo2Percent}% with compensatory tachycardia (HR ${metric.restingHeartRateBpm}). Consider clinical assessment if symptomatic.',
    );
  }
  
  if (spo2Low) {
    return (
      flag: true,
      severity: 'mild',
      interpretation: 
          'Low SpO₂ ${metric.spo2Percent}%. Monitor oxygen saturation and respiratory symptoms.',
    );
  }
  
  // hrHigh only
  return (
    flag: true,
    severity: 'mild',
    interpretation: 
        'Elevated HR ${metric.restingHeartRateBpm} bpm. Consider hydration and rest.',
  );
}

/// Metabolic Risk Calculator
/// Pattern: BMI>25 + Sleep debt>3h/7d + Activity<150min/week + Stress>50
({
  String level,
  int score,
  String interpretation,
}) calculateMetabolicRisk(List<HealthMetricDto> metrics) {
  if (metrics.isEmpty) {
    return (
      level: 'unknown',
      score: 0,
      interpretation: 'Insufficient data.',
    );
  }
  
  final latest = metrics.last;
  int score = 0;
  final factors = <String>[];
  
  // BMI > 25
  if (latest.bmi != null && latest.bmi! > 25) {
    score++;
    factors.add('BMI ${latest.bmi!.toStringAsFixed(1)}');
  }
  
  // Sleep debt > 3h over 7 days
  final sleepDebt = sleepDebtHours(metrics, days: 7);
  if (sleepDebt > 3.0) {
    score++;
    factors.add('Sleep debt ${sleepDebt.toStringAsFixed(1)}h/7d');
  }
  
  // Weekly activity < 150 min
  final wam = weeklyActiveMinutes(metrics);
  if (wam < 150) {
    score++;
    factors.add('Activity ${wam}min/week');
  }
  
  // Stress > 50
  if (latest.stressLevel != null && latest.stressLevel! > 50) {
    score++;
    factors.add('Stress ${latest.stressLevel}');
  }
  
  String level;
  String interpretation;
  
  if (score == 0) {
    level = 'low';
    interpretation = 'Low metabolic risk. Current lifestyle factors are favorable.';
  } else if (score <= 2) {
    level = 'intermediate';
    interpretation = 
        'Intermediate metabolic risk ($score/4 factors: ${factors.join(', ')}). Consider lifestyle modifications.';
  } else {
    level = 'high';
    interpretation = 
        'High metabolic risk ($score/4 factors: ${factors.join(', ')}). Recommend comprehensive lifestyle intervention and consider metabolic screening.';
  }
  
  return (
    level: level,
    score: score,
    interpretation: interpretation,
  );
}

/// Generate Pro Interpretation
/// Creates clinical-style notes for clinicians
List<String> generateProInterpretation(AnalyticsSummary summary, List<HealthMetricDto> metrics) {
  final notes = <String>[];
  
  if (metrics.isEmpty) return notes;
  
  final latest = metrics.last;
  final bp = parseBp(latest.bloodPressureMmHg);
  
  // BP & Cardiovascular
  if (summary.bpCategory != 'normal') {
    final mapStr = summary.map.isNaN ? '—' : summary.map.toStringAsFixed(0);
    final ppStr = summary.pulsePressure.isNaN ? '—' : summary.pulsePressure.toStringAsFixed(0);
    notes.add(
      'BP ${summary.bpCategory}; MAP $mapStr mmHg, Pulse Pressure $ppStr mmHg. ${summary.bpCategory == 'hypertensive crisis' || summary.bpCategory == 'hypertension stage 2' ? 'Urgent monitoring recommended.' : 'Monitor trends and consider lifestyle modifications.'}',
    );
  }
  
  // Shock Index
  if (bp.systolic != null) {
    final si = calculateShockIndex(latest.restingHeartRateBpm, bp.systolic);
    if (!si.isNaN && si >= 0.7) {
      final siLevel = shockIndexLevel(si);
      notes.add(
        'Shock Index ${si.toStringAsFixed(2)} ($siLevel). ${si >= 0.9 ? 'Consider hydration assessment and clinical review if symptomatic.' : 'Monitor for signs of hemodynamic instability.'}',
      );
    }
  }
  
  // Heart Rate Trends
  if (metrics.length >= 7) {
    final hrSeries = metrics.map((m) => m.restingHeartRateBpm.toDouble()).toList();
    if (hrSeries.length >= 3) {
      final recentAvg = hrSeries.sublist(hrSeries.length - 3).reduce((a, b) => a + b) / 3;
      final earlierAvg = hrSeries.length >= 6 
          ? hrSeries.sublist(hrSeries.length - 6, hrSeries.length - 3).reduce((a, b) => a + b) / 3
          : recentAvg;
      
      if (recentAvg - earlierAvg > 5) {
        notes.add(
          'Resting HR trending upward (~${(recentAvg - earlierAvg).toStringAsFixed(0)} bpm over recent days). Possible contributors: stress, infection, dehydration, or deconditioning.',
        );
      }
    }
  }
  
  // Sleep Analysis
  final debt = sleepDebtHours(metrics, days: 7);
  if (debt >= 3) {
    notes.add(
      'Sleep debt ${debt.toStringAsFixed(1)}h over 7 days. Target <3h/week. Chronic sleep debt impacts metabolic health and recovery.',
    );
  }
  
  // Activity Assessment
  final wam = weeklyActiveMinutes(metrics);
  if (wam < 150) {
    notes.add(
      'Active minutes: ${wam}/150 min/week (guideline). Increase moderate-intensity activity to meet minimum recommendations.',
    );
  }
  
  // Metabolic Risk
  final metabolicRisk = calculateMetabolicRisk(metrics);
  if (metabolicRisk.level == 'high' || metabolicRisk.level == 'intermediate') {
    notes.add('Metabolic risk: ${metabolicRisk.level} (${metabolicRisk.score}/4 factors). ${metabolicRisk.interpretation}');
  }
  
  // SpO2 & Respiratory
  if (latest.spo2Percent != null && latest.spo2Percent! < 94) {
    notes.add(
      'SpO₂ ${latest.spo2Percent}% (below normal range). Monitor respiratory symptoms and consider clinical assessment if persistent.',
    );
  }
  
  // Temperature
  if (latest.bodyTemperatureC != null && latest.bodyTemperatureC! > 37.5) {
    notes.add(
      'Body temperature ${latest.bodyTemperatureC!.toStringAsFixed(1)}°C (elevated). Monitor for signs of infection. Rest and hydration recommended.',
    );
  }
  
  return notes;
}

