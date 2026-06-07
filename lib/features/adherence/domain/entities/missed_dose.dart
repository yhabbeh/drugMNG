import 'package:equatable/equatable.dart';

final class MissedDose extends Equatable {
  const MissedDose({
    required this.logId,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledAt,
  });

  final String logId;
  final String medicationId;
  final String medicationName;
  final DateTime scheduledAt;

  @override
  List<Object?> get props => [logId, medicationId, medicationName, scheduledAt];
}
