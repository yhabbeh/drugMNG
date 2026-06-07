import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/domain/repositories/profile_repository.dart';
import 'package:drug/features/profiles/domain/usecases/watch_profiles.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepository;
  late WatchProfiles useCase;

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
    useCase = WatchProfiles(mockRepository);
  });

  test('should call watchProfiles on the repository', () {
    when(() => mockRepository.watchProfiles())
        .thenAnswer((_) => Stream.value(Right(tProfiles)));

    expect(
      useCase(const NoParams()),
      emits(isA<Right<Failure, List<CaregiverProfile>>>()),
    );
    verify(() => mockRepository.watchProfiles()).called(1);
  });

  test('should return AuthFailure on error', () {
    when(() => mockRepository.watchProfiles()).thenAnswer(
      (_) => Stream.value(const Left<Failure, List<CaregiverProfile>>(
        AuthFailure('Not authenticated'),
      )),
    );

    expect(
      useCase(const NoParams()),
      emits(isA<Left<Failure, List<CaregiverProfile>>>()),
    );
  });
}
