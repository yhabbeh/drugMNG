import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

final class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.expirationWarningDays = 30,
    this.refillAlertDays = 7,
    this.loaded = false,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final int expirationWarningDays;
  final int refillAlertDays;
  final bool loaded;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    int? expirationWarningDays,
    int? refillAlertDays,
    bool? loaded,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      expirationWarningDays: expirationWarningDays ?? this.expirationWarningDays,
      refillAlertDays: refillAlertDays ?? this.refillAlertDays,
      loaded: loaded ?? this.loaded,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        notificationsEnabled,
        expirationWarningDays,
        refillAlertDays,
        loaded,
      ];
}
