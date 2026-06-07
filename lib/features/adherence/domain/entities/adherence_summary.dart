import 'package:equatable/equatable.dart';

import 'package:drug/features/adherence/domain/entities/adherence_range.dart';
import 'package:drug/features/adherence/domain/entities/daily_adherence_point.dart';

final class AdherenceSummary extends Equatable {
  const AdherenceSummary({
    required this.range,
    required this.taken,
    required this.skipped,
    required this.missed,
    required this.pending,
    required this.streakDays,
    required this.dailyPoints,
  });

  final AdherenceRange range;
  final int taken;
  final int skipped;
  final int missed;
  final int pending;
  final int streakDays;
  final List<DailyAdherencePoint> dailyPoints;

  int get total => taken + skipped + missed + pending;

  int get logged => taken + skipped + missed;

  double get adherencePercent =>
      logged > 0 ? (taken / logged) * 100 : 0;

  @override
  List<Object?> get props =>
      [range, taken, skipped, missed, pending, streakDays, dailyPoints];
}
