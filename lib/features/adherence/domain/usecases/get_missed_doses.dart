import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/adherence/domain/entities/adherence_range.dart';
import 'package:drug/features/adherence/domain/entities/missed_dose.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';

@injectable
class GetMissedDoses
    implements UseCase<List<MissedDose>, AdherenceRangeParams> {
  GetMissedDoses(this._repository);

  final ScheduleRepository _repository;

  @override
  EitherFailure<List<MissedDose>> call(AdherenceRangeParams params) async {
    final now = params.now;
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
      if (failure != null) return left<Failure, List<MissedDose>>(failure);
    }

    final missed = <MissedDose>[];
    for (final logsResult in results) {
      final logs = logsResult.getOrElse((_) => const <DoseLog>[]);
      for (final log in logs) {
        final isInPast = !log.scheduledAt.isAfter(now);
        final isMissed = log.status == DoseStatus.missed ||
            (log.status == DoseStatus.pending && isInPast);
        if (isMissed) {
          missed.add(MissedDose(
            logId: log.id,
            medicationId: log.medicationId,
            medicationName: log.medicationName,
            scheduledAt: log.scheduledAt,
          ));
        }
      }
    }

    missed.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return right<Failure, List<MissedDose>>(missed);
  }
}
