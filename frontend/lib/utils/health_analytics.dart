import 'dart:math' as math;

import '../services/metrics_api.dart';

class TrendPoint {
  TrendPoint(this.x, this.y);
  final double x; // day index (0..n-1)
  final double y;
}

class TrendSeries {
  TrendSeries(this.label, this.points);
  final String label;
  final List<TrendPoint> points;
}

class AlertItem {
  AlertItem({required this.level, required this.message});
  final String level; // high | medium | low
  final String message;
}

class AnalyticsSummary {
  AnalyticsSummary({
    required this.map,
    required this.pulsePressure,
    required this.bpCategory,
    required this.remPercent,
    required this.sleepQualityIndex,
    required this.activityScore,
    required this.weeklyActiveMinutes,
    required this.stress7DayAvg,
    required this.wellnessScore,
    required this.series,
    required this.alerts,
  });

  final double map; // Mean Arterial Pressure
  final double pulsePressure;
  final String bpCategory;
  final double remPercent;
  final double sleepQualityIndex; // 0-100
  final double activityScore; // 0-100
  final int weeklyActiveMinutes;
  final double stress7DayAvg; // 0-100 scale
  final double wellnessScore; // 0-100
  final List<TrendSeries> series;
  final List<AlertItem> alerts;
}

// --- Parsing helpers ---

({int? systolic, int? diastolic}) parseBp(String? bp) {
  if (bp == null) return (systolic: null, diastolic: null);
  final parts = bp.split('/');
  if (parts.length != 2) return (systolic: null, diastolic: null);
  final s = int.tryParse(parts[0].trim());
  final d = int.tryParse(parts[1].trim());
  return (systolic: s, diastolic: d);
}

double meanArterialPressure(int? systolic, int? diastolic) {
  if (systolic == null || diastolic == null) return double.nan;
  return diastolic + (systolic - diastolic) / 3.0;
}

double pulsePressure(int? systolic, int? diastolic) {
  if (systolic == null || diastolic == null) return double.nan;
  return (systolic - diastolic).toDouble();
}

String bpCategory(int? systolic, int? diastolic) {
  if (systolic == null || diastolic == null) return 'unknown';
  if (systolic > 180 || diastolic > 120) return 'hypertensive crisis';
  if (systolic >= 140 || diastolic >= 90) return 'hypertension stage 2';
  if (systolic >= 130 || diastolic >= 80) return 'hypertension stage 1';
  if (systolic >= 120 && diastolic < 80) return 'elevated';
  return 'normal';
}

// General thresholds and categories
String bmiCategory(double? bmi) {
  if (bmi == null || bmi.isNaN) return 'unknown';
  if (bmi < 18.5) return 'underweight';
  if (bmi < 25) return 'normal';
  if (bmi < 30) return 'overweight';
  return 'obese';
}

bool spo2Low(num? spo2) => spo2 != null && spo2 < 94;
bool tempHigh(num? tempC) => tempC != null && tempC > 37.5;
bool hrHigh(num? rhr) => rhr != null && rhr > 90;
bool hrElevated(num? rhr) => rhr != null && rhr > 80;

// Sleep metrics
double remPercent(double? remHr, double? totalSleepHr) {
  if (remHr == null || totalSleepHr == null || totalSleepHr <= 0) return double.nan;
  return (remHr / totalSleepHr) * 100.0;
}

double sleepEfficiency(double? totalSleepHr, int? interruptions) {
  if (totalSleepHr == null) return double.nan;
  final timeInBed = totalSleepHr + (math.max(0, (interruptions ?? 0)) * 0.25);
  if (timeInBed <= 0) return double.nan;
  return (totalSleepHr / timeInBed) * 100.0;
}

