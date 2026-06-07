import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drug/features/inventory/domain/usecases/get_medications.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository mockRepository;
  late GetMedications useCase;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockRepository = MockInventoryRepository();
    useCase = GetMedications(mockRepository);
  });

  final tMedications = [
    Medication(
      id: '1',
      name: 'Test Med',
      drugForm: DrugForm.tablet,
      currentStock: 30,
      expirationDate: DateTime(2025, 6, 1),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
  ];

  test('should call getMedications on the repository', () async {
    when(() => mockRepository.getMedications())
        .thenAnswer((_) async => Right(tMedications));

    final result = await useCase(const NoParams());

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.getMedications()).called(1);
  });

  test('should return ServerFailure when repository fails', () async {
    when(() => mockRepository.getMedications()).thenAnswer(
      (_) async => const Left(ServerFailure('Failed')),
    );

    final result = await useCase(const NoParams());

    expect(result.isLeft(), isTrue);
    result.fold((f) {
      expect(f, isA<ServerFailure>());
    }, (_) {});
  });
}
