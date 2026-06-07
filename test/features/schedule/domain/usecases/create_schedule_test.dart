import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/domain/entities/schedule_time.dart';
import 'package:drug/features/schedule/domain/entities/scheduled_medication.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/create_schedule.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;
  late CreateSchedule useCase;

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
    useCase = CreateSchedule(mockRepository);
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

  test('should call createSchedule on repository', () async {
    when(() => mockRepository.createSchedule(any()))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));

    final result = await useCase(tSchedule);

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.createSchedule(tSchedule)).called(1);
  });

  test('should return ValidationFailure on error', () async {
    when(() => mockRepository.createSchedule(any())).thenAnswer(
      (_) async => const Left<Failure, Unit>(ValidationFailure('Invalid')),
    );

    final result = await useCase(tSchedule);

    expect(result.isLeft(), isTrue);
    result.fold(
      (f) => expect(f, isA<ValidationFailure>()),
      (_) {},
    );
  });
}