double sleepQualityIndex(double? totalSleepHr, double? remHr, int? interruptions) {
  if (totalSleepHr == null) return double.nan;
  final durationScore = math.min(100.0, (totalSleepHr / 8.0) * 100.0);
  final remPct = remPercent(remHr, totalSleepHr);
  final remScore = 100.0 - (remPct.isNaN ? 0.0 : (remPct - 22.5).abs() * 4.0);
  final interruptionScore = math.max(0.0, 100.0 - (math.max(0, (interruptions ?? 0)) * 25.0));
  return (durationScore * 0.4) + (remScore * 0.3) + (interruptionScore * 0.3);
}

// Activity metrics
double activityScore(int? steps, int? exerciseMin) {
  final stepScore = math.min(100.0, ((steps ?? 0) / 10000.0) * 100.0);
  final exScore = math.min(100.0, ((exerciseMin ?? 0) / 30.0) * 100.0);
  return (stepScore * 0.5) + (exScore * 0.5);
}

int weeklyActiveMinutes(List<HealthMetricDto> data) {
  // sum last 7 entries exercise minutes
  final last7 = data.length >= 7 ? data.sublist(data.length - 7) : List.of(data);
  return last7.fold<int>(0, (sum, d) => sum + (d.exerciseDurationMin ?? 0));
}

double wellnessScoreSimplified(HealthMetricDto d) {
  // Based on docs section 7.2
  double score = 0;
  // BP (20)
  final bp = parseBp(d.bloodPressureMmHg);
  if (bp.systolic != null && bp.diastolic != null) {
    if (bp.systolic! < 120 && bp.diastolic! < 80) {
      score += 20;
    } else if (bp.systolic! < 130 && bp.diastolic! < 85) {
      score += 15;
    } else if (bp.systolic! < 140 && bp.diastolic! < 90) {
      score += 10;
    } else {
      score += 5;
    }
  } else {
    score += 10; // neutral if missing
  }
  // Heart Rate (20)
  final hrScore = 100.0 - (d.restingHeartRateBpm - 65).abs() * 1.5;
  score += math.min(20.0, math.max(0.0, hrScore * 0.2));
  // Sleep (20)
  final s = d.sleepDurationHr;
  if (s >= 7 && s <= 9) score += 20;
  else if (s >= 6 && s <= 10) score += 15;
  else if (s >= 5) score += 10;
  else score += 5;
  // Activity (20)
  final steps = d.stepCount;
  if (steps >= 10000) score += 20;
  else if (steps >= 7500) score += 15;
  else if (steps >= 5000) score += 10;
  else score += 5;
  // Stress (20)
  final st = d.stressLevel ?? 35;
  if (st < 25) score += 20;
  else if (st < 40) score += 15;
  else if (st < 60) score += 10;
  else score += 5;
  return score;
}

List<double> simpleMovingAverage(List<double> values, int n) {
  if (values.isEmpty || n <= 1) return List.of(values);
  final out = <double>[];
  double sum = 0;
  for (int i = 0; i < values.length; i++) {
    sum += values[i];
    if (i >= n) sum -= values[i - n];
    if (i >= n - 1) out.add(sum / n);
  }
  return out;
}

double standardDeviation(List<double> values) {
  if (values.isEmpty) return double.nan;
  final mean = values.reduce((a, b) => a + b) / values.length;
  final varSum = values.fold<double>(0, (sum, v) => sum + math.pow(v - mean, 2).toDouble());
  return math.sqrt(varSum / values.length);
}

double linearRegressionSlope(List<TrendPoint> points) {
  final n = points.length;
  if (n < 2) return double.nan;
  double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
  for (final p in points) {
    sumX += p.x; sumY += p.y; sumXY += p.x * p.y; sumX2 += p.x * p.x;
  }
  final numerator = (n * sumXY) - (sumX * sumY);
  final denominator = (n * sumX2) - (sumX * sumX);
  if (denominator == 0) return double.nan;
  return numerator / denominator;
}

