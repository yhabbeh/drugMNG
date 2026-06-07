import 'package:equatable/equatable.dart';

final class LogDoseParams extends Equatable {
  const LogDoseParams({
    required this.scheduleId,
    required this.profileId,
    required this.medicationId,
    required this.scheduledAt,
    this.notes,
  });

  final String scheduleId;
  final String profileId;
  final String medicationId;
  final DateTime scheduledAt;
  final String? notes;

  @override
  List<Object?> get props => [scheduleId, profileId, medicationId, scheduledAt];
}

final class GetLogsForDateParams extends Equatable {
  const GetLogsForDateParams({
    required this.profileId,
    required this.date,
  });

  final String profileId;
  final DateTime date;

  @override
  List<Object?> get props => [profileId, date];
}

final class AdherenceParams extends Equatable {
  const AdherenceParams({
    required this.profileId,
    required this.periodStart,
    required this.periodEnd,
  });

  final String profileId;
  final DateTime periodStart;
  final DateTime periodEnd;

  @override
  List<Object?> get props => [profileId, periodStart, periodEnd];
}
