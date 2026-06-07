import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:drug/core/constants/hive_box_names.dart';
import 'package:drug/features/settings/domain/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    _load();
  }

  static const _kThemeMode = 'settings.themeMode';
  static const _kNotificationsEnabled = 'settings.notificationsEnabled';
  static const _kExpirationWarningDays = 'settings.expirationWarningDays';

  Box get _box => Hive.box(HiveBoxNames.userPreferences);

  void _load() {
    final themeModeStr =
        _box.get(_kThemeMode, defaultValue: 'system') as String;
    final notificationsEnabled =
        _box.get(_kNotificationsEnabled, defaultValue: true) as bool;
    final expirationWarningDays =
        _box.get(_kExpirationWarningDays, defaultValue: 30) as int;

    emit(SettingsState(
      themeMode: _parseThemeMode(themeModeStr),
      notificationsEnabled: notificationsEnabled,
      expirationWarningDays: expirationWarningDays,
      loaded: true,
    ));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _box.put(_kThemeMode, _themeModeToString(mode));
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _box.put(_kNotificationsEnabled, value);
    emit(state.copyWith(notificationsEnabled: value));
  }

  Future<void> setExpirationWarningDays(int value) async {
    await _box.put(_kExpirationWarningDays, value);
    emit(state.copyWith(expirationWarningDays: value));
  }

  Future<void> clearLocalData() async {
    for (final name in const [
      HiveBoxNames.medications,
      HiveBoxNames.medicationStock,
      HiveBoxNames.caregiverProfiles,
      HiveBoxNames.doseSchedules,
      HiveBoxNames.doseLogs,
      HiveBoxNames.syncQueue,
    ]) {
      await Hive.deleteBoxFromDisk(name);
    }
  }

  ThemeMode _parseThemeMode(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  String _themeModeToString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}
