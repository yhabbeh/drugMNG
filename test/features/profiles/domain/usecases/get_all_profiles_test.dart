import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/domain/repositories/profile_repository.dart';
import 'package:drug/features/profiles/domain/usecases/get_all_profiles.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepository;
  late GetAllProfiles useCase;

  final tProfiles = [
    CaregiverProfile(
      id: '1',
      ownerUid: 'owner-1',
      displayName: 'Self',
      relationship: Relationship.self,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
  ];

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = GetAllProfiles(mockRepository);
  });

  test('should call getAllProfiles on the repository', () async {
    when(() => mockRepository.getAllProfiles())
        .thenAnswer((_) async => Right(tProfiles));

    final result = await useCase(const NoParams());

    expect(result.isRight(), isTrue);
    result.fold((_) {}, (profiles) {
      expect(profiles, equals(tProfiles));
    });
    verify(() => mockRepository.getAllProfiles()).called(1);
  });

  test('should return CacheFailure when repository fails', () async {
    const failure = CacheFailure('No cached profiles');
    when(() => mockRepository.getAllProfiles())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(const NoParams());

    expect(result.isLeft(), isTrue);
    result.fold((f) {
      expect(f, isA<CacheFailure>());
    }, (_) {});
  });
}
