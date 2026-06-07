import 'package:equatable/equatable.dart';

import 'package:drug/features/schedule/domain/entities/schedule_time.dart';

enum ScheduleType { daily, weekly, customInterval, prn }

final class RecurrenceRule extends Equatable {
  const RecurrenceRule({
    required this.type,
    this.times = const [],
    this.intervalHours,
    this.daysOfWeek,
  });

  final ScheduleType type;
  final List<ScheduleTime> times;
  final int? intervalHours;
  final List<int>? daysOfWeek;

  DateTime? nextOccurrence(DateTime from) {
    if (type == ScheduleType.prn) return null;
    if (times.isEmpty) return null;

    final todayOccurrences = times
        .map((t) =>
            DateTime(from.year, from.month, from.day, t.hour, t.minute))
        .where((dt) => dt.isAfter(from) || dt.isAtSameMomentAs(from))
        .toList()
      ..sort();

    if (todayOccurrences.isNotEmpty) return todayOccurrences.first;

    DateTime nextDate;
    switch (type) {
      case ScheduleType.daily:
        nextDate = from.add(const Duration(days: 1));
      case ScheduleType.weekly:
        nextDate = from.add(const Duration(days: 7));
      case ScheduleType.customInterval:
        return from.add(Duration(hours: intervalHours ?? 24));
      case ScheduleType.prn:
        return null;
    }

    final firstTimeToday = times.first;
    return DateTime(nextDate.year, nextDate.month, nextDate.day,
        firstTimeToday.hour, firstTimeToday.minute);
  }

  @override
  List<Object?> get props => [type, times, intervalHours, daysOfWeek];
}
