import 'package:injectable/injectable.dart';
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
