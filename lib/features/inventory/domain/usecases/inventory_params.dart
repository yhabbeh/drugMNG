import 'package:equatable/equatable.dart';

final class UpdateStockParams extends Equatable {
  const UpdateStockParams({
    required this.medicationId,
    required this.quantityChange,
    this.reason,
  });

  final String medicationId;
  final int quantityChange;
  final String? reason;

  @override
  List<Object?> get props => [medicationId, quantityChange, reason];
}

final class ExpiringParams extends Equatable {
  const ExpiringParams({required this.withinDays});

  final int withinDays;

  @override
  List<Object?> get props => [withinDays];
}
