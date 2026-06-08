import 'package:equatable/equatable.dart';

enum CalendarDoseStatus { taken, skipped, pending, missed }

final class CalendarDose extends Equatable {
  const CalendarDose({
    required this.scheduleId,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledAt,
    required this.status,
    this.takenAt,
  });

  final String scheduleId;
  final String medicationId;
  final String medicationName;
  final DateTime scheduledAt;
  final CalendarDoseStatus status;
  final DateTime? takenAt;

  @override
  List<Object?> get props => [
        scheduleId,
        medicationId,
        medicationName,
        scheduledAt,
        status,
        takenAt,
      ];
}
