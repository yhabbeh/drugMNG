import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/features/schedule/data/datasources/schedule_local_datasource.dart';
import 'package:drug/features/schedule/data/models/dose_log_model.dart';
import 'package:drug/features/schedule/data/models/dose_schedule_model.dart';
import 'package:drug/features/schedule/domain/entities/scheduled_medication.dart';

class MockSchedulesBox extends Mock implements Box {}

class MockLogsBox extends Mock implements Box {}

void main() {
  late MockSchedulesBox mockSchedulesBox;
  late MockLogsBox mockLogsBox;
  late ScheduleLocalDataSourceImpl dataSource;

  const tProfileId = 'profile-1';
  final tSchedule = DoseScheduleModel(
    id: 'sched-1',
    profileId: tProfileId,
    medications: const [
      ScheduledMedication(
        medicationId: 'med-1',
        medicationName: 'Amoxicillin',
      ),
    ],
    recurrenceRuleJson: jsonEncode({
      'type': 'daily',
      'times': [{'hour': 8, 'minute': 0}],
    }),
    startDate: DateTime(2026, 6, 1),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 15),
  );

  final tSchedule2 = DoseScheduleModel(
    id: 'sched-2',
    profileId: 'profile-2',
    medications: const [
      ScheduledMedication(
        medicationId: 'med-2',
        medicationName: 'Ibuprofen',
      ),
    ],
    recurrenceRuleJson: jsonEncode({
      'type': 'prn',
      'times': [],
    }),
    startDate: DateTime(2026, 6, 1),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  final tLog = DoseLogModel(
    id: 'log-1',
    scheduleId: 'sched-1',
    profileId: tProfileId,
    medicationId: 'med-1',
    medicationName: 'Amoxicillin',
    scheduledAt: DateTime(2026, 6, 1, 8, 0),
    takenAt: DateTime(2026, 6, 1, 8, 5),
    status: 'taken',
    stockDeductedCount: 1,
  );

  final tLog2 = DoseLogModel(
    id: 'log-2',
    scheduleId: 'sched-2',
    profileId: 'profile-2',
    medicationId: 'med-2',
    medicationName: 'Ibuprofen',
    scheduledAt: DateTime(2026, 6, 1, 12, 0),
    status: 'skipped',
    stockDeductedCount: 0,
  );

  setUp(() {
    mockSchedulesBox = MockSchedulesBox();
    mockLogsBox = MockLogsBox();
    dataSource = ScheduleLocalDataSourceImpl(mockSchedulesBox, mockLogsBox);
  });

  group('getAllSchedules', () {
    test('should return schedules filtered by profileId', () {
      when(() => mockSchedulesBox.values).thenReturn([
        jsonEncode(tSchedule.toJson()),
        jsonEncode(tSchedule2.toJson()),
      ]);

      final result = dataSource.getAllSchedules(tProfileId);
      expect(result.length, 1);
      expect(result.first.id, 'sched-1');
    });

    test('should return empty list when no match', () {
      when(() => mockSchedulesBox.values).thenReturn([]);

      final result = dataSource.getAllSchedules(tProfileId);
      expect(result, isEmpty);
    });
  });

  group('watchSchedules', () {
    test('should emit filtered list on box changes', () {
      when(() => mockSchedulesBox.values).thenReturn([
        jsonEncode(tSchedule.toJson()),
      ]);
      when(() => mockSchedulesBox.watch()).thenAnswer(
        (_) => const Stream.empty(),
      );

      final result = dataSource.watchSchedules(tProfileId);
      expect(result, isA<Stream<List<DoseScheduleModel>>>());
    });
  });

  group('saveSchedule', () {
    test('should store schedule as JSON string', () async {
      when(() => mockSchedulesBox.put(any(), any()))
          .thenAnswer((_) async {});

      await dataSource.saveSchedule(tSchedule);

      verify(() => mockSchedulesBox.put(tSchedule.id, any())).called(1);
    });
  });

  group('deleteSchedule', () {
    test('should remove schedule by id', () async {
      when(() => mockSchedulesBox.delete(any())).thenAnswer((_) async {});

      await dataSource.deleteSchedule('sched-1');

      verify(() => mockSchedulesBox.delete('sched-1')).called(1);
    });
  });

  group('logDose', () {
    test('should store dose log as JSON string', () async {
      when(() => mockLogsBox.put(any(), any())).thenAnswer((_) async {});

      await dataSource.logDose(tLog);

      verify(() => mockLogsBox.put(tLog.id, any())).called(1);
    });
  });

  group('getLogsForDate', () {
    test('should return logs filtered by profileId and date range', () {
      when(() => mockLogsBox.values).thenReturn([
        jsonEncode(tLog.toJson()),
        jsonEncode(tLog2.toJson()),
      ]);

      final result = dataSource.getLogsForDate(
        tProfileId,
        DateTime(2026, 6, 1),
      );

      expect(result.length, 1);
      expect(result.first.id, 'log-1');
    });

    test('should return empty list when no logs for date', () {
      when(() => mockLogsBox.values).thenReturn([]);

      final result = dataSource.getLogsForDate(
        tProfileId,
        DateTime(2026, 6, 1),
      );

      expect(result, isEmpty);
    });
  });

  group('watchLogs', () {
    test('should emit filtered logs on box changes', () {
      when(() => mockLogsBox.values).thenReturn([
        jsonEncode(tLog.toJson()),
      ]);
      when(() => mockLogsBox.watch()).thenAnswer(
        (_) => const Stream.empty(),
      );

      final result = dataSource.watchLogs(tProfileId);
      expect(result, isA<Stream<List<DoseLogModel>>>());
    });
  });
}
