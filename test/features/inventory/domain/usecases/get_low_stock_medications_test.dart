import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drug/features/inventory/domain/usecases/get_low_stock_medications.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository mockRepository;
  late GetLowStockMedications useCase;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockRepository = MockInventoryRepository();
    useCase = GetLowStockMedications(mockRepository);
  });

  final tLowStock = [
    Medication(
      id: '1',
      name: 'Low Stock Med',
      drugForm: DrugForm.tablet,
      currentStock: 3,
      refillThreshold: 10,
      expirationDate: DateTime(2025, 6, 1),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
  ];

  test('should call getLowStockMedications on the repository', () async {
    when(() => mockRepository.getLowStockMedications())
        .thenAnswer((_) async => Right(tLowStock));

    final result = await useCase(const NoParams());

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.getLowStockMedications()).called(1);
  });

  test('should return CacheFailure when repository fails', () async {
    when(() => mockRepository.getLowStockMedications()).thenAnswer(
      (_) async => const Left(CacheFailure('Cache miss')),
    );

    final result = await useCase(const NoParams());

    expect(result.isLeft(), isTrue);
    result.fold((f) {
      expect(f, isA<CacheFailure>());
    }, (_) {});
  });
}
