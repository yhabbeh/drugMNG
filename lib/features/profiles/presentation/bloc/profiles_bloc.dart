import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/domain/usecases/create_profile.dart';
import 'package:drug/features/profiles/domain/usecases/delete_profile.dart';
import 'package:drug/features/profiles/domain/usecases/get_all_profiles.dart';
import 'package:drug/features/profiles/domain/usecases/update_profile.dart';
import 'package:drug/features/profiles/domain/usecases/watch_profiles.dart';

sealed class ProfilesEvent extends Equatable {
  const ProfilesEvent();

  @override
  List<Object?> get props => [];
}

final class ProfilesStarted extends ProfilesEvent {
  const ProfilesStarted();
}

final class ProfileCreated extends ProfilesEvent {
  const ProfileCreated(this.profile);
  final CaregiverProfile profile;

  @override
  List<Object?> get props => [profile];
}

final class ProfileUpdated extends ProfilesEvent {
  const ProfileUpdated(this.profile);
  final CaregiverProfile profile;

  @override
  List<Object?> get props => [profile];
}

final class ProfileDeleted extends ProfilesEvent {
  const ProfileDeleted(this.profileId);
  final String profileId;

  @override
  List<Object?> get props => [profileId];
}

final class ProfilesRefreshRequested extends ProfilesEvent {
  const ProfilesRefreshRequested();

  @override
  List<Object?> get props => [];
}

sealed class ProfilesState extends Equatable {
  const ProfilesState();

  @override
  List<Object?> get props => [];
}

final class ProfilesInitial extends ProfilesState {
  const ProfilesInitial();
}

final class ProfilesLoading extends ProfilesState {
  const ProfilesLoading();
}

final class ProfilesLoaded extends ProfilesState {
  const ProfilesLoaded({
    required this.profiles,
    this.isLoading = false,
  });

  final List<CaregiverProfile> profiles;
  final bool isLoading;

  @override
  List<Object?> get props => [profiles, isLoading];
}

final class ProfilesError extends ProfilesState {
  const ProfilesError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

@Singleton()
final class ProfilesBloc extends Bloc<ProfilesEvent, ProfilesState> {
  ProfilesBloc({
    required GetAllProfiles getAllProfiles,
    required WatchProfiles watchProfiles,
    required CreateProfile createProfile,
    required UpdateProfile updateProfile,
    required DeleteProfile deleteProfile,
  })  : _getAllProfiles = getAllProfiles,
        _watchProfiles = watchProfiles,
        _createProfile = createProfile,
        _updateProfile = updateProfile,
        _deleteProfile = deleteProfile,
        super(const ProfilesInitial()) {
    on<ProfilesStarted>(_onStarted);
    on<ProfileCreated>(_onCreated);
    on<ProfileUpdated>(_onUpdated);
    on<ProfileDeleted>(_onDeleted);
    on<ProfilesRefreshRequested>(_onRefreshRequested);
  }

  final GetAllProfiles _getAllProfiles;
  final WatchProfiles _watchProfiles;
  final CreateProfile _createProfile;
  final UpdateProfile _updateProfile;
  final DeleteProfile _deleteProfile;

  Future<void> _onStarted(
    ProfilesStarted event,
    Emitter<ProfilesState> emit,
  ) async {
    emit(const ProfilesLoading());
    unawaited(_getAllProfiles(const NoParams()));
    await emit.forEach<Either<Failure, List<CaregiverProfile>>>(
      _watchProfiles(const NoParams()),
      onData: (either) {
        return either.fold(
          (failure) => ProfilesError(failure),
          (profiles) => ProfilesLoaded(profiles: profiles),
        );
      },
      onError: (error, stackTrace) => ProfilesError(
        ServerFailure(error.toString()),
      ),
    );
  }

  Future<void> _onCreated(
    ProfileCreated event,
    Emitter<ProfilesState> emit,
  ) async {
    emit(const ProfilesLoading());
    final params = CreateProfileParams(
      ownerUid: event.profile.ownerUid,
      displayName: event.profile.displayName,
      relationship: event.profile.relationship,
      avatarUrl: event.profile.avatarUrl,
      color: event.profile.color,
    );
    final result = await _createProfile(params);
    result.fold(
      (failure) => emit(ProfilesError(failure)),
      (_) {},
    );
  }

  Future<void> _onUpdated(
    ProfileUpdated event,
    Emitter<ProfilesState> emit,
  ) async {
    emit(const ProfilesLoading());
    final result = await _updateProfile(event.profile);
    result.fold(
      (failure) => emit(ProfilesError(failure)),
      (_) {},
    );
  }

  Future<void> _onDeleted(
    ProfileDeleted event,
    Emitter<ProfilesState> emit,
  ) async {
    emit(const ProfilesLoading());
    final result = await _deleteProfile(event.profileId);
    result.fold(
      (failure) => emit(ProfilesError(failure)),
      (_) {},
    );
  }

  Future<void> _onRefreshRequested(
    ProfilesRefreshRequested event,
    Emitter<ProfilesState> emit,
  ) async {
    final result = await _getAllProfiles(const NoParams());
    result.fold(
      (failure) => emit(ProfilesError(failure)),
      (profiles) => emit(ProfilesLoaded(profiles: profiles)),
    );
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
