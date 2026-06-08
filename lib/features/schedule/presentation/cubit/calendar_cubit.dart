import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/usecases/watch_dose_logs.dart';
import 'package:drug/features/schedule/domain/usecases/watch_schedules_for_profile.dart';

sealed class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

final class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

final class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

final class CalendarLoaded extends CalendarState {
  const CalendarLoaded({
    required this.schedules,
    required this.logs,
  });

  final List<DoseSchedule> schedules;
  final List<DoseLog> logs;

  @override
  List<Object?> get props => [schedules, logs];
}

final class CalendarError extends CalendarState {
  const CalendarError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

@injectable
class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit({
    required WatchSchedulesForProfile watchSchedules,
    required WatchDoseLogs watchDoseLogs,
  })  : _watchSchedules = watchSchedules,
        _watchDoseLogs = watchDoseLogs,
        super(const CalendarInitial());

  final WatchSchedulesForProfile _watchSchedules;
  final WatchDoseLogs _watchDoseLogs;
  StreamSubscription? _subscription;

  void startWatching(String profileId) {
    emit(const CalendarLoading());
    _subscription?.cancel();

    _subscription = Rx.combineLatest2<
        Either<Failure, List<DoseSchedule>>,
        Either<Failure, List<DoseLog>>,
        CalendarState>(
      _watchSchedules(profileId),
      _watchDoseLogs(profileId),
      (schedulesResult, logsResult) {
        return schedulesResult.fold(
          (failure) => CalendarError(failure),
          (schedules) => logsResult.fold(
            (failure) => CalendarError(failure),
            (logs) => CalendarLoaded(schedules: schedules, logs: logs),
          ),
        );
      },
    ).listen((state) {
      emit(state);
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
