import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';

import 'package:drug/core/constants/hive_box_names.dart';
import 'package:drug/features/inventory/data/models/medication_model.dart';

abstract interface class InventoryLocalDataSource {
  List<MedicationModel> getAllMedications();
  Stream<List<MedicationModel>> watchMedications();
  Future<void> cacheMedications(List<MedicationModel> medications);
  Future<void> saveMedication(MedicationModel medication);
  Future<void> deleteMedication(String id);
}

@LazySingleton(as: InventoryLocalDataSource)
final class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  @visibleForTesting
  InventoryLocalDataSourceImpl(this._box);

  @factoryMethod
  static InventoryLocalDataSourceImpl create() {
    return InventoryLocalDataSourceImpl(Hive.box(HiveBoxNames.medications));
  }

  final Box _box;

  @override
  List<MedicationModel> getAllMedications() {
    return _allMedications();
  }

  @override
  Stream<List<MedicationModel>> watchMedications() async* {
    yield getAllMedications();
    yield* _box.watch().map((_) => getAllMedications());
  }

  @override
  Future<void> cacheMedications(List<MedicationModel> medications) async {
    await _box.clear();
    for (final medication in medications) {
      await _box.put(medication.id, jsonEncode(medication.toJson()));
    }
  }

  @override
  Future<void> saveMedication(MedicationModel medication) async {
    await _box.put(medication.id, jsonEncode(medication.toJson()));
  }

  @override
  Future<void> deleteMedication(String id) async {
    await _box.delete(id);
  }

  List<MedicationModel> _allMedications() {
    return _box.values.map((raw) {
      return MedicationModel.fromJson(
        jsonDecode(raw as String) as Map<String, dynamic>,
      );
    }).toList();
  }
}
