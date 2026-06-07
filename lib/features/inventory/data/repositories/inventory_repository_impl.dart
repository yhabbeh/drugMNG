import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/exceptions.dart';
import 'package:drug/core/error/failure_mapper.dart';
import 'package:drug/core/error/failures.dart';
import 'package:drug/core/network/network_info.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:drug/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:drug/features/inventory/data/models/medication_model.dart';
import 'package:drug/features/inventory/domain/entities/expiration_warning.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';
import 'package:uuid/uuid.dart';

@LazySingleton(as: InventoryRepository)
final class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl({
    required InventoryRemoteDataSource remoteDataSource,
    required InventoryLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  final InventoryRemoteDataSource _remoteDataSource;
  final InventoryLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  @override
  EitherFailure<List<Medication>> getMedications() async {
    try {
      final local = _localDataSource.getAllMedications();
      if (local.isNotEmpty) {
        unawaited(_refreshCache());
        return Right(local.map((m) => m.toDomain()).toList());
      }

      final remote = await _remoteDataSource.getAllMedications();
      await _localDataSource.cacheMedications(remote);
      return Right(remote.map((m) => m.toDomain()).toList());
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  StreamEitherFailure<List<Medication>> watchMedications() {
    return _localDataSource.watchMedications().map(
          (models) => Right(models.map((m) => m.toDomain()).toList()),
        );
  }

  @override
  EitherFailure<Unit> addMedication(Medication medication) async {
    try {
      final medWithId = medication.id.isEmpty
          ? medication.copyWith(id: const Uuid().v4())
          : medication;
      final model = MedicationModel.fromDomain(medWithId);
      final isConnected = await _networkInfo.isConnected;

      if (isConnected) {
        final remote = await _remoteDataSource.createMedication(model);
        await _localDataSource.saveMedication(remote);
        return const Right(unit);
      }

      await _localDataSource.saveMedication(model);
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<Unit> updateMedication(Medication medication) async {
    try {
      final model = MedicationModel.fromDomain(medication);
      final isConnected = await _networkInfo.isConnected;

      await _localDataSource.saveMedication(model);
      if (isConnected) {
        await _remoteDataSource.updateMedication(model);
      }
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<Unit> deleteMedication(String id) async {
    try {
      await _localDataSource.deleteMedication(id);
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<Unit> updateMedicationStock(UpdateStockParams params) async {
    try {
      final all = _localDataSource.getAllMedications();
      final match = all.where((m) => m.id == params.medicationId).toList();
      if (match.isEmpty) {
        return const Left(CacheFailure('Medication not found in cache'));
      }

      final current = match.first;
      final updated = MedicationModel(
        id: current.id,
        name: current.name,
        drugForm: current.drugForm,
        profileId: current.profileId,
        dosageAmount: current.dosageAmount,
        dosageUnit: current.dosageUnit,
        notes: current.notes,
        currentStock: current.currentStock + params.quantityChange,
        refillThreshold: current.refillThreshold,
        expirationDate: current.expirationDate,
        manufacturer: current.manufacturer,
        batchNumber: current.batchNumber,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );
      await _localDataSource.saveMedication(updated);

      final isConnected = await _networkInfo.isConnected;
      if (isConnected) {
        await _remoteDataSource.updateMedication(updated);
      }
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<List<ExpirationWarning>> getExpiringMedications(
    ExpiringParams params,
  ) async {
    try {
      final all = _localDataSource.getAllMedications();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final warnings = all
          .map((m) => m.toDomain())
          .where((m) {
            final expiryDate = DateTime(m.expirationDate.year, m.expirationDate.month, m.expirationDate.day);
            return expiryDate.difference(today).inDays <= params.withinDays;
          })
          .map((m) {
        final expiryDate = DateTime(m.expirationDate.year, m.expirationDate.month, m.expirationDate.day);
        final daysUntilExpiry = expiryDate.difference(today).inDays;
        return ExpirationWarning(
          medication: m,
          daysUntilExpiry: daysUntilExpiry,
          severity: daysUntilExpiry <= 7
              ? ExpirationSeverity.critical
              : daysUntilExpiry <= 30
                  ? ExpirationSeverity.warning
                  : ExpirationSeverity.info,
        );
      }).toList();
      return Right(warnings);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<List<Medication>> getLowStockMedications() async {
    try {
      final all = _localDataSource.getAllMedications();
      final lowStock = all
          .map((m) => m.toDomain())
          .where((m) =>
              m.refillThreshold != null && m.currentStock <= m.refillThreshold!)
          .toList();
      return Right(lowStock);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  Future<void> _refreshCache() async {
    try {
      final remote = await _remoteDataSource.getAllMedications();
      if (remote.isNotEmpty) {
        await _localDataSource.cacheMedications(remote);
      }
    } catch (_) {}
  }
}
