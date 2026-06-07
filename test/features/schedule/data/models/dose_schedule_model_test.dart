import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:drug/features/inventory/domain/value_objects/enums.dart';
import 'package:drug/features/schedule/data/models/dose_schedule_model.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/domain/entities/schedule_time.dart';
import 'package:drug/features/schedule/domain/entities/scheduled_medication.dart';

void main() {
  final tRecurrenceJson = jsonEncode({
    'type': 'daily',
    'times': [{'hour': 8, 'minute': 0}, {'hour': 20, 'minute': 0}],
    'intervalHours': null,
    'daysOfWeek': null,
  });

  final tJson = <String, dynamic>{
    'id': 'sched-1',
    'profileId': 'profile-1',
    'medicationId': 'med-1',
    'medicationName': 'Amoxicillin',
    'recurrenceRule': tRecurrenceJson,
    'startDate': '2026-06-01T00:00:00.000',
    'endDate': null,
    'dosageAmount': 500.0,
    'dosageUnit': 'mg',
    'instructions': 'Take with food',
    'isActive': true,
    'createdAt': '2025-01-01T00:00:00.000',
    'updatedAt': '2025-01-15T00:00:00.000',
  };

  const tMedications = [
    ScheduledMedication(
      medicationId: 'med-1',
      medicationName: 'Amoxicillin',
      dosageAmount: 500.0,
      dosageUnit: DosageUnit.mg,
    ),
  ];

  final tModel = DoseScheduleModel(
    id: 'sched-1',
    profileId: 'profile-1',
    medications: tMedications,
    recurrenceRuleJson: tRecurrenceJson,
    startDate: DateTime(2026, 6, 1),
    instructions: 'Take with food',
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 15),
  );

  final tEntity = DoseSchedule(
    id: 'sched-1',
    profileId: 'profile-1',
    medications: tMedications,
    recurrenceRule: const RecurrenceRule(
      type: ScheduleType.daily,
      times: [
        ScheduleTime(hour: 8, minute: 0),
        ScheduleTime(hour: 20, minute: 0),
      ],
    ),
    startDate: DateTime(2026, 6, 1),
    instructions: 'Take with food',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 15),
  );

  group('DoseScheduleModel', () {
    test('fromJson creates model correctly', () {
      final result = DoseScheduleModel.fromJson(tJson);
      expect(result.id, tModel.id);
      expect(result.profileId, tModel.profileId);
      expect(result.medications.first.medicationId,
          tModel.medications.first.medicationId);
      expect(result.medications.first.medicationName,
          tModel.medications.first.medicationName);
      expect(result.medications.first.dosageAmount,
          tModel.medications.first.dosageAmount);
      expect(result.medications.first.dosageUnit,
          tModel.medications.first.dosageUnit);
      expect(result.recurrenceRuleJson, tRecurrenceJson);
      expect(result.startDate, tModel.startDate);
      expect(result.instructions, tModel.instructions);
      expect(result.isActive, true);
    });

    test('toJson produces correct map', () {
      final result = tModel.toJson();
      expect(result['id'], 'sched-1');
      expect(result['medications'][0]['medicationName'], 'Amoxicillin');
      expect(result['recurrenceRule'], tRecurrenceJson);
      expect(result['isActive'], true);
    });

    test('toJson round-trip preserves data', () {
      final json = tModel.toJson();
      final restored = DoseScheduleModel.fromJson(json);
      expect(restored.id, tModel.id);
      expect(restored.medications.first.medicationName,
          tModel.medications.first.medicationName);
      expect(restored.recurrenceRuleJson, tRecurrenceJson);
      expect(restored.startDate, tModel.startDate);
    });

    test('fromDomain creates model from entity', () {
      final result = DoseScheduleModel.fromDomain(tEntity);
      expect(result.id, 'sched-1');
      expect(result.medications.first.dosageUnit, DosageUnit.mg);
      expect(result.isActive, true);
    });

    test('toDomain creates entity from model', () {
      final result = tModel.toDomain();
      expect(result.id, 'sched-1');
      expect(result.recurrenceRule.type, ScheduleType.daily);
      expect(result.recurrenceRule.times.length, 2);
      expect(result.recurrenceRule.times.first.hour, 8);
      expect(result.dosageUnit, DosageUnit.mg);
    });

    test('fromDomain toDomain round-trip preserves entity', () {
      final model = DoseScheduleModel.fromDomain(tEntity);
      final entity = model.toDomain();
      expect(entity.id, tEntity.id);
      expect(entity.medications.first.medicationName,
          tEntity.medications.first.medicationName);
      expect(entity.recurrenceRule.type, tEntity.recurrenceRule.type);
      expect(entity.recurrenceRule.times.length,
          tEntity.recurrenceRule.times.length);
    });

    test('handles nullable fields', () {
      final minimalJson = <String, dynamic>{
        'id': 'sched-2',
        'profileId': 'profile-1',
        'medicationId': 'med-2',
        'medicationName': 'Ibuprofen',
        'recurrenceRule': jsonEncode({
          'type': 'prn',
          'times': [],
          'intervalHours': null,
          'daysOfWeek': null,
        }),
        'startDate': '2026-06-01T00:00:00.000',
        'createdAt': '2025-01-01T00:00:00.000',
        'updatedAt': '2025-01-01T00:00:00.000',
      };
      final model = DoseScheduleModel.fromJson(minimalJson);
      expect(model.endDate, isNull);
      expect(model.medications.first.dosageAmount, isNull);
      expect(model.medications.first.dosageUnit, isNull);
      expect(model.instructions, isNull);
    });

    test('handles prn recurrence rule serialization', () {
      const prnMedications = [
        ScheduledMedication(
          medicationId: 'med-3',
          medicationName: 'PRN Med',
        ),
      ];
      final prnEntity = DoseSchedule(
        id: 'sched-3',
        profileId: 'profile-1',
        medications: prnMedications,
        recurrenceRule: const RecurrenceRule(
          type: ScheduleType.prn,
        ),
        startDate: DateTime(2026, 6, 1),
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      final model = DoseScheduleModel.fromDomain(prnEntity);
      final restored = model.toDomain();
      expect(restored.recurrenceRule.type, ScheduleType.prn);
      expect(restored.recurrenceRule.times, isEmpty);
    });
  });
}
