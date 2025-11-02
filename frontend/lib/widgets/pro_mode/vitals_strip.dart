import 'package:flutter/material.dart';

import '../../theme/pro_mode_theme.dart';
import '../../utils/health_analytics.dart';

class VitalsStrip extends StatelessWidget {
  const VitalsStrip({super.key, required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ProModeColors.surface(0.06),
        border: Border(top: BorderSide(color: ProModeColors.surfaceBorder(0.12))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _vital('HR', '${summary.series.isNotEmpty ? summary.series.last.points.last.y.toStringAsFixed(0) : '-'} bpm'),
          _vital('BP', summary.bpCategory.toUpperCase()),
          _vital('MAP', summary.map.isNaN ? '—' : '${summary.map.toStringAsFixed(0)}'),
          _vital('PP', summary.pulsePressure.isNaN ? '—' : '${summary.pulsePressure.toStringAsFixed(0)}'),
          _vital('SI', summary.shockIndex == null ? '—' : summary.shockIndex!.toStringAsFixed(2)),
        ],
      ),
    );
  }

  Widget _vital(String k, String v) {
    return Row(
      children: [
        Text(k, style: const TextStyle(color: ProModeColors.textMuted, fontSize: 12)),
        const SizedBox(width: 6),
        Text(v, style: const TextStyle(color: ProModeColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}


