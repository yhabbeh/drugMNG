import 'package:equatable/equatable.dart';

enum AdherenceRange {
  week(7, '7 Days'),
  month(30, '30 Days'),
  ninetyDays(90, '90 Days');

  const AdherenceRange(this.days, this.label);

  final int days;
  final String label;
}

final class AdherenceRangeParams extends Equatable {
  const AdherenceRangeParams({
    required this.profileId,
    required this.range,
    DateTime? now,
  }) : _now = now;

  final String profileId;
  final AdherenceRange range;
  final DateTime? _now;

  DateTime get now => _now ?? DateTime.now();

  DateTime get end => now;

  DateTime get start =>
      DateTime(now.year, now.month, now.day).subtract(Duration(days: range.days - 1));

  @override
  List<Object?> get props => [profileId, range, _now];
}
