import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/inventory/domain/entities/expiration_warning.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drug/features/inventory/domain/usecases/get_expiring_medications.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository mockRepository;
  late GetExpiringMedications useCase;

  setUpAll(() {
    registerFallbackValue(const ExpiringParams(withinDays: 30));
  });

  setUp(() {
    mockRepository = MockInventoryRepository();
    useCase = GetExpiringMedications(mockRepository);
  });

  const tParams = ExpiringParams(withinDays: 30);

  final tWarnings = [
    ExpirationWarning(
      medication: Medication(
        id: '1',
        name: 'Test Med',
        drugForm: DrugForm.tablet,
        currentStock: 30,
        expirationDate: DateTime(2025, 6, 1),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
      daysUntilExpiry: 15,
      severity: ExpirationSeverity.warning,
    ),
  ];

  test('should call getExpiringMedications on the repository', () async {
    when(() => mockRepository.getExpiringMedications(any()))
        .thenAnswer((_) async => Right(tWarnings));

    final result = await useCase(tParams);

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.getExpiringMedications(tParams)).called(1);
  });

  test('should return ServerFailure when repository fails', () async {
    when(() => mockRepository.getExpiringMedications(any())).thenAnswer(
      (_) async => const Left(ServerFailure('Server error')),
    );

    final result = await useCase(tParams);

    expect(result.isLeft(), isTrue);
    result.fold((f) {
      expect(f, isA<ServerFailure>());
    }, (_) {});
  });
}
