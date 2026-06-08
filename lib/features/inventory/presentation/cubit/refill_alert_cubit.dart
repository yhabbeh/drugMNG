import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/features/inventory/domain/entities/refill_alert.dart';
import 'package:drug/features/inventory/domain/usecases/get_refill_alerts.dart';
import 'package:drug/features/profiles/presentation/cubit/active_profile_cubit.dart';

sealed class RefillAlertState extends Equatable {
  const RefillAlertState();

  @override
  List<Object?> get props => [];
}

final class RefillAlertInitial extends RefillAlertState {
  const RefillAlertInitial();
}

final class RefillAlertLoaded extends RefillAlertState {
  const RefillAlertLoaded({
    required this.alerts,
    required this.lowStockCount,
  });

  final List<RefillAlert> alerts;
  final int lowStockCount;

  @override
  List<Object?> get props => [alerts, lowStockCount];
}

@Singleton()
final class RefillAlertCubit extends Cubit<RefillAlertState> {
  RefillAlertCubit({
    required GetRefillAlerts getRefillAlerts,
    required ActiveProfileCubit activeProfileCubit,
  })  : _getRefillAlerts = getRefillAlerts,
        _activeProfileCubit = activeProfileCubit,
        super(const RefillAlertInitial()) {
    _profileSubscription = _activeProfileCubit.stream.listen((state) {
      if (state is ActiveProfileSelected) {
        refresh(profileId: state.profile.id);
      } else {
        emit(const RefillAlertLoaded(alerts: [], lowStockCount: 0));
      }
    });
  }

  final GetRefillAlerts _getRefillAlerts;
  final ActiveProfileCubit _activeProfileCubit;
  StreamSubscription? _profileSubscription;

  Future<void> refresh({String? profileId, int windowDays = 7}) async {
    String? targetProfileId = profileId;
    if (targetProfileId == null) {
      final activeState = _activeProfileCubit.state;
      if (activeState is ActiveProfileSelected) {
        targetProfileId = activeState.profile.id;
      }
    }

    if (targetProfileId == null || targetProfileId.isEmpty) {
      emit(const RefillAlertLoaded(alerts: [], lowStockCount: 0));
      return;
    }

    final result = await _getRefillAlerts(
      RefillAlertParams(profileId: targetProfileId, windowDays: windowDays),
    );

    result.fold(
      (_) => emit(const RefillAlertLoaded(alerts: [], lowStockCount: 0)),
      (alerts) {
        emit(RefillAlertLoaded(
          alerts: alerts,
          lowStockCount: alerts.length,
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}
