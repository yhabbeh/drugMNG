import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/delete_schedule.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;
  late DeleteSchedule useCase;

  setUp(() {
    mockRepository = MockScheduleRepository();
    useCase = DeleteSchedule(mockRepository);
  });

  test('should call deleteSchedule on repository with given id', () async {
    when(() => mockRepository.deleteSchedule(any()))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));

    final result = await useCase('1');

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.deleteSchedule('1')).called(1);
  });

  test('should return CacheFailure when repository fails', () async {
    when(() => mockRepository.deleteSchedule(any())).thenAnswer(
      (_) async => const Left<Failure, Unit>(CacheFailure('Not found')),
    );

    final result = await useCase('1');

    expect(result.isLeft(), isTrue);
    result.fold(
      (f) => expect(f, isA<CacheFailure>()),
      (_) {},
    );
  });
}
