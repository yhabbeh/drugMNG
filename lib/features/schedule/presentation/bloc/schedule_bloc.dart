import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/usecases/create_schedule.dart';
import 'package:drug/features/schedule/domain/usecases/delete_schedule.dart';
import 'package:drug/features/schedule/domain/usecases/get_schedules_for_profile.dart';
import 'package:drug/features/schedule/domain/usecases/log_dose_skipped.dart';
import 'package:drug/features/schedule/domain/usecases/log_dose_taken.dart';
import 'package:drug/features/schedule/domain/usecases/revert_dose_log.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';
import 'package:drug/features/schedule/domain/usecases/update_schedule.dart';
import 'package:drug/features/schedule/domain/usecases/watch_schedules_for_profile.dart';

sealed class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object?> get props => [];
}

final class SchedulesStarted extends ScheduleEvent {
  const SchedulesStarted(this.profileId);

  final String profileId;

  @override
  List<Object?> get props => [profileId];
}

final class ScheduleAdded extends ScheduleEvent {
  const ScheduleAdded(this.schedule);

  final DoseSchedule schedule;

  @override
  List<Object?> get props => [schedule];
}

final class ScheduleUpdated extends ScheduleEvent {
  const ScheduleUpdated(this.schedule);

  final DoseSchedule schedule;

  @override
  List<Object?> get props => [schedule];
}

final class ScheduleDeleted extends ScheduleEvent {
  const ScheduleDeleted(this.scheduleId);

  final String scheduleId;

  @override
  List<Object?> get props => [scheduleId];
}

final class ScheduleDoseTaken extends ScheduleEvent {
  const ScheduleDoseTaken(this.params);

  final LogDoseParams params;

  @override
  List<Object?> get props => [params];
}

final class ScheduleDoseSkipped extends ScheduleEvent {
  const ScheduleDoseSkipped(this.params);

  final LogDoseParams params;

  @override
  List<Object?> get props => [params];
}

final class ScheduleDoseReverted extends ScheduleEvent {
  const ScheduleDoseReverted(this.params);

  final LogDoseParams params;

  @override
  List<Object?> get props => [params];
}

final class SchedulesRefreshRequested extends ScheduleEvent {
  const SchedulesRefreshRequested(this.profileId);

  final String profileId;

  @override
  List<Object?> get props => [profileId];
}

sealed class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object?> get props => [];
}

final class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

final class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

final class ScheduleLoaded extends ScheduleState {
  const ScheduleLoaded({
    required this.schedules,
    this.isLoading = false,
  });

  final List<DoseSchedule> schedules;
  final bool isLoading;

  @override
  List<Object?> get props => [schedules, isLoading];
}

final class ScheduleDoseActionSuccess extends ScheduleState {
  const ScheduleDoseActionSuccess();
}

final class ScheduleError extends ScheduleState {
  const ScheduleError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

@Singleton()
final class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleBloc({
    required GetSchedulesForProfile getSchedulesForProfile,
    required WatchSchedulesForProfile watchSchedulesForProfile,
    required CreateSchedule createSchedule,
    required UpdateSchedule updateSchedule,
    required DeleteSchedule deleteSchedule,
    required LogDoseTaken logDoseTaken,
    required LogDoseSkipped logDoseSkipped,
    required RevertDoseLog revertDoseLog,
  })  : _getSchedulesForProfile = getSchedulesForProfile,
        _watchSchedulesForProfile = watchSchedulesForProfile,
        _createSchedule = createSchedule,
        _updateSchedule = updateSchedule,
        _deleteSchedule = deleteSchedule,
        _logDoseTaken = logDoseTaken,
        _logDoseSkipped = logDoseSkipped,
        _revertDoseLog = revertDoseLog,
        super(const ScheduleInitial()) {
    on<SchedulesStarted>(_onStarted);
    on<ScheduleAdded>(_onAdded);
    on<ScheduleUpdated>(_onUpdated);
    on<ScheduleDeleted>(_onDeleted);
    on<ScheduleDoseTaken>(_onDoseTaken);
    on<ScheduleDoseSkipped>(_onDoseSkipped);
    on<ScheduleDoseReverted>(_onDoseReverted);
    on<SchedulesRefreshRequested>(_onRefreshRequested);
  }

