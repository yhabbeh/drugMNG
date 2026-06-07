import 'package:equatable/equatable.dart';

import 'package:drug/features/adherence/domain/entities/adherence_range.dart';
import 'package:drug/features/adherence/domain/entities/adherence_summary.dart';
import 'package:drug/features/adherence/domain/entities/missed_dose.dart';

sealed class AdherenceState extends Equatable {
  const AdherenceState();

  @override
  List<Object?> get props => [];
}

class AdherenceInitial extends AdherenceState {
  const AdherenceInitial();
}

class AdherenceLoading extends AdherenceState {
  const AdherenceLoading({required this.range});

  final AdherenceRange range;

  @override
  List<Object?> get props => [range];
}

class AdherenceLoaded extends AdherenceState {
  const AdherenceLoaded({
    required this.range,
    required this.summary,
    required this.missedDoses,
  });

  final AdherenceRange range;
  final AdherenceSummary summary;
  final List<MissedDose> missedDoses;

  @override
  List<Object?> get props => [range, summary, missedDoses];
}

class AdherenceError extends AdherenceState {
  const AdherenceError({required this.message, required this.range});

  final String message;
  final AdherenceRange range;

  @override
  List<Object?> get props => [message, range];
}
