import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/domain/entities/schedule_time.dart';
import 'package:drug/features/schedule/domain/entities/scheduled_medication.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/update_schedule.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;
  late UpdateSchedule useCase;

  setUpAll(() {
    registerFallbackValue(
      DoseSchedule(
        id: '',
        profileId: '',
        medications: const [ScheduledMedication(medicationId: '', medicationName: '')],
        recurrenceRule: const RecurrenceRule(
          type: ScheduleType.daily,
          times: [ScheduleTime(hour: 8, minute: 0)],
        ),
        startDate: DateTime(2020),
        createdAt: DateTime(2020),
        updatedAt: DateTime(2020),
      ),
    );
  });

  setUp(() {
    mockRepository = MockScheduleRepository();
    useCase = UpdateSchedule(mockRepository);
  });

  final tSchedule = DoseSchedule(
    id: '1',
    profileId: 'profile-1',
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

  test('should call updateSchedule on repository', () async {
    when(() => mockRepository.updateSchedule(any()))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));

    final result = await useCase(tSchedule);

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.updateSchedule(tSchedule)).called(1);
  });

  test('should return CacheFailure on error', () async {
    when(() => mockRepository.updateSchedule(any())).thenAnswer(
      (_) async => const Left<Failure, Unit>(CacheFailure('Not found')),
    );

    final result = await useCase(tSchedule);

    expect(result.isLeft(), isTrue);
    result.fold(
      (f) => expect(f, isA<CacheFailure>()),
      (_) {},
    );
  });
}
