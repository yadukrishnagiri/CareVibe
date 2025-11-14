import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../services/medication_api.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../data/medication_database.dart';

class AddMedicationDialog extends StatefulWidget {
  const AddMedicationDialog({super.key});

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  
  final List<TimeOfDay> _reminderTimes = [];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isSubmitting = false;
  MedicationInfo? _selectedMedication;
  List<String> _suggestedDosages = [];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _reminderTimes.add(time);
        _reminderTimes.sort((a, b) {
          final aMinutes = a.hour * 60 + a.minute;
          final bMinutes = b.hour * 60 + b.minute;
          return aMinutes.compareTo(bMinutes);
        });
      });
    }
  }

  void _removeReminderTime(int index) {
    setState(() {
      _reminderTimes.removeAt(index);
    });
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  void _clearEndDate() {
    setState(() {
      _endDate = null;
    });
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _submitMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_reminderTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one reminder time'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final session = context.read<SessionProvider>();
      if (session.jwt == null) {
        throw Exception('Not authenticated');
      }

      final times = _reminderTimes.map(_formatTimeOfDay).toList();
      final medicationName = _nameController.text.trim();
      final dosage = _dosageController.text.trim();

      final result = await MedicationApi.createMedication(
        session.jwt!,
        name: medicationName,
        dosage: dosage,
        times: times,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text.trim(),
      );

      // Schedule notifications for the medication
      final medicationId = result['_id']?.toString() ?? '';
      if (medicationId.isNotEmpty) {
        try {
          await NotificationService().scheduleMedicationReminders(
            medicationId: medicationId,
            medicationName: medicationName,
            dosage: dosage,
            times: times,
          );
        } catch (e) {
          // Notification scheduling failed, but medication was added
          // Continue anyway
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add medication: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.medication_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Add Medication',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Medication Name with Autocomplete
                  Autocomplete<MedicationInfo>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<MedicationInfo>.empty();
                      }
                      return MedicationDatabase.search(textEditingValue.text);
                    },
                    displayStringForOption: (MedicationInfo option) => option.name,
                    onSelected: (MedicationInfo selection) {
                      setState(() {
                        _selectedMedication = selection;
                        _suggestedDosages = selection.commonDosages;
                        _nameController.text = selection.name;
                      });
                    },
                    fieldViewBuilder: (
                      BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted,
                    ) {
                      // Sync our controller with the autocomplete controller
                      if (_nameController.text.isNotEmpty && textEditingController.text.isEmpty) {
                        textEditingController.text = _nameController.text;
                      }
                      
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Medication Name',
                          hintText: 'Start typing medication name...',
                          prefixIcon: const Icon(Icons.medical_information_outlined),
                          suffixIcon: textEditingController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    textEditingController.clear();
                                    _nameController.clear();
                                    setState(() {
                                      _selectedMedication = null;
                                      _suggestedDosages = [];
                                    });
                                  },
                                )
                              : const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'Search from ${MedicationDatabase.medications.length}+ medications',
                          helperMaxLines: 1,
                        ),
                        onChanged: (value) {
                          _nameController.text = value;
                          if (value.isEmpty) {
                            setState(() {
                              _selectedMedication = null;
                              _suggestedDosages = [];
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter medication name';
                          }
                          return null;
                        },
                      );
                    },
                    optionsViewBuilder: (
                      BuildContext context,
                      AutocompleteOnSelected<MedicationInfo> onSelected,
                      Iterable<MedicationInfo> options,
                    ) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 400),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: options.length,
                              shrinkWrap: true,
                              itemBuilder: (BuildContext context, int index) {
                                final MedicationInfo option = options.elementAt(index);
                                return InkWell(
                                  onTap: () {
                                    onSelected(option);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                      horizontal: 12.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          option.category,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Dosage
                  TextFormField(
                    controller: _dosageController,
                    decoration: InputDecoration(
                      labelText: 'Dosage',
                      hintText: _selectedMedication != null 
                          ? 'Select from common dosages below or type custom'
                          : 'e.g., 81 mg, 1 tablet, 1000 IU',
                      prefixIcon: const Icon(Icons.medication_liquid_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter dosage';
                      }
                      return null;
                    },
                  ),
                  
                  // Suggested dosages chips
                  if (_suggestedDosages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Common dosages:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestedDosages.map((dosage) {
                        final isSelected = _dosageController.text == dosage;
                        return FilterChip(
                          label: Text(dosage),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _dosageController.text = dosage;
                            });
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          side: BorderSide(
                            color: isSelected 
                                ? AppColors.primary 
                                : Colors.grey.shade300,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Start Date
                  InkWell(
                    onTap: _selectStartDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_startDate.month}/${_startDate.day}/${_startDate.year}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // End Date (Optional)
                  InkWell(
                    onTap: _selectEndDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_busy, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Date (Optional)',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _endDate != null
                                      ? '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                                      : 'Ongoing',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          if (_endDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearEndDate,
                              tooltip: 'Clear end date',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Reminder Times Section
                  Row(
                    children: [
                      Icon(Icons.alarm, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Reminder Times',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _addReminderTime,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Time'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_reminderTimes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add at least one reminder time',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _reminderTimes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final time = entry.value;
                        return Chip(
                          label: Text(
                            time.format(context),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => _removeReminderTime(index),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          side: BorderSide(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        );
                      }).toList(),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Add any special instructions',
                      prefixIcon: const Icon(Icons.note_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitMedication,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Add Medication',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

