import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/shell_controller.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<AppointmentSummary>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = _fetchAppointments();
  }

  Future<List<AppointmentSummary>> _fetchAppointments() async {
    final session = context.read<SessionProvider>();
    if (!session.isAuthenticated) return [];

    try {
      final res = await http.get(
        Uri.parse('$apiBase/appointments/${session.firebaseUser!.uid}'),
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
    final name = session.firebaseUser?.displayName ?? 'Patient';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          setState(() {
            _appointmentsFuture = _fetchAppointments();
          });
          await _appointmentsFuture;
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
                    Text('Health snapshot', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildHealthSnapshot(),
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
    final email = user?.email ?? 'Not provided';

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
                Text(session.firebaseUser?.displayName ?? 'User', style: Theme.of(context).textTheme.titleMedium),
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

  Widget _buildHealthSnapshot() {
    final metrics = [
      _HealthMetric(label: 'Steps', value: '5,240', trend: '+12%'),
      _HealthMetric(label: 'Sleep', value: '7h 45m', trend: 'Well rested'),
      _HealthMetric(label: 'Heart Rate', value: '72 bpm', trend: 'Steady'),
      _HealthMetric(label: 'SpO₂', value: '97%', trend: 'Great'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(metrics.length, (index) {
        final metric = metrics[index];
        return Container(
          width: math.max((MediaQuery.of(context).size.width - 64) / 2, 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(metric.value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(height: 6),
              Text(metric.trend, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ).animate().fadeIn(duration: 350.ms, delay: (index * 80).ms);
      }),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 8)),
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
                Text(appointment.doctorName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(formattedDate, style: Theme.of(context).textTheme.bodyMedium),
                if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(appointment.notes!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appointment actions coming soon.')),
            ),
            icon: const Icon(Icons.more_horiz),
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

class _HealthMetric {
  _HealthMetric({required this.label, required this.value, required this.trend});

  final String label;
  final String value;
  final String trend;
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
