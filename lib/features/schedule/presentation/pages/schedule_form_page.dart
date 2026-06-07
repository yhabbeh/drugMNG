import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:drug/core/di/injection_container.dart';
import 'package:drug/features/profiles/data/datasources/profile_local_datasource.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/presentation/cubit/active_profile_cubit.dart';
import 'package:drug/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/domain/entities/schedule_time.dart';
import 'package:drug/features/schedule/domain/entities/scheduled_medication.dart';
import 'package:drug/features/schedule/presentation/bloc/schedule_bloc.dart';

class ScheduleFormPage extends StatefulWidget {
  const ScheduleFormPage({super.key, this.schedule, this.profileId});

  final DoseSchedule? schedule;
  final String? profileId;

  @override
  State<ScheduleFormPage> createState() => _ScheduleFormPageState();
}

class _ScheduleFormPageState extends State<ScheduleFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _intervalHoursController;
  late final TextEditingController _instructionsController;
  late ScheduleType _scheduleType;
  late List<ScheduleTime> _times;
  late List<int> _daysOfWeek;
  late DateTime _startDate;
  late DateTime? _endDate;
  bool _isActive = true;
  bool _hasEndDate = false;

  late List<CaregiverProfile> _profiles;
  List<Medication> _medications = [];
  String? _profileId;

  /// The list of medication entries being built by the form.
  late List<_MedEntry> _medEntries;

  bool get _isEditing => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    final sched = widget.schedule;

    _profiles = sl<ProfileLocalDataSource>()
        .getAllProfiles()
        .map((m) => m.toDomain())
        .toList();

    _profileId = sched?.profileId ?? widget.profileId;
    if (_profileId == null && _profiles.isNotEmpty) {
      final activeState = context.read<ActiveProfileCubit>().state;
      _profileId = activeState is ActiveProfileSelected
          ? activeState.profile.id
          : _profiles.first.id;
    }

    if (_profileId != null) {
      _medications = sl<InventoryLocalDataSource>()
          .getAllMedications()
          .where((m) => m.profileId == _profileId)
          .map((m) => m.toDomain())
          .toList();
    }

    // Populate medication entries from existing schedule, or start with one
    // blank entry.
    if (sched != null && sched.medications.isNotEmpty) {
      _medEntries = sched.medications.map((m) {
        return _MedEntry.fromScheduled(m);
      }).toList();
    } else {
      _medEntries = [_MedEntry()];
    }

    _intervalHoursController = TextEditingController(
      text: sched?.recurrenceRule.intervalHours?.toString() ?? '',
    );
    _instructionsController = TextEditingController(
      text: sched?.instructions ?? '',
    );
    _scheduleType = sched?.recurrenceRule.type ?? ScheduleType.daily;
    _times = sched?.recurrenceRule.times.isNotEmpty == true
        ? sched!.recurrenceRule.times
        : [const ScheduleTime(hour: 8, minute: 0)];
    _daysOfWeek = sched?.recurrenceRule.daysOfWeek ?? [];
    _startDate = sched?.startDate ?? DateTime.now();
    _endDate = sched?.endDate;
    _hasEndDate = sched?.endDate != null;
    _isActive = sched?.isActive ?? true;
  }

  void _onProfileChanged(String? newProfileId) {
    if (newProfileId == null) return;
    setState(() {
      _profileId = newProfileId;
      _medications = sl<InventoryLocalDataSource>()
          .getAllMedications()
          .where((m) => m.profileId == newProfileId)
          .map((m) => m.toDomain())
          .toList();
      // Reset all med entries when profile changes
      _medEntries = [_MedEntry()];
    });
  }

  @override
  void dispose() {
    _intervalHoursController.dispose();
    _instructionsController.dispose();
    for (final e in _medEntries) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Edit Schedule' : 'New Schedule';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Profile Selector ───────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _profileId,
              decoration: const InputDecoration(
                labelText: 'Caregiver Profile',
                border: OutlineInputBorder(),
              ),
              items: _profiles.map((p) {
                return DropdownMenuItem<String>(
                  value: p.id,
                  child: Text(p.displayName),
                );
              }).toList(),
              onChanged: _onProfileChanged,
            ),
            const SizedBox(height: 20),

            // ── Medications List ───────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Medications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _medEntries.add(_MedEntry()));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Medication'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._medEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final medEntry = entry.value;
              return _MedicationEntryCard(
                key: ValueKey(medEntry),
                entry: medEntry,
                medications: _medications,
                canRemove: _medEntries.length > 1,
                onRemove: () {
                  setState(() {
                    medEntry.dispose();
                    _medEntries.removeAt(index);
                  });
                },
                onChanged: () => setState(() {}),
              );
            }),
            const SizedBox(height: 20),

            // ── Schedule Type ──────────────────────────────────────────────
            DropdownButtonFormField<ScheduleType>(
              value: _scheduleType,
              decoration: const InputDecoration(
                labelText: 'Schedule Type',
                border: OutlineInputBorder(),
              ),
              items: ScheduleType.values.map((t) {
                return DropdownMenuItem(value: t, child: Text(t.name));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _scheduleType = value);
                }
              },
            ),
            const SizedBox(height: 16),

            if (_scheduleType != ScheduleType.prn) ...[
              _TimeListEditor(
                times: _times,
                onChanged: (times) => setState(() => _times = times),
              ),
              const SizedBox(height: 16),
            ],
            if (_scheduleType == ScheduleType.weekly) ...[
              _DaysOfWeekSelector(
                selectedDays: _daysOfWeek,
                onChanged: (days) => setState(() => _daysOfWeek = days),
              ),
              const SizedBox(height: 16),
            ],
            if (_scheduleType == ScheduleType.customInterval) ...[
              TextFormField(
                controller: _intervalHoursController,
                decoration: const InputDecoration(
                  labelText: 'Interval (hours)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_scheduleType == ScheduleType.customInterval) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Interval is required';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Must be a number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // ── Date Range ─────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${_startDate.month}/${_startDate.day}/${_startDate.year}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _hasEndDate ? _pickEndDate : null,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: _hasEndDate
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _hasEndDate = false;
                                    _endDate = null;
                                  });
                                },
                              )
                            : IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _pickEndDate,
                              ),
                      ),
                      child: Text(
                        _hasEndDate
                            ? '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                            : 'None',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Instructions ───────────────────────────────────────────────
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Active'),
              subtitle: Text(
                _isActive ? 'Reminders will be sent' : 'Reminders paused',
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: Text(_isEditing ? 'Save Changes' : 'Create Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
        _hasEndDate = true;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Validate that every entry has a medication name
    for (final entry in _medEntries) {
      if (entry.nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Each medication must have a name.'),
          ),
        );
        return;
      }
    }

    final now = DateTime.now();
    final sched = widget.schedule;

    final medications = _medEntries.map((e) {
      return ScheduledMedication(
        medicationId: e.medicationId ?? '',
        medicationName: e.nameController.text.trim(),
        dosageAmount: double.tryParse(e.dosageController.text.trim()),
        dosageUnit: e.dosageUnit,
      );
    }).toList();

    final schedule = DoseSchedule(
      id: sched?.id ?? '',
      profileId: _profileId ?? '',
      medications: medications,
      recurrenceRule: RecurrenceRule(
        type: _scheduleType,
        times: _scheduleType == ScheduleType.prn ? [] : _times,
        intervalHours: _scheduleType == ScheduleType.customInterval
            ? int.tryParse(_intervalHoursController.text.trim())
            : null,
        daysOfWeek: _scheduleType == ScheduleType.weekly ? _daysOfWeek : null,
      ),
      startDate: _startDate,
      endDate: _endDate,
      instructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
      isActive: _isActive,
      createdAt: sched?.createdAt ?? now,
      updatedAt: now,
    );

    if (_isEditing) {
      context.read<ScheduleBloc>().add(ScheduleUpdated(schedule));
    } else {
      context.read<ScheduleBloc>().add(ScheduleAdded(schedule));
    }
    context.pop();
  }
}

