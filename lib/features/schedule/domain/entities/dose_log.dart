import 'package:equatable/equatable.dart';

enum DoseStatus { taken, skipped, missed, pending }

final class DoseLog extends Equatable {
  const DoseLog({
    required this.id,
    required this.scheduleId,
    required this.profileId,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    this.notes,
    this.stockDeductedCount = 0,
  });

  final String id;
  final String scheduleId;
  final String profileId;
  final String medicationId;
  final String medicationName;
  final DateTime scheduledAt;
  final DateTime? takenAt;
  final DoseStatus status;
  final String? notes;
  final int stockDeductedCount;

  DoseLog copyWith({
    String? id,
    String? scheduleId,
    String? profileId,
    String? medicationId,
    String? medicationName,
    DateTime? scheduledAt,
    DateTime? takenAt,
    DoseStatus? status,
    String? notes,
    int? stockDeductedCount,
  }) {
    return DoseLog(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      profileId: profileId ?? this.profileId,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      takenAt: takenAt ?? this.takenAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      stockDeductedCount: stockDeductedCount ?? this.stockDeductedCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        scheduleId,
        profileId,
        medicationId,
        medicationName,
        scheduledAt,
        takenAt,
        status,
        notes,
        stockDeductedCount,
      ];
}
