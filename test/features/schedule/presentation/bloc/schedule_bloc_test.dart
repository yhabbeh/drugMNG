import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/domain/entities/schedule_time.dart';
import 'package:drug/features/schedule/domain/entities/scheduled_medication.dart';
import 'package:drug/features/schedule/domain/usecases/create_schedule.dart';
import 'package:drug/features/schedule/domain/usecases/delete_schedule.dart';
import 'package:drug/features/schedule/domain/usecases/get_schedules_for_profile.dart';
import 'package:drug/features/schedule/domain/usecases/log_dose_skipped.dart';
import 'package:drug/features/schedule/domain/usecases/log_dose_taken.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';
import 'package:drug/features/schedule/domain/usecases/update_schedule.dart';
import 'package:drug/features/schedule/domain/usecases/watch_schedules_for_profile.dart';
import 'package:drug/features/schedule/presentation/bloc/schedule_bloc.dart';

class MockGetSchedulesForProfile extends Mock
    implements GetSchedulesForProfile {}

class MockWatchSchedulesForProfile extends Mock
    implements WatchSchedulesForProfile {}

class MockCreateSchedule extends Mock implements CreateSchedule {}

class MockUpdateSchedule extends Mock implements UpdateSchedule {}

class MockDeleteSchedule extends Mock implements DeleteSchedule {}

class MockLogDoseTaken extends Mock implements LogDoseTaken {}

class MockLogDoseSkipped extends Mock implements LogDoseSkipped {}

