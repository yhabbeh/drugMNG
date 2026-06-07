import 'package:flutter_test/flutter_test.dart';
import 'package:drug/core/error/exceptions.dart';
import 'package:drug/core/error/failures.dart';
import 'package:drug/core/error/failure_mapper.dart';

void main() {
  group('mapExceptionToFailure', () {
    test('ServerException maps to ServerFailure', () {
      const exception = ServerException('server error', 500);
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<ServerFailure>());
      expect(failure.message, equals('server error'));
    });

    test('NetworkException maps to NetworkFailure', () {
      const exception = NetworkException('network error');
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, equals('network error'));
    });

    test('CacheException maps to CacheFailure', () {
      const exception = CacheException('cache error');
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<CacheFailure>());
      expect(failure.message, equals('cache error'));
    });

    test('AuthException maps to AuthFailure', () {
      const exception = AuthException('auth error');
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<AuthFailure>());
      expect(failure.message, equals('auth error'));
    });

    test('ConflictException maps to ConflictFailure', () {
      const exception = ConflictException('conflict error');
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<ConflictFailure>());
      expect(failure.message, equals('conflict error'));
    });

    test('ValidationException maps to ValidationFailure', () {
      const exception = ValidationException('validation error');
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, equals('validation error'));
    });

    test('NotificationException maps to NotificationFailure', () {
      const exception = NotificationException('notification error');
      final failure = mapExceptionToFailure(exception);
      expect(failure, isA<NotificationFailure>());
      expect(failure.message, equals('notification error'));
    });
  });
}
