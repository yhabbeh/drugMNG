import 'package:equatable/equatable.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';

final class RefillAlert extends Equatable {
  const RefillAlert({
    required this.medication,
    required this.daysUntilEmpty,
    required this.predictedEmptyDate,
  });

  final Medication medication;
  final int daysUntilEmpty;
  final DateTime predictedEmptyDate;

  @override
  List<Object?> get props => [medication, daysUntilEmpty, predictedEmptyDate];
}
