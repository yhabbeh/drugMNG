import 'package:drug/features/schedule/domain/entities/calendar_dose.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';

final class ScheduleCalendarBuilder {
  static List<DateTime> getOccurrencesForDate(DoseSchedule schedule, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final scheduleStart = DateTime(schedule.startDate.year, schedule.startDate.month, schedule.startDate.day);
    if (startOfDay.isBefore(scheduleStart)) return [];

    if (schedule.endDate != null) {
      final scheduleEnd = DateTime(
        schedule.endDate!.year,
        schedule.endDate!.month,
        schedule.endDate!.day,
        23,
        59,
        59,
        999,
      );
      if (endOfDay.isAfter(scheduleEnd)) return [];
    }

    if (!schedule.isActive) return [];

    final occurrences = <DateTime>[];

    switch (schedule.recurrenceRule.type) {
      case ScheduleType.daily:
        for (final time in schedule.recurrenceRule.times) {
          occurrences.add(DateTime(date.year, date.month, date.day, time.hour, time.minute));
        }
      case ScheduleType.weekly:
        final daysOfWeek = schedule.recurrenceRule.daysOfWeek ?? [];
        if (daysOfWeek.contains(date.weekday)) {
          for (final time in schedule.recurrenceRule.times) {
            occurrences.add(DateTime(date.year, date.month, date.day, time.hour, time.minute));
          }
        }
      case ScheduleType.customInterval:
        final interval = Duration(hours: schedule.recurrenceRule.intervalHours ?? 24);
        var current = schedule.startDate;
        if (current.isBefore(startOfDay)) {
          final hoursDiff = startOfDay.difference(current).inHours;
          final intervalsToSkip = (hoursDiff / (schedule.recurrenceRule.intervalHours ?? 24)).floor();
          current = current.add(interval * intervalsToSkip);
        }
        while (current.isBefore(startOfDay)) {
          current = current.add(interval);
        }
        while (!current.isAfter(endOfDay)) {
          if (!current.isBefore(startOfDay)) {
            occurrences.add(current);
          }
          current = current.add(interval);
        }
      case ScheduleType.prn:
        break;
    }

    return occurrences;
  }

  static List<CalendarDose> buildDosesForDate({
    required DateTime date,
    required List<DoseSchedule> schedules,
    required List<DoseLog> logs,
  }) {
    final calendarDoses = <CalendarDose>[];
    final now = DateTime.now();

    for (final schedule in schedules) {
      final occurrences = getOccurrencesForDate(schedule, date);
      for (final occurrence in occurrences) {
        for (final med in schedule.medications) {
          final log = logs.where((l) =>
              l.scheduleId == schedule.id &&
              l.medicationId == med.medicationId &&
              l.scheduledAt.year == occurrence.year &&
              l.scheduledAt.month == occurrence.month &&
              l.scheduledAt.day == occurrence.day &&
              l.scheduledAt.hour == occurrence.hour &&
              l.scheduledAt.minute == occurrence.minute).firstOrNull;

          CalendarDoseStatus status = CalendarDoseStatus.pending;
          DateTime? takenAt;

          if (log != null) {
            status = switch (log.status) {
              DoseStatus.taken => CalendarDoseStatus.taken,
              DoseStatus.skipped => CalendarDoseStatus.skipped,
              DoseStatus.missed => CalendarDoseStatus.missed,
              DoseStatus.pending => CalendarDoseStatus.pending,
            };
            takenAt = log.takenAt;
          } else if (occurrence.isBefore(now)) {
            status = CalendarDoseStatus.missed;
          }

          calendarDoses.add(CalendarDose(
            scheduleId: schedule.id,
            medicationId: med.medicationId,
            medicationName: med.medicationName,
            scheduledAt: occurrence,
            status: status,
            takenAt: takenAt,
          ));
        }
      }
    }

    return calendarDoses;
  }
}
