import 'package:equatable/equatable.dart';

final class MedicationStock extends Equatable {
  const MedicationStock({
    required this.medicationId,
    required this.currentCount,
    required this.unitSize,
    this.refillThreshold,
    required this.lastUpdated,
  });

  final String medicationId;
  final int currentCount;
  final String unitSize;
  final int? refillThreshold;
  final DateTime lastUpdated;

  MedicationStock copyWith({
    String? medicationId,
    int? currentCount,
    String? unitSize,
    int? refillThreshold,
    DateTime? lastUpdated,
  }) {
    return MedicationStock(
      medicationId: medicationId ?? this.medicationId,
      currentCount: currentCount ?? this.currentCount,
      unitSize: unitSize ?? this.unitSize,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        medicationId,
        currentCount,
        unitSize,
        refillThreshold,
        lastUpdated,
      ];
}
