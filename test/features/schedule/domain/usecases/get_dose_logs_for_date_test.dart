import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/get_dose_logs_for_date.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;
  late GetDoseLogsForDate useCase;

  setUpAll(() {
    registerFallbackValue(
      GetLogsForDateParams(profileId: '', date: DateTime(2020)),
    );
  });

  setUp(() {
    mockRepository = MockScheduleRepository();
    useCase = GetDoseLogsForDate(mockRepository);
  });

  final tParams = GetLogsForDateParams(
    profileId: 'profile-1',
    date: DateTime(2026, 6, 1),
  );
  final tLog = DoseLog(
    id: '1',
    scheduleId: 'sched-1',
    profileId: 'profile-1',
    medicationId: 'med-1',
    medicationName: 'Amoxicillin',
    scheduledAt: DateTime(2026, 6, 1, 8, 0),
    status: DoseStatus.pending,
  );

  test('should call getDoseLogsForDate on repository', () async {
    when(() => mockRepository.getDoseLogsForDate(any())).thenAnswer(
      (_) async => Right<Failure, List<DoseLog>>([tLog]),
    );

    final result = await useCase(tParams);

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.getDoseLogsForDate(tParams)).called(1);
  });

  test('should return CacheFailure on error', () async {
    when(() => mockRepository.getDoseLogsForDate(any())).thenAnswer(
      (_) async => const Left<Failure, List<DoseLog>>(CacheFailure('Failed')),
    );

    final result = await useCase(tParams);

    expect(result.isLeft(), isTrue);
    result.fold(
      (f) => expect(f, isA<CacheFailure>()),
      (_) {},
    );
  });
}
