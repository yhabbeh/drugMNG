import '../../domain/entities/symptom_entry.dart';

final class SymptomEntryModel {
  const SymptomEntryModel({
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
  final String severity;
  final String notes;
  final String? relatedMedicationId;
  final String? relatedMedicationName;

  factory SymptomEntryModel.fromJson(Map<String, dynamic> json) {
    return SymptomEntryModel(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      severity: json['severity'] as String,
      notes: json['notes'] as String,
      relatedMedicationId: json['relatedMedicationId'] as String?,
      relatedMedicationName: json['relatedMedicationName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'occurredAt': occurredAt.toIso8601String(),
      'severity': severity,
      'notes': notes,
      'relatedMedicationId': relatedMedicationId,
      'relatedMedicationName': relatedMedicationName,
    };
  }

  factory SymptomEntryModel.fromDomain(SymptomEntry domain) {
    return SymptomEntryModel(
      id: domain.id,
      profileId: domain.profileId,
      occurredAt: domain.occurredAt,
      severity: domain.severity.name,
      notes: domain.notes,
      relatedMedicationId: domain.relatedMedicationId,
      relatedMedicationName: domain.relatedMedicationName,
    );
  }

  SymptomEntry toDomain() {
    return SymptomEntry(
      id: id,
      profileId: profileId,
      occurredAt: occurredAt,
      severity: SymptomSeverity.values.firstWhere((e) => e.name == severity),
      notes: notes,
      relatedMedicationId: relatedMedicationId,
      relatedMedicationName: relatedMedicationName,
    );
  }
}
