import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:drug/core/router/app_routes.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';
import 'package:drug/features/schedule/presentation/bloc/schedule_bloc.dart';

class SharedDoseActionSheet extends StatefulWidget {
  const SharedDoseActionSheet({super.key, required this.log});

  final DoseLog log;

  @override
  State<SharedDoseActionSheet> createState() => _SharedDoseActionSheetState();
}

class _SharedDoseActionSheetState extends State<SharedDoseActionSheet> {
  late final TextEditingController _notesController;
  bool _notesChanged = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.log.notes ?? '');
    _notesController.addListener(_onNotesChanged);
  }

  @override
  void dispose() {
    _notesController.removeListener(_onNotesChanged);
    _notesController.dispose();
    super.dispose();
  }

  void _onNotesChanged() {
    final changed = _notesController.text.trim() != (widget.log.notes ?? '');
    if (changed != _notesChanged) {
      setState(() {
        _notesChanged = changed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeStr = DateFormat('EEEE, MMMM d • h:mm a').format(widget.log.scheduledAt);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.medication, color: cs.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.log.medicationName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Status Indicator Banner ──
          if (widget.log.status == DoseStatus.taken) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.log.takenAt != null
                          ? 'This dose was taken at ${DateFormat('h:mm a').format(widget.log.takenAt!)}'
                          : 'This dose was marked as taken.',
                      style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Side effect quick trigger ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.symptomForm, extra: widget.log.medicationId);
                },
                icon: const Icon(Icons.sick_outlined),
                label: const Text('Report Side Effect / Symptom'),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Notes (Optional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'e.g., Taken with food, felt slightly dizzy',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            if (_notesChanged) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<ScheduleBloc>().add(
                          ScheduleDoseTaken(
                            LogDoseParams(
                              scheduleId: widget.log.scheduleId,
                              profileId: widget.log.profileId,
                              medicationId: widget.log.medicationId,
                              scheduledAt: widget.log.scheduledAt,
                              notes: _notesController.text.trim().isNotEmpty
                                  ? _notesController.text.trim()
                                  : null,
                            ),
                          ),
                        );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Notes'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseReverted(
                              LogDoseParams(
                                scheduleId: widget.log.scheduleId,
                                profileId: widget.log.profileId,
                                medicationId: widget.log.medicationId,
                                scheduledAt: widget.log.scheduledAt,
                              ),
                            ),
                          );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.undo),
                    label: const Text('Revert Dose'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseSkipped(
                              LogDoseParams(
                                scheduleId: widget.log.scheduleId,
                                profileId: widget.log.profileId,
                                medicationId: widget.log.medicationId,
                                scheduledAt: widget.log.scheduledAt,
                                notes: _notesController.text.trim().isNotEmpty
                                    ? _notesController.text.trim()
                                    : null,
                              ),
                            ),
                          );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Skip Dose'),
                  ),
                ),
              ],
            ),
          ] else if (widget.log.status == DoseStatus.skipped) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.next_plan_outlined, color: Colors.grey.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This dose was skipped.',
                      style: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Notes (Optional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'e.g., Taken with food, felt slightly dizzy',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            if (_notesChanged) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<ScheduleBloc>().add(
                          ScheduleDoseSkipped(
                            LogDoseParams(
                              scheduleId: widget.log.scheduleId,
                              profileId: widget.log.profileId,
                              medicationId: widget.log.medicationId,
                              scheduledAt: widget.log.scheduledAt,
                              notes: _notesController.text.trim().isNotEmpty
                                  ? _notesController.text.trim()
                                  : null,
                            ),
                          ),
                        );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Notes'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseReverted(
                              LogDoseParams(
                                scheduleId: widget.log.scheduleId,
                                profileId: widget.log.profileId,
                                medicationId: widget.log.medicationId,
                                scheduledAt: widget.log.scheduledAt,
                              ),
                            ),
                          );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.undo),
                    label: const Text('Revert Dose'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseTaken(
                              LogDoseParams(
                                scheduleId: widget.log.scheduleId,
                                profileId: widget.log.profileId,
                                medicationId: widget.log.medicationId,
                                scheduledAt: widget.log.scheduledAt,
                                notes: _notesController.text.trim().isNotEmpty
                                    ? _notesController.text.trim()
                                    : null,
                              ),
                            ),
                          );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm Taken'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Add Notes (Optional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'e.g., Taken with food, felt slightly dizzy',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseSkipped(
                              LogDoseParams(
                                scheduleId: widget.log.scheduleId,
                                profileId: widget.log.profileId,
                                medicationId: widget.log.medicationId,
                                scheduledAt: widget.log.scheduledAt,
                                notes: _notesController.text.trim().isNotEmpty
                                    ? _notesController.text.trim()
                                    : null,
                              ),
                            ),
                          );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Skip Dose'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseTaken(
                              LogDoseParams(
                                scheduleId: widget.log.scheduleId,
                                profileId: widget.log.profileId,
                                medicationId: widget.log.medicationId,
                                scheduledAt: widget.log.scheduledAt,
                                notes: _notesController.text.trim().isNotEmpty
                                    ? _notesController.text.trim()
                                    : null,
                              ),
                            ),
                          );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm Taken'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
