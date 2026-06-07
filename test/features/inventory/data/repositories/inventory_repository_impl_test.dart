import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/exceptions.dart';
import 'package:drug/core/error/failures.dart';
import 'package:drug/core/network/network_info.dart';
import 'package:drug/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:drug/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:drug/features/inventory/data/models/medication_model.dart';
import 'package:drug/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';

class MockRemoteDataSource extends Mock
    implements InventoryRemoteDataSource {}

class MockLocalDataSource extends Mock
    implements InventoryLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late InventoryRepositoryImpl repository;
  late MockRemoteDataSource mockRemoteDataSource;
  late MockLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  final tMedicationModel = MedicationModel(
    id: 'med-1',
    name: 'Amoxicillin',
    drugForm: 'capsule',
    currentStock: 30,
    expirationDate: DateTime(2026, 12, 31),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 15),
  );
  final tMedication = tMedicationModel.toDomain();

  setUpAll(() {
    registerFallbackValue(tMedicationModel);
  });

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();

    repository = InventoryRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('getMedications', () {
    test('should return cached data and trigger background refresh', () async {
      when(() => mockLocalDataSource.getAllMedications())
          .thenReturn([tMedicationModel]);
      when(() => mockRemoteDataSource.getAllMedications())
          .thenAnswer((_) async => [tMedicationModel]);
      when(() => mockLocalDataSource.cacheMedications(any()))
          .thenAnswer((_) async {});

      final result = await repository.getMedications();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) {},
        (medications) {
          expect(medications.length, equals(1));
          expect(medications.first.name, equals('Amoxicillin'));
        },
      );
      verify(() => mockRemoteDataSource.getAllMedications()).called(1);
    });

    test('should fetch from remote when cache is empty', () async {
      when(() => mockLocalDataSource.getAllMedications()).thenReturn([]);
      when(() => mockRemoteDataSource.getAllMedications())
          .thenAnswer((_) async => [tMedicationModel]);
      when(() => mockLocalDataSource.cacheMedications(any()))
          .thenAnswer((_) async {});

      final result = await repository.getMedications();

      expect(result.isRight(), isTrue);
      verify(() => mockRemoteDataSource.getAllMedications()).called(1);
      verify(() => mockLocalDataSource.cacheMedications([tMedicationModel]))
          .called(1);
    });

    test('should return CacheFailure when local and remote fail', () async {
      when(() => mockLocalDataSource.getAllMedications()).thenReturn([]);
      when(() => mockRemoteDataSource.getAllMedications())
          .thenThrow(const ServerException('Network error'));

      final result = await repository.getMedications();

      expect(result.isLeft(), isTrue);
    });
  });

  group('addMedication', () {
    test('should save locally and remotely when online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.createMedication(any()))
          .thenAnswer((_) async => tMedicationModel);
      when(() => mockLocalDataSource.saveMedication(any()))
          .thenAnswer((_) async {});

      final result = await repository.addMedication(tMedication);

      expect(result.isRight(), isTrue);
      verify(() => mockRemoteDataSource.createMedication(any())).called(1);
      verify(() => mockLocalDataSource.saveMedication(any())).called(1);
    });

    test('should save locally only when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.saveMedication(any()))
          .thenAnswer((_) async {});

      final result = await repository.addMedication(tMedication);

      expect(result.isRight(), isTrue);
      verifyNever(() => mockRemoteDataSource.createMedication(any()));
      verify(() => mockLocalDataSource.saveMedication(any())).called(1);
    });

    test('should return failure on error', () async {
      when(() => mockNetworkInfo.isConnected).thenThrow(const ServerException('Err'));

      final result = await repository.addMedication(tMedication);

      expect(result.isLeft(), isTrue);
    });
  });

  group('updateMedication', () {
    test('should save locally and remotely when online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.saveMedication(any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteDataSource.updateMedication(any()))
          .thenAnswer((_) async => tMedicationModel);

      final result = await repository.updateMedication(tMedication);

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.saveMedication(any())).called(1);
      verify(() => mockRemoteDataSource.updateMedication(any())).called(1);
    });

    test('should save locally only when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.saveMedication(any()))
          .thenAnswer((_) async {});

      final result = await repository.updateMedication(tMedication);

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.saveMedication(any())).called(1);
      verifyNever(() => mockRemoteDataSource.updateMedication(any()));
    });
  });

  group('deleteMedication', () {
    test('should delete locally', () async {
      when(() => mockLocalDataSource.deleteMedication('med-1'))
          .thenAnswer((_) async {});

      final result = await repository.deleteMedication('med-1');

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.deleteMedication('med-1')).called(1);
    });
  });

  group('updateMedicationStock', () {
    const tParams = UpdateStockParams(
      medicationId: 'med-1',
      quantityChange: -5,
    );

    test('should update stock locally and remotely when online', () async {
      when(() => mockLocalDataSource.getAllMedications())
          .thenReturn([tMedicationModel]);
      when(() => mockLocalDataSource.saveMedication(any()))
          .thenAnswer((_) async {});
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.updateMedication(any()))
          .thenAnswer((_) async => tMedicationModel);

      final result = await repository.updateMedicationStock(tParams);

      expect(result.isRight(), isTrue);
      final captured = verify(() => mockLocalDataSource.saveMedication(
        captureAny(),
      )).captured.first as MedicationModel;
      expect(captured.currentStock, equals(25));
    });

    test('should return CacheFailure when medication not found', () async {
      when(() => mockLocalDataSource.getAllMedications()).thenReturn([]);

      final result = await repository.updateMedicationStock(tParams);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) {},
      );
    });
  });

  group('getExpiringMedications', () {
    const tParams = ExpiringParams(withinDays: 30);

    test('should return expiring medications', () async {
      final nearExpiry = MedicationModel(
        id: 'med-2',
        name: 'Near Expiry',
        drugForm: 'tablet',
        currentStock: 10,
        expirationDate: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      when(() => mockLocalDataSource.getAllMedications())
          .thenReturn([nearExpiry, tMedicationModel]);

      final result = await repository.getExpiringMedications(tParams);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) {},
        (warnings) {
          expect(warnings.length, equals(1));
          expect(warnings.first.medication.name, equals('Near Expiry'));
        },
      );
    });
  });

  group('getLowStockMedications', () {
    test('should return low stock medications', () async {
      final lowStock = MedicationModel(
        id: 'med-3',
        name: 'Low Stock',
        drugForm: 'tablet',
        currentStock: 3,
        refillThreshold: 5,
        expirationDate: DateTime(2026, 12, 31),
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      when(() => mockLocalDataSource.getAllMedications())
          .thenReturn([lowStock, tMedicationModel]);

      final result = await repository.getLowStockMedications();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) {},
        (medications) {
          expect(medications.length, equals(1));
          expect(medications.first.name, equals('Low Stock'));
        },
      );
    });
  });
}
