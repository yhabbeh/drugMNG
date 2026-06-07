import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';
import 'package:drug/features/inventory/domain/usecases/update_medication_stock.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository mockRepository;
  late UpdateMedicationStock useCase;

  setUpAll(() {
    registerFallbackValue(
      const UpdateStockParams(
        medicationId: '',
        quantityChange: 0,
      ),
    );
  });

  setUp(() {
    mockRepository = MockInventoryRepository();
    useCase = UpdateMedicationStock(mockRepository);
  });

  const tParams = UpdateStockParams(
    medicationId: '1',
    quantityChange: -5,
    reason: 'Dispensed',
  );

  test('should call updateMedicationStock on the repository', () async {
    when(() => mockRepository.updateMedicationStock(any()))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase(tParams);

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.updateMedicationStock(tParams)).called(1);
  });

  test('should return ValidationFailure when repository fails', () async {
    when(() => mockRepository.updateMedicationStock(any())).thenAnswer(
      (_) async => const Left(ValidationFailure('Invalid stock update')),
    );

    final result = await useCase(tParams);

    expect(result.isLeft(), isTrue);
    result.fold((f) {
      expect(f, isA<ValidationFailure>());
    }, (_) {});
  });
}
