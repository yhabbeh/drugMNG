import 'package:equatable/equatable.dart';

final class DailyAdherencePoint extends Equatable {
  const DailyAdherencePoint({
    required this.date,
    required this.taken,
    required this.skipped,
    required this.missed,
    required this.pending,
  });

  final DateTime date;
  final int taken;
  final int skipped;
  final int missed;
  final int pending;

  int get total => taken + skipped + missed + pending;

  @override
  List<Object?> get props => [date, taken, skipped, missed, pending];
}
