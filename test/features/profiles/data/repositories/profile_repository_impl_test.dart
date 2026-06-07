import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/exceptions.dart';
import 'package:drug/core/error/failures.dart';
import 'package:drug/core/network/network_info.dart';
import 'package:drug/features/profiles/data/datasources/profile_local_datasource.dart';
import 'package:drug/features/profiles/data/datasources/profile_remote_datasource.dart';
import 'package:drug/features/profiles/data/models/caregiver_profile_model.dart';
import 'package:drug/features/profiles/data/repositories/profile_repository_impl.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';

class MockRemoteDataSource extends Mock implements ProfileRemoteDataSource {}

class MockLocalDataSource extends Mock implements ProfileLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockRemoteDataSource mockRemoteDataSource;
  late MockLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late ProfileRepositoryImpl repository;

  final tProfile = CaregiverProfile(
    id: '1',
    ownerUid: 'owner-1',
    displayName: 'Self',
    relationship: Relationship.self,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  final tModel = CaregiverProfileModel(
    id: '1',
    ownerUid: 'owner-1',
    displayName: 'Self',
    relationship: 'self',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  setUpAll(() {
    registerFallbackValue(tModel);
    registerFallbackValue(tProfile);
  });

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = ProfileRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('getAllProfiles', () {
    test('returns cached profiles when local data exists', () async {
      when(() => mockLocalDataSource.getAllProfiles())
          .thenReturn([tModel]);

      final result = await repository.getAllProfiles();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (profiles) {
        expect(profiles.length, equals(1));
        expect(profiles.first.displayName, equals('Self'));
      });
    });

    test('fetches from remote when cache is empty', () async {
      when(() => mockLocalDataSource.getAllProfiles()).thenReturn([]);
      when(() => mockRemoteDataSource.getAllProfiles())
          .thenAnswer((_) async => [tModel]);
      when(() => mockLocalDataSource.cacheProfiles(any()))
          .thenAnswer((_) async {});

      final result = await repository.getAllProfiles();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (profiles) {
        expect(profiles.length, equals(1));
      });
      verify(() => mockLocalDataSource.cacheProfiles(any())).called(1);
    });

    test('returns CacheFailure when both sources fail', () async {
      when(() => mockLocalDataSource.getAllProfiles()).thenReturn([]);
      when(() => mockRemoteDataSource.getAllProfiles())
          .thenThrow(const ServerException('Server error'));

      final result = await repository.getAllProfiles();

      expect(result.isLeft(), isTrue);
      result.fold((f) {
        expect(f, isA<ServerFailure>());
      }, (_) {});
    });
  });

  group('createProfile', () {
    test('creates via remote when online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.createProfile(any()))
          .thenAnswer((_) async => tModel);
      when(() => mockLocalDataSource.saveProfile(any()))
          .thenAnswer((_) async {});

      final result = await repository.createProfile(tProfile);

      expect(result.isRight(), isTrue);
      verify(() => mockRemoteDataSource.createProfile(any())).called(1);
      verify(() => mockLocalDataSource.saveProfile(any())).called(1);
    });

    test('saves locally when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.saveProfile(any()))
          .thenAnswer((_) async {});

      final result = await repository.createProfile(tProfile);

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.saveProfile(any())).called(1);
      verifyNever(() => mockRemoteDataSource.createProfile(any()));
    });
  });

  group('updateProfile', () {
    test('updates locally and remotely when online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.saveProfile(any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteDataSource.updateProfile(any()))
          .thenAnswer((_) async => tModel);

      final result = await repository.updateProfile(tProfile);

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.saveProfile(any())).called(1);
      verify(() => mockRemoteDataSource.updateProfile(any())).called(1);
    });

    test('updates locally only when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.saveProfile(any()))
          .thenAnswer((_) async {});

      final result = await repository.updateProfile(tProfile);

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.saveProfile(any())).called(1);
      verifyNever(() => mockRemoteDataSource.updateProfile(any()));
    });
  });

  group('deleteProfile', () {
    test('deletes locally and remotely when online', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.deleteProfile(any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteDataSource.deleteProfile(any()))
          .thenAnswer((_) async {});

      final result = await repository.deleteProfile('1');

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.deleteProfile('1')).called(1);
      verify(() => mockRemoteDataSource.deleteProfile('1')).called(1);
    });

    test('deletes locally only when offline', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.deleteProfile(any()))
          .thenAnswer((_) async {});

      final result = await repository.deleteProfile('1');

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.deleteProfile('1')).called(1);
      verifyNever(() => mockRemoteDataSource.deleteProfile(any()));
    });
  });

  group('watchProfiles', () {
    test('emits profiles from local stream', () {
      when(() => mockLocalDataSource.watchProfiles())
          .thenAnswer((_) => Stream.value([tModel]));

      expect(
        repository.watchProfiles(),
        emits(isA<Right<Failure, List<CaregiverProfile>>>()),
      );
    });
  });
}
