import 'package:equatable/equatable.dart';

final class ScheduleTime extends Equatable {
  const ScheduleTime({
    required this.hour,
    required this.minute,
  });

  final int hour;
  final int minute;

  @override
  List<Object?> get props => [hour, minute];
}
