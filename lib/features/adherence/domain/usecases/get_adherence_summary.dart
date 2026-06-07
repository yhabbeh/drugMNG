import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/adherence/domain/entities/adherence_range.dart';
import 'package:drug/features/adherence/domain/entities/adherence_summary.dart';
import 'package:drug/features/adherence/domain/entities/daily_adherence_point.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';

@injectable
class GetAdherenceSummary
    implements UseCase<AdherenceSummary, AdherenceRangeParams> {
  GetAdherenceSummary(this._repository);

  final ScheduleRepository _repository;

  @override
  EitherFailure<AdherenceSummary> call(AdherenceRangeParams params) async {
    final start = DateTime(params.start.year, params.start.month, params.start.day);
    final days = <DateTime>[
      for (int i = 0; i < params.range.days; i++)
        start.add(Duration(days: i)),
    ];

    final results = await Future.wait(
      days.map((d) => _repository.getDoseLogsForDate(
            GetLogsForDateParams(profileId: params.profileId, date: d),
          )),
    );

    for (final r in results) {
      final failure = r.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) return left<Failure, AdherenceSummary>(failure);
    }

    int taken = 0;
    int skipped = 0;
    int missed = 0;
    int pending = 0;
    int streakDays = 0;

    final dailyPoints = <DailyAdherencePoint>[];

    for (var i = 0; i < days.length; i++) {
      final date = days[i];
      final logsResult = results[i];
      final logs = logsResult.getOrElse((_) => const <DoseLog>[]);

      int dayTaken = 0;
      int daySkipped = 0;
      int dayMissed = 0;
      int dayPending = 0;

      for (final log in logs) {
        switch (log.status) {
          case DoseStatus.taken:
            dayTaken++;
          case DoseStatus.skipped:
            daySkipped++;
          case DoseStatus.missed:
            dayMissed++;
          case DoseStatus.pending:
            dayPending++;
        }
      }

      if (dayTaken == 0 && daySkipped == 0 && dayMissed == 0 && dayPending == 0) {
        dailyPoints.add(DailyAdherencePoint(
          date: date,
          taken: 0,
          skipped: 0,
          missed: 0,
          pending: 0,
        ));
        continue;
      }

      taken += dayTaken;
      skipped += daySkipped;
      missed += dayMissed;
      pending += dayPending;

      dailyPoints.add(DailyAdherencePoint(
        date: date,
        taken: dayTaken,
        skipped: daySkipped,
        missed: dayMissed,
        pending: dayPending,
      ));
    }

    for (var i = dailyPoints.length - 1; i >= 0; i--) {
      final p = dailyPoints[i];
      final hasAnyLog = p.taken + p.skipped + p.missed + p.pending > 0;
      if (!hasAnyLog) continue;
      if (p.missed == 0 && p.taken > 0) {
        streakDays++;
      } else {
        break;
      }
    }

    return right<Failure, AdherenceSummary>(AdherenceSummary(
      range: params.range,
      taken: taken,
      skipped: skipped,
      missed: missed,
      pending: pending,
      streakDays: streakDays,
      dailyPoints: dailyPoints,
    ));
  }
}
