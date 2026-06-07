import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/exceptions.dart';
import 'package:drug/core/error/failures.dart';
import 'package:drug/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:drug/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:drug/features/auth/data/models/user_profile_model.dart';
import 'package:drug/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:drug/features/auth/domain/entities/user_profile.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late AuthRepositoryImpl repository;

  final tUserModel = UserProfileModel(
    uid: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
    isAnonymous: false,
    createdAt: DateTime(2024),
  );

  setUpAll(() {
    registerFallbackValue(tUserModel);
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('signInWithGoogle', () {
    test('returns UserProfile on success and caches user', () async {
      when(() => mockRemoteDataSource.signInWithGoogle())
          .thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.cacheUser(any()))
          .thenAnswer((_) async {});

      final result = await repository.signInWithGoogle();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (user) {
        expect(user.uid, equals('test-uid'));
      });
      verify(() => mockLocalDataSource.cacheUser(tUserModel)).called(1);
    });

    test('returns AuthFailure when remote throws AuthException', () async {
      when(() => mockRemoteDataSource.signInWithGoogle())
          .thenThrow(const AuthException('Google sign-in failed'));
      when(() => mockLocalDataSource.cacheUser(any()))
          .thenAnswer((_) async {});

      final result = await repository.signInWithGoogle();

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
      }, (_) {});
    });
  });

  group('signInAnonymously', () {
    test('returns UserProfile on success and caches user', () async {
      when(() => mockRemoteDataSource.signInAnonymously())
          .thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.cacheUser(any()))
          .thenAnswer((_) async {});

      final result = await repository.signInAnonymously();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (user) {
        expect(user.uid, equals('test-uid'));
      });
      verify(() => mockLocalDataSource.cacheUser(tUserModel)).called(1);
    });

    test('returns AuthFailure when remote throws AuthException', () async {
      when(() => mockRemoteDataSource.signInAnonymously())
          .thenThrow(const AuthException('Anonymous sign-in failed'));
      when(() => mockLocalDataSource.cacheUser(any()))
          .thenAnswer((_) async {});

      final result = await repository.signInAnonymously();

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
      }, (_) {});
    });
  });

  group('signOut', () {
    test('calls signOut and clears cache', () async {
      when(() => mockRemoteDataSource.signOut()).thenAnswer((_) async {});
      when(() => mockLocalDataSource.clearCache()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result.isRight(), isTrue);
      verify(() => mockRemoteDataSource.signOut()).called(1);
      verify(() => mockLocalDataSource.clearCache()).called(1);
    });

    test('returns AuthFailure when remote throws AuthException', () async {
      when(() => mockRemoteDataSource.signOut())
          .thenThrow(const AuthException('Sign out failed'));

      final result = await repository.signOut();

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
      }, (_) {});
    });
  });

  group('getCurrentUser', () {
    test('returns remote user and caches it when authenticated', () async {
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.cacheUser(any()))
          .thenAnswer((_) async {});

      final result = await repository.getCurrentUser();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (user) {
        expect(user!.uid, equals('test-uid'));
      });
      verify(() => mockLocalDataSource.cacheUser(tUserModel)).called(1);
    });

    test('returns cached user when remote returns null', () async {
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => null);
      when(() => mockLocalDataSource.getCachedUser())
          .thenReturn(tUserModel);

      final result = await repository.getCurrentUser();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (user) {
        expect(user!.uid, equals('test-uid'));
      });
    });

    test('returns null when both remote and cache are empty', () async {
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => null);
      when(() => mockLocalDataSource.getCachedUser())
          .thenReturn(null);

      final result = await repository.getCurrentUser();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (user) {
        expect(user, isNull);
      });
    });
  });

  group('watchAuthState', () {
    test('emits UserProfile on auth state change', () {
      when(() => mockRemoteDataSource.watchAuthState())
          .thenAnswer((_) => Stream.value(tUserModel));

      expect(
        repository.watchAuthState(),
        emits(isA<Right<Failure, UserProfile?>>()),
      );
    });

    test('emits null on sign out', () {
      when(() => mockRemoteDataSource.watchAuthState())
          .thenAnswer((_) => Stream.value(null));

      expect(
        repository.watchAuthState(),
        emits(isA<Right<Failure, UserProfile?>>()),
      );
    });

    test('emits Left with AuthFailure on error', () {
      when(() => mockRemoteDataSource.watchAuthState())
          .thenAnswer((_) => Stream.error(const AuthException('Auth error')));

      expect(
        repository.watchAuthState(),
        emits(isA<Left<Failure, UserProfile?>>()),
      );
    });
  });
}
