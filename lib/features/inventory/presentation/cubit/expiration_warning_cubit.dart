import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/features/inventory/domain/entities/expiration_warning.dart';
import 'package:drug/features/inventory/domain/usecases/get_expiring_medications.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';

sealed class ExpirationWarningState extends Equatable {
  const ExpirationWarningState();

  @override
  List<Object?> get props => [];
}

final class ExpirationWarningInitial extends ExpirationWarningState {
  const ExpirationWarningInitial();
}

final class ExpirationWarningLoaded extends ExpirationWarningState {
  const ExpirationWarningLoaded({
    required this.warnings,
    required this.criticalCount,
    required this.warningCount,
    required this.infoCount,
  });

  final List<ExpirationWarning> warnings;
  final int criticalCount;
  final int warningCount;
  final int infoCount;

  @override
  List<Object?> get props => [warnings, criticalCount, warningCount, infoCount];
}

@Singleton()
final class ExpirationWarningCubit
    extends Cubit<ExpirationWarningState> {
  ExpirationWarningCubit({
    required GetExpiringMedications getExpiringMedications,
  })  : _getExpiringMedications = getExpiringMedications,
        super(const ExpirationWarningInitial());

  final GetExpiringMedications _getExpiringMedications;

  Future<void> refresh({int withinDays = 90}) async {
    final result = await _getExpiringMedications(
      ExpiringParams(withinDays: withinDays),
    );
    result.fold(
      (_) => emit(const ExpirationWarningLoaded(
        warnings: [],
        criticalCount: 0,
        warningCount: 0,
        infoCount: 0,
      )),
      (warnings) {
        emit(ExpirationWarningLoaded(
          warnings: warnings,
          criticalCount: warnings.where(
            (w) => w.severity == ExpirationSeverity.critical,
          ).length,
          warningCount: warnings.where(
            (w) => w.severity == ExpirationSeverity.warning,
          ).length,
          infoCount: warnings.where(
            (w) => w.severity == ExpirationSeverity.info,
          ).length,
        ));
      },
    );
  }
}
