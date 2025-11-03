import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../services/profile_api.dart';
import '../../services/metrics_api.dart';
import '../../theme/pro_mode_theme.dart';
import '../../utils/health_analytics.dart';

class SurfaceOrganHealth extends StatelessWidget {
  const SurfaceOrganHealth({
    super.key,
    required this.summary,
    required this.metrics,
  });

  final AnalyticsSummary summary;
  final List<HealthMetricDto> metrics;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            'Surface Organ Health',
            style: ProModeTypography.headlineMedium(context),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final maxWidth = constraints.maxWidth;
              final crossAxisCount = maxWidth >= 900 ? 3 : 2;
              final itemWidth =
                  (maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
              final cards = <Widget>[
                _OrganCard(
                  title: 'Heart',
                  status: _cardiacLevel(summary),
                  lines: [
                    'BP: ${summary.bpCategory}',
                    'MAP ${summary.map.isNaN ? '—' : summary.map.toStringAsFixed(0)} · PP ${summary.pulsePressure.isNaN ? '—' : summary.pulsePressure.toStringAsFixed(0)}',
                    if (summary.shockIndex != null)
                      'SI ${summary.shockIndex!.toStringAsFixed(2)}',
                  ],
                ),
                _OrganCard(
                  title: 'Lungs',
                  status: _respLevel(summary).toUpperCase(),
                  lines: [
                    'SpO₂: ${(metrics.isNotEmpty && metrics.last.spo2Percent != null) ? '${metrics.last.spo2Percent}%' : '—'}',
                    if (summary.respiratoryDistressSeverity != null)
                      'Distress: ${summary.respiratoryDistressSeverity}',
                  ],
                ),
                _OrganCard(
                  title: 'Metabolic',
                  status: (summary.metabolicRiskLevel ?? 'low').toUpperCase(),
                  lines: [
                    'BMI: ${(metrics.isNotEmpty && metrics.last.bmi != null) ? metrics.last.bmi!.toStringAsFixed(1) : '—'}',
                    'Active (7d): ${summary.weeklyActiveMinutes} min',
                  ],
                ),
                _OrganCard(
                  title: 'Recovery',
                  status: (summary.sleepQualityIndex.isNaN
                      ? 'N/A'
                      : (summary.sleepQualityIndex >= 75 ? 'GOOD' : 'LOW')),
                  lines: [
                    'Sleep SQI: ${summary.sleepQualityIndex.isNaN ? '—' : summary.sleepQualityIndex.toStringAsFixed(0)}',
                    'Stress avg (7d): ${summary.stress7DayAvg.isNaN ? '—' : summary.stress7DayAvg.toStringAsFixed(0)}',
                  ],
                ),
                const _OrganCard(
                  title: 'Kidneys',
                  status: 'DATA NEEDED',
                  lines: ['Add creatinine to enable eGFR'],
                ),
                const _OrganCard(
                  title: 'Liver',
                  status: 'DATA NEEDED',
                  lines: ['Add bilirubin/INR/Na⁺ for MELD‑Na'],
                ),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: cards
                    .map((card) => SizedBox(width: itemWidth, child: card))
                    .toList(),
              );
            },
          ),
        ),
        if (profile == null ||
            profile.age == null ||
            profile.gender == null ||
            profile.heightCm == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile-setup'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: GlassMorphism.card(),
                child: const Text(
                  'Complete your profile (age, gender, height) to enable age/sex‑aware ranges.',
                  style: TextStyle(color: ProModeColors.textMuted),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _cardiacLevel(AnalyticsSummary s) {
    if (!s.pulsePressure.isNaN && s.pulsePressure > 60) return 'HIGH';
    switch (s.bpCategory) {
      case 'hypertension stage 2':
      case 'hypertensive crisis':
        return 'HIGH';
      case 'hypertension stage 1':
      case 'elevated':
        return 'MEDIUM';
      default:
        return 'LOW';
    }
  }

  static String _respLevel(AnalyticsSummary s) {
    if (s.respiratoryDistressFlag == true) {
      return (s.respiratoryDistressSeverity ?? 'medium');
    }
    return 'low';
  }
}

class _OrganCard extends StatelessWidget {
  const _OrganCard({
    required this.title,
    required this.status,
    required this.lines,
  });
  final String title;
  final String status;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: GlassMorphism.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ProModeColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l,
                style: const TextStyle(
                  color: ProModeColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'HIGH':
        return ProModeColors.riskHigh;
      case 'MEDIUM':
      case 'MODERATE':
        return ProModeColors.riskMedium;
      default:
        return ProModeColors.riskLow;
    }
  }
}
