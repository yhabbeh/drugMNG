import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';

import 'package:drug/core/constants/hive_box_names.dart';
import 'package:drug/features/profiles/data/models/caregiver_profile_model.dart';

abstract interface class ProfileLocalDataSource {
  List<CaregiverProfileModel> getAllProfiles();
  Stream<List<CaregiverProfileModel>> watchProfiles();
  Future<void> cacheProfiles(List<CaregiverProfileModel> profiles);
  Future<void> saveProfile(CaregiverProfileModel profile);
  Future<void> deleteProfile(String id);
}

@LazySingleton(as: ProfileLocalDataSource)
final class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  @visibleForTesting
  ProfileLocalDataSourceImpl(this._box);

  @factoryMethod
  static ProfileLocalDataSourceImpl create() {
    return ProfileLocalDataSourceImpl(Hive.box(HiveBoxNames.caregiverProfiles));
  }

  final Box _box;

  @override
  List<CaregiverProfileModel> getAllProfiles() {
    return _box.values.map((raw) {
      return CaregiverProfileModel.fromJson(
        jsonDecode(raw as String) as Map<String, dynamic>,
      );
    }).toList();
  }

  @override
  Stream<List<CaregiverProfileModel>> watchProfiles() async* {
    yield getAllProfiles();
    yield* _box.watch().map((_) => getAllProfiles());
  }

  @override
  Future<void> cacheProfiles(List<CaregiverProfileModel> profiles) async {
    await _box.clear();
    for (final profile in profiles) {
      await _box.put(profile.id, jsonEncode(profile.toJson()));
    }
  }

  @override
  Future<void> saveProfile(CaregiverProfileModel profile) async {
    await _box.put(profile.id, jsonEncode(profile.toJson()));
  }

  @override
  Future<void> deleteProfile(String id) async {
    await _box.delete(id);
  }
}
