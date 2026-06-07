import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/auth/domain/repositories/auth_repository.dart';
import 'package:drug/features/auth/domain/usecases/sign_out.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SignOut useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignOut(mockRepository);
  });

  test('should call signOut on the repository', () async {
    when(() => mockRepository.signOut())
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase(const NoParams());

    expect(result, const Right(unit));
    verify(() => mockRepository.signOut()).called(1);
  });

  test('should return AuthFailure when repository fails', () async {
    const failure = AuthFailure('Sign out failed');
    when(() => mockRepository.signOut())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(const NoParams());

    expect(result, const Left(failure));
  });
}
