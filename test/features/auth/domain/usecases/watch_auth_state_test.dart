import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/auth/domain/entities/user_profile.dart';
import 'package:drug/features/auth/domain/repositories/auth_repository.dart';
import 'package:drug/features/auth/domain/usecases/watch_auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late WatchAuthState useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = WatchAuthState(mockRepository);
  });

  final tUser = UserProfile(
    uid: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
    isAnonymous: false,
    createdAt: DateTime(2024),
  );

  test('should return auth state stream from repository', () {
    when(() => mockRepository.watchAuthState())
        .thenAnswer((_) => Stream.value(Right(tUser)));

    expect(
      useCase(const NoParams()),
      emits(Right(tUser)),
    );

    verify(() => mockRepository.watchAuthState()).called(1);
  });

  test('should emit AuthFailure on error', () {
    const failure = AuthFailure('Auth state error');
    when(() => mockRepository.watchAuthState())
        .thenAnswer((_) => Stream.value(const Left(failure)));

    expect(
      useCase(const NoParams()),
      emits(const Left(failure)),
    );
  });
}
