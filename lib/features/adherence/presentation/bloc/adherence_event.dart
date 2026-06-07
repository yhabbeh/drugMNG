import 'package:equatable/equatable.dart';

import 'package:drug/features/adherence/domain/entities/adherence_range.dart';

sealed class AdherenceEvent extends Equatable {
  const AdherenceEvent();

  @override
  List<Object?> get props => [];
}

class AdherenceStarted extends AdherenceEvent {
  const AdherenceStarted({
    required this.profileId,
    this.range = AdherenceRange.week,
  });

  final String profileId;
  final AdherenceRange range;

  @override
  List<Object?> get props => [profileId, range];
}

class AdherenceRangeChanged extends AdherenceEvent {
  const AdherenceRangeChanged(this.range);

  final AdherenceRange range;

  @override
  List<Object?> get props => [range];
}

class AdherenceRefreshed extends AdherenceEvent {
  const AdherenceRefreshed();
}
