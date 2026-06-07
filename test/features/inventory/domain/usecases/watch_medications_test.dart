import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drug/features/inventory/domain/usecases/watch_medications.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository mockRepository;
  late WatchMedications useCase;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockRepository = MockInventoryRepository();
    useCase = WatchMedications(mockRepository);
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

  test('should return stream of medications from repository', () {
    when(() => mockRepository.watchMedications())
        .thenAnswer((_) => Stream.value(Right(tMedications)));

    expect(
      useCase(const NoParams()),
      emits(isA<Right<Failure, List<Medication>>>()),
    );
  });

  test('should emit AuthFailure on error', () {
    when(() => mockRepository.watchMedications()).thenAnswer(
      (_) => Stream.value(
        const Left<Failure, List<Medication>>(AuthFailure('Unauthorized')),
      ),
    );

    expect(
      useCase(const NoParams()),
      emits(isA<Left<Failure, List<Medication>>>()),
    );
  });
}