  final GetSchedulesForProfile _getSchedulesForProfile;
  final WatchSchedulesForProfile _watchSchedulesForProfile;
  final CreateSchedule _createSchedule;
  final UpdateSchedule _updateSchedule;
  final DeleteSchedule _deleteSchedule;
  final LogDoseTaken _logDoseTaken;
  final LogDoseSkipped _logDoseSkipped;
  final RevertDoseLog _revertDoseLog;

  Future<void> _onStarted(
    SchedulesStarted event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());
    unawaited(_getSchedulesForProfile(event.profileId));
    await emit.forEach<Either<Failure, List<DoseSchedule>>>(
      _watchSchedulesForProfile(event.profileId),
      onData: (either) {
        return either.fold(
          (failure) => ScheduleError(failure),
          (schedules) => ScheduleLoaded(schedules: schedules),
        );
      },
      onError: (error, stackTrace) => ScheduleError(
        ServerFailure(error.toString()),
      ),
    );
  }

  Future<void> _onAdded(
    ScheduleAdded event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());
    final result = await _createSchedule(event.schedule);
    result.fold(
      (failure) => emit(ScheduleError(failure)),
      (_) {},
    );
  }

  Future<void> _onUpdated(
    ScheduleUpdated event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());
    final result = await _updateSchedule(event.schedule);
    result.fold(
      (failure) => emit(ScheduleError(failure)),
      (_) {},
    );
  }

  Future<void> _onDeleted(
    ScheduleDeleted event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());
    final result = await _deleteSchedule(event.scheduleId);
    result.fold(
      (failure) => emit(ScheduleError(failure)),
      (_) {},
    );
  }

  Future<void> _onDoseTaken(
    ScheduleDoseTaken event,
    Emitter<ScheduleState> emit,
  ) async {
    final currentState = state;
    final result = await _logDoseTaken(event.params);
    result.fold(
      (failure) => emit(ScheduleError(failure)),
      (_) {
        if (currentState is ScheduleLoaded) {
          emit(const ScheduleDoseActionSuccess());
          emit(ScheduleLoaded(
            schedules: currentState.schedules,
            isLoading: false,
          ));
        }
      },
    );
  }

  Future<void> _onDoseSkipped(
    ScheduleDoseSkipped event,
    Emitter<ScheduleState> emit,
  ) async {
    final currentState = state;
    final result = await _logDoseSkipped(event.params);
    result.fold(
      (failure) => emit(ScheduleError(failure)),
      (_) {
        if (currentState is ScheduleLoaded) {
          emit(const ScheduleDoseActionSuccess());
          emit(ScheduleLoaded(
            schedules: currentState.schedules,
            isLoading: false,
          ));
        }
      },
    );
  }

  Future<void> _onDoseReverted(
    ScheduleDoseReverted event,
    Emitter<ScheduleState> emit,
  ) async {
    final currentState = state;
    final result = await _revertDoseLog(event.params);
    result.fold(
      (failure) => emit(ScheduleError(failure)),
      (_) {
        if (currentState is ScheduleLoaded) {
          emit(const ScheduleDoseActionSuccess());
          emit(ScheduleLoaded(
            schedules: currentState.schedules,
            isLoading: false,
          ));
        }
      },
    );
  }

  Future<void> _onRefreshRequested(
    SchedulesRefreshRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    final result = await _getSchedulesForProfile(event.profileId);
    result.fold(
      (failure) => emit(ScheduleError(failure)),
      (schedules) => emit(ScheduleLoaded(schedules: schedules)),
    );
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
