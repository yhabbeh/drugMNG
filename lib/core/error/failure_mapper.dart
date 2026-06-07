import 'package:drug/core/error/exceptions.dart';
import 'package:drug/core/error/failures.dart';

Failure mapExceptionToFailure(AppException exception) {
  return switch (exception) {
    ServerException() => ServerFailure(exception.message),
    NetworkException() => NetworkFailure(exception.message),
    CacheException() => CacheFailure(exception.message),
    AuthException() => AuthFailure(exception.message),
    ConflictException() => ConflictFailure(exception.message),
    ValidationException() => ValidationFailure(exception.message),
    NotificationException() => NotificationFailure(exception.message),
  };
}
