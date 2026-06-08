import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';

final class RefillCalculator {
  static double calculateDosesPerDay(DoseSchedule schedule, String medicationId) {
    if (!schedule.isActive) return 0.0;

    final hasMed = schedule.medications.any((m) => m.medicationId == medicationId);
    if (!hasMed) return 0.0;

    final rule = schedule.recurrenceRule;
    switch (rule.type) {
      case ScheduleType.daily:
        return rule.times.length.toDouble();
      case ScheduleType.weekly:
        final daysCount = rule.daysOfWeek?.length ?? 0;
        if (daysCount == 0) return 0.0;
        return (rule.times.length * daysCount) / 7.0;
      case ScheduleType.customInterval:
        final hours = rule.intervalHours ?? 24;
        if (hours == 0) return 0.0;
        return 24.0 / hours;
      case ScheduleType.prn:
        return 0.0;
    }
  }

  static DateTime? estimateExhaustionDate(
    Medication medication,
    List<DoseSchedule> schedules,
  ) {
    double totalDosesPerDay = 0.0;
    for (final schedule in schedules) {
      totalDosesPerDay += calculateDosesPerDay(schedule, medication.id);
    }

    if (totalDosesPerDay == 0.0) {
      final estimated = medication.estimatedDosesPerDay ?? 0.0;
      if (estimated <= 0) return null;
      totalDosesPerDay = estimated;
    }

    final currentStock = medication.currentStock;
    if (currentStock <= 0) {
      return DateTime.now();
    }

    if (totalDosesPerDay <= 0.0) {
      return null;
    }

    final daysRemaining = (currentStock / totalDosesPerDay).ceil();
    return DateTime.now().add(Duration(days: daysRemaining));
  }
}
