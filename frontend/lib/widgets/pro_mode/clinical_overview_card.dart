import 'package:flutter/material.dart';

import '../../theme/pro_mode_theme.dart';
import '../../utils/health_analytics.dart';
import '../../utils/haptics_helper.dart';
import '../sparkline.dart';

class ClinicalOverviewCard extends StatelessWidget {
  const ClinicalOverviewCard({super.key, required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: GlassMorphism.card(),
      child: Row(
        children: [
          Expanded(child: _LeftStats(summary: summary)),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Sparkline(
              series: TrendSeries('Wellness', [
                // placeholder small spark - consumers will pass a real series later
                TrendPoint(0, summary.wellnessScore),
                TrendPoint(1, summary.wellnessScore * 0.98),
                TrendPoint(2, summary.wellnessScore * 1.01),
                TrendPoint(3, summary.wellnessScore),
              ]),
              color: ProModeColors.accentPrimary,
              height: 48,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftStats extends StatelessWidget {
  const _LeftStats({required this.summary});
  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Clinical Overview', style: ProModeTypography.headlineMedium(context)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _MiniStat(label: 'Wellness', value: '${summary.wellnessScore.toStringAsFixed(0)}/100'),
            _MiniStat(label: 'Activity', value: summary.activityScore.toStringAsFixed(0)),
            _MiniStat(label: 'Sleep SQI', value: summary.sleepQualityIndex.isNaN ? '—' : summary.sleepQualityIndex.toStringAsFixed(0)),
            _MiniStat(label: 'MAP', value: summary.map.isNaN ? '—' : summary.map.toStringAsFixed(0)),
            _MiniStat(label: 'PP', value: summary.pulsePressure.isNaN ? '—' : summary.pulsePressure.toStringAsFixed(0)),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => HapticsHelper.medium(),
          child: Text(
            summary.bpCategory.toUpperCase(),
            style: const TextStyle(
              color: ProModeColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        )
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ProModeColors.surface(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProModeColors.surfaceBorder(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: ProModeColors.textMuted, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(color: ProModeColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}