List<AlertItem> checkAlerts(HealthMetricDto d) {
  final alerts = <AlertItem>[];
  // Threshold-based
  final bp = parseBp(d.bloodPressureMmHg);
  final cat = bpCategory(bp.systolic, bp.diastolic);
  if (cat == 'hypertension stage 2' || cat == 'hypertensive crisis') {
    alerts.add(AlertItem(level: 'high', message: 'Blood pressure markedly elevated. Seek care if persistent.'));
  } else if (cat == 'hypertension stage 1' || cat == 'elevated') {
    alerts.add(AlertItem(level: 'medium', message: 'Blood pressure above ideal range. Monitor regularly.'));
  }
  if (pulsePressure(bp.systolic, bp.diastolic) > 60) {
    alerts.add(AlertItem(level: 'medium', message: 'Wide pulse pressure—follow up if consistent.'));
  }
  if (spo2Low(d.spo2Percent)) {
    alerts.add(AlertItem(level: 'high', message: 'Low SpO₂. If you feel unwell, seek urgent care.'));
  }
  if (tempHigh(d.bodyTemperatureC)) {
    alerts.add(AlertItem(level: 'high', message: 'Fever detected. Rest and hydrate; seek care if severe.'));
  }
  if (hrHigh(d.restingHeartRateBpm)) {
    alerts.add(AlertItem(level: 'medium', message: 'Resting HR high. Consider recovery and hydration.'));
  } else if (hrElevated(d.restingHeartRateBpm)) {
    alerts.add(AlertItem(level: 'low', message: 'Resting HR slightly elevated.'));
  }
  if (d.sleepDurationHr < 6) {
    alerts.add(AlertItem(level: 'medium', message: 'Sleep under 6h. Aim for 7–9h.'));
  }
  if (d.stepCount < 5000) {
    alerts.add(AlertItem(level: 'low', message: 'Low activity today. Short walk helps.'));
  }
  final bmiCat = bmiCategory(d.bmi);
  if (bmiCat == 'overweight' || bmiCat == 'obese') {
    alerts.add(AlertItem(level: 'low', message: 'BMI above normal range. Consider gradual lifestyle changes.'));
  }
  return alerts;
}

List<String> clinicianSummary(AnalyticsSummary s, List<HealthMetricDto> data) {
  final notes = <String>[];
  // BP
  if (s.bpCategory != 'normal') {
    notes.add('BP ${s.bpCategory}; MAP ${s.map.isNaN ? '—' : s.map.toStringAsFixed(0)} mmHg, PP ${s.pulsePressure.isNaN ? '—' : s.pulsePressure.toStringAsFixed(0)} mmHg.');
  }
  // Sleep debt
  final debt = sleepDebtHours(data, days: 7);
  if (debt >= 3) notes.add('Sleep debt ~${debt.toStringAsFixed(1)} h in 7d.');
  // Activity minutes
  final wam = weeklyActiveMinutes(data);
  if (wam < 150) notes.add('Active minutes 7d: $wam (below 150 recommended).');
  // HR trend (30d)
  final hrSeries = [for (int i = 0; i < data.length; i++) TrendPoint(i.toDouble(), data[i].restingHeartRateBpm.toDouble())];
  final last30 = hrSeries.length > 30 ? hrSeries.sublist(hrSeries.length - 30) : hrSeries;
  final slope = linearRegressionSlope(last30);
  if (!slope.isNaN && slope > 0.05) notes.add('Rising resting HR over last month.');
  // Stress average
  final stressVals = data.where((d) => d.stressLevel != null).map((d) => d.stressLevel!.toDouble()).toList();
  if (stressVals.isNotEmpty) {
    final avg = stressVals.reduce((a, b) => a + b) / stressVals.length;
    if (avg > 50) notes.add('Elevated average stress level.');
  }
  return notes;
}

