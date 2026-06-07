import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/usecases/get_dose_logs_for_date.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';

sealed class DoseLogState extends Equatable {
  const DoseLogState();

  @override
  List<Object?> get props => [];
}

final class DoseLogInitial extends DoseLogState {
  const DoseLogInitial();
}

final class DoseLogLoading extends DoseLogState {
  const DoseLogLoading();
}

final class DoseLogLoaded extends DoseLogState {
  const DoseLogLoaded({
    required this.logs,
    required this.date,
  });

  final List<DoseLog> logs;
  final DateTime date;

  @override
  List<Object?> get props => [logs, date];
}

final class DoseLogError extends DoseLogState {
  const DoseLogError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

@Singleton()
final class DoseLogCubit extends Cubit<DoseLogState> {
  DoseLogCubit({
    required GetDoseLogsForDate getDoseLogsForDate,
  })  : _getDoseLogsForDate = getDoseLogsForDate,
        super(const DoseLogInitial());

  final GetDoseLogsForDate _getDoseLogsForDate;

  Future<void> loadForDate(String profileId, DateTime date) async {
    emit(const DoseLogLoading());
    final result = await _getDoseLogsForDate(
      GetLogsForDateParams(profileId: profileId, date: date),
    );
    result.fold(
      (failure) => emit(DoseLogError(failure)),
      (logs) => emit(DoseLogLoaded(logs: logs, date: date)),
    );
  }
}
