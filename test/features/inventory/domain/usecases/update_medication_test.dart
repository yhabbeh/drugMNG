import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drug/features/inventory/domain/usecases/update_medication.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository mockRepository;
  late UpdateMedication useCase;

  setUpAll(() {
    registerFallbackValue(
      Medication(
        id: '',
        name: '',
        drugForm: DrugForm.tablet,
        currentStock: 0,
        expirationDate: DateTime(2024),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    );
  });

  setUp(() {
    mockRepository = MockInventoryRepository();
    useCase = UpdateMedication(mockRepository);
  });

  final tMedication = Medication(
    id: '1',
    name: 'Updated Med',
    drugForm: DrugForm.tablet,
    currentStock: 20,
    expirationDate: DateTime(2025, 6, 1),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  test('should call updateMedication on the repository', () async {
    when(() => mockRepository.updateMedication(any()))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase(tMedication);

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.updateMedication(tMedication)).called(1);
  });

  test('should return ConflictFailure when repository fails', () async {
    when(() => mockRepository.updateMedication(any())).thenAnswer(
      (_) async => const Left(ConflictFailure('Conflict')),
    );

    final result = await useCase(tMedication);

    expect(result.isLeft(), isTrue);
    result.fold((f) {
      expect(f, isA<ConflictFailure>());
    }, (_) {});
  });
}
