import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/features/profiles/data/datasources/profile_local_datasource.dart';
import 'package:drug/features/profiles/data/models/caregiver_profile_model.dart';

class MockBox extends Mock implements Box {}

void main() {
  late MockBox mockBox;
  late ProfileLocalDataSourceImpl dataSource;

  final tModel = CaregiverProfileModel(
    id: '1',
    ownerUid: 'owner-1',
    displayName: 'Self',
    relationship: 'self',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  setUp(() {
    mockBox = MockBox();
    dataSource = ProfileLocalDataSourceImpl(mockBox);
  });

  group('getAllProfiles', () {
    test('returns empty list when box is empty', () {
      when(() => mockBox.values).thenReturn([]);

      final result = dataSource.getAllProfiles();

      expect(result, isEmpty);
    });

    test('returns deserialized profiles', () {
      when(() => mockBox.values).thenReturn([jsonEncode(tModel.toJson())]);

      final result = dataSource.getAllProfiles();

      expect(result.length, equals(1));
      expect(result.first.id, equals('1'));
    });
  });

  group('cacheProfiles', () {
    test('clears box and saves all profiles', () async {
      when(() => mockBox.clear()).thenAnswer((_) async => 0);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await dataSource.cacheProfiles([tModel]);

      verify(() => mockBox.clear()).called(1);
      verify(() => mockBox.put('1', any())).called(1);
    });
  });

  group('saveProfile', () {
    test('calls box.put with serialized json', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await dataSource.saveProfile(tModel);

      verify(() => mockBox.put('1', any())).called(1);
    });
  });

  group('deleteProfile', () {
    test('calls box.delete with given id', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});

      await dataSource.deleteProfile('1');

      verify(() => mockBox.delete('1')).called(1);
    });
  });
}
