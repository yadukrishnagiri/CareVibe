import 'package:flutter/material.dart';

import '../../theme/pro_mode_theme.dart';
import '../../utils/health_analytics.dart';
import '../../utils/haptics_helper.dart';

class TopCommandBar extends StatelessWidget {
  const TopCommandBar({super.key, required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _KpiChip(
                    label: 'Shock Index',
                    value: summary.shockIndex == null ? '—' : summary.shockIndex!.toStringAsFixed(2),
                    color: _levelColor(_shockLevel(summary.shockIndex)),
                  ),
                  const SizedBox(width: 8),
                  _KpiChip(
                    label: 'Sepsis Risk',
                    value: summary.sepsisPatternLevel?.toUpperCase() ?? 'LOW',
                    color: _levelColor(summary.sepsisPatternLevel ?? 'low'),
                  ),
                  const SizedBox(width: 8),
                  _KpiChip(
                    label: 'Cardiac',
                    value: _cardiacRiskLabel(summary),
                    color: _levelColor(_cardiacRiskLevel(summary)),
                  ),
                  const SizedBox(width: 8),
                  _KpiChip(
                    label: 'Respiratory',
                    value: (summary.respiratoryDistressSeverity ?? 'none').toUpperCase(),
                    color: _levelColor(_respLevel(summary)),
                  ),
                  const SizedBox(width: 8),
                  _KpiChip(
                    label: 'Metabolic',
                    value: (summary.metabolicRiskLevel ?? 'low').toUpperCase(),
                    color: _levelColor(summary.metabolicRiskLevel ?? 'low'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _shockLevel(double? si) {
    if (si == null || si.isNaN) return 'low';
    if (si < 0.7) return 'low';
    if (si < 0.9) return 'medium';
    return 'high';
  }

  static String _cardiacRiskLevel(AnalyticsSummary s) {
    final pp = s.pulsePressure;
    if (!pp.isNaN && pp > 60) return 'high';
    switch (s.bpCategory) {
      case 'hypertension stage 2':
      case 'hypertensive crisis':
        return 'high';
      case 'hypertension stage 1':
      case 'elevated':
        return 'medium';
      default:
        return 'low';
    }
  }

  static String _cardiacRiskLabel(AnalyticsSummary s) {
    final level = _cardiacRiskLevel(s).toUpperCase();
    if (!s.pulsePressure.isNaN && s.pulsePressure > 60) {
      return '$level · PP ${s.pulsePressure.toStringAsFixed(0)}';
    }
    return level;
  }

  static String _respLevel(AnalyticsSummary s) {
    if (s.respiratoryDistressFlag == true) {
      return (s.respiratoryDistressSeverity ?? 'medium');
    }
    return 'low';
  }

  static Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return ProModeColors.riskHigh;
      case 'medium':
      case 'moderate':
        return ProModeColors.riskMedium;
      default:
        return ProModeColors.riskLow;
    }
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticsHelper.light(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ProModeColors.surface(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.9), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: ProModeColors.textPrimary, fontSize: 12)),
            const SizedBox(width: 8),
            Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}


