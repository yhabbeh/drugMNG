import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';

import 'package:drug/core/constants/hive_box_names.dart';
import 'package:drug/features/schedule/data/models/dose_log_model.dart';
import 'package:drug/features/schedule/data/models/dose_schedule_model.dart';

abstract interface class ScheduleLocalDataSource {
  List<DoseScheduleModel> getAllSchedules(String profileId);
  Stream<List<DoseScheduleModel>> watchSchedules(String profileId);
  Future<void> saveSchedule(DoseScheduleModel schedule);
  Future<void> deleteSchedule(String id);
  Future<void> logDose(DoseLogModel log);
  Future<void> deleteLog(String id);
  Future<DoseLogModel?> getLogById(String id);
  List<DoseLogModel> getLogsForDate(String profileId, DateTime date);
  Stream<List<DoseLogModel>> watchLogs(String profileId);
}

@LazySingleton(as: ScheduleLocalDataSource)
final class ScheduleLocalDataSourceImpl implements ScheduleLocalDataSource {
  @visibleForTesting
  ScheduleLocalDataSourceImpl(
    this._schedulesBox,
    this._logsBox,
  );

  @factoryMethod
  static ScheduleLocalDataSourceImpl create() {
    return ScheduleLocalDataSourceImpl(
      Hive.box(HiveBoxNames.doseSchedules),
      Hive.box(HiveBoxNames.doseLogs),
    );
  }

  final Box _schedulesBox;
  final Box _logsBox;

  @override
  List<DoseScheduleModel> getAllSchedules(String profileId) {
    return _allSchedules().where((s) => s.profileId == profileId).toList();
  }

  @override
  Stream<List<DoseScheduleModel>> watchSchedules(String profileId) async* {
    yield getAllSchedules(profileId);
    yield* _schedulesBox
        .watch()
        .map((_) => getAllSchedules(profileId));
  }

  @override
  Future<void> saveSchedule(DoseScheduleModel schedule) async {
    await _schedulesBox.put(
      schedule.id,
      jsonEncode(schedule.toJson()),
    );
  }

  @override
  Future<void> deleteSchedule(String id) async {
    await _schedulesBox.delete(id);
  }

  @override
  Future<void> logDose(DoseLogModel log) async {
    await _logsBox.put(log.id, jsonEncode(log.toJson()));
  }

  @override
  Future<void> deleteLog(String id) async {
    await _logsBox.delete(id);
  }

  @override
  Future<DoseLogModel?> getLogById(String id) async {
    final raw = _logsBox.get(id);
    if (raw == null) return null;
    return DoseLogModel.fromJson(
      jsonDecode(raw as String) as Map<String, dynamic>,
    );
  }

  @override
  List<DoseLogModel> getLogsForDate(String profileId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _allLogs().where((l) {
      return l.profileId == profileId &&
          !l.scheduledAt.isBefore(startOfDay) &&
          l.scheduledAt.isBefore(endOfDay);
    }).toList();
  }

  @override
  Stream<List<DoseLogModel>> watchLogs(String profileId) async* {
    final getLogs = () => _allLogs().where((l) => l.profileId == profileId).toList();
    yield getLogs();
    yield* _logsBox.watch().map((_) => getLogs());
  }

  List<DoseScheduleModel> _allSchedules() {
    return _schedulesBox.values.map((raw) {
      return DoseScheduleModel.fromJson(
        jsonDecode(raw as String) as Map<String, dynamic>,
      );
    }).toList();
  }

  List<DoseLogModel> _allLogs() {
    return _logsBox.values.map((raw) {
      return DoseLogModel.fromJson(
        jsonDecode(raw as String) as Map<String, dynamic>,
      );
    }).toList();
  }
}
