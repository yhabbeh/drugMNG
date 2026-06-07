import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/log_dose_skipped.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;
  late LogDoseSkipped useCase;

  setUpAll(() {
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
    mockRepository = MockScheduleRepository();
    useCase = LogDoseSkipped(mockRepository);
  });

  final tParams = LogDoseParams(
    scheduleId: '1',
    profileId: 'profile-1',
    medicationId: 'med-1',
    scheduledAt: DateTime(2026, 6, 1, 8, 0),
  );

  test('should call logDoseSkipped on repository', () async {
    when(() => mockRepository.logDoseSkipped(any()))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));

    final result = await useCase(tParams);

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.logDoseSkipped(tParams)).called(1);
  });

  test('should return ServerFailure on error', () async {
    when(() => mockRepository.logDoseSkipped(any())).thenAnswer(
      (_) async => const Left<Failure, Unit>(ServerFailure('Failed')),
    );

    final result = await useCase(tParams);

    expect(result.isLeft(), isTrue);
    result.fold(
      (f) => expect(f, isA<ServerFailure>()),
      (_) {},
    );
  });
}
