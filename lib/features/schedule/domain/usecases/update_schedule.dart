import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';

@injectable
class UpdateSchedule implements UseCase<Unit, DoseSchedule> {
  UpdateSchedule(this._repository);

  final ScheduleRepository _repository;

  @override
  EitherFailure<Unit> call(DoseSchedule params) {
    return _repository.updateSchedule(params);
  }
}
