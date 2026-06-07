import 'package:equatable/equatable.dart';

final class AdherenceReport extends Equatable {
  const AdherenceReport({
    required this.profileId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalScheduled,
    required this.taken,
    required this.skipped,
    required this.missed,
  });

  final String profileId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalScheduled;
  final int taken;
  final int skipped;
  final int missed;

  double get adherencePercent =>
      totalScheduled > 0 ? (taken / totalScheduled) * 100 : 0;

  @override
  List<Object?> get props => [
        profileId,
        periodStart,
        periodEnd,
        totalScheduled,
        taken,
        skipped,
        missed,
      ];
}
