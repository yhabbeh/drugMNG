import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/entities/refill_alert.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drug/features/inventory/domain/services/refill_calculator.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';

final class RefillAlertParams extends Equatable {
  const RefillAlertParams({
    required this.profileId,
    required this.windowDays,
  });

  final String profileId;
  final int windowDays;

  @override
  List<Object?> get props => [profileId, windowDays];
}

@injectable
class GetRefillAlerts implements UseCase<List<RefillAlert>, RefillAlertParams> {
  GetRefillAlerts({
    required InventoryRepository inventoryRepository,
    required ScheduleRepository scheduleRepository,
  })  : _inventoryRepository = inventoryRepository,
        _scheduleRepository = scheduleRepository;

  final InventoryRepository _inventoryRepository;
  final ScheduleRepository _scheduleRepository;

  @override
  EitherFailure<List<RefillAlert>> call(RefillAlertParams params) async {
    // 1. Fetch medications
    final medicationsResult = await _inventoryRepository.getMedications();
    
    return medicationsResult.fold(
      (failure) => Left(failure),
      (medications) async {
        // Filter medications by profileId
        final profileMeds = medications
            .where((med) => med.profileId == params.profileId)
            .toList();

        if (profileMeds.isEmpty) {
          return const Right([]);
        }

        // 2. Fetch schedules for profile
        final schedulesResult =
            await _scheduleRepository.getSchedulesForProfile(params.profileId);

        return schedulesResult.fold(
          (failure) => Left(failure),
          (schedules) {
            final alerts = <RefillAlert>[];

            for (final med in profileMeds) {
              final emptyDate = RefillCalculator.estimateExhaustionDate(
                med,
                schedules,
              );

              if (emptyDate != null) {
                final daysRemaining = emptyDate.difference(DateTime.now()).inDays;
                
                // Alert if predicted depletion date is within windowDays
                // OR if stock is below refillThreshold (if set)
                final isUnderAlertWindow = daysRemaining <= params.windowDays;
                final isUnderStockThreshold = med.refillThreshold != null &&
                    med.currentStock <= med.refillThreshold!;

                if (isUnderAlertWindow || isUnderStockThreshold) {
                  alerts.add(RefillAlert(
                    medication: med,
                    daysUntilEmpty: daysRemaining < 0 ? 0 : daysRemaining,
                    predictedEmptyDate: emptyDate,
                  ));
                }
              } else if (med.refillThreshold != null &&
                  med.currentStock <= med.refillThreshold!) {
                // Handle cases where there is no schedule, but stock is below threshold
                alerts.add(RefillAlert(
                  medication: med,
                  daysUntilEmpty: 0,
                  predictedEmptyDate: DateTime.now(),
                ));
              }
            }

            return Right(alerts);
          },
        );
      },
    );
  }
}
