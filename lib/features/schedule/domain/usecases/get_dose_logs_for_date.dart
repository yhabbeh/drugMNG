import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';

@injectable
class GetDoseLogsForDate
    implements UseCase<List<DoseLog>, GetLogsForDateParams> {
  GetDoseLogsForDate(this._repository);

  final ScheduleRepository _repository;

  @override
  EitherFailure<List<DoseLog>> call(GetLogsForDateParams params) {
    return _repository.getDoseLogsForDate(params);
  }
}
