import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/exceptions.dart';
import 'package:drug/core/error/failure_mapper.dart';
import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:drug/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:drug/features/auth/domain/entities/user_profile.dart';
import 'package:drug/features/auth/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  EitherFailure<UserProfile> signInWithGoogle() async {
    try {
      final user = await _remoteDataSource.signInWithGoogle();
      await _localDataSource.cacheUser(user);
      return Right(user.toDomain());
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<UserProfile> signInAnonymously() async {
    try {
      final user = await _remoteDataSource.signInAnonymously();
      await _localDataSource.cacheUser(user);
      return Right(user.toDomain());
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<Unit> signOut() async {
    try {
      await _remoteDataSource.signOut();
      await _localDataSource.clearCache();
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<UserProfile?> getCurrentUser() async {
    try {
      final remoteUser = await _remoteDataSource.getCurrentUser();
      if (remoteUser != null) {
        await _localDataSource.cacheUser(remoteUser);
        return Right(remoteUser.toDomain());
      }
      final cachedUser = _localDataSource.getCachedUser();
      return Right(cachedUser?.toDomain());
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  StreamEitherFailure<UserProfile?> watchAuthState() {
    return _remoteDataSource.watchAuthState().transform(
      StreamTransformer.fromHandlers(
        handleData: (user, sink) {
          if (user == null) {
            sink.add(const Right<Failure, UserProfile?>(null));
          } else {
            sink.add(Right<Failure, UserProfile?>(user.toDomain()));
          }
        },
        handleError: (Object error, StackTrace stackTrace, sink) {
          if (error is AppException) {
            sink.add(Left<Failure, UserProfile?>(mapExceptionToFailure(error)));
          } else {
            sink.add(Left<Failure, UserProfile?>(AuthFailure(error.toString())));
          }
        },
      ),
    );
  }
}
