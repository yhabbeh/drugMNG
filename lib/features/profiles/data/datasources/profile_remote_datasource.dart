import 'package:injectable/injectable.dart';
import 'package:drug/features/profiles/data/models/caregiver_profile_model.dart';

abstract interface class ProfileRemoteDataSource {
  Future<List<CaregiverProfileModel>> getAllProfiles();
  Stream<List<CaregiverProfileModel>> watchProfiles();
  Future<CaregiverProfileModel> createProfile(CaregiverProfileModel profile);
  Future<CaregiverProfileModel> updateProfile(CaregiverProfileModel profile);
  Future<void> deleteProfile(String id);
}

@LazySingleton(as: ProfileRemoteDataSource)
final class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl();

  @override
  Future<List<CaregiverProfileModel>> getAllProfiles() async => [];

  @override
  Stream<List<CaregiverProfileModel>> watchProfiles() => Stream.value([]);

  @override
  Future<CaregiverProfileModel> createProfile(CaregiverProfileModel profile) async => profile;

  @override
  Future<CaregiverProfileModel> updateProfile(CaregiverProfileModel profile) async => profile;

  @override
  Future<void> deleteProfile(String id) async {}
}
