import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/adherence/domain/entities/adherence_range.dart';
import 'package:drug/features/adherence/domain/usecases/get_adherence_summary.dart';
import 'package:drug/features/adherence/domain/usecases/get_missed_doses.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_event.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_state.dart';

class AdherenceBloc extends Bloc<AdherenceEvent, AdherenceState> {
  AdherenceBloc({
    required GetAdherenceSummary getAdherenceSummary,
    required GetMissedDoses getMissedDoses,
  })  : _getAdherenceSummary = getAdherenceSummary,
        _getMissedDoses = getMissedDoses,
        super(const AdherenceInitial()) {
    on<AdherenceStarted>(_onStarted);
    on<AdherenceRangeChanged>(_onRangeChanged);
    on<AdherenceRefreshed>(_onRefreshed);
  }

  final GetAdherenceSummary _getAdherenceSummary;
  final GetMissedDoses _getMissedDoses;

  String? _profileId;
  AdherenceRange _range = AdherenceRange.week;

  Future<void> _onStarted(
    AdherenceStarted event,
    Emitter<AdherenceState> emit,
  ) async {
    _profileId = event.profileId;
    _range = event.range;
    await _load(emit, event.range);
  }

  Future<void> _onRangeChanged(
    AdherenceRangeChanged event,
    Emitter<AdherenceState> emit,
  ) async {
    _range = event.range;
    await _load(emit, event.range);
  }

  Future<void> _onRefreshed(
    AdherenceRefreshed event,
    Emitter<AdherenceState> emit,
  ) async {
    await _load(emit, _range);
  }

  Future<void> _load(Emitter<AdherenceState> emit, AdherenceRange range) async {
    final profileId = _profileId;
    if (profileId == null) return;
    emit(AdherenceLoading(range: range));
    final params = AdherenceRangeParams(profileId: profileId, range: range);
    final summaryResult = await _getAdherenceSummary(params);
    final missedResult = await _getMissedDoses(params);

    final failure = summaryResult.fold<Failure?>((f) => f, (_) => null) ??
        missedResult.fold<Failure?>((f) => f, (_) => null);

    if (failure != null) {
      emit(AdherenceError(message: failure.message, range: range));
      return;
    }

    final summary = summaryResult.getOrElse((_) => throw UnimplementedError());
    final missed = missedResult.getOrElse((_) => throw UnimplementedError());
    emit(AdherenceLoaded(
      range: range,
      summary: summary,
      missedDoses: missed,
    ));
  }
}
