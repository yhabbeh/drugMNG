import 'dart:convert';

import 'package:drug/features/inventory/domain/value_objects/enums.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/domain/entities/schedule_time.dart';
import 'package:drug/features/schedule/domain/entities/scheduled_medication.dart';

final class DoseScheduleModel {
  const DoseScheduleModel({
    required this.id,
    required this.profileId,
    required this.medications,
    required this.recurrenceRuleJson,
    required this.startDate,
    this.endDate,
    this.instructions,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final List<ScheduledMedication> medications;
  final String recurrenceRuleJson;
  final DateTime startDate;
  final DateTime? endDate;
  final String? instructions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DoseScheduleModel.fromJson(Map<String, dynamic> json) {
    List<ScheduledMedication> medications;

    if (json.containsKey('medications')) {
      // New format
      medications = (json['medications'] as List<dynamic>)
          .map((e) =>
              ScheduledMedication.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      // Legacy single-medication format — migrate transparently
      medications = [
        ScheduledMedication(
          medicationId: json['medicationId'] as String? ?? '',
          medicationName: json['medicationName'] as String? ?? '',
          dosageAmount: (json['dosageAmount'] as num?)?.toDouble(),
          dosageUnit: json['dosageUnit'] != null
              ? DosageUnit.values.firstWhere(
                  (u) => u.name == json['dosageUnit'],
                  orElse: () => DosageUnit.mg,
                )
              : null,
        ),
      ];
    }

    return DoseScheduleModel(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      medications: medications,
      recurrenceRuleJson: json['recurrenceRule'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      instructions: json['instructions'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'medications': medications.map((m) => m.toJson()).toList(),
      'recurrenceRule': recurrenceRuleJson,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'instructions': instructions,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static String _serializeRecurrenceRule(RecurrenceRule rule) {
    return jsonEncode({
      'type': rule.type.name,
      'times': rule.times
          .map((t) => {'hour': t.hour, 'minute': t.minute})
          .toList(),
      'intervalHours': rule.intervalHours,
      'daysOfWeek': rule.daysOfWeek,
    });
  }

  static RecurrenceRule _deserializeRecurrenceRule(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return RecurrenceRule(
      type: ScheduleType.values.firstWhere((t) => t.name == map['type']),
      times: (map['times'] as List<dynamic>)
          .map((t) => ScheduleTime(
                hour: (t as Map)['hour'] as int,
                minute: t['minute'] as int,
              ))
          .toList(),
      intervalHours: map['intervalHours'] as int?,
      daysOfWeek: (map['daysOfWeek'] as List<dynamic>?)
          ?.map((d) => d as int)
          .toList(),
    );
  }

  factory DoseScheduleModel.fromDomain(DoseSchedule schedule) {
    return DoseScheduleModel(
      id: schedule.id,
      profileId: schedule.profileId,
      medications: schedule.medications,
      recurrenceRuleJson: _serializeRecurrenceRule(schedule.recurrenceRule),
      startDate: schedule.startDate,
      endDate: schedule.endDate,
      instructions: schedule.instructions,
      isActive: schedule.isActive,
      createdAt: schedule.createdAt,
      updatedAt: schedule.updatedAt,
    );
  }

  DoseSchedule toDomain() {
    return DoseSchedule(
      id: id,
      profileId: profileId,
      medications: medications,
      recurrenceRule: _deserializeRecurrenceRule(recurrenceRuleJson),
      startDate: startDate,
      endDate: endDate,
      instructions: instructions,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
