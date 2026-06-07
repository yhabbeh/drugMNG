import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/profiles/domain/repositories/profile_repository.dart';
import 'package:drug/features/profiles/domain/usecases/delete_profile.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepository;
  late DeleteProfile useCase;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = DeleteProfile(mockRepository);
  });

  test('should call deleteProfile on the repository with given id', () async {
    when(() => mockRepository.deleteProfile(any()))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase('profile-1');

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.deleteProfile('profile-1')).called(1);
  });

  test('should return CacheFailure when repository fails', () async {
    const failure = CacheFailure('Delete failed');
    when(() => mockRepository.deleteProfile(any()))
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase('profile-1');

    expect(result.isLeft(), isTrue);
    result.fold((f) {
      expect(f, isA<CacheFailure>());
    }, (_) {});
  });
}
