import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:drug/core/notifications/notification_scheduler_impl.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/domain/entities/schedule_time.dart';
import 'package:drug/features/schedule/domain/entities/scheduled_medication.dart';

class MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {
  @override
  Future<void> cancel(int id, {String? tag}) async {}
  @override
  Future<void> cancelAll() async {}
}

void main() {
  late MockPlugin mockPlugin;
  late NotificationSchedulerImpl scheduler;

  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(
      tz.TZDateTime.from(DateTime(2026), tz.local),
    );
    registerFallbackValue(
      const NotificationDetails(
        android: AndroidNotificationDetails('channel', 'name'),
      ),
    );
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(DateTimeComponents.time);
  });

  setUp(() {
    mockPlugin = MockPlugin();
    scheduler = NotificationSchedulerImpl(plugin: mockPlugin);
  });

  group('scheduleForDose', () {
    test('should schedule notifications for upcoming occurrences', () async {
      when(() => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            payload: any(named: 'payload'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          )).thenAnswer((_) async {});

      final schedule = DoseSchedule(
        id: 'sched-1',
        profileId: 'profile-1',
        medications: const [
          ScheduledMedication(
            medicationId: 'med-1',
            medicationName: 'Amoxicillin',
          ),
        ],
        recurrenceRule: const RecurrenceRule(
          type: ScheduleType.daily,
          times: [ScheduleTime(hour: 8, minute: 0)],
        ),
        startDate: DateTime(2026, 6, 1),
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      await scheduler.scheduleForDose(schedule);

      verify(() => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            payload: any(named: 'payload'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          )).called(greaterThan(0));
    });
  });

  group('cancelForSchedule', () {
    test('should not throw', () async {
      await scheduler.cancelForSchedule('sched-1');
    });
  });

  group('cancelAllForProfile', () {
    test('should not throw', () async {
      await scheduler.cancelAllForProfile('profile-1');
    });
  });

  group('rescheduleAll', () {
    test('should schedule active schedules', () async {
      when(() => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            payload: any(named: 'payload'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          )).thenAnswer((_) async {});

      await scheduler.rescheduleAll([
        DoseSchedule(
          id: 'sched-1',
          profileId: 'profile-1',
          medications: const [
            ScheduledMedication(
              medicationId: 'med-1',
              medicationName: 'Amoxicillin',
            ),
          ],
          recurrenceRule: const RecurrenceRule(
            type: ScheduleType.daily,
            times: [ScheduleTime(hour: 8, minute: 0)],
          ),
          startDate: DateTime(2026, 6, 1),
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          isActive: true,
        ),
      ]);

      verify(() => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            payload: any(named: 'payload'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          )).called(greaterThan(0));
    });
  });
}
