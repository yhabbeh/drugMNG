import 'package:fpdart/fpdart.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/schedule/domain/entities/adherence_report.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';

abstract interface class ScheduleRepository {
  EitherFailure<List<DoseSchedule>> getSchedulesForProfile(String profileId);
  StreamEitherFailure<List<DoseSchedule>> watchSchedulesForProfile(
      String profileId);
  EitherFailure<Unit> createSchedule(DoseSchedule schedule);
  EitherFailure<Unit> updateSchedule(DoseSchedule schedule);
  EitherFailure<Unit> deleteSchedule(String id);
  EitherFailure<Unit> logDoseTaken(LogDoseParams params);
  EitherFailure<Unit> logDoseSkipped(LogDoseParams params);
  EitherFailure<Unit> revertDoseLog(LogDoseParams params);
  EitherFailure<List<DoseLog>> getDoseLogsForDate(GetLogsForDateParams params);
  EitherFailure<AdherenceReport> getAdherenceReport(AdherenceParams params);
}
