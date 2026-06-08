import 'package:equatable/equatable.dart';

enum SymptomSeverity { mild, moderate, severe }

final class SymptomEntry extends Equatable {
  const SymptomEntry({
    required this.id,
    required this.profileId,
    required this.occurredAt,
    required this.severity,
    required this.notes,
    this.relatedMedicationId,
    this.relatedMedicationName,
  });

  final String id;
  final String profileId;
  final DateTime occurredAt;
  final SymptomSeverity severity;
  final String notes;
  final String? relatedMedicationId;
  final String? relatedMedicationName;

  SymptomEntry copyWith({
    String? id,
    String? profileId,
    DateTime? occurredAt,
    SymptomSeverity? severity,
    String? notes,
    String? relatedMedicationId,
    String? relatedMedicationName,
  }) {
    return SymptomEntry(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      occurredAt: occurredAt ?? this.occurredAt,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      relatedMedicationId: relatedMedicationId ?? this.relatedMedicationId,
      relatedMedicationName: relatedMedicationName ?? this.relatedMedicationName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        occurredAt,
        severity,
        notes,
        relatedMedicationId,
        relatedMedicationName,
      ];
}
