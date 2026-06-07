import 'package:injectable/injectable.dart';
import 'package:drug/features/inventory/data/models/medication_model.dart';

abstract interface class InventoryRemoteDataSource {
  Future<List<MedicationModel>> getAllMedications();
  Stream<List<MedicationModel>> watchMedications();
  Future<MedicationModel> createMedication(MedicationModel medication);
  Future<MedicationModel> updateMedication(MedicationModel medication);
  Future<void> deleteMedication(String id);
}

@LazySingleton(as: InventoryRemoteDataSource)
final class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  InventoryRemoteDataSourceImpl();

  @override
  Future<List<MedicationModel>> getAllMedications() async => [];

  @override
  Stream<List<MedicationModel>> watchMedications() => Stream.value([]);

  @override
  Future<MedicationModel> createMedication(MedicationModel medication) async => medication;

  @override
  Future<MedicationModel> updateMedication(MedicationModel medication) async => medication;

  @override
  Future<void> deleteMedication(String id) async {}
}