AnalyticsSummary computeAnalytics(List<HealthMetricDto> data) {
  if (data.isEmpty) {
    return AnalyticsSummary(
      map: double.nan,
      pulsePressure: double.nan,
      bpCategory: 'unknown',
      remPercent: double.nan,
      sleepQualityIndex: double.nan,
      activityScore: 0,
      weeklyActiveMinutes: 0,
      stress7DayAvg: double.nan,
      wellnessScore: 0,
      series: const [],
      alerts: const [],
    );
  }

  // Use most recent day for point-in-time metrics
  final latest = data.last;
  final bp = parseBp(latest.bloodPressureMmHg);
  final mapVal = meanArterialPressure(bp.systolic, bp.diastolic);
  final pp = pulsePressure(bp.systolic, bp.diastolic);
  final bpCat = bpCategory(bp.systolic, bp.diastolic);
  final remPct = remPercent(latest.remSleepHr, latest.sleepDurationHr);
  final sqi = sleepQualityIndex(latest.sleepDurationHr, latest.remSleepHr, latest.sleepInterruptions);
  final actScore = activityScore(latest.stepCount, latest.exerciseDurationMin);
  final wam = weeklyActiveMinutes(data);
  final last7 = data.length >= 7 ? data.sublist(data.length - 7) : List.of(data);
  final stress7 = last7.where((d) => d.stressLevel != null).map((d) => d.stressLevel!.toDouble()).toList();
  final stressAvg = stress7.isEmpty ? double.nan : (stress7.reduce((a, b) => a + b) / stress7.length);
  final wellness = _wellnessIndex(data);

  // Build series for charts
  final stepsSeries = TrendSeries('Steps', [
    for (int i = 0; i < data.length; i++) TrendPoint(i.toDouble(), data[i].stepCount.toDouble())
  ]);
  final sleepSeries = TrendSeries('Sleep (h)', [
    for (int i = 0; i < data.length; i++) TrendPoint(i.toDouble(), data[i].sleepDurationHr)
  ]);
  final hrSeries = TrendSeries('Resting HR', [
    for (int i = 0; i < data.length; i++) TrendPoint(i.toDouble(), data[i].restingHeartRateBpm.toDouble())
  ]);

  // Aggregate alerts for latest day
  final alerts = checkAlerts(latest);

  return AnalyticsSummary(
    map: mapVal,
    pulsePressure: pp,
    bpCategory: bpCat,
    remPercent: remPct,
    sleepQualityIndex: sqi,
    activityScore: actScore,
    weeklyActiveMinutes: wam,
    stress7DayAvg: stressAvg,
    wellnessScore: wellness,
    series: [stepsSeries, sleepSeries, hrSeries],
    alerts: alerts,
  );
}

// --- Additional analytics helpers for tabs ---

double sleepDebtHours(List<HealthMetricDto> data, {int days = 7}) {
  final last = data.length >= days ? data.sublist(data.length - days) : List.of(data);
  double debt = 0.0;
  for (final d in last) {
    final deficit = 7.0 - d.sleepDurationHr;
    if (deficit > 0) debt += deficit;
  }
  return debt;
}

TrendSeries buildSleepHoursSeries(List<HealthMetricDto> data) {
  return TrendSeries('Sleep (h)', [
    for (int i = 0; i < data.length; i++) TrendPoint(i.toDouble(), data[i].sleepDurationHr)
  ]);
}

TrendSeries buildSleepRemPctSeries(List<HealthMetricDto> data) {
  return TrendSeries('REM %', [
    for (int i = 0; i < data.length; i++)
      TrendPoint(
        i.toDouble(),
        remPercent(data[i].remSleepHr, data[i].sleepDurationHr).isNaN
            ? 0
            : remPercent(data[i].remSleepHr, data[i].sleepDurationHr),
      )
  ]);
}

TrendSeries buildStressSeries(List<HealthMetricDto> data) {
  return TrendSeries('Stress', [
    for (int i = 0; i < data.length; i++) TrendPoint(i.toDouble(), (data[i].stressLevel ?? 0).toDouble())
  ]);
}

TrendSeries buildStressSma7Series(List<HealthMetricDto> data) {
  final vals = [for (final d in data) (d.stressLevel ?? 0).toDouble()];
  final sma = simpleMovingAverage(vals, 7);
  // align x starting at index 6
  return TrendSeries('Stress (7d MA)', [
    for (int i = 0; i < sma.length; i++) TrendPoint((i + 6).toDouble(), sma[i])
  ]);
}

