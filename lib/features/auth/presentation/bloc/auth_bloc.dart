import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/auth/domain/entities/user_profile.dart';
import 'package:drug/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:drug/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:drug/features/auth/domain/usecases/sign_out.dart';
import 'package:drug/features/auth/domain/usecases/watch_auth_state.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

final class AuthAnonymousSignInRequested extends AuthEvent {
  const AuthAnonymousSignInRequested();
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final UserProfile user;

  @override
  List<Object?> get props => [user];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  const AuthError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

@Singleton()
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required WatchAuthState watchAuthState,
    required SignInWithGoogle signInWithGoogle,
    required SignInAnonymously signInAnonymously,
    required SignOut signOut,
  })  : _watchAuthState = watchAuthState,
        _signInWithGoogle = signInWithGoogle,
        _signInAnonymously = signInAnonymously,
        _signOut = signOut,
        super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthAnonymousSignInRequested>(_onAnonymousSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final WatchAuthState _watchAuthState;
  final SignInWithGoogle _signInWithGoogle;
  final SignInAnonymously _signInAnonymously;
  final SignOut _signOut;

  @override
  Future<void> close() {
    return super.close();
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    await emit.forEach<Either<Failure, UserProfile?>>(
      _watchAuthState(const NoParams()),
      onData: (either) {
        return either.fold(
          (failure) => const AuthUnauthenticated(),
          (user) {
            if (user != null) {
              return AuthAuthenticated(user);
            } else {
              return const AuthUnauthenticated();
            }
          },
        );
      },
      onError: (error, stackTrace) => AuthError(
        AuthFailure(error.toString()),
      ),
    );
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _signInWithGoogle(const NoParams());
    result.fold(
      (failure) => emit(AuthError(failure)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAnonymousSignInRequested(
    AuthAnonymousSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _signInAnonymously(const NoParams());
    result.fold(
      (failure) => emit(AuthError(failure)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _signOut(const NoParams());
    result.fold(
      (failure) => emit(AuthError(failure)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }
}
