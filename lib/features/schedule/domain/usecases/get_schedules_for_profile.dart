import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';

@injectable
class GetSchedulesForProfile
    implements UseCase<List<DoseSchedule>, String> {
  GetSchedulesForProfile(this._repository);

  final ScheduleRepository _repository;

  @override
  EitherFailure<List<DoseSchedule>> call(String params) {
    return _repository.getSchedulesForProfile(params);
  }
}
