import 'package:drug/features/schedule/domain/entities/dose_log.dart';

final class DoseLogModel {
  const DoseLogModel({
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
  final String status;
  final String? notes;
  final int stockDeductedCount;

  factory DoseLogModel.fromJson(Map<String, dynamic> json) {
    return DoseLogModel(
      id: json['id'] as String,
      scheduleId: json['scheduleId'] as String,
      profileId: json['profileId'] as String,
      medicationId: json['medicationId'] as String,
      medicationName: json['medicationName'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      takenAt: json['takenAt'] != null
          ? DateTime.parse(json['takenAt'] as String)
          : null,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      stockDeductedCount: json['stockDeductedCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduleId': scheduleId,
      'profileId': profileId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'scheduledAt': scheduledAt.toIso8601String(),
      'takenAt': takenAt?.toIso8601String(),
      'status': status,
      'notes': notes,
      'stockDeductedCount': stockDeductedCount,
    };
  }

  factory DoseLogModel.fromDomain(DoseLog log) {
    return DoseLogModel(
      id: log.id,
      scheduleId: log.scheduleId,
      profileId: log.profileId,
      medicationId: log.medicationId,
      medicationName: log.medicationName,
      scheduledAt: log.scheduledAt,
      takenAt: log.takenAt,
      status: log.status.name,
      notes: log.notes,
      stockDeductedCount: log.stockDeductedCount,
    );
  }

  DoseLog toDomain() {
    return DoseLog(
      id: id,
      scheduleId: scheduleId,
      profileId: profileId,
      medicationId: medicationId,
      medicationName: medicationName,
      scheduledAt: scheduledAt,
      takenAt: takenAt,
      status: DoseStatus.values.firstWhere((s) => s.name == status),
      notes: notes,
      stockDeductedCount: stockDeductedCount,
    );
  }
}
