import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/domain/entities/schedule_time.dart';
import 'package:drug/features/schedule/domain/entities/scheduled_medication.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/watch_schedules_for_profile.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;
  late WatchSchedulesForProfile useCase;

  setUp(() {
    mockRepository = MockScheduleRepository();
    useCase = WatchSchedulesForProfile(mockRepository);
  });

  const tProfileId = 'profile-1';
  final tSchedule = DoseSchedule(
    id: '1',
    profileId: tProfileId,
    medications: const [
      ScheduledMedication(
        medicationId: 'med-1',
        medicationName: 'Amoxicillin',
      ),
    ],
    recurrenceRule: const RecurrenceRule(
      type: ScheduleType.daily,
      times: [ScheduleTime(hour: 8, minute: 0)],
    ),
    startDate: DateTime(2026, 6, 1),
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );

  test('should return schedule stream from repository', () {
    when(() => mockRepository.watchSchedulesForProfile(any())).thenAnswer(
      (_) => Stream.value(
        Right<Failure, List<DoseSchedule>>([tSchedule]),
      ),
    );

    final stream = useCase(tProfileId);

    expect(stream, isA<Stream<Either<Failure, List<DoseSchedule>>>>());
    verify(() => mockRepository.watchSchedulesForProfile(tProfileId)).called(1);
  });

  test('should propagate error', () {
    when(() => mockRepository.watchSchedulesForProfile(any())).thenAnswer(
      (_) => Stream.value(
        const Left<Failure, List<DoseSchedule>>(ServerFailure('Error')),
      ),
    );

    final stream = useCase(tProfileId);

    expect(
      stream,
      emits(isA<Left<Failure, List<DoseSchedule>>>()),
    );
  });
}
