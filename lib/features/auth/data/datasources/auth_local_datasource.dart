import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';

import 'package:drug/core/constants/hive_box_names.dart';
import 'package:drug/features/auth/data/models/user_profile_model.dart';

abstract interface class AuthLocalDataSource {
  UserProfileModel? getCachedUser();
  Future<void> cacheUser(UserProfileModel user);
  Future<void> clearCache();
  Stream<UserProfileModel?> watchCachedUser();
}

@LazySingleton(as: AuthLocalDataSource)
final class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  @visibleForTesting
  AuthLocalDataSourceImpl(this._box);

  @factoryMethod
  static AuthLocalDataSourceImpl create() {
    return AuthLocalDataSourceImpl(Hive.box(HiveBoxNames.userPreferences));
  }

  final Box _box;
  static const _userKey = 'cached_user';

  @override
  UserProfileModel? getCachedUser() {
    final raw = _box.get(_userKey) as String?;
    if (raw == null) return null;
    return UserProfileModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> cacheUser(UserProfileModel user) async {
    await _box.put(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<void> clearCache() async {
    await _box.delete(_userKey);
  }

  @override
  Stream<UserProfileModel?> watchCachedUser() {
    return _box.watch(key: _userKey).map((event) {
      if (event.deleted || event.value == null) return null;
      return UserProfileModel.fromJson(
        jsonDecode(event.value as String) as Map<String, dynamic>,
      );
    });
  }
}
