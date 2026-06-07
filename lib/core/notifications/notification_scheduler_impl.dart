import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import 'package:drug/core/notifications/notification_payload.dart';
import 'package:drug/core/notifications/notification_scheduler.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';

final class NotificationSchedulerImpl implements NotificationScheduler {
  NotificationSchedulerImpl({
    required FlutterLocalNotificationsPlugin plugin,
  }) : _plugin = plugin;

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'dose_reminders';
  static const _channelName = 'Dose Reminders';

  int _notificationId(String scheduleId, int occurrenceIndex) =>
      scheduleId.hashCode.abs() * 1000 + occurrenceIndex;

  static Future<FlutterLocalNotificationsPlugin> init({
    required void Function(String? payload) onSelectNotification,
  }) async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        onSelectNotification(response.payload);
      },
    );

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    return plugin;
  }

  @override
  Future<void> scheduleForDose(DoseSchedule schedule) async {
    final now = DateTime.now();
    final startDate = schedule.startDate.isAfter(now) ? schedule.startDate : now;

    final occurrences = <DateTime>[];
    var current = schedule.recurrenceRule.nextOccurrence(startDate);
    while (current != null && occurrences.length < 7) {
      occurrences.add(current);
      current = schedule.recurrenceRule.nextOccurrence(
        current.add(const Duration(minutes: 1)),
      );
    }

    for (var i = 0; i < occurrences.length; i++) {
      final dt = occurrences[i];
      final id = _notificationId(schedule.id, i);
      final payload = NotificationPayload(
        scheduleId: schedule.id,
        profileId: schedule.profileId,
        medicationId: schedule.medicationId,
        scheduledAt: dt.toIso8601String(),
      ).encode();

      await _plugin.zonedSchedule(
        id,
        schedule.medicationName,
        'Time for your ${schedule.medicationName} dose',
        tz.TZDateTime.from(dt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            fullScreenIntent: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: payload,
      );
    }
  }

  @override
  Future<void> cancelForSchedule(String scheduleId) async {
    for (var i = 0; i < 7; i++) {
      await _plugin.cancel(_notificationId(scheduleId, i));
    }
  }

  @override
  Future<void> cancelAllForProfile(String profileId) async {
    await _plugin.cancelAll();
  }

  @override
  Future<void> rescheduleAll(List<DoseSchedule> schedules) async {
    await _plugin.cancelAll();
    for (final schedule in schedules) {
      if (schedule.isActive) {
        await scheduleForDose(schedule);
      }
    }
  }
}
