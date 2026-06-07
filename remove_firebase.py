import os
import re

# 1. pubspec.yaml
with open('pubspec.yaml', 'r') as f:
    pubspec = f.read()

pubspec = re.sub(r'\s+firebase_core:.*', '', pubspec)
pubspec = re.sub(r'\s+firebase_auth:.*', '', pubspec)
pubspec = re.sub(r'\s+cloud_firestore:.*', '', pubspec)
pubspec = re.sub(r'\s+firebase_messaging:.*', '', pubspec)
pubspec = re.sub(r'\s+fake_cloud_firestore:.*', '', pubspec)
with open('pubspec.yaml', 'w') as f:
    f.write(pubspec)

# 2. main.dart
with open('lib/main.dart', 'r') as f:
    main_dart = f.read()

main_dart = re.sub(r"import 'package:firebase_core/firebase_core.dart';\n", '', main_dart)
with open('lib/main.dart', 'w') as f:
    f.write(main_dart)

# 3. core_module.dart
with open('lib/core/di/modules/core_module.dart', 'r') as f:
    core_module = f.read()

core_module = re.sub(r"import 'package:cloud_firestore/cloud_firestore.dart';\n", '', core_module)
core_module = re.sub(r"import 'package:firebase_auth/firebase_auth.dart';\n", '', core_module)
core_module = re.sub(r"\s+@lazySingleton\n\s+FirebaseAuth get firebaseAuth => FirebaseAuth.instance;\n", '', core_module)
core_module = re.sub(r"\s+@lazySingleton\n\s+FirebaseFirestore get firestore => FirebaseFirestore.instance;\n", '', core_module)

with open('lib/core/di/modules/core_module.dart', 'w') as f:
    f.write(core_module)

# 4. AuthRemoteDataSource
auth_ds = """import 'package:injectable/injectable.dart';
import 'package:drug/core/error/exceptions.dart';
import 'package:drug/features/auth/data/models/user_profile_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserProfileModel> signInWithGoogle();
  Future<UserProfileModel> signInAnonymously();
  Future<void> signOut();
  Future<UserProfileModel?> getCurrentUser();
  Stream<UserProfileModel?> watchAuthState();
}

@LazySingleton(as: AuthRemoteDataSource)
final class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl();

  @override
  Future<UserProfileModel> signInAnonymously() async {
    return UserProfileModel(uid: 'local_user', email: null, displayName: 'Local User', photoUrl: null, isAnonymous: true, createdAt: DateTime.now());
  }

  @override
  Future<UserProfileModel> signInWithGoogle() async {
    throw UnimplementedError('Google sign-in not yet implemented');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserProfileModel?> getCurrentUser() async {
    return UserProfileModel(uid: 'local_user', email: null, displayName: 'Local User', photoUrl: null, isAnonymous: true, createdAt: DateTime.now());
  }

  @override
  Stream<UserProfileModel?> watchAuthState() {
    return Stream.value(UserProfileModel(uid: 'local_user', email: null, displayName: 'Local User', photoUrl: null, isAnonymous: true, createdAt: DateTime.now()));
  }
}
"""
with open('lib/features/auth/data/datasources/auth_remote_datasource.dart', 'w') as f:
    f.write(auth_ds)

# 5. ProfileRemoteDataSource
prof_ds = """import 'package:injectable/injectable.dart';
import 'package:drug/core/error/exceptions.dart';
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
"""
with open('lib/features/profiles/data/datasources/profile_remote_datasource.dart', 'w') as f:
    f.write(prof_ds)

# 6. InventoryRemoteDataSource
inv_ds = """import 'package:injectable/injectable.dart';
import 'package:drug/core/error/exceptions.dart';
import 'package:drug/features/inventory/data/models/medication_model.dart';

abstract interface class InventoryRemoteDataSource {
  Future<List<MedicationModel>> getAllMedications(String profileId);
  Stream<List<MedicationModel>> watchMedications(String profileId);
  Future<MedicationModel> createMedication(MedicationModel medication);
  Future<MedicationModel> updateMedication(MedicationModel medication);
  Future<void> deleteMedication(String profileId, String id);
}

@LazySingleton(as: InventoryRemoteDataSource)
final class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  InventoryRemoteDataSourceImpl();

  @override
  Future<List<MedicationModel>> getAllMedications(String profileId) async => [];

  @override
  Stream<List<MedicationModel>> watchMedications(String profileId) => Stream.value([]);

  @override
  Future<MedicationModel> createMedication(MedicationModel medication) async => medication;

  @override
  Future<MedicationModel> updateMedication(MedicationModel medication) async => medication;

  @override
  Future<void> deleteMedication(String profileId, String id) async {}
}
"""
with open('lib/features/inventory/data/datasources/inventory_remote_datasource.dart', 'w') as f:
    f.write(inv_ds)

# 7. ScheduleRemoteDataSource
sched_ds = """import 'package:injectable/injectable.dart';
import 'package:drug/core/error/exceptions.dart';
import 'package:drug/features/schedule/data/models/dose_log_model.dart';
import 'package:drug/features/schedule/data/models/dose_schedule_model.dart';

abstract interface class ScheduleRemoteDataSource {
  Future<List<DoseScheduleModel>> getAllSchedules(String profileId);
  Stream<List<DoseScheduleModel>> watchSchedules(String profileId);
  Future<DoseScheduleModel> createSchedule(DoseScheduleModel schedule);
  Future<DoseScheduleModel> updateSchedule(DoseScheduleModel schedule);
  Future<void> deleteSchedule(String profileId, String id);
  Future<void> logDoseTaken(DoseLogModel log);
  Future<void> logDoseSkipped(DoseLogModel log);
  Stream<List<DoseLogModel>> watchLogs(String profileId);
}

@LazySingleton(as: ScheduleRemoteDataSource)
final class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  ScheduleRemoteDataSourceImpl();

  @override
  Future<List<DoseScheduleModel>> getAllSchedules(String profileId) async => [];

  @override
  Stream<List<DoseScheduleModel>> watchSchedules(String profileId) => Stream.value([]);

  @override
  Future<DoseScheduleModel> createSchedule(DoseScheduleModel schedule) async => schedule;

  @override
  Future<DoseScheduleModel> updateSchedule(DoseScheduleModel schedule) async => schedule;

  @override
  Future<void> deleteSchedule(String profileId, String id) async {}

  @override
  Future<void> logDoseTaken(DoseLogModel log) async {}

  @override
  Future<void> logDoseSkipped(DoseLogModel log) async {}

  @override
  Stream<List<DoseLogModel>> watchLogs(String profileId) => Stream.value([]);
}
"""
with open('lib/features/schedule/data/datasources/schedule_remote_datasource.dart', 'w') as f:
    f.write(sched_ds)

