import 'package:equatable/equatable.dart';

import 'package:drug/features/inventory/domain/value_objects/enums.dart';

/// A single medication entry within a [DoseSchedule].
final class ScheduledMedication extends Equatable {
  const ScheduledMedication({
    required this.medicationId,
    required this.medicationName,
    this.dosageAmount,
    this.dosageUnit,
  });

  /// ID from the inventory. Empty string if the name was entered manually.
  final String medicationId;

  /// Display name of the medication.
  final String medicationName;

  final double? dosageAmount;
  final DosageUnit? dosageUnit;

  ScheduledMedication copyWith({
    String? medicationId,
    String? medicationName,
    double? dosageAmount,
    DosageUnit? dosageUnit,
  }) {
    return ScheduledMedication(
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      dosageAmount: dosageAmount ?? this.dosageAmount,
      dosageUnit: dosageUnit ?? this.dosageUnit,
    );
  }

  Map<String, dynamic> toJson() => {
        'medicationId': medicationId,
        'medicationName': medicationName,
        'dosageAmount': dosageAmount,
        'dosageUnit': dosageUnit?.name,
      };

  factory ScheduledMedication.fromJson(Map<String, dynamic> json) {
    return ScheduledMedication(
      medicationId: json['medicationId'] as String? ?? '',
      medicationName: json['medicationName'] as String? ?? '',
      dosageAmount: (json['dosageAmount'] as num?)?.toDouble(),
      dosageUnit: json['dosageUnit'] != null
          ? DosageUnit.values.firstWhere(
              (u) => u.name == json['dosageUnit'],
              orElse: () => DosageUnit.mg,
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [
        medicationId,
        medicationName,
        dosageAmount,
        dosageUnit,
      ];
}
