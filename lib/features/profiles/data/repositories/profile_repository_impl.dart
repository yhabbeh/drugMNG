import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/exceptions.dart';
import 'package:drug/core/error/failure_mapper.dart';
import 'package:drug/core/network/network_info.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/profiles/data/datasources/profile_local_datasource.dart';
import 'package:drug/features/profiles/data/datasources/profile_remote_datasource.dart';
import 'package:drug/features/profiles/data/models/caregiver_profile_model.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/domain/repositories/profile_repository.dart';
import 'package:uuid/uuid.dart';

@LazySingleton(as: ProfileRepository)
final class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
    required ProfileLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  @override
  EitherFailure<List<CaregiverProfile>> getAllProfiles() async {
    try {
      final localProfiles = _localDataSource.getAllProfiles();
      if (localProfiles.isNotEmpty) {
        unawaited(_refreshCache());
        return Right(localProfiles.map((m) => m.toDomain()).toList());
      }

      final remoteProfiles = await _remoteDataSource.getAllProfiles();
      await _localDataSource.cacheProfiles(remoteProfiles);
      return Right(remoteProfiles.map((m) => m.toDomain()).toList());
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  StreamEitherFailure<List<CaregiverProfile>> watchProfiles() {
    return _localDataSource.watchProfiles().map(
          (models) => Right(models.map((m) => m.toDomain()).toList()),
        );
  }

  @override
  EitherFailure<CaregiverProfile> createProfile(CaregiverProfile profile) async {
    try {
      // Assign a UUID if the form did not provide one.
      final profileWithId = profile.id.isEmpty
          ? profile.copyWith(id: const Uuid().v4())
          : profile;
      final model = CaregiverProfileModel.fromDomain(profileWithId);
      final isConnected = await _networkInfo.isConnected;

      if (isConnected) {
        final remoteProfile = await _remoteDataSource.createProfile(model);
        await _localDataSource.saveProfile(remoteProfile);
        return Right(remoteProfile.toDomain());
      }

      await _localDataSource.saveProfile(model);
      return Right(model.toDomain());
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<CaregiverProfile> updateProfile(CaregiverProfile profile) async {
    try {
      final model = CaregiverProfileModel.fromDomain(profile);
      final isConnected = await _networkInfo.isConnected;

      await _localDataSource.saveProfile(model);
      if (isConnected) {
        await _remoteDataSource.updateProfile(model);
      }
      return Right(profile);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<Unit> deleteProfile(String profileId) async {
    try {
      final isConnected = await _networkInfo.isConnected;

      await _localDataSource.deleteProfile(profileId);
      if (isConnected) {
        await _remoteDataSource.deleteProfile(profileId);
      }
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  Future<void> _refreshCache() async {
    try {
      final remoteProfiles = await _remoteDataSource.getAllProfiles();
      // Never wipe local data with an empty remote result.
      if (remoteProfiles.isNotEmpty) {
        await _localDataSource.cacheProfiles(remoteProfiles);
      }
    } catch (_) {}
  }
}
