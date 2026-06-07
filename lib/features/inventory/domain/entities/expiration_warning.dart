import 'package:equatable/equatable.dart';

import 'package:drug/features/inventory/domain/entities/medication.dart';

enum ExpirationSeverity { critical, warning, info }

final class ExpirationWarning extends Equatable {
  const ExpirationWarning({
    required this.medication,
    required this.daysUntilExpiry,
    required this.severity,
  });

  final Medication medication;
  final int daysUntilExpiry;
  final ExpirationSeverity severity;

  @override
  List<Object?> get props => [medication, daysUntilExpiry, severity];
}