void main() {
  late MockGetSchedulesForProfile mockGetSchedulesForProfile;
  late MockWatchSchedulesForProfile mockWatchSchedulesForProfile;
  late MockCreateSchedule mockCreateSchedule;
  late MockUpdateSchedule mockUpdateSchedule;
  late MockDeleteSchedule mockDeleteSchedule;
  late MockLogDoseTaken mockLogDoseTaken;
  late MockLogDoseSkipped mockLogDoseSkipped;

  const tProfileId = 'profile-1';
  final tSchedule = DoseSchedule(
    id: 'sched-1',
    profileId: tProfileId,
    medications: const [
      ScheduledMedication(
        medicationId: 'med-1',
        medicationName: 'Amoxicillin',
        dosageAmount: 500,
        dosageUnit: DosageUnit.mg,
      ),
    ],
    recurrenceRule: const RecurrenceRule(
      type: ScheduleType.daily,
      times: [ScheduleTime(hour: 8, minute: 0)],
    ),
    startDate: DateTime(2026, 6, 1),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 15),
  );
  final tLogParams = LogDoseParams(
    scheduleId: 'sched-1',
    profileId: tProfileId,
    medicationId: 'med-1',
    scheduledAt: DateTime(2026, 6, 1, 8, 0),
  );

  setUpAll(() {
    registerFallbackValue(tProfileId);
    registerFallbackValue(tSchedule);
    registerFallbackValue(tLogParams);
    registerFallbackValue(
      LogDoseParams(
        scheduleId: '',
        profileId: '',
        medicationId: '',
        scheduledAt: DateTime(2020),
      ),
    );
  });

  setUp(() {
    mockGetSchedulesForProfile = MockGetSchedulesForProfile();
    mockWatchSchedulesForProfile = MockWatchSchedulesForProfile();
    mockCreateSchedule = MockCreateSchedule();
    mockUpdateSchedule = MockUpdateSchedule();
    mockDeleteSchedule = MockDeleteSchedule();
    mockLogDoseTaken = MockLogDoseTaken();
    mockLogDoseSkipped = MockLogDoseSkipped();
    when(() => mockGetSchedulesForProfile(any())).thenAnswer(
      (_) async => const Right<Failure, List<DoseSchedule>>([]),
    );
  });

  group('ScheduleBloc', () {
    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleLoading, ScheduleLoaded] when SchedulesStarted receives schedules',
      setUp: () {
        when(() => mockWatchSchedulesForProfile(any())).thenAnswer(
          (_) => Stream.value(
            Right<Failure, List<DoseSchedule>>([tSchedule]),
          ),
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      act: (bloc) => bloc.add(const SchedulesStarted(tProfileId)),
      expect: () => [
        const ScheduleLoading(),
        ScheduleLoaded(schedules: [tSchedule]),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleLoading] when ScheduleAdded succeeds',
      setUp: () {
        when(() => mockCreateSchedule(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        when(() => mockWatchSchedulesForProfile(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      seed: () => const ScheduleLoaded(schedules: []),
      act: (bloc) => bloc.add(ScheduleAdded(tSchedule)),
      expect: () => [
        const ScheduleLoading(),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleLoading, ScheduleError] when ScheduleAdded fails',
      setUp: () {
        when(() => mockCreateSchedule(any())).thenAnswer(
          (_) async => const Left<Failure, Unit>(
            ValidationFailure('Add failed'),
          ),
        );
        when(() => mockWatchSchedulesForProfile(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      act: (bloc) => bloc.add(ScheduleAdded(tSchedule)),
      expect: () => [
        const ScheduleLoading(),
        isA<ScheduleError>(),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleLoading] when ScheduleUpdated succeeds',
      setUp: () {
        when(() => mockUpdateSchedule(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        when(() => mockWatchSchedulesForProfile(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      seed: () => ScheduleLoaded(schedules: [tSchedule]),
      act: (bloc) => bloc.add(ScheduleUpdated(tSchedule)),
      expect: () => [
        const ScheduleLoading(),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleLoading, ScheduleError] when ScheduleUpdated fails',
      setUp: () {
        when(() => mockUpdateSchedule(any())).thenAnswer(
          (_) async => const Left<Failure, Unit>(
            ValidationFailure('Update failed'),
          ),
        );
        when(() => mockWatchSchedulesForProfile(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      act: (bloc) => bloc.add(ScheduleUpdated(tSchedule)),
      expect: () => [
        const ScheduleLoading(),
        isA<ScheduleError>(),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleLoading] when ScheduleDeleted succeeds',
      setUp: () {
        when(() => mockDeleteSchedule(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        when(() => mockWatchSchedulesForProfile(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      seed: () => ScheduleLoaded(schedules: [tSchedule]),
      act: (bloc) => bloc.add(const ScheduleDeleted('sched-1')),
      expect: () => [
        const ScheduleLoading(),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleLoading, ScheduleError] when ScheduleDeleted fails',
      setUp: () {
        when(() => mockDeleteSchedule(any())).thenAnswer(
          (_) async => const Left<Failure, Unit>(
            CacheFailure('Delete failed'),
          ),
        );
        when(() => mockWatchSchedulesForProfile(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      act: (bloc) => bloc.add(const ScheduleDeleted('sched-1')),
      expect: () => [
        const ScheduleLoading(),
        isA<ScheduleError>(),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [] when ScheduleDoseTaken succeeds',
      setUp: () {
        when(() => mockLogDoseTaken(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        when(() => mockWatchSchedulesForProfile(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      seed: () => ScheduleLoaded(schedules: [tSchedule]),
      act: (bloc) => bloc.add(ScheduleDoseTaken(tLogParams)),
      expect: () => [],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleError] when ScheduleDoseTaken fails',
      setUp: () {
        when(() => mockLogDoseTaken(any())).thenAnswer(
          (_) async => const Left<Failure, Unit>(
            CacheFailure('Log dose failed'),
          ),
        );
        when(() => mockWatchSchedulesForProfile(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      act: (bloc) => bloc.add(ScheduleDoseTaken(tLogParams)),
      expect: () => [
        isA<ScheduleError>(),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [] when ScheduleDoseSkipped succeeds',
      setUp: () {
        when(() => mockLogDoseSkipped(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        when(() => mockWatchSchedulesForProfile(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      seed: () => ScheduleLoaded(schedules: [tSchedule]),
      act: (bloc) => bloc.add(ScheduleDoseSkipped(tLogParams)),
      expect: () => [],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleError] when ScheduleDoseSkipped fails',
      setUp: () {
        when(() => mockLogDoseSkipped(any())).thenAnswer(
          (_) async => const Left<Failure, Unit>(
            CacheFailure('Log dose failed'),
          ),
        );
        when(() => mockWatchSchedulesForProfile(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      act: (bloc) => bloc.add(ScheduleDoseSkipped(tLogParams)),
      expect: () => [
        isA<ScheduleError>(),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleLoaded] when SchedulesRefreshRequested succeeds',
      setUp: () {
        when(() => mockGetSchedulesForProfile(any())).thenAnswer(
          (_) async => Right<Failure, List<DoseSchedule>>([tSchedule]),
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      act: (bloc) => bloc.add(const SchedulesRefreshRequested(tProfileId)),
      expect: () => [
        ScheduleLoaded(schedules: [tSchedule]),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleError] when SchedulesRefreshRequested fails',
      setUp: () {
        when(() => mockGetSchedulesForProfile(any())).thenAnswer(
          (_) async => const Left<Failure, List<DoseSchedule>>(
            CacheFailure('Refresh failed'),
          ),
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      act: (bloc) => bloc.add(const SchedulesRefreshRequested(tProfileId)),
      expect: () => [
        isA<ScheduleError>(),
      ],
    );

    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleLoading, ScheduleLoaded] when SchedulesStarted switches profile',
      setUp: () {
        when(() => mockWatchSchedulesForProfile(any())).thenAnswer(
          (invocation) {
            final profileId = invocation.positionalArguments.first as String;
            if (profileId == tProfileId) {
              return Stream.value(
                Right<Failure, List<DoseSchedule>>([tSchedule]),
              );
            }
            return Stream.value(
              const Right<Failure, List<DoseSchedule>>([]),
            );
          },
        );
      },
      build: () => ScheduleBloc(
        getSchedulesForProfile: mockGetSchedulesForProfile,
        watchSchedulesForProfile: mockWatchSchedulesForProfile,
        createSchedule: mockCreateSchedule,
        updateSchedule: mockUpdateSchedule,
        deleteSchedule: mockDeleteSchedule,
        logDoseTaken: mockLogDoseTaken,
        logDoseSkipped: mockLogDoseSkipped,
      ),
      act: (bloc) {
        bloc.add(const SchedulesStarted(tProfileId));
        bloc.add(const SchedulesStarted('profile-2'));
      },
      expect: () => [
        const ScheduleLoading(),
        ScheduleLoaded(schedules: [tSchedule]),
        const ScheduleLoading(),
        const ScheduleLoaded(schedules: []),
      ],
    );
  });
}
