import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/auth/domain/entities/user_profile.dart';
import 'package:drug/features/auth/domain/repositories/auth_repository.dart';
import 'package:drug/features/auth/domain/usecases/sign_in_with_google.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SignInWithGoogle useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInWithGoogle(mockRepository);
  });

  final tUser = UserProfile(
    uid: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
    isAnonymous: false,
    createdAt: DateTime(2024),
  );

  test('should call signInWithGoogle on the repository', () async {
    when(() => mockRepository.signInWithGoogle())
        .thenAnswer((_) async => Right(tUser));

    final result = await useCase(const NoParams());

    expect(result, Right(tUser));
    verify(() => mockRepository.signInWithGoogle()).called(1);
  });

  test('should return AuthFailure when repository fails', () async {
    const failure = AuthFailure('Google sign-in failed');
    when(() => mockRepository.signInWithGoogle())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(const NoParams());

    expect(result, const Left(failure));
  });
}
