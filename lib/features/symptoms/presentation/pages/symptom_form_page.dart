import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:drug/features/profiles/presentation/cubit/active_profile_cubit.dart';
import 'package:drug/features/symptoms/domain/entities/symptom_entry.dart';
import 'package:drug/features/symptoms/presentation/cubit/symptom_cubit.dart';

class SymptomFormPage extends StatefulWidget {
  const SymptomFormPage({super.key, this.initialMedicationId});

  final String? initialMedicationId;

  @override
  State<SymptomFormPage> createState() => _SymptomFormPageState();
}

class _SymptomFormPageState extends State<SymptomFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _notesController;
  late DateTime _occurredAt;
  SymptomSeverity _severity = SymptomSeverity.mild;
  String? _selectedMedicationId;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _occurredAt = DateTime.now();
    _selectedMedicationId = widget.initialMedicationId;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );

    if (pickedTime == null) return;

    setState(() {
      _occurredAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _submit(String profileId, List<Medication> medications) {
    if (!_formKey.currentState!.validate()) return;

    final med = medications.where((m) => m.id == _selectedMedicationId).firstOrNull;

    final entry = SymptomEntry(
      id: const Uuid().v4(),
      profileId: profileId,
      occurredAt: _occurredAt,
      severity: _severity,
      notes: _notesController.text.trim(),
      relatedMedicationId: _selectedMedicationId,
      relatedMedicationName: med?.name,
    );

    context.read<SymptomCubit>().saveEntry(entry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final activeState = context.read<ActiveProfileCubit>().state;
    if (activeState is! ActiveProfileSelected) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Symptom')),
        body: const Center(child: Text('No active profile selected')),
      );
    }
    final profile = activeState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Symptom / Side Effect'),
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, invState) {
          final medications = invState is InventoryLoaded ? invState.medications : <Medication>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How are you feeling, ${profile.displayName}?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log any symptoms, side-effects, or changes in vitals below.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // ── Severity Picker ──
                  Text(
                    'Severity Level',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: SymptomSeverity.values.map((sev) {
                      final isSelected = _severity == sev;
                      final label = switch (sev) {
                        SymptomSeverity.mild => 'Mild',
                        SymptomSeverity.moderate => 'Moderate',
                        SymptomSeverity.severe => 'Severe',
                      };
                      final baseColor = switch (sev) {
                        SymptomSeverity.mild => Colors.teal,
                        SymptomSeverity.moderate => Colors.orange,
                        SymptomSeverity.severe => Colors.red,
                      };

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setState(() => _severity = sev),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? baseColor.withOpacity(0.12)
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? baseColor : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: baseColor.withOpacity(0.24),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.lens,
                                    size: 14,
                                    color: baseColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? baseColor : Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Notes Input ──
                  Text(
                    'Notes / Description',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Felt mild headache, nausea after dinner',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please provide some details';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Date & Time Picker ──
                  Text(
                    'Time Occurred',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _selectDateTime,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(_occurredAt),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Related Medication Dropdown ──
                  Text(
                    'Related Medication (Optional)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedMedicationId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select medication',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('None / General Symptom'),
                      ),
                      ...medications.map(
                        (med) => DropdownMenuItem<String>(
                          value: med.id,
                          child: Text(med.name),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedMedicationId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 36),

                  // ── Submit Button ──
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => _submit(profile.id, medications),
                      icon: const Icon(Icons.check),
                      label: const Text('Log Symptom'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
