import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/domain/entities/schedule_time.dart';
import 'package:drug/features/schedule/domain/entities/scheduled_medication.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/get_schedules_for_profile.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;
  late GetSchedulesForProfile useCase;

  setUp(() {
    mockRepository = MockScheduleRepository();
    useCase = GetSchedulesForProfile(mockRepository);
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

  test('should call getSchedulesForProfile on repository', () async {
    when(() => mockRepository.getSchedulesForProfile(any()))
        .thenAnswer((_) async => Right<Failure, List<DoseSchedule>>([tSchedule]));

    final result = await useCase(tProfileId);

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.getSchedulesForProfile(tProfileId)).called(1);
  });

  test('should return CacheFailure on error', () async {
    when(() => mockRepository.getSchedulesForProfile(any())).thenAnswer(
      (_) async => const Left<Failure, List<DoseSchedule>>(
        CacheFailure('Failed'),
      ),
    );

    final result = await useCase(tProfileId);

    expect(result.isLeft(), isTrue);
    result.fold(
      (f) => expect(f, isA<CacheFailure>()),
      (_) {},
    );
  });
}
