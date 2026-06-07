import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/usecases/add_medication.dart';
import 'package:drug/features/inventory/domain/usecases/delete_medication.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';
import 'package:drug/features/inventory/domain/usecases/update_medication.dart';
import 'package:drug/features/inventory/domain/usecases/update_medication_stock.dart';
import 'package:drug/features/inventory/domain/usecases/watch_medications.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';
import 'package:drug/features/inventory/presentation/bloc/inventory_bloc.dart';

class MockWatchMedications extends Mock implements WatchMedications {}

class MockAddMedication extends Mock implements AddMedication {}

class MockUpdateMedication extends Mock implements UpdateMedication {}

class MockDeleteMedication extends Mock implements DeleteMedication {}

class MockUpdateMedicationStock extends Mock
    implements UpdateMedicationStock {}

void main() {
  late MockWatchMedications mockWatchMedications;
  late MockAddMedication mockAddMedication;
  late MockUpdateMedication mockUpdateMedication;
  late MockDeleteMedication mockDeleteMedication;
  late MockUpdateMedicationStock mockUpdateMedicationStock;

  final tMedication = Medication(
    id: 'med-1',
    name: 'Amoxicillin',
    drugForm: DrugForm.capsule,
    currentStock: 30,
    expirationDate: DateTime(2026, 12, 31),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 15),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(tMedication);
    registerFallbackValue(
      const UpdateStockParams(
        medicationId: '',
        quantityChange: 0,
      ),
    );
  });

  setUp(() {
    mockWatchMedications = MockWatchMedications();
    mockAddMedication = MockAddMedication();
    mockUpdateMedication = MockUpdateMedication();
    mockDeleteMedication = MockDeleteMedication();
    mockUpdateMedicationStock = MockUpdateMedicationStock();
  });

  InventoryBloc buildBloc() => InventoryBloc(
        watchMedications: mockWatchMedications,
        addMedication: mockAddMedication,
        updateMedication: mockUpdateMedication,
        deleteMedication: mockDeleteMedication,
        updateMedicationStock: mockUpdateMedicationStock,
      );

  group('InventoryBloc', () {
    blocTest<InventoryBloc, InventoryState>(
      'emits [InventoryLoading, InventoryLoaded] when MedicationsStarted receives medications',
      setUp: () {
        when(() => mockWatchMedications(any())).thenAnswer(
          (_) => Stream.value(
            Right<Failure, List<Medication>>([tMedication]),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const MedicationsStarted()),
      expect: () => [
        const InventoryLoading(),
        InventoryLoaded(medications: [tMedication]),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits [InventoryLoading] when MedicationAdded succeeds',
      setUp: () {
        when(() => mockAddMedication(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        when(() => mockWatchMedications(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: buildBloc,
      seed: () => const InventoryLoaded(medications: []),
      act: (bloc) => bloc.add(MedicationAdded(tMedication)),
      expect: () => [
        const InventoryLoading(),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits [InventoryLoading, InventoryError] when MedicationAdded fails',
      setUp: () {
        when(() => mockAddMedication(any())).thenAnswer(
          (_) async => const Left<Failure, Unit>(
            ValidationFailure('Add failed'),
          ),
        );
        when(() => mockWatchMedications(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(MedicationAdded(tMedication)),
      expect: () => [
        const InventoryLoading(),
        isA<InventoryError>(),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits [InventoryLoading] when MedicationUpdated succeeds',
      setUp: () {
        when(() => mockUpdateMedication(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        when(() => mockWatchMedications(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: buildBloc,
      seed: () => InventoryLoaded(medications: [tMedication]),
      act: (bloc) => bloc.add(MedicationUpdated(tMedication)),
      expect: () => [
        const InventoryLoading(),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits [InventoryLoading, InventoryError] when MedicationUpdated fails',
      setUp: () {
        when(() => mockUpdateMedication(any())).thenAnswer(
          (_) async => const Left<Failure, Unit>(
            ValidationFailure('Update failed'),
          ),
        );
        when(() => mockWatchMedications(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(MedicationUpdated(tMedication)),
      expect: () => [
        const InventoryLoading(),
        isA<InventoryError>(),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits [InventoryLoading] when MedicationDeleted succeeds',
      setUp: () {
        when(() => mockDeleteMedication(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        when(() => mockWatchMedications(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: buildBloc,
      seed: () => InventoryLoaded(medications: [tMedication]),
      act: (bloc) => bloc.add(const MedicationDeleted('med-1')),
      expect: () => [
        const InventoryLoading(),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits [InventoryLoading, InventoryError] when MedicationDeleted fails',
      setUp: () {
        when(() => mockDeleteMedication(any())).thenAnswer(
          (_) async => const Left<Failure, Unit>(
            CacheFailure('Delete failed'),
          ),
        );
        when(() => mockWatchMedications(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const MedicationDeleted('med-1')),
      expect: () => [
        const InventoryLoading(),
        isA<InventoryError>(),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits [InventoryLoading] when MedicationStockAdjusted succeeds',
      setUp: () {
        when(() => mockUpdateMedicationStock(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        when(() => mockWatchMedications(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: buildBloc,
      seed: () => InventoryLoaded(medications: [tMedication]),
      act: (bloc) => bloc.add(
        const MedicationStockAdjusted(
          UpdateStockParams(
            medicationId: 'med-1',
            quantityChange: -5,
          ),
        ),
      ),
      expect: () => [
        const InventoryLoading(),
      ],
    );

    blocTest<InventoryBloc, InventoryState>(
      'emits [InventoryLoading, InventoryError] when MedicationStockAdjusted fails',
      setUp: () {
        when(() => mockUpdateMedicationStock(any())).thenAnswer(
          (_) async => const Left<Failure, Unit>(
            CacheFailure('Stock update failed'),
          ),
        );
        when(() => mockWatchMedications(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const MedicationStockAdjusted(
          UpdateStockParams(
            medicationId: 'med-1',
            quantityChange: -5,
          ),
        ),
      ),
      expect: () => [
        const InventoryLoading(),
        isA<InventoryError>(),
      ],
    );
  });
}
