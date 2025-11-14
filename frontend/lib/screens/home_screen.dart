import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/shell_controller.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api.dart';
import '../services/metrics_api.dart';
import '../services/medication_api.dart';
import '../services/weather_service.dart';
import '../utils/health_analytics.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<AppointmentSummary>> _appointmentsFuture;
  late Future<HealthMetricDto?> _todayMetricsFuture;
  late Future<HealthMetricDto?> _yesterdayMetricsFuture;

  @override
  void initState() {
    super.initState();
    // Initialize with placeholder futures, then update after first frame
    _appointmentsFuture = Future.value(<AppointmentSummary>[]);
    _todayMetricsFuture = Future.value(null);
    _yesterdayMetricsFuture = Future.value(null);
    
    // Use post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _appointmentsFuture = _fetchAppointments();
          _todayMetricsFuture = _fetchTodayMetrics();
          _yesterdayMetricsFuture = _fetchYesterdayMetrics();
        });
      }
    });
  }

  Future<HealthMetricDto?> _fetchTodayMetrics() async {
    if (!mounted) return null;
    final session = context.read<SessionProvider>();
    if (!session.isAuthenticated || session.jwt == null) return null;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      final metrics = await MetricsApi.fetchMyMetrics(
        session.jwt!,
        startDate: today,
        endDate: tomorrow,
      );
      
      if (metrics.isNotEmpty) {
        // Find today's metric or use the most recent one
        for (var metric in metrics) {
          final metricDate = DateTime(metric.date.year, metric.date.month, metric.date.day);
          if (metricDate == today) {
            return metric;
          }
        }
        return metrics.last;
      }
    } catch (e) {
      debugPrint('Failed to fetch today metrics: $e');
    }
    return null;
  }

  Future<HealthMetricDto?> _fetchYesterdayMetrics() async {
    if (!mounted) return null;
    final session = context.read<SessionProvider>();
    if (!session.isAuthenticated || session.jwt == null) return null;

    try {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      final today = DateTime(now.year, now.month, now.day);
      
      final metrics = await MetricsApi.fetchMyMetrics(
        session.jwt!,
        startDate: yesterday,
        endDate: today,
      );
      
      if (metrics.isNotEmpty) {
        // Find yesterday's metric
        for (var metric in metrics) {
          final metricDate = DateTime(metric.date.year, metric.date.month, metric.date.day);
          if (metricDate == yesterday) {
            return metric;
          }
        }
        // Return most recent if exact match not found
        return metrics.first;
      }
    } catch (e) {
      debugPrint('Failed to fetch yesterday metrics: $e');
    }
    return null;
  }

  Future<List<AppointmentSummary>> _fetchAppointments() async {
    if (!mounted) return [];
    final session = context.read<SessionProvider>();
    if (!session.isAuthenticated) return [];

    try {
      // For demo mode, use demo UID, otherwise use Firebase UID
      final userId = session.isDemoMode
          ? (session.demoUserInfo?['uid'] as String? ?? 'demo-user')
          : (session.firebaseUser?.uid ?? '');
      
      if (userId.isEmpty) return [];
      
      final res = await http.get(
        Uri.parse('$apiBase/appointments/$userId'),
        headers: authHeaders(session.jwt!),
      );
      if (res.statusCode == 200) {
        final List<dynamic> json = jsonDecode(res.body) as List<dynamic>;
        return json
            .map((item) => AppointmentSummary(
                  doctorName: item['doctorName']?.toString() ?? 'Specialist',
                  date: DateTime.tryParse(item['date']?.toString() ?? '') ?? DateTime.now(),
                  notes: item['notes']?.toString(),
                ))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load appointments: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final name = session.isDemoMode
        ? (session.demoUserInfo?['displayName'] as String? ?? 'Demo User')
        : (session.firebaseUser?.displayName ?? 'Patient');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          setState(() {
            _appointmentsFuture = _fetchAppointments();
            _todayMetricsFuture = _fetchTodayMetrics();
            _yesterdayMetricsFuture = _fetchYesterdayMetrics();
          });
          await Future.wait([
            _appointmentsFuture,
            _todayMetricsFuture,
            _yesterdayMetricsFuture,
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              pinned: true,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,', style: Theme.of(context).textTheme.bodyMedium),
                  Text(name, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
                    ),
                    onPressed: () {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      // Toggle via ThemeProvider
                      // ignore: use_build_context_synchronously
                      context.read<ThemeProvider>().toggle(!isDark);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications are coming soon!')),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroBanner(name).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                    const SizedBox(height: 24),
                    _buildProfileSection(context).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: 24),
                    // Health Score Card
                    _HealthScoreCard(future: _todayMetricsFuture)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 100.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 24),
                    // Climate Card
                    const _ClimateCard()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 16),
                    // Air Quality Card
                    const _AqiCard()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 250.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 24),
                    Text('Upcoming appointments', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    FutureBuilder<List<AppointmentSummary>>(
                      future: _appointmentsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final items = snapshot.data ?? [];
                        if (items.isEmpty) {
                          return _EmptyStateCard(title: 'No upcoming visits', subtitle: 'Schedule with a specialist to keep track of your care.');
                        }
                        return Column(
                          children: items
                              .map((appointment) => _AppointmentCard(appointment: appointment))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Today vs Yesterday Comparison
                    _ComparisonCard(
                      todayFuture: _todayMetricsFuture,
                      yesterdayFuture: _yesterdayMetricsFuture,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 24),
                    // Medication Reminders
                    _MedicationRemindersCard()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 400.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 24),
                    _AITipBanner(name: name),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF3A7AFE), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 18, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good to see you, $name',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Let’s take care of your health today. Check reminders or ask our AI for guidance.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.85))),
          const SizedBox(height: 16),
          Builder(
            builder: (context) => FilledButton.tonal(
              onPressed: () => Scaffold.of(context).openDrawer(),
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
              child: const Text('View Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final user = session.firebaseUser;
    final photoUrl = user?.photoURL;
    final email = session.isDemoMode
        ? (session.demoUserInfo?['email'] as String? ?? 'Not provided')
        : (user?.email ?? 'Not provided');
    final displayName = session.isDemoMode
        ? (session.demoUserInfo?['displayName'] as String? ?? 'Demo User')
        : (session.firebaseUser?.displayName ?? 'User');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? const Icon(Icons.person, color: AppColors.primary) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(email, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              final scaffold = ScaffoldMessenger.of(context);
              try {
                final auth = AuthProvider(context.read<SessionProvider>());
                await auth.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
              } catch (e) {
                scaffold.showSnackBar(const SnackBar(content: Text('Failed to logout. Please try again.')));
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }


  void _jumpToTab(int index) {
    final nav = context.read<ShellController>();
    nav.jumpToIndex(index);
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature coming soon in this demo.')),
    );
  }
}

class AppointmentSummary {
  AppointmentSummary({required this.doctorName, required this.date, this.notes});

  final String doctorName;
  final DateTime date;
  final String? notes;
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final AppointmentSummary appointment;

  @override
  Widget build(BuildContext context) {
    final formattedDate = '${appointment.date.day}/${appointment.date.month}/${appointment.date.year} · ${TimeOfDay.fromDateTime(appointment.date).format(context)}';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 26, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctorName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    appointment.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appointment actions coming soon.')),
            ),
            icon: Icon(
              Icons.more_horiz,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking flow coming soon.')),
            ),
            child: const Text('Book appointment'),
          ),
        ],
      ),
    );
  }
}

