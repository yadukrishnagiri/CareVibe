import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../providers/session_provider.dart';
import '../services/profile_api.dart';
import '../theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _age;
  String? _gender; // male | female | other
  double? _heightCm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prof = context.read<ProfileProvider>();
      if (prof.profile == null) await prof.load();
      final p = prof.profile;
      setState(() {
        _age = p?.age;
        _gender = p?.gender;
        _heightCm = p?.heightCm;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final prof = context.watch<ProfileProvider>();
    final session = context.watch<SessionProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Complete your profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('We use this to personalize ranges and calculations. These are stored securely.'),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _age?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'Age (years) *'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0 || n > 120) return 'Enter a valid age';
                  return null;
                },
                onSaved: (v) => _age = int.tryParse(v ?? ''),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v),
                decoration: const InputDecoration(labelText: 'Gender *'),
                validator: (v) => (v == null || v.isEmpty) ? 'Select gender' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _heightCm?.toStringAsFixed(1) ?? '',
                decoration: const InputDecoration(labelText: 'Height (cm) *'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 30 || n > 260) return 'Enter height in cm';
                  return null;
                },
                onSaved: (v) => _heightCm = double.tryParse(v ?? ''),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: prof.loading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        _formKey.currentState!.save();
                        final dto = UserProfileDto(age: _age, gender: _gender, heightCm: _heightCm);
                        await context.read<ProfileProvider>().save(dto);
                        if (mounted) {
                          if (context.read<ProfileProvider>().isComplete) {
                            Navigator.pushReplacementNamed(context, '/shell');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all fields')));
                          }
                        }
                      },
                child: prof.loading ? const CircularProgressIndicator() : const Text('Save & continue'),
              ),
              if (session.isAuthenticated)
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/shell'),
                  child: const Text('Skip for now'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


