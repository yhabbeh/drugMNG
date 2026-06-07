import 'package:flutter_test/flutter_test.dart';

import 'package:drug/features/schedule/data/models/dose_log_model.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';

void main() {
  final tJson = <String, dynamic>{
    'id': 'log-1',
    'scheduleId': 'sched-1',
    'profileId': 'profile-1',
    'medicationId': 'med-1',
    'medicationName': 'Amoxicillin',
    'scheduledAt': '2026-06-01T08:00:00.000',
    'takenAt': '2026-06-01T08:05:00.000',
    'status': 'taken',
    'notes': null,
    'stockDeductedCount': 1,
  };

  final tModel = DoseLogModel(
    id: 'log-1',
    scheduleId: 'sched-1',
    profileId: 'profile-1',
    medicationId: 'med-1',
    medicationName: 'Amoxicillin',
    scheduledAt: DateTime(2026, 6, 1, 8, 0),
    takenAt: DateTime(2026, 6, 1, 8, 5),
    status: 'taken',
    stockDeductedCount: 1,
  );

  final tEntity = DoseLog(
    id: 'log-1',
    scheduleId: 'sched-1',
    profileId: 'profile-1',
    medicationId: 'med-1',
    medicationName: 'Amoxicillin',
    scheduledAt: DateTime(2026, 6, 1, 8, 0),
    takenAt: DateTime(2026, 6, 1, 8, 5),
    status: DoseStatus.taken,
    stockDeductedCount: 1,
  );

  group('DoseLogModel', () {
    test('fromJson creates model correctly', () {
      final result = DoseLogModel.fromJson(tJson);
      expect(result.id, tModel.id);
      expect(result.scheduleId, tModel.scheduleId);
      expect(result.profileId, tModel.profileId);
      expect(result.medicationName, tModel.medicationName);
      expect(result.status, 'taken');
      expect(result.stockDeductedCount, 1);
    });

    test('toJson produces correct map', () {
      final result = tModel.toJson();
      expect(result['id'], 'log-1');
      expect(result['status'], 'taken');
      expect(result['stockDeductedCount'], 1);
    });

    test('toJson round-trip preserves data', () {
      final json = tModel.toJson();
      final restored = DoseLogModel.fromJson(json);
      expect(restored.id, tModel.id);
      expect(restored.status, tModel.status);
      expect(restored.scheduledAt, tModel.scheduledAt);
      expect(restored.takenAt, tModel.takenAt);
    });

    test('fromDomain creates model from entity', () {
      final result = DoseLogModel.fromDomain(tEntity);
      expect(result.id, 'log-1');
      expect(result.status, 'taken');
      expect(result.stockDeductedCount, 1);
    });

    test('toDomain creates entity from model', () {
      final result = tModel.toDomain();
      expect(result.id, 'log-1');
      expect(result.status, DoseStatus.taken);
      expect(result.stockDeductedCount, 1);
    });

    test('fromDomain toDomain round-trip preserves entity', () {
      final model = DoseLogModel.fromDomain(tEntity);
      final entity = model.toDomain();
      expect(entity.id, tEntity.id);
      expect(entity.status, tEntity.status);
      expect(entity.scheduledAt, tEntity.scheduledAt);
    });

    test('handles nullable takenAt and notes', () {
      final skippedJson = <String, dynamic>{
        'id': 'log-2',
        'scheduleId': 'sched-1',
        'profileId': 'profile-1',
        'medicationId': 'med-1',
        'medicationName': 'Amoxicillin',
        'scheduledAt': '2026-06-01T20:00:00.000',
        'status': 'skipped',
        'notes': 'Had side effects',
        'stockDeductedCount': 0,
      };
      final model = DoseLogModel.fromJson(skippedJson);
      expect(model.takenAt, isNull);
      expect(model.notes, 'Had side effects');
      expect(model.status, 'skipped');
      expect(model.stockDeductedCount, 0);
    });

    test('handles missed status without takenAt', () {
      final missedJson = <String, dynamic>{
        'id': 'log-3',
        'scheduleId': 'sched-1',
        'profileId': 'profile-1',
        'medicationId': 'med-1',
        'medicationName': 'Amoxicillin',
        'scheduledAt': '2026-06-01T08:00:00.000',
        'status': 'missed',
        'stockDeductedCount': 0,
      };
      final model = DoseLogModel.fromJson(missedJson);
      final entity = model.toDomain();
      expect(entity.status, DoseStatus.missed);
      expect(entity.takenAt, isNull);
    });
  });
}
