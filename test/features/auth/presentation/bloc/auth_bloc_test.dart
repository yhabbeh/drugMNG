import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/auth/domain/entities/user_profile.dart';
import 'package:drug/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:drug/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:drug/features/auth/domain/usecases/sign_out.dart';
import 'package:drug/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:drug/features/auth/presentation/bloc/auth_bloc.dart';

class MockWatchAuthState extends Mock implements WatchAuthState {}

class MockSignInWithGoogle extends Mock implements SignInWithGoogle {}

class MockSignInAnonymously extends Mock implements SignInAnonymously {}

class MockSignOut extends Mock implements SignOut {}

void main() {
  late MockWatchAuthState mockWatchAuthState;
  late MockSignInWithGoogle mockSignInWithGoogle;
  late MockSignInAnonymously mockSignInAnonymously;
  late MockSignOut mockSignOut;

  final tUser = UserProfile(
    uid: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
    isAnonymous: false,
    createdAt: DateTime(2024),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(tUser);
  });

  setUp(() {
    mockWatchAuthState = MockWatchAuthState();
    mockSignInWithGoogle = MockSignInWithGoogle();
    mockSignInAnonymously = MockSignInAnonymously();
    mockSignOut = MockSignOut();
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthAuthenticated] when AuthStarted receives authenticated user',
      setUp: () {
        when(() => mockWatchAuthState(any())).thenAnswer(
          (_) => Stream.value(Right<Failure, UserProfile?>(tUser)),
        );
      },
      build: () => AuthBloc(
        watchAuthState: mockWatchAuthState,
        signInWithGoogle: mockSignInWithGoogle,
        signInAnonymously: mockSignInAnonymously,
        signOut: mockSignOut,
      ),
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [
        AuthAuthenticated(tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when AuthStarted receives null user',
      setUp: () {
        when(() => mockWatchAuthState(any())).thenAnswer(
          (_) => Stream.value(const Right<Failure, UserProfile?>(null)),
        );
      },
      build: () => AuthBloc(
        watchAuthState: mockWatchAuthState,
        signInWithGoogle: mockSignInWithGoogle,
        signInAnonymously: mockSignInAnonymously,
        signOut: mockSignOut,
      ),
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [
        const AuthUnauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on successful Google sign-in',
      setUp: () {
        when(() => mockSignInWithGoogle(any())).thenAnswer(
          (_) async => Right<Failure, UserProfile>(tUser),
        );
      },
      build: () => AuthBloc(
        watchAuthState: mockWatchAuthState,
        signInWithGoogle: mockSignInWithGoogle,
        signInAnonymously: mockSignInAnonymously,
        signOut: mockSignOut,
      ),
      act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on failed Google sign-in',
      setUp: () {
        when(() => mockSignInWithGoogle(any())).thenAnswer(
          (_) async => const Left<Failure, UserProfile>(
            AuthFailure('Google sign-in failed'),
          ),
        );
      },
      build: () => AuthBloc(
        watchAuthState: mockWatchAuthState,
        signInWithGoogle: mockSignInWithGoogle,
        signInAnonymously: mockSignInAnonymously,
        signOut: mockSignOut,
      ),
      act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on successful anonymous sign-in',
      setUp: () {
        when(() => mockSignInAnonymously(any())).thenAnswer(
          (_) async => Right<Failure, UserProfile>(tUser),
        );
      },
      build: () => AuthBloc(
        watchAuthState: mockWatchAuthState,
        signInWithGoogle: mockSignInWithGoogle,
        signInAnonymously: mockSignInAnonymously,
        signOut: mockSignOut,
      ),
      act: (bloc) => bloc.add(const AuthAnonymousSignInRequested()),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on failed anonymous sign-in',
      setUp: () {
        when(() => mockSignInAnonymously(any())).thenAnswer(
          (_) async => const Left<Failure, UserProfile>(
            AuthFailure('Anonymous sign-in failed'),
          ),
        );
      },
      build: () => AuthBloc(
        watchAuthState: mockWatchAuthState,
        signInWithGoogle: mockSignInWithGoogle,
        signInAnonymously: mockSignInAnonymously,
        signOut: mockSignOut,
      ),
      act: (bloc) => bloc.add(const AuthAnonymousSignInRequested()),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] on successful sign out',
      setUp: () {
        when(() => mockSignOut(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
      },
      build: () => AuthBloc(
        watchAuthState: mockWatchAuthState,
        signInWithGoogle: mockSignInWithGoogle,
        signInAnonymously: mockSignInAnonymously,
        signOut: mockSignOut,
      ),
      seed: () => AuthAuthenticated(tUser),
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on failed sign out',
      setUp: () {
        when(() => mockSignOut(any())).thenAnswer(
          (_) async => const Left<Failure, Unit>(
            AuthFailure('Sign out failed'),
          ),
        );
      },
      build: () => AuthBloc(
        watchAuthState: mockWatchAuthState,
        signInWithGoogle: mockSignInWithGoogle,
        signInAnonymously: mockSignInAnonymously,
        signOut: mockSignOut,
      ),
      seed: () => AuthAuthenticated(tUser),
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );
  });
}
