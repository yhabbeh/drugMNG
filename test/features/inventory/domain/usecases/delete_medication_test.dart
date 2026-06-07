import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drug/features/inventory/domain/usecases/delete_medication.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository mockRepository;
  late DeleteMedication useCase;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    mockRepository = MockInventoryRepository();
    useCase = DeleteMedication(mockRepository);
  });

  test('should call deleteMedication on the repository with given id',
      () async {
    when(() => mockRepository.deleteMedication('1'))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase('1');

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.deleteMedication('1')).called(1);
  });

  test('should return CacheFailure when repository fails', () async {
    when(() => mockRepository.deleteMedication('1')).thenAnswer(
      (_) async => const Left(CacheFailure('Delete failed')),
    );

    final result = await useCase('1');

    expect(result.isLeft(), isTrue);
    result.fold((f) {
      expect(f, isA<CacheFailure>());
    }, (_) {});
  });
}
