import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../services/metrics_api.dart';
import '../theme/app_theme.dart';
import '../utils/health_analytics.dart';
import '../utils/exporters.dart';
import '../theme/pro_mode_theme.dart';
import '../widgets/pro_mode/top_command_bar.dart';
import '../widgets/pro_mode/clinical_overview_card.dart';
import '../widgets/pro_mode/surface_organ_health.dart';
import '../widgets/pro_mode/vitals_strip.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<HealthMetricDto> _metrics = [];
  AnalyticsSummary? _summary;
  bool _loading = false;
  String? _error;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _proMode = false;

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final session = context.read<SessionProvider>();
      final jwt = session.jwt;
      if (jwt == null) throw Exception('Not authenticated');
      
      // Validate date range
      if (_startDate == null || _endDate == null) {
        throw Exception('Please select a valid date range');
      }
      
      if (_startDate!.isAfter(_endDate!)) {
        throw Exception('Start date must be before end date');
      }
      
      // Fetch metrics using date range
      final list = await MetricsApi.fetchMyMetrics(
        jwt, 
        startDate: _startDate, 
        endDate: _endDate
      );
      
      if (list.isEmpty) {
        setState(() {
          _metrics = [];
          _summary = null;
          _error = 'No health data available for the selected date range';
        });
        return;
      }
      
      final summary = computeAnalytics(list);
      setState(() { 
        _metrics = list; 
        _summary = summary; 
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _load();
    }
  }

  String _formatDateRange() {
    if (_startDate == null || _endDate == null) return 'Select dates';
    final start = '${_startDate!.month}/${_startDate!.day}';
    final end = '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}';
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: _proMode ? const Color(0xFF0B0F17) : Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Analytics'),
          actions: [
            TextButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(_formatDateRange(), style: const TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Reset to last 30 days',
              onPressed: () {
                setState(() {
                  _endDate = DateTime.now();
                  _startDate = _endDate!.subtract(const Duration(days: 30));
                });
                _load();
              },
            ),
            const SizedBox(width: 4),
            _ModeToggle(
              value: _proMode,
              onChanged: (v) => setState(() => _proMode = v),
            ),
            IconButton(
              tooltip: 'Export',
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => _openExportSheet(context),
            ),
            const SizedBox(width: 6),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Sleep'),
              Tab(text: 'Activity'),
              Tab(text: 'Heart'),
              Tab(text: 'Stress'),
              Tab(text: 'Weight'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text(_error!, style: Theme.of(context).textTheme.bodyLarge)),
                  )
                : s == null
                    ? const SizedBox.shrink()
                    : TabBarView(
                        children: [
                          _proMode
                              ? _ProOverview(summary: s, metrics: _metrics).animate().fadeIn(duration: 200.ms)
                              : _OverviewTab(summary: s, metrics: _metrics, proMode: false).animate().fadeIn(duration: 200.ms),
                          _SleepTab(metrics: _metrics, proMode: _proMode).animate().fadeIn(duration: 200.ms),
                          _ActivityTab(metrics: _metrics, summary: s, proMode: _proMode).animate().fadeIn(duration: 200.ms),
                          _HeartTab(metrics: _metrics, summary: s, proMode: _proMode).animate().fadeIn(duration: 200.ms),
                          _StressTab(metrics: _metrics, proMode: _proMode).animate().fadeIn(duration: 200.ms),
                          _WeightTab(metrics: _metrics, proMode: _proMode).animate().fadeIn(duration: 200.ms),
                        ],
                      ),
        bottomNavigationBar: _proMode && s != null ? VitalsStrip(summary: s) : null,
      ),
    );
  }

  void _openExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bottomSheetContext) {
        final s = _summary;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.picture_as_pdf_rounded, color: Theme.of(context).colorScheme.primary),
                title: const Text('Share PDF report'),
                onTap: () async {
                  Navigator.of(bottomSheetContext).pop();
                  
                  if (_metrics.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No data available to export')),
                      );
                    }
                    return;
                  }
                  
                  if (s != null && _startDate != null && _endDate != null) {
                    final session = context.read<SessionProvider>();
                    final jwt = session.jwt;
                    if (jwt != null) {
                      try {
                        await shareAnalyticsPdf(
                          summary: s,
                          data: _metrics,
                          jwt: jwt,
                          startDate: _startDate!,
                          endDate: _endDate!,
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to generate PDF: ${e.toString()}')),
                          );
                        }
                      }
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.table_rows_rounded, color: Theme.of(context).colorScheme.primary),
                title: const Text('Export CSV'),
                onTap: () async {
                  Navigator.of(bottomSheetContext).pop();
                  
                  if (_metrics.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No data available to export')),
                      );
                    }
                    return;
                  }
                  
                  try {
                    await shareCsv(_metrics);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to export CSV: ${e.toString()}')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartCard(BuildContext context, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _proMode
                ? const TextStyle(color: ProModeColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)
                : Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.14),
      ),
      child: Row(
        children: [
          Text('User', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 6),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
          const SizedBox(width: 6),
          Row(
            children: const [
              Icon(Icons.medical_information_outlined, size: 18),
              SizedBox(width: 4),
              Text('Pro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.summary, required this.metrics, required this.proMode});
  final AnalyticsSummary summary;
  final List<HealthMetricDto> metrics;
  final bool proMode;

  @override
  Widget build(BuildContext context) {
    final notes = clinicianSummary(summary, metrics);
    return RefreshIndicator(
      onRefresh: () async {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: ListView(
          children: [
            _OverviewCards(summary: summary, proMode: proMode),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Blood Pressure (MAP & Pulse Pressure)',
              proMode: proMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BpInfo(summary: summary),
                  if (proMode) ...[
                    const SizedBox(height: 14),
                    _ProInsight(text: 'ACC/AHA guidance · Monitor if MAP >100 mmHg or Pulse Pressure >60 mmHg repeatedly.'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (summary.alerts.isNotEmpty)
              _SectionCard(
                title: proMode ? 'Alerts & clinical notes' : 'Alerts',
                proMode: proMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (proMode && notes.isNotEmpty) ...[
                      Text('Clinical synthesis', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      for (final n in notes)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(n)),
                            ],
                          ),
                        ),
                      if (summary.alerts.isNotEmpty) const Divider(height: 24),
                    ],
                    if (summary.alerts.isEmpty)
                      Text('No active alerts. Continue current plan.', style: Theme.of(context).textTheme.bodyMedium)
                    else ...summary.alerts.map((a) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                a.level == 'high' ? Icons.warning_amber_rounded : a.level == 'medium' ? Icons.error_outline : Icons.info_outline,
                                color: a.level == 'high' ? Colors.red : a.level == 'medium' ? Colors.orange : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(a.message)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProOverview extends StatelessWidget {
  const _ProOverview({required this.summary, required this.metrics});
  final AnalyticsSummary summary;
  final List<HealthMetricDto> metrics;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        children: [
          const SizedBox(height: 8),
          TopCommandBar(summary: summary),
          const SizedBox(height: 12),
          ClinicalOverviewCard(summary: summary),
          const SizedBox(height: 16),
          SurfaceOrganHealth(summary: summary, metrics: metrics),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SleepTab extends StatelessWidget {
  const _SleepTab({required this.metrics, required this.proMode});
  final List<HealthMetricDto> metrics;
  final bool proMode;

  @override
  Widget build(BuildContext context) {
    final sleepSeries = buildSleepHoursSeries(metrics);
    final remSeries = buildSleepRemPctSeries(metrics);
    final debt7 = sleepDebtHours(metrics, days: 7);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Sleep Debt (7d)',
                  value: '${debt7.toStringAsFixed(1)} h',
                  subtitle: proMode ? 'Guide: keep <3 h over 7 days' : null,
                  proMode: proMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Avg REM % (latest)',
                  value: remSeries.points.isEmpty ? '—' : '${remSeries.points.last.y.toStringAsFixed(0)}%',
                  subtitle: proMode ? 'Optimal 20–25%' : null,
                  proMode: proMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Sleep Hours',
            proMode: proMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 220, child: _LineChartSimple(series: [sleepSeries], colors: const [AppColors.primary])),
                if (proMode) ...[
                  const SizedBox(height: 12),
                  _ProInsight(text: 'Avg sleep ${sleepSeries.points.isEmpty ? '—' : (sleepSeries.points.last.y).toStringAsFixed(1)} h · Variability to monitor if stdev >0.9h over 14d.'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'REM Percentage',
            proMode: proMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 220, child: _LineChartSimple(series: [remSeries], colors: const [Color(0xFFF59E0B)])),
                if (proMode) ...[
                  const SizedBox(height: 12),
                  _ProInsight(text: 'Ideal REM 20–25%. Watch sustained dips <15% or spikes >30% with fatigue.'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.metrics, required this.summary, required this.proMode});
  final List<HealthMetricDto> metrics;
  final AnalyticsSummary summary;
  final bool proMode;

  @override
  Widget build(BuildContext context) {
    final stepsSeries = buildStepsSeries(metrics);
    final wam = weeklyActiveMinutes(metrics);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Activity Score',
                  value: summary.activityScore.toStringAsFixed(0),
                  subtitle: proMode ? 'Weighted steps + active minutes' : null,
                  proMode: proMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Active Minutes (7d)',
                  value: '$wam',
                  subtitle: proMode ? 'Guideline ≥150' : null,
                  proMode: proMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Steps Trend',
            proMode: proMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 220, child: _LineChartSimple(series: [stepsSeries], colors: const [AppColors.primary])),
                if (proMode) ...[
                  const SizedBox(height: 12),
                  _ProInsight(text: 'Activity Score weights steps (50%) + active minutes (50%). Flag <6000 avg steps or <150 weekly mins.'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartTab extends StatelessWidget {
  const _HeartTab({required this.metrics, required this.summary, required this.proMode});
  final List<HealthMetricDto> metrics;
  final AnalyticsSummary summary;
  final bool proMode;

  @override
  Widget build(BuildContext context) {
    final hr = buildRestingHrSeries(metrics);
    final hrVals = hr.points.map((e) => e.y).toList();
    final sma7 = simpleMovingAverage(hrVals, 7);
    final smaSeries = TrendSeries('HR (7d MA)', [
      for (int i = 0; i < sma7.length; i++) TrendPoint((i + 6).toDouble(), sma7[i])
    ]);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'MAP',
                  value: summary.map.isNaN ? '—' : summary.map.toStringAsFixed(0),
                  subtitle: proMode ? 'Goal 70–100' : null,
                  proMode: proMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Pulse Pressure',
                  value: summary.pulsePressure.isNaN ? '—' : summary.pulsePressure.toStringAsFixed(0),
                  subtitle: proMode ? 'Alert >60' : null,
                  proMode: proMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'BP Category',
            proMode: proMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BpInfo(summary: summary),
                if (proMode) ...[
                  const SizedBox(height: 12),
                  _ProInsight(text: 'Target: <120/<80. Review if stage 1 persists 2+ weeks or stage 2 immediately.'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Resting Heart Rate (with 7-day MA)',
            proMode: proMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 220, child: _LineChartSimple(series: [hr, smaSeries], colors: const [AppColors.primary, Color(0xFF22C55E)])),
                if (proMode) ...[
                  const SizedBox(height: 12),
                  _ProInsight(text: 'Trending slope ${smaSeries.points.isEmpty ? '—' : (smaSeries.points.last.y - smaSeries.points.first.y).toStringAsFixed(1)} bpm / month. Flag >90 bpm resting or sustained upward slope.'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StressTab extends StatelessWidget {
  const _StressTab({required this.metrics, required this.proMode});
  final List<HealthMetricDto> metrics;
  final bool proMode;

  @override
  Widget build(BuildContext context) {
    final s1 = buildStressSeries(metrics);
    final s2 = buildStressSma7Series(metrics);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ListView(
        children: [
          _SectionCard(
            title: 'Stress Trend (with 7-day MA)',
            proMode: proMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 220, child: _LineChartSimple(series: [s1, s2], colors: const [AppColors.primary, Color(0xFF22C55E)])),
                if (proMode) ...[
                  const SizedBox(height: 12),
                  _ProInsight(text: 'Scores >60 sustained signal high stress load. Use MA to validate downward trend before de-escalating support.'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightTab extends StatelessWidget {
  const _WeightTab({required this.metrics, required this.proMode});
  final List<HealthMetricDto> metrics;
  final bool proMode;

  @override
  Widget build(BuildContext context) {
    final w = buildWeightSeries(metrics);
    final b = buildBmiSeries(metrics);
    final latestBmi = b.points.isEmpty ? null : b.points.last.y;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'BMI',
                  value: latestBmi == null || latestBmi == 0 ? '—' : latestBmi.toStringAsFixed(1),
                  subtitle: proMode ? 'Target 18.5–24.9' : null,
                  proMode: proMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Weight (latest)',
                  value: w.points.isEmpty || w.points.last.y == 0 ? '—' : '${w.points.last.y.toStringAsFixed(1)} kg',
                  subtitle: proMode ? 'Compare to 30d avg' : null,
                  proMode: proMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Weight Trend',
            proMode: proMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 220, child: _LineChartSimple(series: [w], colors: const [AppColors.primary])),
                if (proMode) ...[
                  const SizedBox(height: 12),
                  _ProInsight(text: 'Monitor ≥5% change within 3 months or rapid deviations with symptoms.'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'BMI Trend',
            proMode: proMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 220, child: _LineChartSimple(series: [b], colors: const [Color(0xFFF59E0B)])),
                if (proMode) ...[
                  const SizedBox(height: 12),
                  _ProInsight(text: 'Goal 18.5–24.9. Combine with waist circumference for cardiometabolic risk assessment.'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.proMode = false});
  final String title;
  final Widget child;
  final bool proMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: proMode
          ? GlassMorphism.card(borderOpacity: 0.12, radius: 24)
          : BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 12)),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LineChartSimple extends StatelessWidget {
  const _LineChartSimple({required this.series, required this.colors});
  final List<TrendSeries> series;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grid = isDark ? Colors.white.withOpacity(0.18) : AppColors.textSecondary.withOpacity(0.08);
    final border = isDark ? Colors.white.withOpacity(0.22) : AppColors.textSecondary.withOpacity(0.12);
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: grid, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: border, width: 1)),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 10,
            tooltipMargin: 12,
            getTooltipItems: (spots) => List.generate(spots.length, (index) {
              final s = spots[index];
              final col = colors[index % colors.length];
              return LineTooltipItem('${s.y.toStringAsFixed(1)}', TextStyle(color: col, fontWeight: FontWeight.w600));
            }),
          ),
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          for (int i = 0; i < series.length; i++)
            LineChartBarData(
              spots: series[i].points.map((p) => FlSpot(p.x, p.y)).toList(),
              isCurved: true,
              gradient: LinearGradient(colors: [colors[i % colors.length], colors[i % colors.length].withOpacity(0.4)]),
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [colors[i % colors.length].withOpacity(0.18), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProInsight extends StatelessWidget {
  const _ProInsight({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.insights_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).brightness == Brightness.dark
                ? const TextStyle(color: Colors.white70, fontSize: 12)
                : Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({required this.summary, required this.proMode});
  final AnalyticsSummary summary;
  final bool proMode;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _MetricTile(
        label: 'Wellness',
        value: '${summary.wellnessScore.toStringAsFixed(0)}/100',
        subtitle: proMode ? 'Weighted: Vitals 30 · Sleep 25 · Activity 25 · Metabolic 10 · Stress 10' : null,
        proMode: proMode,
      ),
      _MetricTile(
        label: 'Activity',
        value: summary.activityScore.toStringAsFixed(0),
        subtitle: proMode ? 'Target ≥150 active min & 10k steps daily' : null,
        proMode: proMode,
      ),
      _MetricTile(
        label: 'Sleep SQI',
        value: summary.sleepQualityIndex.isNaN ? '—' : summary.sleepQualityIndex.toStringAsFixed(0),
        subtitle: proMode ? 'Blend of duration, REM %, interruptions (ideal ≥75)' : null,
        proMode: proMode,
      ),
      _MetricTile(
        label: 'REM %',
        value: summary.remPercent.isNaN ? '—' : '${summary.remPercent.toStringAsFixed(0)}%',
        subtitle: proMode ? 'Optimal 20–25%. Flag <15% or >30% consistently' : null,
        proMode: proMode,
      ),
      _MetricTile(
        label: 'MAP',
        value: summary.map.isNaN ? '—' : summary.map.toStringAsFixed(0),
        subtitle: proMode ? 'Expected range 70–100 mmHg' : null,
        proMode: proMode,
      ),
      _MetricTile(
        label: 'Pulse Pressure',
        value: summary.pulsePressure.isNaN ? '—' : summary.pulsePressure.toStringAsFixed(0),
        subtitle: proMode ? 'Alert if >60 mmHg at rest' : null,
        proMode: proMode,
      ),
      _MetricTile(
        label: 'BP Category',
        value: summary.bpCategory,
        subtitle: proMode ? 'ACC/AHA classification' : null,
        proMode: proMode,
      ),
      _MetricTile(
        label: 'Active minutes (7d)',
        value: '${summary.weeklyActiveMinutes}',
        subtitle: proMode ? 'Guideline: ≥150 min/week moderate intensity' : null,
        proMode: proMode,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.9,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: tiles.length,
      itemBuilder: (_, i) => tiles[i],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value, this.subtitle, this.proMode = false});
  final String label;
  final String value;
  final String? subtitle;
  final bool proMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: proMode
          ? GlassMorphism.card(borderOpacity: 0.12, radius: 20)
          : BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 10)),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: proMode
                ? const TextStyle(color: ProModeColors.textMuted)
                : Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: proMode
                ? const TextStyle(color: ProModeColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)
                : Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: proMode
                  ? const TextStyle(color: ProModeColors.textMuted, fontSize: 12)
                  : Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _MultiLineChart extends StatelessWidget {
  const _MultiLineChart({required this.series});
  final List<TrendSeries> series;

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.primary, const Color(0xFF22C55E), const Color(0xFFF59E0B)];
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          for (int i = 0; i < series.length; i++)
            LineChartBarData(
              spots: series[i].points.map((p) => FlSpot(p.x, p.y)).toList(),
              isCurved: true,
              color: colors[i % colors.length],
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
        ],
      ),
    );
  }
}

class _BpInfo extends StatelessWidget {
  const _BpInfo({required this.summary});
  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _infoChip('MAP', summary.map.isNaN ? '—' : '${summary.map.toStringAsFixed(0)} mmHg'),
        _infoChip('Pulse Pressure', summary.pulsePressure.isNaN ? '—' : '${summary.pulsePressure.toStringAsFixed(0)} mmHg'),
        _infoChip('Category', summary.bpCategory),
      ],
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.primary.withOpacity(0.06),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


