import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/auth/domain/entities/user_profile.dart';
import 'package:drug/features/auth/domain/repositories/auth_repository.dart';
import 'package:drug/features/auth/domain/usecases/sign_in_anonymously.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SignInAnonymously useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInAnonymously(mockRepository);
  });

  final tAnonymousUser = UserProfile(
    uid: 'anon-uid',
    email: null,
    displayName: 'Guest',
    isAnonymous: true,
    createdAt: DateTime(2024),
  );

  test('should call signInAnonymously on the repository', () async {
    when(() => mockRepository.signInAnonymously())
        .thenAnswer((_) async => Right(tAnonymousUser));

    final result = await useCase(const NoParams());

    expect(result, Right(tAnonymousUser));
    verify(() => mockRepository.signInAnonymously()).called(1);
  });

  test('should return AuthFailure when repository fails', () async {
    const failure = AuthFailure('Anonymous sign-in failed');
    when(() => mockRepository.signInAnonymously())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(const NoParams());

    expect(result, const Left(failure));
  });
}
