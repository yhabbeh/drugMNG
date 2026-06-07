import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';

abstract interface class NotificationScheduler {
  Future<void> scheduleForDose(DoseSchedule schedule);
  Future<void> cancelForSchedule(String scheduleId);
  Future<void> cancelAllForProfile(String profileId);
  Future<void> rescheduleAll(List<DoseSchedule> schedules);
}