// ── Internal mutable state for a single medication entry ────────────────────

class _MedEntry {
  _MedEntry({
    String? medicationId,
    String initialName = '',
    String initialDosage = '',
    DosageUnit? dosageUnit,
  })  : medicationId = medicationId,
        nameController = TextEditingController(text: initialName),
        dosageController = TextEditingController(text: initialDosage),
        dosageUnit = dosageUnit;

  factory _MedEntry.fromScheduled(ScheduledMedication m) {
    return _MedEntry(
      medicationId: m.medicationId.isEmpty ? null : m.medicationId,
      initialName: m.medicationName,
      initialDosage: m.dosageAmount?.toString() ?? '',
      dosageUnit: m.dosageUnit,
    );
  }

  String? medicationId;
  final TextEditingController nameController;
  final TextEditingController dosageController;
  DosageUnit? dosageUnit;

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
  }
}

// ── Card for one medication entry in the list ────────────────────────────────

class _MedicationEntryCard extends StatefulWidget {
  const _MedicationEntryCard({
    super.key,
    required this.entry,
    required this.medications,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final _MedEntry entry;
  final List<Medication> medications;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  State<_MedicationEntryCard> createState() => _MedicationEntryCardState();
}

class _MedicationEntryCardState extends State<_MedicationEntryCard> {
  void _onInventoryChanged(String? medicationId) {
    setState(() {
      widget.entry.medicationId = medicationId;
      if (medicationId != null) {
        final med =
            widget.medications.firstWhere((m) => m.id == medicationId);
        widget.entry.nameController.text = med.name;
        widget.entry.dosageController.text =
            med.dosageAmount?.toString() ?? '';
        widget.entry.dosageUnit = med.dosageUnit;
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final inventoryValue =
        widget.medications.any((m) => m.id == entry.medicationId)
            ? entry.medicationId
            : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Medication',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                if (widget.canRemove)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: Colors.redAccent,
                    tooltip: 'Remove',
                    onPressed: widget.onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Inventory picker
            DropdownButtonFormField<String>(
              value: inventoryValue,
              decoration: const InputDecoration(
                labelText: 'Pick from Inventory (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None (enter name below)'),
                ),
                ...widget.medications.map((m) {
                  return DropdownMenuItem<String>(
                    value: m.id,
                    child: Text('${m.name} (${m.drugForm.name})'),
                  );
                }),
              ],
              onChanged: _onInventoryChanged,
            ),
            const SizedBox(height: 10),

            // Medication name
            TextFormField(
              controller: entry.nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),

            // Dosage row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage Amount',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<DosageUnit>(
                    value: entry.dosageUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: DosageUnit.values.map((u) {
                      return DropdownMenuItem(value: u, child: Text(u.name));
                    }).toList(),
                    onChanged: (v) {
                      setState(() => entry.dosageUnit = v);
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Time list editor ─────────────────────────────────────────────────────────

final class _TimeListEditor extends StatelessWidget {
  const _TimeListEditor({
    required this.times,
    required this.onChanged,
  });

  final List<ScheduleTime> times;
  final ValueChanged<List<ScheduleTime>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Times',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addTime(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Time'),
            ),
          ],
        ),
        ...times.asMap().entries.map((entry) {
          final index = entry.key;
          final time = entry.value;
          final period = time.hour >= 12 ? 'PM' : 'AM';
          final hour12 = time.hour == 0
              ? 12
              : time.hour > 12
                  ? time.hour - 12
                  : time.hour;
          final timeStr =
              '${hour12.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';

          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(timeStr),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: times.length > 1
                  ? () {
                      final updated = [...times];
                      updated.removeAt(index);
                      onChanged(updated);
                    }
                  : null,
            ),
            onTap: () => _editTime(context, index),
          );
        }),
      ],
    );
  }

  Future<void> _addTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (time != null) {
      onChanged([
        ...times,
        ScheduleTime(hour: time.hour, minute: time.minute),
      ]);
    }
  }

  Future<void> _editTime(BuildContext context, int index) async {
    final current = times[index];
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (time != null) {
      final updated = [...times];
      updated[index] = ScheduleTime(hour: time.hour, minute: time.minute);
      onChanged(updated);
    }
  }
}

// ── Days of week selector ────────────────────────────────────────────────────

final class _DaysOfWeekSelector extends StatelessWidget {
  const _DaysOfWeekSelector({
    required this.selectedDays,
    required this.onChanged,
  });

  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  static const _dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _dayValues = [1, 2, 3, 4, 5, 6, 7];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Days of Week',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final day = _dayValues[index];
            final isSelected = selectedDays.contains(day);
            return GestureDetector(
              onTap: () {
                final updated = [...selectedDays];
                if (isSelected) {
                  updated.remove(day);
                } else {
                  updated.add(day);
                }
                updated.sort();
                onChanged(updated);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _dayNames[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
