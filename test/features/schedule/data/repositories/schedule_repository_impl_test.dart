import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/exceptions.dart';
import 'package:drug/core/network/network_info.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';
import 'package:drug/features/schedule/data/datasources/schedule_local_datasource.dart';
import 'package:drug/features/schedule/data/datasources/schedule_remote_datasource.dart';
import 'package:drug/features/schedule/data/models/dose_log_model.dart';
import 'package:drug/features/schedule/data/models/dose_schedule_model.dart';
import 'package:drug/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:drug/features/schedule/domain/entities/scheduled_medication.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';

class MockRemoteDataSource extends Mock
    implements ScheduleRemoteDataSource {}

class MockLocalDataSource extends Mock
    implements ScheduleLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late ScheduleRepositoryImpl repository;
  late MockRemoteDataSource mockRemoteDataSource;
  late MockLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late MockInventoryRepository mockInventoryRepository;

  const tProfileId = 'profile-1';
  final tRecurrenceJson = jsonEncode({
    'type': 'daily',
    'times': [{'hour': 8, 'minute': 0}],
  });

  final tScheduleModel = DoseScheduleModel(
    id: 'sched-1',
    profileId: tProfileId,
    medications: const [
      ScheduledMedication(
        medicationId: 'med-1',
        medicationName: 'Amoxicillin',
      ),
    ],
    recurrenceRuleJson: tRecurrenceJson,
    startDate: DateTime(2026, 6, 1),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 15),
  );
  final tSchedule = tScheduleModel.toDomain();

  setUpAll(() {
    registerFallbackValue(tScheduleModel);
    registerFallbackValue(
      DoseLogModel(
        id: '',
        scheduleId: '',
        profileId: '',
        medicationId: '',
        medicationName: '',
        scheduledAt: DateTime(2020),
        takenAt: null,
        status: 'taken',
        stockDeductedCount: 0,
      ),
    );
    registerFallbackValue(
      const UpdateStockParams(
        medicationId: '',
        quantityChange: 0,
      ),
    );
  });

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    mockInventoryRepository = MockInventoryRepository();

    repository = ScheduleRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
      inventoryRepository: mockInventoryRepository,
    );

    // Default stubs
    when(() => mockLocalDataSource.getAllSchedules(any())).thenReturn([]);
    when(() => mockLocalDataSource.deleteLog(any()))
        .thenAnswer((_) async {});
    when(() => mockInventoryRepository.getMedications())
        .thenAnswer((_) async => const Right([]));
    when(() => mockInventoryRepository.updateMedicationStock(any()))
        .thenReturn(const Right(unit));
  });

  group('getSchedulesForProfile', () {
    test('should return cached data and trigger background refresh', () async {
      when(() => mockLocalDataSource.getAllSchedules(tProfileId))
          .thenReturn([tScheduleModel]);
      when(() => mockRemoteDataSource.getAllSchedules(tProfileId))
          .thenAnswer((_) async => [tScheduleModel]);
      when(() => mockLocalDataSource.saveSchedule(any()))
          .thenAnswer((_) async {});

      final result = await repository.getSchedulesForProfile(tProfileId);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) {},
        (schedules) {
          expect(schedules.length, equals(1));
          expect(schedules.first.medicationName, equals('Amoxicillin'));
        },
      );
      verify(() => mockRemoteDataSource.getAllSchedules(tProfileId)).called(1);
    });

    test('should fetch from remote when cache is empty', () async {
      when(() => mockLocalDataSource.getAllSchedules(tProfileId))
          .thenReturn([]);
      when(() => mockRemoteDataSource.getAllSchedules(tProfileId))
          .thenAnswer((_) async => [tScheduleModel]);
      when(() => mockLocalDataSource.saveSchedule(any()))
          .thenAnswer((_) async {});

      final result = await repository.getSchedulesForProfile(tProfileId);

      expect(result.isRight(), isTrue);
      verify(() => mockRemoteDataSource.getAllSchedules(tProfileId)).called(1);
      verify(() => mockLocalDataSource.saveSchedule(any())).called(1);
    });

    test('should return CacheFailure when local and remote fail', () async {
      when(() => mockLocalDataSource.getAllSchedules(tProfileId))
          .thenReturn([]);
      when(() => mockRemoteDataSource.getAllSchedules(tProfileId))
          .thenThrow(const ServerException('Network error'));

      final result = await repository.getSchedulesForProfile(tProfileId);

      expect(result.isLeft(), isTrue);
    });
  });

  group('createSchedule', () {
    test('should save locally and remotely when online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.createSchedule(any()))
          .thenAnswer((_) async => tScheduleModel);
      when(() => mockLocalDataSource.saveSchedule(any()))
          .thenAnswer((_) async {});

      final result = await repository.createSchedule(tSchedule);

      expect(result.isRight(), isTrue);
      verify(() => mockRemoteDataSource.createSchedule(any())).called(1);
      verify(() => mockLocalDataSource.saveSchedule(any())).called(1);
    });

    test('should save locally only when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.saveSchedule(any()))
          .thenAnswer((_) async {});

      final result = await repository.createSchedule(tSchedule);

      expect(result.isRight(), isTrue);
      verifyNever(() => mockRemoteDataSource.createSchedule(any()));
      verify(() => mockLocalDataSource.saveSchedule(any())).called(1);
    });

    test('should return failure on error', () async {
      when(() => mockNetworkInfo.isConnected).thenThrow(const ServerException('Err'));

      final result = await repository.createSchedule(tSchedule);

      expect(result.isLeft(), isTrue);
    });
  });

  group('updateSchedule', () {
    test('should save locally and remotely when online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.saveSchedule(any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteDataSource.updateSchedule(any()))
          .thenAnswer((_) async => tScheduleModel);

      final result = await repository.updateSchedule(tSchedule);

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.saveSchedule(any())).called(1);
      verify(() => mockRemoteDataSource.updateSchedule(any())).called(1);
    });

    test('should save locally only when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.saveSchedule(any()))
          .thenAnswer((_) async {});

      final result = await repository.updateSchedule(tSchedule);

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.saveSchedule(any())).called(1);
      verifyNever(() => mockRemoteDataSource.updateSchedule(any()));
    });
  });

  group('deleteSchedule', () {
    test('should delete locally', () async {
      when(() => mockLocalDataSource.deleteSchedule('sched-1'))
          .thenAnswer((_) async {});

      final result = await repository.deleteSchedule('sched-1');

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.deleteSchedule('sched-1')).called(1);
    });
  });

  group('logDoseTaken', () {
    test('should log dose locally and remotely when online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.logDose(any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteDataSource.logDoseTaken(any()))
          .thenAnswer((_) async {});

      final result = await repository.logDoseTaken(
        LogDoseParams(
          scheduleId: 'sched-1',
          profileId: tProfileId,
          medicationId: 'med-1',
          scheduledAt: DateTime(2026, 6, 1, 8, 0),
        ),
      );

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.logDose(any())).called(1);
      verify(() => mockRemoteDataSource.logDoseTaken(any())).called(1);
    });

    test('should log dose locally only when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.logDose(any()))
          .thenAnswer((_) async {});

      final result = await repository.logDoseTaken(
        LogDoseParams(
          scheduleId: 'sched-1',
          profileId: tProfileId,
          medicationId: 'med-1',
          scheduledAt: DateTime(2026, 6, 1, 8, 0),
        ),
      );

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.logDose(any())).called(1);
      verifyNever(() => mockRemoteDataSource.logDoseTaken(any()));
    });

    test('should deduct stock for all medications in the schedule when taken', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.getAllSchedules(any())).thenReturn([tScheduleModel]);
      when(() => mockLocalDataSource.logDose(any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteDataSource.logDoseTaken(any()))
          .thenAnswer((_) async {});

      final result = await repository.logDoseTaken(
        LogDoseParams(
          scheduleId: 'sched-1',
          profileId: tProfileId,
          medicationId: 'med-1',
          scheduledAt: DateTime(2026, 6, 1, 8, 0),
        ),
      );

      expect(result.isRight(), isTrue);
      verify(() => mockInventoryRepository.updateMedicationStock(
        const UpdateStockParams(
          medicationId: 'med-1',
          quantityChange: -1,
          reason: 'Dose taken',
        ),
      )).called(1);
    });
  });

  group('logDoseSkipped', () {
    test('should log skipped dose locally and remotely when online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.logDose(any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteDataSource.logDoseSkipped(any()))
          .thenAnswer((_) async {});

      final result = await repository.logDoseSkipped(
        LogDoseParams(
          scheduleId: 'sched-1',
          profileId: tProfileId,
          medicationId: 'med-1',
          scheduledAt: DateTime(2026, 6, 1, 8, 0),
        ),
      );

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.logDose(any())).called(1);
      verify(() => mockRemoteDataSource.logDoseSkipped(any())).called(1);
    });
  });

  group('getDoseLogsForDate', () {
    test('should return logs for date', () async {
      when(() => mockLocalDataSource.getLogsForDate(
            tProfileId,
            DateTime(2026, 6, 1),
          )).thenReturn([]);

      final result = await repository.getDoseLogsForDate(
        GetLogsForDateParams(
          profileId: tProfileId,
          date: DateTime(2026, 6, 1),
        ),
      );

      expect(result.isRight(), isTrue);
    });
  });

  group('getAdherenceReport', () {
    test('should compute adherence report from local logs', () async {
      when(() => mockLocalDataSource.getLogsForDate(
            tProfileId,
            DateTime(2026, 6, 1),
          )).thenReturn([]);

      final result = await repository.getAdherenceReport(
        AdherenceParams(
          profileId: tProfileId,
          periodStart: DateTime(2026, 6, 1),
          periodEnd: DateTime(2026, 6, 7),
        ),
      );

      expect(result.isRight(), isTrue);
    });
  });

  group('revertDoseLog', () {
    final tLogDate = DateTime(2026, 6, 1, 8, 0);
    final tLogTaken = DoseLogModel(
      id: 'log-1',
      scheduleId: 'sched-1',
      profileId: tProfileId,
      medicationId: 'med-1',
      medicationName: 'Amoxicillin',
      scheduledAt: tLogDate,
      takenAt: DateTime(2026, 6, 1, 8, 5),
      status: 'taken',
      stockDeductedCount: 1,
    );
    final tLogSkipped = DoseLogModel(
      id: 'log-2',
      scheduleId: 'sched-1',
      profileId: tProfileId,
      medicationId: 'med-1',
      medicationName: 'Amoxicillin',
      scheduledAt: tLogDate,
      takenAt: null,
      status: 'skipped',
      stockDeductedCount: 0,
    );

    test('should restore stock and delete log when reverting a taken dose', () async {
      when(() => mockLocalDataSource.getLogsForDate(tProfileId, any()))
          .thenReturn([tLogTaken]);
      when(() => mockLocalDataSource.deleteLog('log-1'))
          .thenAnswer((_) async {});

      final result = await repository.revertDoseLog(
        LogDoseParams(
          scheduleId: 'sched-1',
          profileId: tProfileId,
          medicationId: 'med-1',
          scheduledAt: tLogDate,
        ),
      );

      expect(result.isRight(), isTrue);
      verify(() => mockInventoryRepository.updateMedicationStock(
        const UpdateStockParams(
          medicationId: 'med-1',
          quantityChange: 1,
          reason: 'Dose reverted',
        ),
      )).called(1);
      verify(() => mockLocalDataSource.deleteLog('log-1')).called(1);
    });

    test('should delete log but not change stock when reverting a skipped dose', () async {
      when(() => mockLocalDataSource.getLogsForDate(tProfileId, any()))
          .thenReturn([tLogSkipped]);
      when(() => mockLocalDataSource.deleteLog('log-2'))
          .thenAnswer((_) async {});

      final result = await repository.revertDoseLog(
        LogDoseParams(
          scheduleId: 'sched-1',
          profileId: tProfileId,
          medicationId: 'med-1',
          scheduledAt: tLogDate,
        ),
      );

      expect(result.isRight(), isTrue);
      verifyNever(() => mockInventoryRepository.updateMedicationStock(any()));
      verify(() => mockLocalDataSource.deleteLog('log-2')).called(1);
    });
  });

  group('idempotency and status changes', () {
    final tLogDate = DateTime(2026, 6, 1, 8, 0);
    final tLogTaken = DoseLogModel(
      id: 'log-1',
      scheduleId: 'sched-1',
      profileId: tProfileId,
      medicationId: 'med-1',
      medicationName: 'Amoxicillin',
      scheduledAt: tLogDate,
      takenAt: DateTime(2026, 6, 1, 8, 5),
      status: 'taken',
      stockDeductedCount: 1,
    );
    final tLogSkipped = DoseLogModel(
      id: 'log-2',
      scheduleId: 'sched-1',
      profileId: tProfileId,
      medicationId: 'med-1',
      medicationName: 'Amoxicillin',
      scheduledAt: tLogDate,
      takenAt: null,
      status: 'skipped',
      stockDeductedCount: 0,
    );

    test('should not deduct stock again if dose is already marked taken', () async {
      when(() => mockLocalDataSource.getLogsForDate(tProfileId, any()))
          .thenReturn([tLogTaken]);
      when(() => mockLocalDataSource.logDose(any())).thenAnswer((_) async {});
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.logDoseTaken(
        LogDoseParams(
          scheduleId: 'sched-1',
          profileId: tProfileId,
          medicationId: 'med-1',
          scheduledAt: tLogDate,
        ),
      );

      expect(result.isRight(), isTrue);
      verifyNever(() => mockInventoryRepository.updateMedicationStock(any()));
    });

    test('should deduct stock if status changes from skipped to taken', () async {
      when(() => mockLocalDataSource.getLogsForDate(tProfileId, any()))
          .thenReturn([tLogSkipped]);
      when(() => mockLocalDataSource.logDose(any())).thenAnswer((_) async {});
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.logDoseTaken(
        LogDoseParams(
          scheduleId: 'sched-1',
          profileId: tProfileId,
          medicationId: 'med-1',
          scheduledAt: tLogDate,
        ),
      );

      expect(result.isRight(), isTrue);
      verify(() => mockInventoryRepository.updateMedicationStock(
        const UpdateStockParams(
          medicationId: 'med-1',
          quantityChange: -1,
          reason: 'Dose taken',
        ),
      )).called(1);
    });

    test('should restore stock if status changes from taken to skipped', () async {
      when(() => mockLocalDataSource.getLogsForDate(tProfileId, any()))
          .thenReturn([tLogTaken]);
      when(() => mockLocalDataSource.logDose(any())).thenAnswer((_) async {});
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.logDoseSkipped(
        LogDoseParams(
          scheduleId: 'sched-1',
          profileId: tProfileId,
          medicationId: 'med-1',
          scheduledAt: tLogDate,
        ),
      );

      expect(result.isRight(), isTrue);
      verify(() => mockInventoryRepository.updateMedicationStock(
        const UpdateStockParams(
          medicationId: 'med-1',
          quantityChange: 1,
          reason: 'Dose change to skipped',
        ),
      )).called(1);
    });
  });
}
