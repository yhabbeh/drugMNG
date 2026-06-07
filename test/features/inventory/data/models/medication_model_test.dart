import 'package:flutter_test/flutter_test.dart';

import 'package:drug/features/inventory/data/models/medication_model.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';

void main() {
  final tJson = <String, dynamic>{
    'id': 'med-1',
    'name': 'Amoxicillin',
    'drugForm': 'capsule',
    'profileId': 'profile-1',
    'dosageAmount': 500.0,
    'dosageUnit': 'mg',
    'notes': 'Take with food',
    'currentStock': 30,
    'refillThreshold': 10,
    'expirationDate': '2026-12-31T00:00:00.000',
    'manufacturer': 'Pfizer',
    'batchNumber': 'BATCH-001',
    'createdAt': '2025-01-01T00:00:00.000',
    'updatedAt': '2025-01-15T00:00:00.000',
  };

  final tModel = MedicationModel(
    id: 'med-1',
    name: 'Amoxicillin',
    drugForm: 'capsule',
    profileId: 'profile-1',
    dosageAmount: 500.0,
    dosageUnit: 'mg',
    notes: 'Take with food',
    currentStock: 30,
    refillThreshold: 10,
    expirationDate: DateTime(2026, 12, 31),
    manufacturer: 'Pfizer',
    batchNumber: 'BATCH-001',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 15),
  );

  final tEntity = Medication(
    id: 'med-1',
    name: 'Amoxicillin',
    drugForm: DrugForm.capsule,
    profileId: 'profile-1',
    dosageAmount: 500.0,
    dosageUnit: DosageUnit.mg,
    notes: 'Take with food',
    currentStock: 30,
    refillThreshold: 10,
    expirationDate: DateTime(2026, 12, 31),
    manufacturer: 'Pfizer',
    batchNumber: 'BATCH-001',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 15),
  );

  group('MedicationModel', () {
    test('fromJson creates model correctly', () {
      final result = MedicationModel.fromJson(tJson);
      expect(result.id, tModel.id);
      expect(result.name, tModel.name);
      expect(result.drugForm, tModel.drugForm);
      expect(result.profileId, tModel.profileId);
      expect(result.dosageAmount, tModel.dosageAmount);
      expect(result.dosageUnit, tModel.dosageUnit);
      expect(result.notes, tModel.notes);
      expect(result.currentStock, tModel.currentStock);
      expect(result.refillThreshold, tModel.refillThreshold);
      expect(result.expirationDate, tModel.expirationDate);
      expect(result.manufacturer, tModel.manufacturer);
      expect(result.batchNumber, tModel.batchNumber);
      expect(result.createdAt, tModel.createdAt);
      expect(result.updatedAt, tModel.updatedAt);
    });

    test('fromJson accepts null profileId', () {
      final jsonWithoutProfile = <String, dynamic>{...tJson};
      jsonWithoutProfile.remove('profileId');
      final result = MedicationModel.fromJson(jsonWithoutProfile);
      expect(result.profileId, isNull);
    });

    test('toJson produces correct map', () {
      final result = tModel.toJson();
      expect(result['id'], 'med-1');
      expect(result['name'], 'Amoxicillin');
      expect(result['drugForm'], 'capsule');
      expect(result['currentStock'], 30);
    });

    test('toJson round-trip preserves data', () {
      final json = tModel.toJson();
      final restored = MedicationModel.fromJson(json);
      expect(restored, isNot(same(tModel)));
      expect(restored.id, tModel.id);
      expect(restored.name, tModel.name);
      expect(restored.drugForm, tModel.drugForm);
      expect(restored.currentStock, tModel.currentStock);
      expect(restored.expirationDate, tModel.expirationDate);
    });

    test('fromDomain creates model from entity', () {
      final result = MedicationModel.fromDomain(tEntity);
      expect(result.id, 'med-1');
      expect(result.drugForm, 'capsule');
      expect(result.dosageUnit, 'mg');
    });

    test('toDomain creates entity from model', () {
      final result = tModel.toDomain();
      expect(result.id, 'med-1');
      expect(result.drugForm, DrugForm.capsule);
      expect(result.dosageUnit, DosageUnit.mg);
    });

    test('fromDomain toDomain round-trip preserves entity', () {
      final model = MedicationModel.fromDomain(tEntity);
      final entity = model.toDomain();
      expect(entity.id, tEntity.id);
      expect(entity.name, tEntity.name);
      expect(entity.drugForm, tEntity.drugForm);
      expect(entity.currentStock, tEntity.currentStock);
      expect(entity.expirationDate, tEntity.expirationDate);
    });

    test('handles nullable fields', () {
      final minimalJson = <String, dynamic>{
        'id': 'med-2',
        'name': 'Ibuprofen',
        'drugForm': 'tablet',
        'currentStock': 0,
        'expirationDate': '2026-06-01T00:00:00.000',
        'createdAt': '2025-01-01T00:00:00.000',
        'updatedAt': '2025-01-01T00:00:00.000',
      };
      final model = MedicationModel.fromJson(minimalJson);
      expect(model.profileId, isNull);
      expect(model.dosageAmount, isNull);
      expect(model.dosageUnit, isNull);
      expect(model.notes, isNull);
      expect(model.refillThreshold, isNull);
      expect(model.manufacturer, isNull);
      expect(model.batchNumber, isNull);
    });
  });
}
