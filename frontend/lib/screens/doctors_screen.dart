import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/chat_context_provider.dart';
import '../services/location_service.dart';
import '../services/osm_places.dart';
import '../services/geoapify_places_service.dart';
import '../theme/app_theme.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  List<Doctor> _doctors = [];
  final TextEditingController _searchController = TextEditingController();
  bool _loading = false;
  bool _filterHospitals = false;
  bool _filterClinics = true;
  bool _filterDoctors = true;

  @override
  void initState() {
    super.initState();
    _prefillFromChat();
  }

  void _prefillFromChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatCtx = context.read<ChatContextProvider>();
      if (chatCtx.lastKeywords.isNotEmpty) {
        _searchController.text = chatCtx.lastKeywords;
      }
      if (chatCtx.preferHospital) {
        _filterHospitals = true;
      }
    });
  }
  Future<void> _useMyLocation() async {
    setState(() => _loading = true);
    try {
      final ok = await LocationService.ensurePermission();
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required. Please enable it in Settings.')),
        );
        return;
      }
      final pos = await LocationService.getCurrentPosition();
      final kw = _buildKeywords();
      final geoapifyCategories = _buildGeoapifyCategories();
      if (GeoapifyPlacesService.isConfigured) {
        final results = await GeoapifyPlacesService.fetchNearby(
          lat: pos.latitude,
          lon: pos.longitude,
          categories: geoapifyCategories,
        );
        setState(() {
          _doctors = results
              .map((p) => Doctor(
                    name: p.name,
                    specialty: p.category,
                    distance: _formatDistance(p.distanceMeters),
                    source: 'geoapify',
                    placeId: p.id,
                  ))
              .toList();
          _padWithDummies();
        });
      } else {
        final results = await OsmPlacesService.fetchNearbyDoctors(
          lat: pos.latitude,
          lon: pos.longitude,
          keywords: kw,
        );
        setState(() {
          _doctors = results
              .map((p) => Doctor(
                    name: p.name,
                    specialty: p.category,
                    distance: _formatDistance(p.distanceMeters),
                  ))
              .toList();
          _padWithDummies();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load nearby doctors: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _buildKeywords() {
    final terms = <String>[];
    final input = _searchController.text.trim();
    if (input.isNotEmpty) terms.add(input);
    if (_filterHospitals) terms.add('hospital');
    if (_filterClinics) terms.add('clinic');
    if (_filterDoctors) terms.add('doctor');
    if (terms.isEmpty) return 'doctor clinic';
    // Nominatim free-text handles multiple tokens reasonably well
    return terms.join(' ');
  }

  List<String> _buildGeoapifyCategories() {
    final cats = <String>[];
    if (_filterHospitals) cats.add('healthcare.hospital');
    if (_filterClinics) cats.add('healthcare.clinic_or_praxis');
    if (_filterDoctors) cats.add('healthcare.clinic_or_praxis');
    if (cats.isEmpty) return ['healthcare.clinic_or_praxis'];
    return cats;
  }

  void _padWithDummies() {
    const target = 5;
    final need = target - _doctors.length;
    if (need <= 0) return;
    final List<Doctor> dummies = [];
    final category = _filterHospitals
        ? 'hospital'
        : (_filterClinics
            ? 'clinic'
            : 'doctors');
    final names = _filterHospitals
        ? ['Sunrise Hospital', 'CityCare Hospital', 'LifePoint Hospital']
        : _filterClinics
            ? ['Green Cross Clinic', 'Wellness Family Clinic', 'City Care Clinic']
            : ['Community Health Doctor', 'Family Care Doctor', 'Neighborhood GP'];
    final distances = ['0.9 km', '1.6 km', '2.4 km', '3.1 km', '4.8 km'];
    for (int i = 0; i < need && i < names.length; i++) {
      dummies.add(Doctor(name: names[i], specialty: category, distance: distances[i]));
    }
    _doctors.addAll(dummies);
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
            icon: const Icon(Icons.my_location_rounded),
            onPressed: _useMyLocation,
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
                  hintText: 'Specialty keywords (e.g., cardiologist, clinic)…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            selected: _filterHospitals,
                            onSelected: (val) => setState(() => _filterHospitals = val),
                            label: const Text('Hospitals'),
                            avatar: const Icon(Icons.local_hospital_outlined, size: 18),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _filterClinics,
                            onSelected: (val) => setState(() => _filterClinics = val),
                            label: const Text('Clinics'),
                            avatar: const Icon(Icons.medical_services_outlined, size: 18),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _filterDoctors,
                            onSelected: (val) => setState(() => _filterDoctors = val),
                            label: const Text('Doctors'),
                            avatar: const Icon(Icons.person_search_outlined, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _doctors.isEmpty
                    ? const _DoctorsEmptyState()
                    : ListView.separated(
                        itemCount: _doctors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final doctor = _doctors[index];
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
  Doctor({required this.name, required this.specialty, required this.distance, this.source, this.placeId});

  final String name;
  final String specialty;
  final String distance;
  final String? source; // 'geoapify' | 'google' | 'osm'
  final String? placeId; // provider-specific id
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

  Future<void> _openDetails(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _DoctorDetailSheet(doctor: doctor),
    );
    if (result != null && result.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }
}

class _DoctorDetailSheet extends StatefulWidget {
  const _DoctorDetailSheet({required this.doctor});

  final Doctor doctor;

  @override
  State<_DoctorDetailSheet> createState() => _DoctorDetailSheetState();
}

class _DoctorDetailSheetState extends State<_DoctorDetailSheet> {
  String? _selectedSlot;
  String? _phone;
  String? _website;
  String? _opening;

  @override
  void initState() {
    super.initState();
    _loadDetailsIfAvailable();
  }

  Future<void> _loadDetailsIfAvailable() async {
    if (widget.doctor.source == 'geoapify' && widget.doctor.placeId != null && GeoapifyPlacesService.isConfigured) {
      final details = await GeoapifyPlacesService.fetchDetails(widget.doctor.placeId!);
      if (!mounted) return;
      setState(() {
        _phone = details?.phone;
        _website = details?.website;
        _opening = details?.openingHours;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;
    final slots = <String>[
      'Today · 5:30 PM',
      'Tomorrow · 9:00 AM',
      'Fri · 11:30 AM',
    ];

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
          const SizedBox(height: 8),
          if (_opening != null && _opening!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(_opening!, style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: 8),
          Text('Next availability', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final s in slots)
                ChoiceChip(
                  label: Text(s),
                  selected: _selectedSlot == s,
                  onSelected: (_) => setState(() => _selectedSlot = s),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final msg = _phone != null ? 'Calling $_phone…' : 'Calling clinic…';
                    Navigator.of(context).pop(msg);
                  },
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Call clinic'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_selectedSlot == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select a time slot first')),
                      );
                      return;
                    }
                    Navigator.of(context).pop('Booking confirmed for $_selectedSlot');
                  },
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
