sealed class AppException implements Exception {
  const AppException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;
}

final class ServerException extends AppException {
  const ServerException([super.message = 'Server error occurred.', super.statusCode]);
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error occurred.', super.statusCode]);
}

final class CacheException extends AppException {
  const CacheException([super.message = 'Cache error occurred.', super.statusCode]);
}

final class AuthException extends AppException {
  const AuthException([super.message = 'Authentication error occurred.', super.statusCode]);
}

final class ConflictException extends AppException {
  const ConflictException([super.message = 'Conflict error occurred.', super.statusCode]);
}

final class ValidationException extends AppException {
  const ValidationException([super.message = 'Validation error occurred.', super.statusCode]);
}

final class NotificationException extends AppException {
  const NotificationException([super.message = 'Notification error occurred.', super.statusCode]);
}
