import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;

import '../services/api.dart';
import '../theme/app_theme.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  List<Doctor> _doctors = [];
  List<Doctor> _filtered = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _searchController.addListener(_applyFilter);
  }

  Future<void> _loadDoctors() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/doctors'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as List<dynamic>;
        final doctors = json
            .map((d) => Doctor(
                  name: d['name']?.toString() ?? 'Doctor',
                  specialty: d['specialty']?.toString() ?? 'Specialist',
                  distance: d['distance']?.toString() ?? '',
                ))
            .toList();
        setState(() {
          _doctors = doctors;
          _filtered = doctors;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch doctors: $e');
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = _doctors;
      } else {
        _filtered = _doctors
            .where((doctor) =>
                doctor.name.toLowerCase().contains(query) || doctor.specialty.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nearby Specialists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Filters coming soon!')),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search specialty…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _filtered.isEmpty
                    ? const _DoctorsEmptyState()
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final doctor = _filtered[index];
                          return _DoctorCard(doctor: doctor).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Doctor {
  Doctor({required this.name, required this.specialty, required this.distance});

  final String name;
  final String specialty;
  final String distance;
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 26, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('4.9 · ${doctor.specialty}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(doctor.distance, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Open slots', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _DoctorDetailSheet(doctor: doctor),
    );
  }
}

class _DoctorDetailSheet extends StatelessWidget {
  const _DoctorDetailSheet({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 28, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 28)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(doctor.specialty, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Experience', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('12 years at City Hospital · 4.9 rating · Telehealth available', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text('Next availability', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            children: const [
              Chip(label: Text('Today · 5:30 PM')),
              Chip(label: Text('Tomorrow · 9:00 AM')),
              Chip(label: Text('Nov 1 · 11:30 AM')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Call feature coming soon')),
                  ),
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Call clinic'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking coming soon')),
                  ),
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: const Text('Book visit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DoctorsEmptyState extends StatelessWidget {
  const _DoctorsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text('No specialists found', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('Try a different search term or check again later.', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
