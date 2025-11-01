import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/metrics_api.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<HealthMetricDto> _metrics = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final session = context.read<SessionProvider>();
      final jwt = session.jwt;
      if (jwt == null) throw Exception('Not authenticated');
      final list = await MetricsApi.fetchMyMetrics(jwt, days: 7);
      setState(() { _metrics = list; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final heartSpots = _metrics.isNotEmpty
        ? _metrics.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.restingHeartRateBpm.toDouble())).toList()
        : [FlSpot(0, 72), FlSpot(1, 76), FlSpot(2, 74), FlSpot(3, 78), FlSpot(4, 73), FlSpot(5, 71), FlSpot(6, 75)];
    final sleepBars = _metrics.isNotEmpty
        ? _metrics.map((m) => m.sleepDurationHr).toList()
        : [6.5, 7.2, 8.1, 5.9, 7.6, 8.0, 7.4];
    final steps = _metrics.isNotEmpty ? _metrics.last.stepCount : 5400;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Your Health Overview')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: Theme.of(context).textTheme.bodyLarge))
                : ListView(
                    children: [
                      _PeriodSelector().animate().fadeIn(duration: 250.ms),
                      const SizedBox(height: 18),
                      _buildChartCard(
                        context,
                        title: 'Heart rate trend',
                        child: SizedBox(height: 180, child: _HeartRateChart(spots: heartSpots)),
                      ),
                      const SizedBox(height: 18),
                      _buildChartCard(
                        context,
                        title: 'Sleep hours',
                        child: SizedBox(height: 180, child: _SleepBarChart(bars: sleepBars)),
                      ),
                      const SizedBox(height: 18),
                      _buildChartCard(
                        context,
                        title: 'Steps goal',
                        child: _StepsRadial(completed: steps),
                      ),
                      const SizedBox(height: 18),
                      _InsightCard(
                        text: _metrics.isNotEmpty
                            ? 'Latest: ${_metrics.last.stepCount} steps, ${_metrics.last.sleepDurationHr.toStringAsFixed(1)}h sleep, HR ${_metrics.last.restingHeartRateBpm} bpm.'
                            : 'You walked 5,400 steps yesterday — great job! Keep your momentum with a quick evening stroll.',
                      ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideY(begin: 0.2),
                      const SizedBox(height: 80),
                    ],
                  ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15);
  }
}

class _PeriodSelector extends StatefulWidget {
  @override
  State<_PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<_PeriodSelector> {
  String _period = 'Week';

  @override
  Widget build(BuildContext context) {
    final options = ['Week', 'Month'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options
          .map(
            (label) => ChoiceChip(
              label: Text(label),
              selected: _period == label,
              onSelected: (_) => setState(() => _period = label),
            ),
          )
          .toList(),
    );
  }
}

class _HeartRateChart extends StatelessWidget {
  const _HeartRateChart({required this.spots});

  final List<FlSpot> spots;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Text(labels[value.toInt()]);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF60A5FA)]),
            barWidth: 4,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.3), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepBarChart extends StatelessWidget {
  const _SleepBarChart({required this.bars});

  final List<double> bars;
  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Text(labels[value.toInt()]);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(bars.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: bars[index],
                width: 18,
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StepsRadial extends StatelessWidget {
  const _StepsRadial({required this.completed});

  final int completed;

  @override
  Widget build(BuildContext context) {
    const goal = 8000;
    final progress = completed / goal;

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 14,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$completed steps', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Goal $goal', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 8))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights_rounded, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