class _AITipBanner extends StatelessWidget {
  const _AITipBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi $name! Here’s a wellness tip:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  'A 10-minute walk after meals can improve your digestion and help regulate blood sugar levels.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 500.ms).slideY(begin: 0.2);
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled ? AppColors.textSecondary.withOpacity(0.4) : AppColors.primary;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ).animate().scale(begin: const Offset(0.95, 0.95), duration: 300.ms, curve: Curves.easeOutBack),
    );
  }
}

// Health Score Card
class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({required this.future});

  final Future<HealthMetricDto?> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HealthMetricDto?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final metric = snapshot.data;
        double score = 0;
        String status = 'Calculating...';
        Color statusColor = AppColors.primary;
        String insight = '';

        if (metric != null) {
          score = wellnessScoreSimplified(metric);
          
          if (score >= 80) {
            status = 'Excellent';
            statusColor = const Color(0xFF10B981); // Green
            insight = 'You\'re maintaining excellent health! Keep up the great work.';
          } else if (score >= 60) {
            status = 'Good';
            statusColor = const Color(0xFF3B82F6); // Blue
            insight = 'Your health is in good shape. Small improvements can boost your score even higher.';
          } else if (score >= 40) {
            status = 'Fair';
            statusColor = const Color(0xFFF59E0B); // Orange
            insight = 'There\'s room for improvement. Focus on sleep, activity, and stress management.';
          } else {
            status = 'Poor';
            statusColor = const Color(0xFFEF4444); // Red
            insight = 'Consider consulting with a healthcare provider and focusing on key health metrics.';
          }
        } else {
          score = 0;
          status = 'No Data';
          statusColor = AppColors.textSecondary;
          insight = 'Start tracking your health metrics to see your score.';
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusColor.withOpacity(0.15),
                statusColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: statusColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Score',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          score.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '/ 100',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      insight,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      backgroundColor: statusColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                    Text(
                      '${(score / 100 * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Climate Card (Weather)
class _ClimateCard extends StatefulWidget {
  const _ClimateCard();

  @override
  State<_ClimateCard> createState() => _ClimateCardState();
}

class _ClimateCardState extends State<_ClimateCard> {
  WeatherData? _weatherData;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final weatherService = WeatherService();
      WeatherData? weatherData;
      
      // Try to get user's location first
      Position? position;
      try {
        position = await _getUserLocation();
      } catch (e) {
        print('[ClimateCard] Location error: $e');
        _error = 'Location access denied. Please enable location permissions for CareVibe.';
      }

      if (position != null) {
        print('[ClimateCard] Location obtained: ${position.latitude}, ${position.longitude}');
        weatherData = await weatherService.getWeatherByCoordinates(
          position.latitude,
          position.longitude,
        );
      } else {
        // If location failed, use default city as a fallback
        print('[ClimateCard] Location not available, using default city');
        weatherData = await weatherService.getWeatherByCity('London');
      }

      if (mounted) {
        setState(() {
          _weatherData = weatherData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<Position?> _getUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.cloud_rounded;
      case 'rain':
      case 'drizzle':
        return Icons.water_drop_rounded;
      case 'thunderstorm':
        return Icons.flash_on_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.cloud_queue_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  Color _getAqiColor(int? aqiLevel) {
    if (aqiLevel == null) return Colors.white.withOpacity(0.3);
    
    switch (aqiLevel) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.white.withOpacity(0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (_error.isNotEmpty || _weatherData == null) {
      // Fallback to demo data if there's an error
      final temp = 22;
      final condition = 'Sunny';
      final tip = 'Perfect weather for a walk! Aim for 30 minutes of outdoor activity today.';

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$temp°C',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        condition,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tip,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '(Demo data - $_error)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      );
    }

    final weather = _weatherData!;
    final temp = weather.temperature.round();
    final condition = weather.condition;
    final tip = weather.getHealthTip();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
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
              Icon(
                _getWeatherIcon(condition),
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$temp°C',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      condition,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchWeather,
                tooltip: 'Refresh weather',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tip,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (weather.cityName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '📍 ${weather.cityName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// Air Quality Index (AQI) Card
class _AqiCard extends StatefulWidget {
  const _AqiCard();

  @override
  State<_AqiCard> createState() => _AqiCardState();
}

class _AqiCardState extends State<_AqiCard> {
  WeatherData? _weatherData;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final weatherService = WeatherService();
      WeatherData? weatherData;
      
      // Try to get user's location first
      Position? position;
      try {
        position = await _getUserLocation();
      } catch (e) {
        print('[AqiCard] Location error: $e');
        _error = 'Location access denied.';
      }

      if (position != null) {
        print('[AqiCard] Location obtained: ${position.latitude}, ${position.longitude}');
        weatherData = await weatherService.getWeatherByCoordinates(
          position.latitude,
          position.longitude,
        );
      } else {
        // If location failed, use default city as a fallback
        print('[AqiCard] Location not available, using default city');
        weatherData = await weatherService.getWeatherByCity('London');
      }

      if (mounted) {
        setState(() {
          _weatherData = weatherData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<Position?> _getUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Color _getAqiColor(int? aqiLevel) {
    if (aqiLevel == null) return Colors.grey;
    
    switch (aqiLevel) {
      case 1:
        return const Color(0xFF10B981); // Green
      case 2:
        return const Color(0xFF84CC16); // Light Green
      case 3:
        return const Color(0xFFF59E0B); // Orange
      case 4:
        return const Color(0xFFEF4444); // Red
      case 5:
        return const Color(0xFF9333EA); // Purple
      default:
        return Colors.grey;
    }
  }

  String _getAqiAdvice(int? aqiLevel) {
    if (aqiLevel == null) {
      return 'Air quality data unavailable. Exercise with caution.';
    }
    
    switch (aqiLevel) {
      case 1:
        return 'Air quality is excellent. Perfect for outdoor activities!';
      case 2:
        return 'Air quality is good. Enjoy your outdoor activities.';
      case 3:
        return 'Moderate air quality. Sensitive individuals should reduce prolonged outdoor exertion.';
      case 4:
        return 'Poor air quality detected. Consider staying indoors and using an air purifier.';
      case 5:
        return 'Very poor air quality! Avoid outdoor activities. Stay indoors with air purification.';
      default:
        return 'Air quality data unavailable.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.purple.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            height: 40,
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (_error.isNotEmpty || _weatherData == null || _weatherData!.aqi == null) {
      // Fallback to demo data if there's an error or no AQI data
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade400, Colors.grey.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
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
                const Icon(Icons.air_rounded, color: Colors.white, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AQI Unavailable',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unable to fetch air quality data',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final aqi = _weatherData!.aqi!;
    final aqiColor = _getAqiColor(aqi.level);
    final aqiAdvice = _getAqiAdvice(aqi.level);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            aqiColor.withOpacity(0.8),
            aqiColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: aqiColor.withOpacity(0.3),
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
              const Icon(Icons.air_rounded, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AQI: ${aqi.getLevelDescription()}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Air Quality Index',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchWeather,
                tooltip: 'Refresh AQI',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            aqiAdvice,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Today vs Yesterday Comparison
class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.todayFuture,
    required this.yesterdayFuture,
  });

  final Future<HealthMetricDto?> todayFuture;
  final Future<HealthMetricDto?> yesterdayFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, HealthMetricDto?>>(
      future: Future.wait([
        todayFuture,
        yesterdayFuture,
      ]).then((results) => {
        'today': results[0],
        'yesterday': results[1],
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final today = snapshot.data?['today'];
        final yesterday = snapshot.data?['yesterday'];

        if (today == null && yesterday == null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'No data available for comparison',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        final metrics = [
          _ComparisonMetric(
            label: 'Steps',
            todayValue: (today?.stepCount ?? 0).toDouble(),
            yesterdayValue: (yesterday?.stepCount ?? 0).toDouble(),
            format: (v) => '${(v / 1000).toStringAsFixed(1)}k',
          ),
          _ComparisonMetric(
            label: 'Sleep',
            todayValue: today?.sleepDurationHr ?? 0,
            yesterdayValue: yesterday?.sleepDurationHr ?? 0,
            format: (v) => '${v.toStringAsFixed(1)}h',
          ),
          _ComparisonMetric(
            label: 'Heart Rate',
            todayValue: today?.restingHeartRateBpm.toDouble() ?? 0,
            yesterdayValue: yesterday?.restingHeartRateBpm.toDouble() ?? 0,
            format: (v) => '${v.toInt()} bpm',
          ),
          _ComparisonMetric(
            label: 'SpO₂',
            todayValue: today?.spo2Percent?.toDouble() ?? 0,
            yesterdayValue: yesterday?.spo2Percent?.toDouble() ?? 0,
            format: (v) => '${v.toInt()}%',
          ),
        ];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today vs Yesterday',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: metrics.map((metric) {
                  final change = metric.todayValue - metric.yesterdayValue;
                  final percentChange = metric.yesterdayValue > 0
                      ? (change / metric.yesterdayValue * 100).abs()
                      : 0.0;
                  final isPositive = change > 0 || (change == 0 && metric.todayValue > 0);
                  
                  return Container(
                    width: (MediaQuery.of(context).size.width - 64) / 2,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isPositive
                            ? const Color(0xFF10B981).withOpacity(0.3)
                            : const Color(0xFFEF4444).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                metric.format(metric.todayValue),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            if (metric.yesterdayValue > 0)
                              Row(
                                children: [
                                  Icon(
                                    change > 0 ? Icons.arrow_upward : change < 0 ? Icons.arrow_downward : Icons.remove,
                                    size: 16,
                                    color: change > 0
                                        ? const Color(0xFF10B981)
                                        : change < 0
                                            ? const Color(0xFFEF4444)
                                            : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${percentChange.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: change > 0
                                          ? const Color(0xFF10B981)
                                          : change < 0
                                              ? const Color(0xFFEF4444)
                                              : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComparisonMetric {
  _ComparisonMetric({
    required this.label,
    required this.todayValue,
    required this.yesterdayValue,
    required this.format,
  });

  final String label;
  final double todayValue;
  final double yesterdayValue;
  final String Function(double) format;
}

// Medication Reminders Card
class _MedicationRemindersCard extends StatelessWidget {
  const _MedicationRemindersCard();

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionProvider>(context);
    final jwt = session.jwt;
    
    if (jwt == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<MedicationReminderDto>>(
      future: MedicationApi.getTodayReminders(jwt),
      builder: (context, snapshot) {
        final medications = snapshot.data ?? [];

        return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Medication Reminders',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 24),
                color: AppColors.primary,
                onPressed: () {
                  Navigator.pushNamed(context, '/medications');
                },
                tooltip: 'Add Medication',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (snapshot.connectionState == ConnectionState.waiting)
            const Center(child: CircularProgressIndicator())
          else if (medications.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blueGrey.withOpacity(0.1),
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No medications scheduled',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...medications.take(3).map((med) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.medication_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              med.dosage,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          med.time,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
        );
      },
    );
  }
}
