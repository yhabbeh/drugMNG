import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';

@injectable
class WatchSchedulesForProfile
    implements StreamUseCase<List<DoseSchedule>, String> {
  WatchSchedulesForProfile(this._repository);

  final ScheduleRepository _repository;

  @override
  StreamEitherFailure<List<DoseSchedule>> call(String params) {
    return _repository.watchSchedulesForProfile(params);
  }
}
