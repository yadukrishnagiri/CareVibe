import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../utils/health_analytics.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.series, this.color = const Color(0xFF2563EB), this.height = 36});

  final TrendSeries series;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.2)]);
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(enabled: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: series.points.map((p) => FlSpot(p.x, p.y)).toList(),
              isCurved: true,
              gradient: gradient,
              barWidth: 2.5,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [color.withOpacity(0.18), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            ),
          ],
        ),
      ),
    );
  }
}


