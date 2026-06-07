import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/domain/repositories/profile_repository.dart';
import 'package:drug/features/profiles/domain/usecases/update_profile.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepository;
  late UpdateProfile useCase;

  final tProfile = CaregiverProfile(
    id: '1',
    ownerUid: 'owner-1',
    displayName: 'Updated Name',
    relationship: Relationship.self,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  setUpAll(() {
    registerFallbackValue(tProfile);
  });

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = UpdateProfile(mockRepository);
  });

  test('should call updateProfile on the repository', () async {
    when(() => mockRepository.updateProfile(any()))
        .thenAnswer((_) async => Right(tProfile));

    final result = await useCase(tProfile);

    expect(result.isRight(), isTrue);
    result.fold((_) {}, (profile) {
      expect(profile.displayName, equals('Updated Name'));
    });
    verify(() => mockRepository.updateProfile(tProfile)).called(1);
  });

  test('should return CacheFailure when repository fails', () async {
    const failure = CacheFailure('Update failed');
    when(() => mockRepository.updateProfile(any()))
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(tProfile);

    expect(result.isLeft(), isTrue);
    result.fold((f) {
      expect(f, isA<CacheFailure>());
    }, (_) {});
  });
}
