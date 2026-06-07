import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/schedule/domain/entities/adherence_report.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/get_adherence_report.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;
  late GetAdherenceReport useCase;

  setUpAll(() {
    registerFallbackValue(
      AdherenceParams(
        profileId: '',
        periodStart: DateTime(2020),
        periodEnd: DateTime(2020),
      ),
    );
  });

  setUp(() {
    mockRepository = MockScheduleRepository();
    useCase = GetAdherenceReport(mockRepository);
  });

  final tParams = AdherenceParams(
    profileId: 'profile-1',
    periodStart: DateTime(2026, 6, 1),
    periodEnd: DateTime(2026, 6, 30),
  );
  final tReport = AdherenceReport(
    profileId: 'profile-1',
    periodStart: DateTime(2026, 6, 1),
    periodEnd: DateTime(2026, 6, 30),
    totalScheduled: 30,
    taken: 25,
    skipped: 3,
    missed: 2,
  );

  test('should call getAdherenceReport on repository', () async {
    when(() => mockRepository.getAdherenceReport(any())).thenAnswer(
      (_) async => Right<Failure, AdherenceReport>(tReport),
    );

    final result = await useCase(tParams);

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.getAdherenceReport(tParams)).called(1);
  });

  test('should return ServerFailure on error', () async {
    when(() => mockRepository.getAdherenceReport(any())).thenAnswer(
      (_) async => const Left<Failure, AdherenceReport>(ServerFailure('Err')),
    );

    final result = await useCase(tParams);

    expect(result.isLeft(), isTrue);
    result.fold(
      (f) => expect(f, isA<ServerFailure>()),
      (_) {},
    );
  });

  test('adherencePercent returns correct value', () {
    expect(tReport.adherencePercent, closeTo(83.33, 0.01));
  });
}
