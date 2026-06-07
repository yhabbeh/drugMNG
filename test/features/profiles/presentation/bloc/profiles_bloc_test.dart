import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/domain/usecases/create_profile.dart';
import 'package:drug/features/profiles/domain/usecases/delete_profile.dart';
import 'package:drug/features/profiles/domain/usecases/get_all_profiles.dart';
import 'package:drug/features/profiles/domain/usecases/update_profile.dart';
import 'package:drug/features/profiles/domain/usecases/watch_profiles.dart';
import 'package:drug/features/profiles/presentation/bloc/profiles_bloc.dart';

class MockGetAllProfiles extends Mock implements GetAllProfiles {}

class MockWatchProfiles extends Mock implements WatchProfiles {}

class MockCreateProfile extends Mock implements CreateProfile {}

class MockUpdateProfile extends Mock implements UpdateProfile {}

class MockDeleteProfile extends Mock implements DeleteProfile {}

void main() {
  late MockGetAllProfiles mockGetAllProfiles;
  late MockWatchProfiles mockWatchProfiles;
  late MockCreateProfile mockCreateProfile;
  late MockUpdateProfile mockUpdateProfile;
  late MockDeleteProfile mockDeleteProfile;

  final tProfile = CaregiverProfile(
    id: '1',
    ownerUid: 'owner-1',
    displayName: 'Self',
    relationship: Relationship.self,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(tProfile);
    registerFallbackValue('');
    registerFallbackValue(
      const CreateProfileParams(
        ownerUid: '',
        displayName: '',
        relationship: Relationship.self,
      ),
    );
  });

  setUp(() {
    mockGetAllProfiles = MockGetAllProfiles();
    mockWatchProfiles = MockWatchProfiles();
    mockCreateProfile = MockCreateProfile();
    mockUpdateProfile = MockUpdateProfile();
    mockDeleteProfile = MockDeleteProfile();
    when(() => mockGetAllProfiles(any())).thenAnswer(
      (_) async => const Right<Failure, List<CaregiverProfile>>([]),
    );
  });

  group('ProfilesBloc', () {
    blocTest<ProfilesBloc, ProfilesState>(
      'emits [ProfilesLoading, ProfilesLoaded] when ProfilesStarted receives profiles',
      setUp: () {
        when(() => mockWatchProfiles(any())).thenAnswer(
          (_) => Stream.value(
            Right<Failure, List<CaregiverProfile>>([tProfile]),
          ),
        );
      },
      build: () => ProfilesBloc(
        getAllProfiles: mockGetAllProfiles,
        watchProfiles: mockWatchProfiles,
        createProfile: mockCreateProfile,
        updateProfile: mockUpdateProfile,
        deleteProfile: mockDeleteProfile,
      ),
      act: (bloc) => bloc.add(const ProfilesStarted()),
      expect: () => [
        const ProfilesLoading(),
        ProfilesLoaded(profiles: [tProfile]),
      ],
    );

    blocTest<ProfilesBloc, ProfilesState>(
      'emits [ProfilesLoading, ProfilesLoaded] when ProfileCreated succeeds',
      setUp: () {
        when(() => mockCreateProfile(any())).thenAnswer(
          (_) async => Right<Failure, CaregiverProfile>(tProfile),
        );
        when(() => mockWatchProfiles(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ProfilesBloc(
        getAllProfiles: mockGetAllProfiles,
        watchProfiles: mockWatchProfiles,
        createProfile: mockCreateProfile,
        updateProfile: mockUpdateProfile,
        deleteProfile: mockDeleteProfile,
      ),
      seed: () => const ProfilesLoaded(profiles: []),
      act: (bloc) => bloc.add(ProfileCreated(tProfile)),
      expect: () => [
        const ProfilesLoading(),
      ],
    );

    blocTest<ProfilesBloc, ProfilesState>(
      'emits [ProfilesLoading, ProfilesError] when ProfileCreated fails',
      setUp: () {
        when(() => mockCreateProfile(any())).thenAnswer(
          (_) async => const Left<Failure, CaregiverProfile>(
            ValidationFailure('Create failed'),
          ),
        );
        when(() => mockWatchProfiles(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ProfilesBloc(
        getAllProfiles: mockGetAllProfiles,
        watchProfiles: mockWatchProfiles,
        createProfile: mockCreateProfile,
        updateProfile: mockUpdateProfile,
        deleteProfile: mockDeleteProfile,
      ),
      act: (bloc) => bloc.add(ProfileCreated(tProfile)),
      expect: () => [
        const ProfilesLoading(),
        isA<ProfilesError>(),
      ],
    );

    blocTest<ProfilesBloc, ProfilesState>(
      'emits [ProfilesLoading, ProfilesLoaded] when ProfileUpdated succeeds',
      setUp: () {
        when(() => mockUpdateProfile(any())).thenAnswer(
          (_) async => Right<Failure, CaregiverProfile>(tProfile),
        );
        when(() => mockWatchProfiles(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ProfilesBloc(
        getAllProfiles: mockGetAllProfiles,
        watchProfiles: mockWatchProfiles,
        createProfile: mockCreateProfile,
        updateProfile: mockUpdateProfile,
        deleteProfile: mockDeleteProfile,
      ),
      act: (bloc) => bloc.add(ProfileUpdated(tProfile)),
      expect: () => [
        const ProfilesLoading(),
      ],
    );

    blocTest<ProfilesBloc, ProfilesState>(
      'emits [ProfilesLoading, ProfilesError] when ProfileUpdated fails',
      setUp: () {
        when(() => mockUpdateProfile(any())).thenAnswer(
          (_) async => const Left<Failure, CaregiverProfile>(
            ValidationFailure('Update failed'),
          ),
        );
        when(() => mockWatchProfiles(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ProfilesBloc(
        getAllProfiles: mockGetAllProfiles,
        watchProfiles: mockWatchProfiles,
        createProfile: mockCreateProfile,
        updateProfile: mockUpdateProfile,
        deleteProfile: mockDeleteProfile,
      ),
      act: (bloc) => bloc.add(ProfileUpdated(tProfile)),
      expect: () => [
        const ProfilesLoading(),
        isA<ProfilesError>(),
      ],
    );

    blocTest<ProfilesBloc, ProfilesState>(
      'emits [ProfilesLoading, ProfilesLoaded] when ProfileDeleted succeeds',
      setUp: () {
        when(() => mockDeleteProfile(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        when(() => mockWatchProfiles(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ProfilesBloc(
        getAllProfiles: mockGetAllProfiles,
        watchProfiles: mockWatchProfiles,
        createProfile: mockCreateProfile,
        updateProfile: mockUpdateProfile,
        deleteProfile: mockDeleteProfile,
      ),
      seed: () => ProfilesLoaded(profiles: [tProfile]),
      act: (bloc) => bloc.add(const ProfileDeleted('1')),
      expect: () => [
        const ProfilesLoading(),
      ],
    );

    blocTest<ProfilesBloc, ProfilesState>(
      'emits [ProfilesLoading, ProfilesError] when ProfileDeleted fails',
      setUp: () {
        when(() => mockDeleteProfile(any())).thenAnswer(
          (_) async => const Left<Failure, Unit>(
            CacheFailure('Delete failed'),
          ),
        );
        when(() => mockWatchProfiles(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
      },
      build: () => ProfilesBloc(
        getAllProfiles: mockGetAllProfiles,
        watchProfiles: mockWatchProfiles,
        createProfile: mockCreateProfile,
        updateProfile: mockUpdateProfile,
        deleteProfile: mockDeleteProfile,
      ),
      act: (bloc) => bloc.add(const ProfileDeleted('1')),
      expect: () => [
        const ProfilesLoading(),
        isA<ProfilesError>(),
      ],
    );

    blocTest<ProfilesBloc, ProfilesState>(
      'emits [ProfilesLoaded] when ProfilesRefreshRequested succeeds',
      setUp: () {
        when(() => mockGetAllProfiles(any())).thenAnswer(
          (_) async => Right<Failure, List<CaregiverProfile>>([tProfile]),
        );
      },
      build: () => ProfilesBloc(
        getAllProfiles: mockGetAllProfiles,
        watchProfiles: mockWatchProfiles,
        createProfile: mockCreateProfile,
        updateProfile: mockUpdateProfile,
        deleteProfile: mockDeleteProfile,
      ),
      act: (bloc) => bloc.add(const ProfilesRefreshRequested()),
      expect: () => [
        ProfilesLoaded(profiles: [tProfile]),
      ],
    );

    blocTest<ProfilesBloc, ProfilesState>(
      'emits [ProfilesError] when ProfilesRefreshRequested fails',
      setUp: () {
        when(() => mockGetAllProfiles(any())).thenAnswer(
          (_) async => const Left<Failure, List<CaregiverProfile>>(
            CacheFailure('Refresh failed'),
          ),
        );
      },
      build: () => ProfilesBloc(
        getAllProfiles: mockGetAllProfiles,
        watchProfiles: mockWatchProfiles,
        createProfile: mockCreateProfile,
        updateProfile: mockUpdateProfile,
        deleteProfile: mockDeleteProfile,
      ),
      act: (bloc) => bloc.add(const ProfilesRefreshRequested()),
      expect: () => [
        isA<ProfilesError>(),
      ],
    );
  });
}
