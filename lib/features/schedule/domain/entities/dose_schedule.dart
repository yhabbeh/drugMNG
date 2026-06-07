import 'package:equatable/equatable.dart';

import 'package:drug/features/inventory/domain/value_objects/enums.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/domain/entities/scheduled_medication.dart';

final class DoseSchedule extends Equatable {
  const DoseSchedule({
    required this.id,
    required this.profileId,
    required this.medications,
    required this.recurrenceRule,
    required this.startDate,
    this.endDate,
    this.instructions,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;

  /// All medications to be taken on this schedule.
  final List<ScheduledMedication> medications;

  final RecurrenceRule recurrenceRule;
  final DateTime startDate;
  final DateTime? endDate;
  final String? instructions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Convenience getters for backward compatibility ──────────────────────────

  String get medicationId =>
      medications.isNotEmpty ? medications.first.medicationId : '';

  String get medicationName =>
      medications.isNotEmpty ? medications.first.medicationName : '';

  double? get dosageAmount =>
      medications.isNotEmpty ? medications.first.dosageAmount : null;

  DosageUnit? get dosageUnit =>
      medications.isNotEmpty ? medications.first.dosageUnit : null;

  // ────────────────────────────────────────────────────────────────────────────

  DoseSchedule copyWith({
    String? id,
    String? profileId,
    List<ScheduledMedication>? medications,
    RecurrenceRule? recurrenceRule,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoseSchedule(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      medications: medications ?? this.medications,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        medications,
        recurrenceRule,
        startDate,
        endDate,
        instructions,
        isActive,
        createdAt,
        updatedAt,
      ];
}
