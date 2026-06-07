import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/usecases/get_dose_logs_for_date.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';
import 'package:drug/features/schedule/presentation/cubit/dose_log_cubit.dart';

class MockGetDoseLogsForDate extends Mock implements GetDoseLogsForDate {}

void main() {
  late MockGetDoseLogsForDate mockGetDoseLogsForDate;

  const tProfileId = 'profile-1';
  final tDate = DateTime(2026, 6, 1);
  final tLog = DoseLog(
    id: 'log-1',
    scheduleId: 'sched-1',
    profileId: tProfileId,
    medicationId: 'med-1',
    medicationName: 'Amoxicillin',
    scheduledAt: DateTime(2026, 6, 1, 8, 0),
    takenAt: DateTime(2026, 6, 1, 8, 5),
    status: DoseStatus.taken,
    stockDeductedCount: 1,
  );

  setUpAll(() {
    registerFallbackValue(
      GetLogsForDateParams(profileId: '', date: DateTime(2020)),
    );
  });

  setUp(() {
    mockGetDoseLogsForDate = MockGetDoseLogsForDate();
  });

  group('DoseLogCubit', () {
    blocTest<DoseLogCubit, DoseLogState>(
      'emits [DoseLogLoading, DoseLogLoaded] when loadForDate succeeds',
      setUp: () {
        when(() => mockGetDoseLogsForDate(any())).thenAnswer(
          (_) async =>
              Right<Failure, List<DoseLog>>([tLog]),
        );
      },
      build: () => DoseLogCubit(
        getDoseLogsForDate: mockGetDoseLogsForDate,
      ),
      act: (cubit) => cubit.loadForDate(tProfileId, tDate),
      expect: () => [
        const DoseLogLoading(),
        DoseLogLoaded(logs: [tLog], date: tDate),
      ],
    );

    blocTest<DoseLogCubit, DoseLogState>(
      'emits [DoseLogLoading, DoseLogError] when loadForDate fails',
      setUp: () {
        when(() => mockGetDoseLogsForDate(any())).thenAnswer(
          (_) async => const Left<Failure, List<DoseLog>>(
            CacheFailure('Load failed'),
          ),
        );
      },
      build: () => DoseLogCubit(
        getDoseLogsForDate: mockGetDoseLogsForDate,
      ),
      act: (cubit) => cubit.loadForDate(tProfileId, tDate),
      expect: () => [
        const DoseLogLoading(),
        isA<DoseLogError>(),
      ],
    );
  });
}
