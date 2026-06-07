import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:drug/features/inventory/data/models/medication_model.dart';

class MockBox extends Mock implements Box {}

void main() {
  late MockBox mockBox;
  late InventoryLocalDataSourceImpl dataSource;

  final tMedication1 = MedicationModel(
    id: 'med-1',
    name: 'Amoxicillin',
    drugForm: 'capsule',
    currentStock: 30,
    expirationDate: DateTime(2026, 12, 31),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 15),
  );
  final tMedication2 = MedicationModel(
    id: 'med-2',
    name: 'Ibuprofen',
    drugForm: 'tablet',
    currentStock: 50,
    expirationDate: DateTime(2026, 6, 1),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  Map<String, dynamic> serialize(MedicationModel m) => m.toJson();

  setUp(() {
    mockBox = MockBox();
    dataSource = InventoryLocalDataSourceImpl(mockBox);
  });

  group('getAllMedications', () {
    test('should return all medications in the box', () {
      when(() => mockBox.values).thenReturn([
        jsonEncode(serialize(tMedication1)),
        jsonEncode(serialize(tMedication2)),
      ]);

      final result = dataSource.getAllMedications();
      expect(result.length, 2);
      expect(result.first.id, 'med-1');
    });

    test('should return empty list when no match', () {
      when(() => mockBox.values).thenReturn([]);

      final result = dataSource.getAllMedications();
      expect(result, isEmpty);
    });
  });

  group('watchMedications', () {
    test('should emit list on box changes', () {
      when(() => mockBox.values).thenReturn([
        jsonEncode(serialize(tMedication1)),
      ]);
      when(() => mockBox.watch()).thenAnswer(
        (_) => const Stream.empty(),
      );

      final result = dataSource.watchMedications();
      expect(result, isA<Stream<List<MedicationModel>>>());
    });
  });

  group('cacheMedications', () {
    test('should clear box and store all medications', () async {
      when(() => mockBox.clear()).thenAnswer((_) async => 0);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await dataSource.cacheMedications([tMedication1, tMedication2]);

      verify(() => mockBox.clear()).called(1);
      verify(() => mockBox.put(tMedication1.id, any())).called(1);
      verify(() => mockBox.put(tMedication2.id, any())).called(1);
    });
  });

  group('saveMedication', () {
    test('should store medication as JSON string', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await dataSource.saveMedication(tMedication1);

      verify(() => mockBox.put(tMedication1.id, any())).called(1);
    });
  });

  group('deleteMedication', () {
    test('should remove medication by id', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});

      await dataSource.deleteMedication('med-1');

      verify(() => mockBox.delete('med-1')).called(1);
    });
  });
}
