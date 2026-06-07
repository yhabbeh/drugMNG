import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/domain/repositories/profile_repository.dart';
import 'package:drug/features/profiles/domain/usecases/create_profile.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepository;
  late CreateProfile useCase;

  setUpAll(() {
    registerFallbackValue(
      CaregiverProfile(
        id: '',
        ownerUid: 'owner-1',
        displayName: 'Test',
        relationship: Relationship.self,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    );
  });

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = CreateProfile(mockRepository);
  });

  const tParams = CreateProfileParams(
    ownerUid: 'owner-1',
    displayName: 'Spouse',
    relationship: Relationship.spouse,
  );

  test('should call createProfile on the repository with generated profile',
      () async {
    when(() => mockRepository.createProfile(any()))
        .thenAnswer((_) async => Right(tProfile));

    final result = await useCase(tParams);

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.createProfile(any())).called(1);
  });

  test('should return ValidationFailure when repository fails', () async {
    when(() => mockRepository.createProfile(any())).thenAnswer(
      (_) async => const Left(ValidationFailure('Invalid profile')),
    );

    final result = await useCase(tParams);

    expect(result.isLeft(), isTrue);
    result.fold((f) {
      expect(f, isA<ValidationFailure>());
    }, (_) {});
  });
}

final tProfile = CaregiverProfile(
  id: '1',
  ownerUid: 'owner-1',
  displayName: 'Spouse',
  relationship: Relationship.spouse,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);
