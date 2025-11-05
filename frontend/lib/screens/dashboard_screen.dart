import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// Dummy data for today's metrics
class TodayMetrics {
  final int stepCount;
  final int stepGoal;
  final double sleepDurationHr;
  final int restingHeartRateBpm;
  final String bloodPressureMmHg;
  final double bodyTemperatureC;
  final int spo2Percent;
  final int caloriesBurned;
  final int exerciseDurationMin;
  final String physicalActivityLevel;
  final int stressLevel;

  TodayMetrics({
    this.stepCount = 6240,
    this.stepGoal = 8000,
    this.sleepDurationHr = 7.2,
    this.restingHeartRateBpm = 72,
    this.bloodPressureMmHg = '118/76',
    this.bodyTemperatureC = 36.6,
    this.spo2Percent = 97,
    this.caloriesBurned = 1920,
    this.exerciseDurationMin = 30,
    this.physicalActivityLevel = 'active',
    this.stressLevel = 35,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TodayMetrics _today = TodayMetrics();

  String _getDayName() {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[DateTime.now().weekday - 1];
  }

  String _getDate() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[now.month - 1]} ${now.day.toString().padLeft(2, '0')}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Health',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getDayName() + ' • ' + _getDate(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Main Stats Row
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.directions_walk_rounded,
                  label: 'Steps',
                  value: '${_today.stepCount}',
                  subtitle: '${_today.stepGoal} goal',
                  progress: _today.stepCount / _today.stepGoal,
                  color: AppColors.primary,
                ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.bedtime_rounded,
                  label: 'Sleep',
                  value: '${_today.sleepDurationHr.toStringAsFixed(1)}h',
                  subtitle: 'Last night',
                  progress: _today.sleepDurationHr / 8.0,
                  color: const Color(0xFF6366F1),
                ).animate().fadeIn(duration: 200.ms, delay: 50.ms).slideX(begin: 0.1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.favorite_rounded,
                  label: 'Heart Rate',
                  value: '${_today.restingHeartRateBpm}',
                  subtitle: 'bpm resting',
                  progress: 0.72,
                  color: const Color(0xFFEF4444),
                ).animate().fadeIn(duration: 200.ms, delay: 100.ms).slideX(begin: -0.1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.bolt_rounded,
                  label: 'Calories',
                  value: '${_today.caloriesBurned}',
                  subtitle: 'burned',
                  progress: _today.caloriesBurned / 2500,
                  color: const Color(0xFFF59E0B),
                ).animate().fadeIn(duration: 200.ms, delay: 150.ms).slideX(begin: 0.1),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Vitals Section
          _SectionHeader(
            title: 'Vitals',
            icon: Icons.monitor_heart_rounded,
          ).animate().fadeIn(duration: 250.ms, delay: 200.ms),
          const SizedBox(height: 12),
          _VitalsGrid(today: _today).animate().fadeIn(duration: 300.ms, delay: 250.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),

          // Activity Summary
          _SectionHeader(
            title: 'Activity Summary',
            icon: Icons.trending_up_rounded,
          ).animate().fadeIn(duration: 250.ms, delay: 300.ms),
          const SizedBox(height: 12),
          _ActivityCard(today: _today).animate().fadeIn(duration: 300.ms, delay: 350.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),

          // Health Insights
          _InsightCard(
            text: _buildInsightText(),
          ).animate().fadeIn(duration: 300.ms, delay: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _buildInsightText() {
    final stepProgress = (_today.stepCount / _today.stepGoal * 100).round();
    if (stepProgress >= 100) {
      return 'Excellent! You\'ve exceeded your daily step goal. Keep up the great work!';
    } else if (stepProgress >= 75) {
      return 'You\'re ${100 - stepProgress}% away from your step goal. A short walk will get you there!';
    } else {
      return 'Your activity level is ${_today.physicalActivityLevel}. Consider adding a 15-minute walk to boost your steps.';
    }
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final double progress;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 4,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Text(
                      '${(progress * 100).clamp(0, 100).round()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _VitalsGrid extends StatelessWidget {
  final TodayMetrics today;

  const _VitalsGrid({required this.today});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.2 : 0.06,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _VitalRow(
            icon: Icons.monitor_heart,
            label: 'Blood Pressure',
            value: today.bloodPressureMmHg,
            unit: 'mmHg',
            color: const Color(0xFF8B5CF6),
          ),
          const Divider(height: 24),
          _VitalRow(
            icon: Icons.device_thermostat,
            label: 'Body Temperature',
            value: today.bodyTemperatureC.toStringAsFixed(1),
            unit: '°C',
            color: const Color(0xFFF97316),
          ),
          const Divider(height: 24),
          _VitalRow(
            icon: Icons.air,
            label: 'Oxygen Saturation',
            value: today.spo2Percent.toString(),
            unit: '%',
            color: const Color(0xFF10B981),
          ),
          const Divider(height: 24),
          _VitalRow(
            icon: Icons.psychology,
            label: 'Stress Level',
            value: today.stressLevel.toString(),
            unit: '/100',
            color: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}

class _VitalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _VitalRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final TodayMetrics today;

  const _ActivityCard({required this.today});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.2 : 0.06,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Exercise',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActivityStat(
                label: 'Duration',
                value: '${today.exerciseDurationMin} min',
                icon: Icons.timer_rounded,
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              _ActivityStat(
                label: 'Activity',
                value: today.physicalActivityLevel.toUpperCase(),
                icon: Icons.directions_run_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ActivityStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Insight',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