TrendSeries buildStepsSeries(List<HealthMetricDto> data) {
  return TrendSeries('Steps', [
    for (int i = 0; i < data.length; i++) TrendPoint(i.toDouble(), data[i].stepCount.toDouble())
  ]);
}

TrendSeries buildRestingHrSeries(List<HealthMetricDto> data) {
  return TrendSeries('Resting HR', [
    for (int i = 0; i < data.length; i++) TrendPoint(i.toDouble(), data[i].restingHeartRateBpm.toDouble())
  ]);
}

TrendSeries buildWeightSeries(List<HealthMetricDto> data) {
  return TrendSeries('Weight (kg)', [
    for (int i = 0; i < data.length; i++) TrendPoint(i.toDouble(), (data[i].weightKg ?? 0).toDouble())
  ]);
}

TrendSeries buildBmiSeries(List<HealthMetricDto> data) {
  return TrendSeries('BMI', [
    for (int i = 0; i < data.length; i++) TrendPoint(i.toDouble(), (data[i].bmi ?? 0).toDouble())
  ]);
}

TrendSeries buildWellnessSeries(List<HealthMetricDto> data) {
  final vals = [for (final d in data) _wellnessIndexSingle(d)];
  return TrendSeries('Wellness', [
    for (int i = 0; i < vals.length; i++) TrendPoint(i.toDouble(), vals[i])
  ]);
}

// --- Subscores and Wellness Index ---

double _subscoreVitals(HealthMetricDto d) {
  final bp = parseBp(d.bloodPressureMmHg);
  final cat = bpCategory(bp.systolic, bp.diastolic);
  double bpScore = switch (cat) {
    'normal' => 100,
    'elevated' => 75,
    'hypertension stage 1' => 50,
    'hypertension stage 2' => 25,
    'hypertensive crisis' => 0,
    _ => 60,
  };
  final hr = d.restingHeartRateBpm.toDouble();
  final hrScore = math.max(0, 100 - (hr - 65).abs() * 2);
  final spo2Score = math.min(100, math.max(0, ((d.spo2Percent ?? 98) - 90) * 12.5));
  final tempScore = d.bodyTemperatureC == null ? 70 : (d.bodyTemperatureC! <= 37.5 ? 100 : 40);
  return (bpScore * 0.4) + (hrScore * 0.3) + (spo2Score * 0.2) + (tempScore * 0.1);
}

double _subscoreSleep(HealthMetricDto d) {
  final sqi = sleepQualityIndex(d.sleepDurationHr, d.remSleepHr, d.sleepInterruptions);
  return sqi.isNaN ? 60 : sqi;
}

double _subscoreActivity(HealthMetricDto d) {
  return activityScore(d.stepCount, d.exerciseDurationMin);
}

double _subscoreMetabolic(HealthMetricDto d) {
  final bmi = d.bmi ?? 0;
  if (bmi <= 0) return 60;
  // 22.5 center, penalize distance from 22.5 within [18.5, 30]
  final dist = (bmi - 22.5).abs();
  return math.max(0, 100 - dist * 12);
}

double _subscoreStress(HealthMetricDto d) {
  final s = (d.stressLevel ?? 35).toDouble();
  return math.max(0, 100 - s);
}

double _wellnessIndexSingle(HealthMetricDto d) {
  final vit = _subscoreVitals(d);
  final slp = _subscoreSleep(d);
  final act = _subscoreActivity(d);
  final met = _subscoreMetabolic(d);
  final str = _subscoreStress(d);
  return (vit * 0.3) + (slp * 0.25) + (act * 0.25) + (met * 0.1) + (str * 0.1);
}

double _wellnessIndex(List<HealthMetricDto> data) {
  if (data.isEmpty) return 0;
  return _wellnessIndexSingle(data.last);
}



