import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

final class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.expirationWarningDays = 30,
    this.loaded = false,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final int expirationWarningDays;
  final bool loaded;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    int? expirationWarningDays,
    bool? loaded,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      expirationWarningDays: expirationWarningDays ?? this.expirationWarningDays,
      loaded: loaded ?? this.loaded,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        notificationsEnabled,
        expirationWarningDays,
        loaded,
      ];
}
