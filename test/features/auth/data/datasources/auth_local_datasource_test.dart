import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:drug/features/auth/data/models/user_profile_model.dart';

class MockBox extends Mock implements Box {}

void main() {
  late MockBox mockBox;
  late AuthLocalDataSourceImpl dataSource;

  final tUserModel = UserProfileModel(
    uid: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
    isAnonymous: false,
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockBox = MockBox();
    dataSource = AuthLocalDataSourceImpl(mockBox);
  });

  group('getCachedUser', () {
    test('returns null when no cached user exists', () {
      when(() => mockBox.get('cached_user')).thenReturn(null);

      final result = dataSource.getCachedUser();

      expect(result, isNull);
    });

    test('returns deserialized user when cached user exists', () {
      when(() => mockBox.get('cached_user'))
          .thenReturn(jsonEncode(tUserModel.toJson()));

      final result = dataSource.getCachedUser();

      expect(result, isNotNull);
      expect(result!.uid, equals('test-uid'));
    });
  });

  group('cacheUser', () {
    test('calls box.put with serialized json', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await dataSource.cacheUser(tUserModel);

      verify(() => mockBox.put('cached_user', any())).called(1);
    });
  });

  group('clearCache', () {
    test('calls box.delete', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});

      await dataSource.clearCache();

      verify(() => mockBox.delete('cached_user')).called(1);
    });
  });

  group('watchCachedUser', () {
    test('emits null when box event is deleted', () {
      when(() => mockBox.watch(key: any(named: 'key'))).thenAnswer(
        (_) => Stream.value(BoxEvent('cached_user', null, true)),
      );

      expect(
        dataSource.watchCachedUser(),
        emits(null),
      );
    });
  });
}
