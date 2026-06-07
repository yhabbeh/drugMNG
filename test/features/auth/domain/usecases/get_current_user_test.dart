import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/auth/domain/entities/user_profile.dart';
import 'package:drug/features/auth/domain/repositories/auth_repository.dart';
import 'package:drug/features/auth/domain/usecases/get_current_user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late GetCurrentUser useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetCurrentUser(mockRepository);
  });

  final tUser = UserProfile(
    uid: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
    isAnonymous: false,
    createdAt: DateTime(2024),
  );

  test('should return user when authenticated', () async {
    when(() => mockRepository.getCurrentUser())
        .thenAnswer((_) async => Right(tUser));

    final result = await useCase(const NoParams());

    expect(result, Right(tUser));
    verify(() => mockRepository.getCurrentUser()).called(1);
  });

  test('should return null when not authenticated', () async {
    when(() => mockRepository.getCurrentUser())
        .thenAnswer((_) async => const Right(null));

    final result = await useCase(const NoParams());

    expect(result, const Right<Failure, dynamic>(null));
  });

  test('should return AuthFailure when repository fails', () async {
    const failure = AuthFailure('Failed to get current user');
    when(() => mockRepository.getCurrentUser())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(const NoParams());

    expect(result, const Left(failure));
  });
}
