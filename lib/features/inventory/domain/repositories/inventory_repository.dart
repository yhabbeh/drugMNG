import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/entities/expiration_warning.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class InventoryRepository {
  EitherFailure<List<Medication>> getMedications();
  StreamEitherFailure<List<Medication>> watchMedications();
  EitherFailure<Unit> addMedication(Medication medication);
  EitherFailure<Unit> updateMedication(Medication medication);
  EitherFailure<Unit> deleteMedication(String id);
  EitherFailure<Unit> updateMedicationStock(UpdateStockParams params);
  EitherFailure<List<ExpirationWarning>> getExpiringMedications(ExpiringParams params);
  EitherFailure<List<Medication>> getLowStockMedications();
}
