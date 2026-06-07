import 'package:flutter_test/flutter_test.dart';

import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/domain/entities/schedule_time.dart';

void main() {
  group('RecurrenceRule.nextOccurrence', () {
    final base = DateTime(2026, 6, 1, 10, 0);

    test('returns next time today if after current time', () {
      final rule = const RecurrenceRule(
        type: ScheduleType.daily,
        times: [ScheduleTime(hour: 14, minute: 30)],
      );
      final result = rule.nextOccurrence(base);
      expect(result, DateTime(2026, 6, 1, 14, 30));
    });

    test('returns first time today if at same moment', () {
      final rule = const RecurrenceRule(
        type: ScheduleType.daily,
        times: [ScheduleTime(hour: 10, minute: 0)],
      );
      final result = rule.nextOccurrence(base);
      expect(result, DateTime(2026, 6, 1, 10, 0));
    });

    test('returns next day for daily type when all times passed', () {
      final rule = const RecurrenceRule(
        type: ScheduleType.daily,
        times: [ScheduleTime(hour: 8, minute: 0)],
      );
      final result = rule.nextOccurrence(base);
      expect(result, DateTime(2026, 6, 2, 8, 0));
    });

    test('returns next week for weekly type when all times passed', () {
      final rule = const RecurrenceRule(
        type: ScheduleType.weekly,
        times: [ScheduleTime(hour: 8, minute: 0)],
      );
      final result = rule.nextOccurrence(base);
      expect(result, DateTime(2026, 6, 8, 8, 0));
    });

    test('returns after interval hours for customInterval type when all times passed', () {
      final rule = const RecurrenceRule(
        type: ScheduleType.customInterval,
        intervalHours: 6,
        times: [ScheduleTime(hour: 10, minute: 0)],
      );
      final afterMorning = DateTime(2026, 6, 1, 11, 0);
      final result = rule.nextOccurrence(afterMorning);
      expect(result, DateTime(2026, 6, 1, 17, 0));
    });

    test('returns null for prn type with times', () {
      final rule = const RecurrenceRule(
        type: ScheduleType.prn,
        times: [ScheduleTime(hour: 10, minute: 0)],
      );
      expect(rule.nextOccurrence(base), isNull);
    });

    test('returns null when no times defined', () {
      final rule = const RecurrenceRule(
        type: ScheduleType.daily,
        times: [],
      );
      expect(rule.nextOccurrence(base), isNull);
    });

    test('picks earliest future time when multiple times in day', () {
      final rule = const RecurrenceRule(
        type: ScheduleType.daily,
        times: [
          ScheduleTime(hour: 14, minute: 0),
          ScheduleTime(hour: 9, minute: 0),
          ScheduleTime(hour: 11, minute: 0),
        ],
      );
      final morning = DateTime(2026, 6, 1, 8, 0);
      final result = rule.nextOccurrence(morning);
      expect(result, DateTime(2026, 6, 1, 9, 0));
    });
  });
}
