import 'dart:convert';

final class NotificationPayload {
  const NotificationPayload({
    required this.scheduleId,
    required this.profileId,
    required this.medicationId,
    required this.scheduledAt,
  });

  final String scheduleId;
  final String profileId;
  final String medicationId;
  final String scheduledAt;

  String encode() => jsonEncode({
        'scheduleId': scheduleId,
        'profileId': profileId,
        'medicationId': medicationId,
        'scheduledAt': scheduledAt,
      });

  factory NotificationPayload.decode(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return NotificationPayload(
      scheduleId: map['scheduleId'] as String,
      profileId: map['profileId'] as String,
      medicationId: map['medicationId'] as String,
      scheduledAt: map['scheduledAt'] as String,
    );
  }
}
